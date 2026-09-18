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

**Mention**: a place on the web where the product was named. Polled from Google Alerts, Hacker News, App Store reviews, Bluesky, Reddit and X.

**Finding**: a problem the audit observed on a Page.

**Lead**: a suggested action with a verb and a score. Open (possibly snoozed), done or dismissed.

**Mute**: something that never becomes a Lead again: a term, a query pattern, a page, a rival section or a domain.

**Digest**: the Monday email.

**Sweep**: a scheduled collection run. Nightly, weekly or monthly.

## How data gets in

Only through the Sweep. `Foothold::Sweep.call(:nightly)` refreshes the content inventory, counts yesterday's visits per landing page, pulls Search Console queries up to two days ago, checks the SERP for every tracked Term and, monthly, prices Terms. `Foothold::Sweep.call(:weekly)` refreshes each Rival's ranking Terms. `Foothold::SweepJob` wraps both for a scheduler and the "Sweep now" button runs the nightly one on demand.

After every Sweep the lead builders run. Each reports the Leads the data supports right now, scored in estimated monthly search visits at stake; a Lead is raised once, refreshed while open, and closed by the Sweep when its condition clears. Dismissed leads never come back; done leads come back after a month if the condition persists. See [docs/adr/0002-leads-are-derived-and-keyed-by-identity.md](docs/adr/0002-leads-are-derived-and-keyed-by-identity.md).

Rival phrases are screened once for relevance when `FOOTHOLD_ANTHROPIC_API_KEY` is set, so a rival's dictionary section doesn't flood the queue, and the ones that pass are clustered by rival section into one Lead each. A Lead the operator resolves is measured a month later: position before and after for a term, search visits and signups for a page.

## What each lead offers

The Queue shows the best `queue_size` leads by score. Every lead has a primary verb; the rest sit behind ⋯. Issue verbs open a GitHub issue carrying the lead's evidence for the Claude Code Action, which opens a PR.

