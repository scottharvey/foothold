module Foothold
  # Defaults match a conventional Rails SaaS shell (Ahoy, a marketing site with
  # a blog and feature pages) so a host initializer can stay small.
  class Configuration
    HOST_CLASSES = %i[visits_class events_class].freeze

    SEARCH_ENGINES = %w[google bing duckduckgo yahoo ecosia brave yandex baidu startpage].freeze

    DEFAULT_THRESHOLDS = {
      max_tracked_terms: 50,            # tracked Terms that get a paid SERP check per night
      serp_depth: 30,                   # organic results fetched per SERP check
      search_console_backfill_days: 90, # first Search Console run reaches this far back
      discover_min_impressions: 5,      # Search Console queries below this never become Terms
      volume_refresh_days: 30,          # how often volume and difficulty are refreshed
      volume_batch_size: 1000,
      sweep_run_retention_days: 90,
      rival_keyword_limit: 200,
      index_inspection_limit: 200,
      crawl_limit: 300,
      track_this_impressions: 100,
      drop_places: 5,
      page_two_range: 11..20,
      leaky_page_min_clicks: 20,
      not_indexed_after_days: 14,
      lead_reopen_days: 30,             # a lead the operator marked done comes back after this if the condition persists
      snooze_days: 28,
      queue_size: 20,                   # open leads shown on the Queue; the rest wait, ranked by score
      outcome_window_days: 28,          # days after a lead is resolved before its effect is measured
      term_gap_min_volume: 50,          # rival phrases below this monthly volume never become term gaps
      term_gap_track_limit: 10,         # phrases "Track" starts tracking from a term gap cluster
      alternative_rival_position: 10,   # a rival must rank this well or better on a qualifying term
      alternative_min_rival_terms: 3,   # ...for at least this many terms before it's worth a page
      programmatic_page_grace_days: 42  # how long a generated page gets before its traffic/signups are judged
    }.freeze

    attr_accessor :mount_path, :parent_controller, :layout, :authenticate, :skip_host_before_actions,
                  :site_domain, :site_description, :location_code, :language_code,
                  :pages, :visits, :signup_event_name, :search_engines,
                  :search_console_client, :dataforseo_client, :fetcher, :github_client, :relevance_client,
                  :thresholds, :digest_recipient, :parent_mailer,
                  :playbooks, :playbook_url, :rapport_new_contact_url, :mention_feeds,
                  :page_style_guidance,
                  *HOST_CLASSES
    attr_writer :site_name, :search_console_property

    def initialize
      @mount_path = "/foothold"
      @parent_controller = "::ApplicationController"
      @layout = "hub"
      @skip_host_before_actions = %i[require_authentication redirect_to_onboarding_if_needed sync_stripe_checkout_session require_active_subscription]

      # The one Site this install watches.
      @site_domain = ENV["APP_HOST"].presence
      @site_name = nil
      # One line on what the product is, for the relevance check on rival phrases.
      @site_description = nil
      @search_console_property = nil
      @location_code = 2840 # United States
      @language_code = "en"

      # Host reads. Both run only inside the Sweep.
      # pages: -> { [ { url:, title:, description:, term:, kind:, published_on: }, ... ] }
      @pages = -> { [] }
      # visits: ->(date) { [ Foothold::Visit, ... ] }; the default reads Ahoy.
      @visits_class = "Ahoy::Visit"
      @events_class = "Ahoy::Event"
      @signup_event_name = "registered"
      @visits = default_visits
      @search_engines = SEARCH_ENGINES

      # API clients, built lazily so a missing key only disables that source.
      @search_console_client = -> { SearchConsole.from_env }
      @dataforseo_client = -> { DataForSeo.from_env }
      @github_client = -> { GitHub.from_env }
      # Anything responding to classify(phrases, site_name:, description:).
      @relevance_client = -> { Relevance.from_env }
      @fetcher = nil

      @thresholds = DEFAULT_THRESHOLDS.dup

      # Used from the second release on. Declared now so hosts can set them.
      @digest_recipient = ENV["MAIL_FROM"].presence
      @parent_mailer = "::ApplicationMailer"
      @playbooks = {}
      @playbook_url = nil
      # ->(label:, url:) { main_app.rapport.new_contact_path(...) }, run in the view.
      @rapport_new_contact_url = nil
      @mention_feeds = []

      # Handed to the GitHub Action as house style, one rule per line. A host
      # can override this list entirely; these are just the defaults.
      @page_style_guidance = [
        "No em dashes (—). Use a period, comma, or parentheses instead.",
        "No invented statistics, customer quotes, or capability claims — only what config/features.yml actually says."
      ]

      # Runs in the controller. Redirects anyone who is not a signed-in admin.
      @authenticate = lambda do
        resume_session if respond_to?(:resume_session, true)
        user = Current.user if defined?(::Current)
        unless user&.admin?
          redirect_to(user ? main_app.root_path : main_app.new_session_path)
        end
      end
    end

    def site_name
      @site_name.presence || site_domain
    end

    def search_console_property
      @search_console_property.presence || "sc-domain:#{site_domain}"
    end

    def threshold(key)
      thresholds.fetch(key)
    end

    def search_engine?(referring_domain)
      labels = referring_domain.to_s.downcase.split(".")
      labels.intersect?(search_engines)
    end

    private

    def default_visits
      lambda do |date|
        visits = Foothold.host_class(:visits_class) or next []
        events = Foothold.host_class(:events_class)
        scope = visits.where(started_at: date.in_time_zone.all_day)
        signups = if events
          events.where(name: signup_event_name, visit_id: scope.select(:id)).distinct.pluck(:visit_id).to_set
        else
          Set.new
        end
        scope.pluck(:id, :landing_page, :referring_domain, :started_at).map do |id, landing, referrer, started_at|
          Visit.new(landing_path: Url.path(landing), referring_domain: referrer, signup: signups.include?(id), started_at: started_at)
        end
      end
    end
  end
end
