# Changelog

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
