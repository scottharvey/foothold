# Changelog

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
