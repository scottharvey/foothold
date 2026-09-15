# Changelog

## 0.6.1

- Fix: the DataForSEO client sent no `User-Agent`/`Accept` headers (Ruby's
  bare default), and treated any non-`20000` task status as a hard failure —
  including status `40106` ("Task completed with partial results"), which
  DataForSEO returns when some SERP pages time out but still hands back
  whatever it did retrieve, uncharged. The Serp sweep was failing every run
  because of this. Partial-result tasks now keep their usable results
  instead of being discarded.

## 0.6.0

- Programmatic SEO pages, first template (alternatives pages): a new
  `alternative_gap` Lead fires when a Rival ranks well for several tracked
  Terms and there's no alternatives page pointing at us instead. Approving
  it opens a GitHub issue (new `Foothold::GitHub` client, `FOOTHOLD_GITHUB_TOKEN`
  / `FOOTHOLD_GITHUB_REPO`) carrying the Rival's real ranking data, for a
  Claude Code GitHub Action to draft into a PR. A new `page_underperforming`
  Lead watches generated (`kind: "alternative"`) Pages after a grace period
  and flags ones with no traffic, or traffic with no signups — using the
  Ahoy-derived `page_days.signups` the Visits sweep already collects, no new
  data plumbing needed.
- The GitHub issue Approve opens now carries house style rules for the
  drafting Action (new `config.page_style_guidance`, defaults to "no em
  dashes" and "no invented claims" — a host can override the list) and tells
  it where to add screenshot placeholders (a new `screenshots` frontmatter
  field on alternatives pages, rendered with the host's existing
  `marketing_screenshot_placeholder`, same as `config/features.yml` already
  does).

## 0.5.15

- Fix: the lead show page's subtitle built its "opened X ago" `<time>` tag
  with plain string interpolation, which drops Rails' `html_safe` flag —
  so the shared header component escaped it and printed the raw `<time
  datetime="...">` markup as visible text instead of rendering it. Built
  with `safe_join` instead so the tag renders normally.

## 0.5.14

- Fix: the Queue's row checkboxes (added for bulk actions) shifted DaisyUI's
  `.list-row` grid by one column, so the badge silently took over the
  "fill remaining space" track instead of the summary text — giving every
  row a ragged, inconsistently-indented title. The summary column is now
  marked `list-col-grow` explicitly instead of relying on column position.

## 0.5.13

- Lead detail pages explain the SEO behind each kind in plain language for
  an operator who isn't an SEO: what the signal means, why it matters, and
  what typically helps — separate from config.playbooks, which stays the
  host's own specific how-to

## 0.5.12

- Every lead in the Queue is now clickable, not just the ones tied to a
  Page. Each opens its own detail screen: evidence, links to wherever the
  lead points (a Foothold page/term, a mention's actual URL, a referrer's
  site, a page-two landing URL), a ranking-rivals table for term gaps, and
  the remaining payload as a detail table, plus the same Playbook/Track/
  Done/Dismiss actions as the row

## 0.5.11

- Queue: select any number of leads and Done or Dismiss them together,
  instead of one button click per lead

## 0.5.10

- Sweep history episodes are now collapsible (native `<details>`, no JS):
  only the latest episode is open by default, so a long history doesn't bury
  the most recent run under dozens of older ones

## 0.5.9

- Fix: `Mentions::HackerNews` sent `feed[:query]` unquoted to Algolia's
  search, which OR-matches the individual words rather than the phrase — a
  two-word product name (or common single words) surfaced entirely
  unrelated stories/comments as "mentions". The query is now quoted, so
  only the exact phrase matches.

Note: v0.5.8 was tagged empty (a botched `git add` staged nothing) and
was left in place rather than force-deleted. Skip straight to v0.5.9.

## 0.5.7

- Fix: `SearchConsole#search_analytics` called `query_search_analytics`,
  which doesn't exist on `google-apis-searchconsole_v1` (the real method is
  `query_searchanalytic`, singular). Every Search Console sweep raised
  `NoMethodError` and was never caught, since the host's test suite runs
  against a fake client. Confirmed against google-apis-searchconsole_v1 0.23.0.

## 0.5.6

- Drops its own "Hub" link from the header, now that the host places one
  link back to the Hub in the layout's top bar (next to Sign out) shared by
  every operator tool, instead of each tool showing its own

## 0.5.5

- Header now renders through the host's shared Ui::ToolHeaderComponent, so
  Foothold's chrome matches every other operator tool on /hub (Rapport,
  Growth, Email templates) instead of its own bespoke markup. The product
  name next to "Foothold" is now the host app's own name (e.g. "Launchpad"),
  not the tracked site's domain, matching how every other tool shows it.

## 0.5.4

- Sweep history groups consecutive same-kind runs into one episode, since a
  single click runs several sources back to back; skipped sources (no
  credential configured) are shown but faded so real activity stands out
- Digest section moved into a card to match the rest of the page

## 0.5.3

- Sweeps moved into the main nav alongside Queue, Terms, Rivals and Mentions

## 0.5.2

- Sweep now, Weekly audit and Send digest now moved out of the main nav into
  a Sweeps page, which also lists sweep history, watermarks and cost — data
  that existed already but had no screen of its own

## 0.5.1

- Queue, Terms, Rivals and Mentions are four separate pages instead of one
  long page with anchor links, matching how Mentions already worked

## 0.5.0

- Mentions: Google Alerts, Hacker News, App Store reviews and Bluesky, each polled from its own watermark
- A mention lead, unresolved mentions listed at /foothold/mentions
- New mentions and findings sections in the Monday digest

## 0.4.0

- The weekly Sweep now audits every page still in the sitemap: HTTP status, title and description length, H1 count, a self-pointing canonical, image alt text, broken and redirected internal links, thin content, and orphan pages
- Search Console index coverage per page, oldest-checked first
- Audit and not-indexed leads, and a page detail screen listing open findings

## 0.3.0

- Referrers, recorded per day from the same visits the nightly sweep already reads
- New referrer and position drop leads
- The Monday digest: movers, new referrers, findings (empty until the audit ships), and the top three leads, stored per week and mailed once
- "Send digest now" for testing on real data

## 0.2.0

- Rivals and their ranking Terms, refreshed by the weekly Sweep
- Leads: a queue of suggested actions derived after every Sweep, keyed by kind and identity, with done, dismiss and track actions
- Builders for term gap, page two, leaky page, title mismatch and track this
- Host-configured Growth playbook per lead kind

## 0.1.0

First release.

- Sites, Terms, Pages and Readings
- Nightly Sweep: content inventory from the host, visits per page per day from the host's analytics, Search Console queries and positions, SERP checks for tracked Terms, monthly volume and difficulty
- A watermark per source so runs resume where they left off and API spend is recorded per run
- Term list with a 28-day position sparkline, clicks and signups attributed by landing page
- Admin-only access by default, configurable per host
