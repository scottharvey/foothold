module Foothold
  module Leads
    # What can be done about each kind of lead. The first verb is the primary
    # one. Verbs of type :issue hand the work to the Claude Code GitHub Action
    # through an issue; :post verbs Foothold carries out itself; :link verbs
    # go somewhere else; :copy verbs put text on the clipboard.
    module Actions
      Action = Data.define(:verb, :label, :type, :primary, :input) do
        def issue? = type == :issue
        def post? = type == :post
        def link? = type == :link
        def copy? = type == :copy
      end

      VERBS = {
        propose: { label: "Propose page", type: :issue },
        refresh: { label: "Refresh page", type: :issue },
        revise: { label: "Revise page", type: :issue },
        fix: { label: "Fix", type: :issue },
        retitle: { label: "Propose title", type: :issue, input: :title },
        retire: { label: "Retire page", type: :issue },
        approve: { label: "Approve", type: :issue },
        track: { label: "Track", type: :post },
        ignore: { label: "Ignore term", type: :post },
        inspect: { label: "Inspect in Search Console", type: :link },
        visit: { label: "Visit", type: :link },
        reply: { label: "Reply", type: :link },
        contact: { label: "Save contact", type: :link },
        ask_for_link: { label: "Copy link request", type: :copy }
      }.freeze

      module_function

      def verbs(lead)
        payload = lead.payload
        case lead.kind
        when "drop" then [ :refresh ]
        when "leaky_page" then [ :revise ]
        when "not_indexed" then payload["fixable"] ? [ :fix, :inspect ] : [ :inspect ]
        when "term_gap" then [ :propose, :track ]
        when "page_two" then payload["tracked"] ? [ :refresh ] : [ :refresh, :track ]
        when "title_mismatch" then [ :retitle ]
        when "track_this" then [ :track, :ignore ]
        when "new_referrer" then [ :visit, :contact ]
        when "mention" then payload["linked"] ? [ :reply, :contact ] : [ :reply, :ask_for_link, :contact ]
        when "audit" then [ :fix ]
        when "alternative_gap" then [ :approve ]
        when "page_underperforming" then payload["recommendation"] == "retire" ? [ :retire, :revise ] : [ :revise, :retire ]
        else []
        end
      end

      def for(lead)
        verbs(lead).each_with_index.map do |verb, index|
          spec = VERBS.fetch(verb)
          Action.new(verb: verb, label: spec[:label], type: spec[:type], primary: index.zero?, input: spec[:input])
        end
      end

      def find(lead, verb)
        self.for(lead).find { |action| action.verb == verb.to_s.to_sym }
      end

      # Mute keys this lead could be silenced by, most specific first.
      def mute_options(lead)
        payload = lead.payload
        keys = []
        keys << "term:#{payload['phrase']}" if payload["phrase"].present?
        keys << "phrase:#{pattern_for(payload['phrase'])}" if payload["phrase"].present? && pattern_for(payload["phrase"])
        keys << "rival_path:#{payload['domain']}#{payload['path']}" if lead.kind == "term_gap" && payload["domain"].present?
        keys << "page:#{payload['url']}" if lead.page_id.present? && payload["url"].present?
        keys << "domain:#{payload['domain']}" if %w[new_referrer mention].include?(lead.kind) && payload["domain"].present?
        keys.uniq.map { |key| { key: key, label: Mute.label_for(key) } }
      end

      # "cuevas in spanish" => "* in spanish": the query template, when the
      # phrase has one.
      def pattern_for(phrase)
        words = phrase.to_s.split
        return nil if words.size < 3

        "* #{words.drop(1).join(' ')}"
      end
    end
  end
end
