require "nokogiri"

module Foothold
  module Mentions
    # An Atom/RSS feed exported from a Google Alert. `feed[:url]` is the
    # feed's own URL, kept private to this install.
    class GoogleAlerts < Base
      def fetch(feed, since:)
        return [] if feed[:url].blank?

        doc = Nokogiri::XML(get(feed[:url]))
        doc.remove_namespaces!
        doc.css("entry, item").filter_map do |entry|
          published = entry.at_css("published, pubDate")&.text
          found_at = published.present? ? Time.zone.parse(published) : Time.current
          next if since && found_at < since

          link = entry.at_css("link")
          url = unwrap(link&.[]("href").presence || entry.at_css("link")&.text)
          next if url.blank?

          Mention::Row.new(url: url, external_id: nil, title: entry.at_css("title")&.text,
                           author: nil, excerpt: entry.at_css("summary, description")&.text, found_at: found_at)
        end
      end

      private

      # Google Alerts wraps the real link behind a redirect with a "url" param.
      def unwrap(href)
        return href if href.blank?

        uri = URI(href)
        query = URI.decode_www_form(uri.query.to_s).to_h
        query["url"] || href
      rescue URI::InvalidURIError
        href
      end
    end
  end
end
