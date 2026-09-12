# Foothold

Operator-only watch on one product's presence on the web. Foothold collects, on a schedule, what Google shows the site for, where the site ranks, which pages visitors land on and whether they sign up, and turns that into a short list of terms with a trend each. Later releases add rivals, a queue of suggested actions, a weekly digest, a site audit and mentions.

It is a mountable engine for the operator, not a customer-facing feature, and it is deliberately not a dashboard. Open it once a week, or read the digest.

Built for my own Rails apps and shared as-is under MIT. It assumes a fairly conventional shell (see [What it expects from the host](#what-it-expects-from-the-host)). Issues and pull requests are welcome, but there is no support commitment and the API may change between minor versions.

## Vocabulary

**Site**: the product domain this install watches. One per install.

**Term**: a search phrase worth ranking for. Discovered from Search Console, declared by a Page, borrowed from a Rival, or added by hand. Only tracked Terms get a paid SERP check.

**Rival**: a competitor domain whose ranking Terms are compared with the Site's.

**Page**: an entry in the Site's own content inventory, keyed by path, with the Term it targets.

**Reading**: one observed position for a Term on a date, from Search Console or a SERP check, with the landing page and that day's search visits and signups.

**Referrer**: a domain that sent a visitor.

**Mention**: a place on the web where the product was named.

**Finding**: a problem the audit observed on a Page.

**Lead**: a suggested action. Open, done or dismissed.

**Digest**: the Monday email.

**Sweep**: a scheduled collection run. Nightly, weekly or monthly.

## How data gets in

Only through the Sweep. `Foothold::Sweep.call(:nightly)` refreshes the content inventory, counts yesterday's visits per landing page, pulls Search Console queries up to two days ago, checks the SERP for every tracked Term and, monthly, prices Terms. `Foothold::Sweep.call(:weekly)` refreshes each Rival's ranking Terms. `Foothold::SweepJob` wraps both for a scheduler and the "Sweep now" button runs the nightly one on demand.

After every Sweep the lead builders run. Each reports the Leads the data supports right now; a Lead is raised once, refreshed while open, and closed by the Sweep when its condition clears. See [docs/adr/0002-leads-are-derived-and-keyed-by-identity.md](docs/adr/0002-leads-are-derived-and-keyed-by-identity.md).

Every source records a `SweepRun` with a watermark, the last date it fully collected, and what the run cost. A source whose credential is missing records "skipped" and moves nothing. The reasoning is in [docs/adr/0001-collect-on-a-schedule-with-watermarks.md](docs/adr/0001-collect-on-a-schedule-with-watermarks.md).

## What it expects from the host

| Concern | Default | Used for |
|---|---|---|
| Visits | `Ahoy::Visit` and `Ahoy::Event` (`registered`) | visits, search visits and signups per Page per day |
| Content inventory | `config.pages` lambda, empty by default | Pages and their target Terms |
| Search Console | `FOOTHOLD_GOOGLE_SERVICE_ACCOUNT_JSON` | queries, impressions, positions |
| SERP and keyword data | `FOOTHOLD_DATAFORSEO_LOGIN` / `_PASSWORD` | tracked Term positions, volume, difficulty |

Screens render in a host layout (`hub` by default), inherit from the host's `ApplicationController` and use the host's `Ui::*` ViewComponents with Tailwind and DaisyUI class names.

## Installation

```ruby
# Gemfile
gem "foothold", github: "scottharvey/foothold", tag: "v0.1.0"
```

```bash
bundle install
bin/rails db:migrate   # the engine adds its own migrations
```

```ruby
# config/routes.rb
mount Foothold::Engine, at: Foothold.configuration.mount_path
```

```yaml
# config/recurring.yml (Solid Queue), or your scheduler of choice
foothold_nightly:
  class: Foothold::SweepJob
  args: [ nightly ]
  schedule: every day at 3am
```

Then set the environment keys, visit `/foothold` as an admin and press "Sweep now".

Search Console: create a service account in Google Cloud, enable the Search Console API, download its JSON key, and add the service account's email address as a user on the property in Search Console. Put the JSON (raw or Base64) in `FOOTHOLD_GOOGLE_SERVICE_ACCOUNT_JSON`.

## Configuration

`config/initializers/foothold.rb`. Every setting has a default.

```ruby
Foothold.configure do |config|
  config.mount_path = "/foothold"
  config.site_domain = "example.com"        # default: ENV["APP_HOST"]
  config.site_name = "Example"
  config.search_console_property = "sc-domain:example.com"
  config.location_code = 2840               # DataForSEO location, United States
  config.language_code = "en"

  # The Site's own pages. Runs inside the Sweep.
  config.pages = -> { [ { url: "/blog/hello", title: "Hello", description: "…", term: "anki alternative", kind: "blog", published_on: Date.new(2026, 8, 23) } ] }

  # Visits for one day. The default reads Ahoy; set to nil to disable.
  config.visits = ->(date) { [ Foothold::Visit.new(landing_path: "/", referring_domain: "google.com", signup: false, started_at: Time.current) ] }

  # Cost and discovery controls.
  config.thresholds[:max_tracked_terms] = 50
  config.thresholds[:discover_min_impressions] = 5

  # Lead kind => a how-to in the host, and how to link to it from the queue.
  config.playbooks = { "term_gap" => "competitor-comparison-posts" }
  config.playbook_url = ->(slug) { main_app.growth_playbook_path(slug) }
end
```

## Layout

- `app/models/foothold`: Site, Term, Page, PageDay, Reading, Rival, RivalTerm, Lead, SweepRun, and the TermSummary shown in the list
- `app/services/foothold/sweep`: one class per source
- `app/services/foothold/leads`: one builder per lead kind
- `lib/foothold`: configuration, the Search Console and DataForSEO clients, URL normalisation
- `app/controllers/foothold`, `app/views/foothold`: the screens
- `db/migrate`: the migrations that create the `foothold_*` tables

## Tests

The engine does not yet carry a dummy app. Its tests run inside the host application it was built for, where Ahoy and the content inventory exist for real.

## License

MIT. See `MIT-LICENSE`.
