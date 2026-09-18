module Foothold
  module Leads
    # A generated page has had its grace period and still isn't earning its
    # keep: no traffic, or traffic with nobody signing up. Recommends
    # retiring it once it has been indexed twice as long as the grace period
    # and still has no visits; revising it otherwise.
    class PageUnderperforming < Base
      def candidates
        grace = threshold(:programmatic_page_grace_days)
        cutoff = grace.days.ago
        site.pages.where(kind: "alternative").where(first_seen_at: ...cutoff).filter_map do |page|
          visits = page.page_days.sum(:visits)
          signups = page.page_days.sum(:signups)
          next if visits.positive? && signups.positive?

          age = (today - page.first_seen_at.to_date).to_i
          indexed = page.index_status == "PASS"
          recommendation = visits.zero? && indexed && age >= grace * 2 ? "retire" : "revise"
          reason = visits.zero? ? "no visits" : "#{visits} #{'visit'.pluralize(visits)}, no signups"

          { identity: { page_id: page.id }, page: page,
            summary: "#{page.url} has had #{reason} since it went live #{page.first_seen_at.to_date}",
            score: 10 + visits * 0.5,
            payload: { url: page.url, visits: visits, signups: signups, days: age, indexed: indexed, recommendation: recommendation,
                       first_seen_on: page.first_seen_at.to_date, queries: queries_for(page),
                       evidence: "#{reason} in #{age} days · #{indexed ? 'indexed' : 'not indexed'} · suggest #{recommendation}" } }
        end
      end

      private

      def queries_for(page)
        Reading.from_search_console.joins(:term).where(foothold_terms: { site_id: site.id })
               .where(date: window(28), landing_url: page.url).includes(:term).group_by(&:term_id)
               .map do |_id, rows|
                 { phrase: rows.first.term.phrase, impressions: rows.sum(&:impressions), clicks: rows.sum(&:search_clicks),
                   position: (rows.sum { |row| row.position.to_f } / rows.size).round(1) }
               end.sort_by { |query| -query[:clicks] }.first(10)
      end
    end
  end
end
