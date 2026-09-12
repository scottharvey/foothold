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
        readings = Reading.from_search_console.where(term_id: terms.select(:id), date: last_week.first..this_week.last)
                          .or(Reading.from_serp.where(term_id: terms.select(:id), date: last_week.first..this_week.last))
                          .group_by(&:term_id)

        readings.filter_map do |term_id, rows|
          now = rows.select { |row| this_week.cover?(row.date) }
          before = rows.select { |row| last_week.cover?(row.date) }
          next if now.empty? || before.empty?

          now_avg = now.sum { |row| row.position.to_f } / now.size
          before_avg = before.sum { |row| row.position.to_f } / before.size
          delta = (now_avg - before_avg).round(1)
          next if delta <= threshold_places

          term = rows.first.term
          { identity: { term_id: term_id, week_starting: week_starting }, term: term,
            summary: "#{quoted(term.phrase)} dropped from #{before_avg.round(1)} to #{now_avg.round(1)} this week",
            payload: { phrase: term.phrase, before: before_avg.round(1), after: now_avg.round(1), delta: delta,
                      evidence: "#{before_avg.round(1)} → #{now_avg.round(1)} (#{format('%+.1f', delta)})" } }
        end
      end

      private

      def term
        @term ||= {}
      end
    end
  end
end
