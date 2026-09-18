module Foothold
  module Leads
    # A Page that search sends people to, none of whom sign up. Carries the
    # queries that brought them, since intent mismatch is the usual cause.
    class LeakyPage < Base
      DAYS = 28

      def candidates
        minimum = threshold(:leaky_page_min_clicks)
        totals = PageDay.joins(:page).where(foothold_pages: { site_id: site.id }).where(date: window(DAYS))
                        .group(:page_id).pluck(:page_id, Arel.sql("SUM(search_visits)"), Arel.sql("SUM(search_signups)"))

        totals.filter_map do |page_id, visits, signups|
          next unless visits >= minimum && signups.zero?

          page = site.pages.find(page_id)
          { identity: { page_id: page_id }, page: page,
            summary: "#{page.url} had #{visits} search visits and no signups in #{DAYS} days",
            score: score.monthly(visits, DAYS),
            payload: { url: page.url, search_visits: visits, signups: 0, days: DAYS, queries: queries_for(page),
                       evidence: "#{visits} search visits, 0 signups, #{DAYS} days" } }
        end
      end

      private

      def queries_for(page)
        Reading.from_search_console.joins(:term).where(foothold_terms: { site_id: site.id })
               .where(date: window(DAYS), landing_url: page.url).includes(:term).group_by(&:term_id)
               .map do |_term_id, rows|
                 { phrase: rows.first.term.phrase, impressions: rows.sum(&:impressions), clicks: rows.sum(&:search_clicks),
                   position: (rows.sum { |row| row.position.to_f } / rows.size).round(1) }
               end.sort_by { |query| -query[:clicks] }.first(10)
      end
    end
  end
end
