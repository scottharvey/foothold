module Foothold
  module Leads
    # A page that has been in the sitemap for a while and Google still has
    # not indexed. Says why, when the inspection result does.
    class NotIndexed < Base
      # indexing_state and robots_txt_state values that mean we blocked it ourselves.
      FIXABLE = %w[BLOCKED_BY_META_TAG BLOCKED_BY_HTTP_HEADER BLOCKED_BY_ROBOTS_TXT DISALLOWED].freeze

      def candidates
        cutoff = threshold(:not_indexed_after_days).days.ago
        site.pages.in_sitemap.where(first_seen_at: ...cutoff).where.not(index_status: [ nil, "PASS" ]).filter_map do |page|
          detail = page.index_detail.to_h
          fixable = detail.values_at("indexing_state", "robots_txt_state").any? { |state| FIXABLE.include?(state) }
          term = page.term

          { identity: { page_id: page.id }, page: page, term: term,
            summary: "#{page.url} is still not indexed (#{reason(page, detail).downcase})",
            score: term&.volume ? score.potential(term.volume) : 10,
            payload: { url: page.url, status: page.index_status, reason: reason(page, detail), detail: detail.compact, fixable: fixable,
                       inspect_url: inspect_url(page), phrase: term&.phrase,
                       evidence: "#{reason(page, detail)}, first seen #{page.first_seen_at.to_date}" } }
        end
      end

      private

      def reason(page, detail)
        detail["coverage_state"].presence || page.index_status.humanize
      end

      def inspect_url(page)
        base = site.domain.include?(":") ? "http://#{site.domain}" : "https://#{site.domain}"
        "https://search.google.com/search-console/inspect?resource_id=#{CGI.escape(site.property)}&id=#{CGI.escape("#{base}#{page.url}")}"
      end
    end
  end
end
