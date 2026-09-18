# Leads are scored in one unit, clustered where the rival is, and each carries a verb

The first production install raised two thousand term-gap leads in three days, one per phrase a rival's dictionary section ranked for. The queue sorted by kind, so nothing below term gaps was reachable, dismiss came back in a month, and every row ended in Done or Dismiss with nothing in between. Three decisions fix that.

**One score across kinds.** Every builder estimates the monthly search visits at stake for its lead, using a fixed click-through curve by position and the phrase's volume (or Search Console impressions when volume is unknown). The queue sorts by that score and shows a working set; the rest wait. A drop on a term that sends signups outranks a low-volume gap whatever their kinds.

**Clusters, not phrases.** A term gap is one lead per rival and first path segment of the rival's landing pages, carrying the phrases and the winning pages as evidence. A section a rival wins with a template is one decision. Phrases below a volume floor, phrases the Site already ranks for, and phrases a relevance check says a prospective customer would never type are left out. Rival phrases stay on the rival row and only become Terms when tracked.

**A verb per kind, and permanence.** Each kind declares its verbs. Issue verbs open a GitHub issue carrying the lead's evidence for a drafting Action; Foothold carries out the rest itself or links out. Done records the verb and where it went, and a month later the term's position or the page's visits are compared before and after. Dismissed never returns; Snooze hides for a month; Mute silences a term, a query pattern, a page, a rival section or a domain for good.

## Considered options

- **Lower the rival keyword limit.** Cheap, but the same flood arrives at any limit above a few dozen, and it hides the signal (a rival winning a whole section) along with the noise.
- **Rank within kind only.** Keeps the kind order the digest already used, but a kind with thousands of rows still buries every other kind.
- **Score, cluster and act (chosen).** More code in the builders and a verb registry, but the queue becomes a short list of decisions with a record of whether each paid off.

## Consequences

- Builders own their evidence. A verb that needs the top of the SERP, the queries that landed on a page or the index inspection reason gets it from the payload, so the sweeps store those now.
- Scores are estimates in a made-up unit. They rank; they do not forecast. The thresholds and the mute list are visible and editable so a wrong ranking is fixed by the operator, not by code.
- Changing a cluster's key (rival and path segment) orphans its open lead, which the sweep closes and replaces.
