module Foothold
  module Leads
    # A Term whose average position this week sits just off page one, with
    # enough impressions to be worth the push.
    class PageTwo < Base
      MIN_IMPRESSIONS = 20

      def candidates
        range = threshold(:page_two_range)
        readings = Reading.from_search_console.joins(:term).where(foothold_terms: { site_id: site.id })
                          .where(date: window(7)).includes(:term).group_by(&:term_id)

        readings.filter_map do |term_id, rows|
          average = (rows.sum { |row| row.position.to_f } / rows.size).round(1)
          impressions = rows.sum(&:impressions)
          next unless range.cover?(average) && impressions >= MIN_IMPRESSIONS

          term = rows.first.term
          landing = rows.filter_map(&:landing_url).tally.max_by(&:last)&.first
          page = landing && site.pages.find_by(url: landing)
          evidence = "average #{average} over 7 days · #{impressions} impressions"
          evidence += " · #{landing}" if landing

          { identity: { term_id: term_id }, term: term, page: page,
            summary: "#{quoted(term.phrase)} sits at #{average}, one push from page one",
            payload: { phrase: term.phrase, average_position: average, impressions: impressions, landing_url: landing, evidence: evidence } }
        end
      end
    end
  end
end
