module Foothold
  module Leads
    # A generated page has had its grace period and still isn't earning its
    # keep: no traffic, or traffic with nobody signing up.
    class PageUnderperforming < Base
      def candidates
        cutoff = threshold(:programmatic_page_grace_days).days.ago
        site.pages.where(kind: "alternative").where(first_seen_at: ...cutoff).filter_map do |page|
          visits = page.page_days.sum(:visits)
          signups = page.page_days.sum(:signups)
          next if visits.positive? && signups.positive?

          reason = visits.zero? ? "no visits" : "#{visits} #{'visit'.pluralize(visits)}, no signups"
          { identity: { page_id: page.id }, page: page,
            summary: "#{page.url} has had #{reason} since it went live #{page.first_seen_at.to_date}",
            payload: { url: page.url, visits: visits, signups: signups,
                       evidence: "#{reason} in #{(Date.current - page.first_seen_at.to_date).to_i} days" } }
        end
      end
    end
  end
end
