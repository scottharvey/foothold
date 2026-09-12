module Foothold
  class Sweep
    # Polls every configured mention feed and records new rows as Mentions.
    # Each feed source resumes from its own watermark, named "mentions:<source>".
    class MentionFeeds < Base
      SOURCES = {
        "google_alerts" => Foothold::Mentions::GoogleAlerts,
        "hacker_news" => Foothold::Mentions::HackerNews,
        "app_store" => Foothold::Mentions::AppStore,
        "bluesky" => Foothold::Mentions::Bluesky
      }.freeze

      def call
        config.mention_feeds.each { |feed| poll(feed) }
      end

      private

      def poll(feed)
        source = feed[:source].to_s
        fetcher = SOURCES[source]
        return unless fetcher

        tracked("mentions:#{source}") do |run|
          since = run.watermark&.to_time
          rows = fetcher.new.fetch(feed, since: since)
          rows.each { |row| Foothold::Mention.record!(site: site, source: source, row: row) }
          run.note(found: rows.size)
          run.watermark = today
        end
      end
    end
  end
end
