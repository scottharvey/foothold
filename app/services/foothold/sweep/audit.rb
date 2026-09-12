require "nokogiri"

module Foothold
  class Sweep
    # Crawls every page still in the sitemap and records what is wrong with
    # it. A page not seen this run has its findings resolved, not deleted, so
    # history stays visible.
    class Audit < Base
      THIN_WORDS = 300
      MAX_LINKS_PER_PAGE = 50

      def call
        tracked("audit") do |run|
          fetcher = config.fetcher || Fetcher.new
          pages = site.pages.in_sitemap.order(:id).limit(threshold(:crawl_limit)).to_a
          inbound = Hash.new(0)

          pages.each do |page|
            links = audit_page(fetcher, page)
            links.each { |link| inbound[link] += 1 } if links
          end
          pages.each { |page| page.update_column(:inbound_links, inbound[page.url]) }
          mark_orphans(pages, inbound)

          run.note(pages: pages.size, findings: Finding.where(page_id: pages.map(&:id)).open.count)
          run.watermark = today
        end
      end

      private

      # Returns the page's internal links (for orphan detection), or nil if
      # the page could not be parsed.
      def audit_page(fetcher, page)
        url = "#{base_url}#{page.url}"
        response = fetcher.get(url)
        keep = []

        keep << observe(page, "status", identity: "status", detail: response.status.to_s) unless response.status == 200
        page.update!(http_status: response.status, crawled_at: Time.current)
        return nil unless response.status == 200

        doc = Nokogiri::HTML5(response.body)
        title = doc.at_css("title")&.text.to_s.strip
        description = doc.at_css("meta[name='description']")&.[]("content").to_s.strip
        word_count = doc.at_css("body")&.text.to_s.split.size
        page.update!(title: title.presence || page.title, description: description.presence || page.description, word_count: word_count)

        keep << observe(page, "title_length", identity: "title_length", detail: title.length.to_s) if title.blank? || title.length > 60
        keep << observe(page, "description_length", identity: "description_length", detail: description.length.to_s) if description.blank? || description.length > 160

        h1_count = doc.css("h1").size
        keep << observe(page, "h1_count", identity: "h1_count", detail: h1_count.to_s) if h1_count != 1

        canonical = doc.at_css("link[rel='canonical']")&.[]("href")
        keep << observe(page, "canonical", identity: "canonical", detail: canonical.to_s) unless canonical.present? && Url.path(canonical) == page.url

        doc.css("img").each_with_index do |img, index|
          next if img["alt"].present?

          keep << observe(page, "img_alt", identity: "img_alt:#{index}", detail: img["src"].to_s)
        end

        keep.concat(check_links(fetcher, page, doc))
        keep << observe(page, "thin", identity: "thin", detail: "#{word_count} words") if thin_kind?(page) && word_count.to_i < THIN_WORDS

        Finding::CHECKS.each { |check| Finding.resolve_missing!(page: page, check: check, keep: keep.select { |finding| finding&.check == check }.map(&:id)) }
        internal_links(doc)
      end

      def check_links(fetcher, page, doc)
        internal_links(doc).first(MAX_LINKS_PER_PAGE).filter_map do |path|
          response = fetcher.get("#{base_url}#{path}")
          next observe(page, "broken_link", identity: "broken_link:#{path}", detail: path) if response.status.nil? || response.status >= 400
          next observe(page, "redirected_link", identity: "redirected_link:#{path}", detail: path) if response.redirected
        end
      end

      def internal_links(doc)
        doc.css("a[href]").filter_map do |a|
          href = a["href"].to_s
          next nil if href.blank? || href.start_with?("#", "mailto:", "tel:")
          next Url.path(href) if href.start_with?("/")
          next Url.path(href) if Url.on_site?(href, site.domain)

          nil
        end.uniq
      end

      def mark_orphans(pages, inbound)
        pages.each do |page|
          next if page.published_on.present? && page.published_on > 30.days.ago.to_date

          finding = if inbound[page.url].to_i.zero?
            observe(page, "orphan", identity: "orphan")
          end
          Finding.resolve_missing!(page: page, check: "orphan", keep: Array(finding&.id))
        end
      end

      def observe(page, check, identity:, detail: nil)
        Finding.observe!(page: page, check: check, identity: identity, detail: detail)
      end

      def thin_kind?(page)
        %w[blog feature].include?(page.kind)
      end

      def base_url
        scheme = site.domain.include?(":") ? "http" : "https"
        "#{scheme}://#{site.domain}"
      end
    end
  end
end
