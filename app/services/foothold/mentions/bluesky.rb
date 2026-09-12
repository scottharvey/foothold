module Foothold
  module Mentions
    # Bluesky's public, unauthenticated post search. `feed[:query]` is the
    # phrase to search for.
    class Bluesky < Base
      ENDPOINT = "https://public.api.bsky.app/xrpc/app.bsky.feed.searchPosts".freeze

      def fetch(feed, since:)
        return [] if feed[:query].blank?

        params = { q: feed[:query], sort: "latest" }
        params[:since] = since.utc.iso8601 if since
        uri = URI(ENDPOINT)
        uri.query = URI.encode_www_form(params)

        Array(get_json(uri)["posts"]).filter_map do |post|
          author = post.dig("author", "handle")
          rkey = post["uri"].to_s.split("/").last
          next if author.blank? || rkey.blank?

          Mention::Row.new(url: "https://bsky.app/profile/#{author}/post/#{rkey}", external_id: post["uri"],
                           title: nil, author: author, excerpt: post.dig("record", "text"),
                           found_at: Time.zone.parse(post.dig("record", "createdAt") || post["indexedAt"].to_s))
        end
      end
    end
  end
end
