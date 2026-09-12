module Foothold
  module Leads
    # A page that has been in the sitemap for a while and Google still has
    # not indexed.
    class NotIndexed < Base
      def candidates
        cutoff = threshold(:not_indexed_after_days).days.ago
        site.pages.in_sitemap.where(first_seen_at: ...cutoff).where.not(index_status: [ nil, "PASS" ]).filter_map do |page|
          { identity: { page_id: page.id }, page: page,
            summary: "#{page.url} is still not indexed (#{page.index_status.humanize.downcase})",
            payload: { url: page.url, status: page.index_status, evidence: "#{page.index_status}, first seen #{page.first_seen_at.to_date}" } }
        end
      end
    end
  end
end
