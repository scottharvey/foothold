module Foothold
  module Leads
    # A Page that search sends people to, none of whom sign up.
    class LeakyPage < Base
      def candidates
        minimum = threshold(:leaky_page_min_clicks)
        totals = PageDay.joins(:page).where(foothold_pages: { site_id: site.id }).where(date: window(28))
                        .group(:page_id).pluck(:page_id, Arel.sql("SUM(search_visits)"), Arel.sql("SUM(search_signups)"))

        totals.filter_map do |page_id, visits, signups|
          next unless visits >= minimum && signups.zero?

          page = site.pages.find(page_id)
          { identity: { page_id: page_id }, page: page,
            summary: "#{page.url} had #{visits} search visits and no signups in 28 days",
            payload: { url: page.url, search_visits: visits, signups: 0, evidence: "#{visits} search visits, 0 signups, 28 days" } }
        end
      end
    end
  end
end
