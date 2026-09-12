# Foothold collects on a schedule, resuming from a watermark per source

Foothold is a mountable, operator-only engine that watches one product's presence on the web. It reads Google Search Console, a pay-as-you-go SERP API, the host's visit analytics and the host's own content inventory. Nothing is fetched on request. A recurring job runs a Sweep, and every source in a Sweep records a run with the last date it fully collected, so the next run resumes from there and never pays for the same day twice. Sweeps are idempotent: every write is a find-or-create or an upsert keyed by term, date and source.

Host data enters only through lambdas set in an initializer. Foothold tables hold no host ids and no foreign keys to host tables. The host's app/ directory never references Foothold.

## Considered options

- **Fetch on page load.** Simple, but every visit to the page costs API money and Search Console data is not final for two days anyway.
- **Callbacks on host models.** Foothold has no interest in individual host records, only in daily totals, and callbacks would couple the engine to one host.
- **Scheduled sweep with a watermark per source (chosen).** Data lags by a day for visits and two days for Search Console. Cost is bounded by the number of tracked terms, and a failed night simply resumes the next one.

## Consequences

- Installing Foothold touches only the Gemfile, routes, an initializer and the job schedule.
- Each source can be turned off by leaving its credential unset; the run records "skipped" and the watermark does not move.
- Readings for a day can arrive after the visits for that day were counted, so both the visits sweep and the Search Console sweep copy attribution in their own direction.
- Sweep runs are kept for ninety days so spend and failures stay visible.
