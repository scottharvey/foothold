# Leads are derived after every sweep and keyed by kind and identity

A Lead is a suggested action. Foothold never asks the operator to create one; a set of builders runs after every Sweep and each reports the leads the data supports right now. Every lead carries a digest of its kind and an identity (a term, a page, a domain, a week) so the same suggestion is raised once, refreshed while it stays open, and never duplicated.

Kinds come in two families. State kinds describe a condition (a term gap, a page on page two, a leaky page): the sweep closes them when the condition clears and reopens them the moment it recurs; a condition the operator marked done reopens after a month if it persists; a dismissed one never reopens. Event kinds describe something that happened (a position drop, a new referrer, a mention): their identity includes the event, so they stay resolved once resolved.

## Considered options

- **Leads as a plain to-do list the operator fills in.** No derivation to maintain, but the queue would only ever contain what the operator already noticed.
- **Recompute suggestions on page load with no stored state.** Nothing to dedupe, but nothing to mark done either, and each view would re-run every builder.
- **Derived rows keyed by identity (chosen).** Builders stay small and pure, the queue remembers what was resolved, and a recurring condition resurfaces on its own.

## Consequences

- Builders must produce a stable identity. Changing what identifies a kind orphans its open leads, which the sweep then closes.
- A lead's summary and evidence are refreshed on every build, so the queue always shows current numbers.
- The Growth playbook for a kind is looked up at build time from host configuration, so re-mapping takes effect on the next sweep.
