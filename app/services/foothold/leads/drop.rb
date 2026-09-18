module Foothold
  module Leads
    # A tracked or page-targeted Term whose 7-day average position got
    # meaningfully worse than the 7 days before. An event: identity includes
    # the week, so a resolved drop never resurfaces on its own.
    class Drop < Base
      def candidates
        week_starting = today.beginning_of_week
        this_week = week_starting..(week_starting + 6)
        last_week = (week_starting - 7)..(week_starting - 1)
        threshold_places = threshold(:drop_places)

        terms = site.terms.tracked.or(site.terms.where(id: site.pages.where.not(term_id: nil).select(:term_id)))
        readings = Reading.where(term_id: terms.select(:id), date: last_week.first..this_week.last).includes(:term).group_by(&:term_id)

        readings.filter_map do |term_id, rows|
          now = rows.select { |row| this_week.cover?(row.date) && row.position }
          before = rows.select { |row| last_week.cover?(row.date) && row.position }
          next if now.empty? || before.empty?

          now_avg = (now.sum { |row| row.position.to_f } / now.size).round(1)
          before_avg = (before.sum { |row| row.position.to_f } / before.size).round(1)
          delta = (now_avg - before_avg).round(1)
          next if delta <= threshold_places

          term = rows.first.term
          landing = now.filter_map(&:landing_url).tally.max_by(&:last)&.first
          page = landing && site.pages.find_by(url: landing)
          snapshot = latest_serp(term_id)
          rivals_above = Array(snapshot&.serp_top).select { |hit| hit["position"].to_i < now_avg }.first(5)

          { identity: { term_id: term_id, week_starting: week_starting }, term: term, page: page,
            summary: "#{quoted(term.phrase)} dropped from #{before_avg} to #{now_avg} this week",
            score: term.volume ? score.gain(term.volume, from: now_avg, to: before_avg) : delta * 2,
            payload: { phrase: term.phrase, before: before_avg, after: now_avg, delta: delta, volume: term.volume,
                       landing_url: landing, http_status: page&.http_status, rivals_above: rivals_above,
                       evidence: "#{before_avg} → #{now_avg} (#{format('%+.1f', delta)})#{" · volume #{term.volume}" if term.volume}" } }
        end
      end
    end
  end
end
