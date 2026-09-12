module Foothold
  module Mentions
    # The App Store's free customer-reviews feed. `feed[:app_id]` and
    # `feed[:country]` (default "us") identify the app.
    class AppStore < Base
      def fetch(feed, since:)
        return [] if feed[:app_id].blank?

        country = feed[:country].presence || "us"
        uri = "https://itunes.apple.com/#{country}/rss/customerreviews/id=#{feed[:app_id]}/sortBy=mostRecent/json"
        entries = Array(get_json(uri).dig("feed", "entry"))
        # The App Store includes the app's own metadata as the first "entry"
        # when there are reviews; it has no author or rating.
        entries = entries.reject { |entry| entry["im:rating"].nil? }

        entries.filter_map do |entry|
          found_at = entry.dig("updated", "label").present? ? Time.zone.parse(entry["updated"]["label"]) : Time.current
          next if since && found_at < since

          id = entry.dig("id", "label")
          Mention::Row.new(url: id, external_id: id, title: entry.dig("title", "label"),
                           author: entry.dig("author", "name", "label"), excerpt: entry.dig("content", "label"), found_at: found_at)
        end
      end
    end
  end
end
