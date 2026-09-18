module Foothold
  class Sweep
    # Google's index verdict for pages still in the sitemap, oldest-checked
    # first so every page gets refreshed within the inspection quota. Keeps
    # the reason too, so a not-indexed lead can say what to fix.
    class IndexCoverage < Base
      def call
        tracked("index_coverage") do |run|
          client = config.search_console_client&.call
          next skip(run, "not configured") unless client

          pages = site.pages.in_sitemap.order(Arel.sql("index_checked_at ASC NULLS FIRST")).limit(threshold(:index_inspection_limit)).to_a
          pages.each { |page| inspect_page(client, page) }

          run.note(pages: pages.size)
          run.watermark = today
        end
      end

      private

      def inspect_page(client, page)
        result = client.inspect_url(site.property, "#{base_url}#{page.url}")
        detail = { coverage_state: result.coverage_state, robots_txt_state: result.robots_txt_state, indexing_state: result.indexing_state,
                   page_fetch_state: result.page_fetch_state, last_crawl_time: result.last_crawl_time&.to_s }.compact
        page.update!(index_status: result.verdict, index_detail: detail, index_checked_at: Time.current)
      rescue StandardError => e
        Rails.logger.warn("[Foothold::Sweep::IndexCoverage] #{page.url}: #{e.class}: #{e.message}")
      end

      def base_url
        scheme = site.domain.include?(":") ? "http" : "https"
        "#{scheme}://#{site.domain}"
      end
    end
  end
end
