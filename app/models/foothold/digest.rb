module Foothold
  # The Monday email. Built once per week and stored, so a resend or a preview
  # shows exactly what went out.
  class Digest < ApplicationRecord
    MOVERS = 5

    belongs_to :site

    validates :week_starting, presence: true, uniqueness: { scope: :site_id }

    def self.build!(site: Site.current, week_starting: Date.current.beginning_of_week)
      digest = find_or_initialize_by(site: site, week_starting: week_starting)
      digest.recipient = Foothold.configuration.digest_recipient
      digest.payload = new_payload(site, week_starting)
      digest.save!
      digest
    end

    def sent?
      sent_at.present?
    end

    %w[movers_up movers_down new_referrers new_mentions findings top_leads actioned].each do |section|
      define_method(section) { payload.fetch(section, []) }
    end

    def counts
      payload.fetch("counts", {})
    end

    def self.new_payload(site, week_starting)
      week = week_starting..(week_starting + 6)
      movers = term_movers(site, week_starting)
      referrers = site.referrers.where(first_seen_on: week).not_search_engines
      mentions = site.mentions.where(found_at: week_starting..(week_starting + 7))
      findings = Finding.open.joins(:page).where(foothold_pages: { site_id: site.id }).where(first_seen_at: week_starting..(week_starting + 7))
      leads = site.leads.active.by_score
      actioned = site.leads.where(state: "done", resolved_by: "operator").where("outcome->>'measured_on' >= ?", week_starting.iso8601)

      {
        "movers_up" => movers.select { |mover| mover["delta"] && mover["delta"] < 0 }.first(MOVERS),
        "movers_down" => movers.select { |mover| mover["delta"] && mover["delta"] > 0 }.sort_by { |mover| -mover["delta"] }.first(MOVERS),
        "new_referrers" => referrers.map { |referrer| { "domain" => referrer.domain, "visits" => referrer.visits, "signups" => referrer.signups } },
        "new_mentions" => mentions.map { |mention| { "url" => mention.url, "title" => mention.title, "source" => mention.source } },
        "findings" => findings.includes(:page).map { |finding| { "summary" => "#{finding.page.url}: #{finding.description}" } },
        "top_leads" => leads.first(3).map { |lead| { "kind" => lead.kind, "summary" => lead.summary, "score" => lead.score } },
        "actioned" => actioned.map { |lead| { "summary" => lead.summary, "action" => lead.action, "outcome" => lead.outcome } },
        "counts" => { "open_leads" => leads.count, "new_referrers" => referrers.count, "new_mentions" => mentions.count, "actioned" => actioned.count }
      }
    end
    private_class_method :new_payload

    # This week's and last week's 7-day average position per term, most moved first.
    def self.term_movers(site, week_starting)
      this_week = week_starting..(week_starting + 6)
      last_week = (week_starting - 7)..(week_starting - 1)
      readings = Reading.from_search_console.joins(:term).where(foothold_terms: { site_id: site.id })
                        .where(date: (last_week.first)..(this_week.last)).includes(:term)
      by_term = readings.group_by(&:term_id)

      by_term.filter_map do |_term_id, rows|
        now = rows.select { |row| this_week.cover?(row.date) }
        before = rows.select { |row| last_week.cover?(row.date) }
        next if now.empty? || before.empty?

        now_avg = now.sum { |row| row.position.to_f } / now.size
        before_avg = before.sum { |row| row.position.to_f } / before.size
        delta = (now_avg - before_avg).round(1)
        next if delta.zero?

        { "phrase" => rows.first.term.phrase, "position" => now_avg.round(1), "delta" => delta }
      end.sort_by { |mover| mover["delta"].abs }.reverse
    end
    private_class_method :term_movers
  end
end