| Kind | Primary verb | Also |
|---|---|---|
| Drop | Refresh page (issue, with who ranks above you now) | |
| Leaky page | Revise page (issue, with the queries that land there) | |
| Not indexed | Fix (issue) when the block is ours, else Inspect in Search Console | |
| Term gap | Propose page (issue, with the cluster and the rival's winning pages) | Track the biggest terms |
| Page two | Refresh page (issue, with the top of the SERP) | Track |
| Title mismatch | Propose title (issue, editable before sending) | |
| Track this | Track | Ignore term |
| New referrer | Visit | Save contact |
| Mention | Reply | Copy link request, Save contact |
| Audit | Fix (issue, with the findings) | |
| Alternative gap | Approve (issue) | |
| Page underperforming | Revise page or Retire page, whichever the data suggests | the other |

Every lead can also be marked Done by hand with a note, snoozed, dismissed for good, or muted (which closes everything the mute covers).

Every source records a `SweepRun` with a watermark, the last date it fully collected, and what the run cost. A source whose credential is missing records "skipped" and moves nothing. The reasoning is in [docs/adr/0001-collect-on-a-schedule-with-watermarks.md](docs/adr/0001-collect-on-a-schedule-with-watermarks.md).

## What it expects from the host

| Concern | Default | Used for |
|---|---|---|
| Visits | `Ahoy::Visit` and `Ahoy::Event` (`registered`) | visits, search visits and signups per Page per day |
| Content inventory | `config.pages` lambda, empty by default | Pages and their target Terms |
| Search Console | `FOOTHOLD_GOOGLE_SERVICE_ACCOUNT_JSON` | queries, impressions, positions, index coverage |
| SERP and keyword data | `FOOTHOLD_DATAFORSEO_LOGIN` / `_PASSWORD` | tracked Term positions, volume, difficulty, rival ranking Terms |
| Fetching the Site's own pages | `config.fetcher`, a plain `Net::HTTP` client by default | the weekly audit |
| Mentions | `config.mention_feeds`, empty by default | Google Alerts, Hacker News, App Store reviews, Bluesky, Reddit, X |
| GitHub issues | `FOOTHOLD_GITHUB_TOKEN` / `FOOTHOLD_GITHUB_REPO` | every issue verb: proposing, refreshing, revising, fixing, retitling and retiring pages for a Claude Code Action to draft |
| Relevance check | `FOOTHOLD_ANTHROPIC_API_KEY` (or `ANTHROPIC_API_KEY`), optional `FOOTHOLD_RELEVANCE_MODEL` | screening rival phrases once each; leave unset to skip |
| Contacts | `config.rapport_new_contact_url` | the Save contact verb on referrers and mentions |

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

Then set the environment keys and visit `/foothold` as an admin. The nav bar has Queue (the root, what to do next), Terms, Rivals, Mentions, Mutes and Sweeps. Press "Sweep now".

Upgrading to 0.7.0 runs a migration that empties every Foothold table. Add your rivals back afterwards.

Search Console: create a service account in Google Cloud, enable the Search Console API, download its JSON key, and add the service account's email address as a user on the property in Search Console. Put the JSON (raw or Base64) in `FOOTHOLD_GOOGLE_SERVICE_ACCOUNT_JSON`.

## Configuration

`config/initializers/foothold.rb`. Every setting has a default.

```ruby
Foothold.configure do |config|
  config.mount_path = "/foothold"
  config.site_domain = "example.com"        # default: ENV["APP_HOST"]
  config.site_name = "Example"
  config.site_description = "a spaced-repetition app for learning languages"  # for the relevance check
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
  config.thresholds[:queue_size] = 20            # leads shown on the Queue
  config.thresholds[:term_gap_min_volume] = 50   # rival phrases below this never become term gaps
  config.thresholds[:snooze_days] = 28
  config.thresholds[:outcome_window_days] = 28

  # Relevance check on rival phrases. Anything responding to
  # classify(phrases, site_name:, description:) => { phrase => true/false }.
  # The default reads FOOTHOLD_ANTHROPIC_API_KEY; return nil to skip.
  config.relevance_client = -> { Foothold::Relevance.from_env }

  # Lead kind => a how-to in the host, and how to link to it from the queue.
  config.playbooks = { "term_gap" => "competitor-comparison-posts" }
  config.playbook_url = ->(slug) { main_app.growth_playbook_path(slug) }

  # The Save contact verb on referrer and mention leads. Runs in the view.
  config.rapport_new_contact_url = ->(label:, url:) { main_app.rapport.new_contact_path }

  # Mention feeds. Google Alerts, Hacker News, App Store and Bluesky need no
  # auth. Reddit and X need credentials below. Leave out a feed to skip its
  # source.
  config.mention_feeds = [
    { source: "google_alerts", url: ENV["FOOTHOLD_GOOGLE_ALERTS_RSS"] },
    { source: "hacker_news", query: config.site_name },
    { source: "app_store", app_id: ENV["FOOTHOLD_APP_STORE_ID"], country: "us" },
    { source: "bluesky", query: config.site_name },
    { source: "reddit", query: config.site_name },
    { source: "x", query: config.site_name }
  ].select { |feed| feed.values_at(:url, :query, :app_id).any?(&:present?) }
end
```

### Reddit and X credentials

Reddit and X aren't free/no-auth like the other mention sources, so they read
credentials from `ENV` (or pass `client_id:`/`client_secret:`/`user_agent:`/
`bearer_token:` directly on the feed hash instead):

**Reddit** — free, but needs an app:

1. Create a "script" app at <https://www.reddit.com/prefs/apps> ("create app" → script).
2. Set `FOOTHOLD_REDDIT_CLIENT_ID` (the string under the app name) and `FOOTHOLD_REDDIT_CLIENT_SECRET`.
3. Set `FOOTHOLD_REDDIT_USER_AGENT` to something descriptive, per [Reddit's API rules](https://github.com/reddit-archive/reddit/wiki/API), e.g. `"web:foothold:v1 (by /u/yourname)"`.

Foothold exchanges these for an hourly OAuth2 app-only token on each sweep — no refresh-token bookkeeping needed.

**X** — no free tier for search; needs a paid pay-per-usage (or higher) developer plan:

1. Apply for API access and enable billing at <https://developer.x.com>.
2. Generate an app-only **Bearer Token** for your app.
3. Set `FOOTHOLD_X_BEARER_TOKEN`.

X's recent-search endpoint only covers the last 7 days, and pay-per-usage billing is metered per post returned (roughly $0.005/post as of 2026) — cheap for a low-mention-volume product, but check <https://docs.x.com/x-api/getting-started/pricing> for current rates before enabling it.

## Layout

- `app/models/foothold`: Site, Term, Page, PageDay, Reading, Rival, RivalTerm, Lead, SweepRun, and the TermSummary shown in the list
- `app/services/foothold/sweep`: one class per source
- `app/services/foothold/leads`: one builder per lead kind, plus `Score`, `Actions` (the verbs per kind), `Act` (carries one out), `Requests` (the GitHub issue per verb) and `Outcomes`
- `lib/foothold/fetcher.rb`: fetches the Site's own pages for the weekly audit
- `lib/foothold`: configuration, the Search Console, DataForSEO, GitHub and relevance (Claude) clients, URL normalisation
- `app/controllers/foothold`, `app/views/foothold`: the screens
- `db/migrate`: the migrations that create the `foothold_*` tables

## Tests

The engine does not yet carry a dummy app. Its tests run inside the host application it was built for, where Ahoy and the content inventory exist for real.

## License

MIT. See `MIT-LICENSE`.
