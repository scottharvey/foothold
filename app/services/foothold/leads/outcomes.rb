module Foothold
  module Leads
    # Measures what happened after a lead was resolved by the operator: the
    # term's average position, or the page's search visits and signups, in
    # the window before versus the window after. Runs nightly; each lead is
    # measured once, when its window has elapsed.
    class Outcomes < Sweep::Base
      def call
        tracked("outcomes") do |run|
          days = threshold(:outcome_window_days)
          due = site.leads.where(state: "done", resolved_by: "operator", outcome: {})
                    .where(resolved_at: ..days.days.ago).where("term_id IS NOT NULL OR page_id IS NOT NULL")
          measured = due.count { |lead| measure(lead, days) }
          run.note(leads: measured)
          run.watermark = today
        end
      end

      private

      def measure(lead, days)
        at = lead.resolved_at.to_date
        before = (at - days)..(at - 1)
        after = (at + 1)..(at + days)
        outcome = lead.term_id ? term_outcome(lead.term_id, before, after) : page_outcome(lead.page_id, before, after)
        return false unless outcome

        lead.update!(outcome: outcome.merge("measured_on" => today.iso8601, "days" => days))
        true
      end

      def term_outcome(term_id, before, after)
        first = average_position(term_id, before)
        second = average_position(term_id, after)
        return nil unless first && second

        { "metric" => "position", "before" => first, "after" => second, "delta" => (second - first).round(1) }
      end

      def average_position(term_id, range)
        rows = Reading.from_search_console.where(term_id: term_id, date: range).where.not(position: nil)
        count = rows.count
        return nil if count.zero?

        (rows.sum(:position).to_f / count).round(1)
      end

      def page_outcome(page_id, before, after)
        first = PageDay.where(page_id: page_id, date: before).pick(Arel.sql("COALESCE(SUM(search_visits), 0)"), Arel.sql("COALESCE(SUM(search_signups), 0)"))
        second = PageDay.where(page_id: page_id, date: after).pick(Arel.sql("COALESCE(SUM(search_visits), 0)"), Arel.sql("COALESCE(SUM(search_signups), 0)"))
        return nil if first.sum.zero? && second.sum.zero?

        { "metric" => "search_visits", "before" => first[0], "after" => second[0], "delta" => second[0] - first[0],
          "signups_before" => first[1], "signups_after" => second[1] }
      end
    end
  end
end
