module Foothold
  module Leads
    # A Term whose average position this week sits just off page one, with
    # enough impressions to be worth the push. Carries who is above us.
    class PageTwo < Base
      MIN_IMPRESSIONS = 20
      DAYS = 7

      def candidates
        range = threshold(:page_two_range)
        readings = Reading.from_search_console.joins(:term).where(foothold_terms: { site_id: site.id })
                          .where(date: window(DAYS)).includes(:term).group_by(&:term_id)

        readings.filter_map do |term_id, rows|
          average = (rows.sum { |row| row.position.to_f } / rows.size).round(1)
          impressions = rows.sum(&:impressions)
          next unless range.cover?(average) && impressions >= MIN_IMPRESSIONS

          term = rows.first.term
          landing = rows.filter_map(&:landing_url).tally.max_by(&:last)&.first
          page = landing && site.pages.find_by(url: landing)
          top = Array(latest_serp(term_id)&.serp_top).first(3)
          evidence = "average #{average} over #{DAYS} days · #{impressions} impressions"
          evidence += " · #{landing}" if landing

          { identity: { term_id: term_id }, term: term, page: page,
            summary: "#{quoted(term.phrase)} sits at #{average}, one push from page one",
            score: term.volume ? score.gain(term.volume, from: average, to: 3) : score.monthly(impressions, DAYS) * (score.ctr(3) - score.ctr(average)),
            payload: { phrase: term.phrase, average_position: average, impressions: impressions, landing_url: landing, volume: term.volume,
                       tracked: term.tracked?, http_status: page&.http_status, top_results: top, evidence: evidence } }
        end
      end
    end
  end
end
