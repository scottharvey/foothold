module Foothold
  module Leads
    # A discovered Term with enough impressions to deserve a daily check.
    class TrackThis < Base
      def candidates
        minimum = threshold(:track_this_impressions)
        totals = Reading.from_search_console.joins(:term).where(foothold_terms: { site_id: site.id, tracked: false })
                        .where(date: window(28)).group(:term_id).sum(:impressions)

        totals.filter_map do |term_id, impressions|
          next if impressions < minimum

          term = site.terms.find(term_id)
          { identity: { term_id: term_id }, term: term,
            summary: "#{quoted(term.phrase)} had #{impressions} impressions in 28 days; track it?",
            payload: { phrase: term.phrase, impressions: impressions, evidence: "#{impressions} impressions in 28 days" } }
        end
      end
    end
  end
end
