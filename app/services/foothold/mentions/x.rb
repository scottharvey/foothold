module Foothold
  module Mentions
    # X's (formerly Twitter's) recent-search API. There is no free tier for
    # search: this needs a pay-per-use (or higher) developer plan and an
    # app-only bearer token. `feed[:bearer_token]` or
    # FOOTHOLD_X_BEARER_TOKEN. Recent search only covers the last 7 days, so
    # a watermark older than that is ignored rather than sent (the API
    # rejects it).
    class X < Base
      ENDPOINT = "https://api.x.com/2/tweets/search/recent".freeze

      def fetch(feed, since:)
        return [] if feed[:query].blank?

        token = feed[:bearer_token].presence || ENV["FOOTHOLD_X_BEARER_TOKEN"]
        return [] if token.blank?

        params = { query: feed[:query], max_results: 100, "tweet.fields" => "created_at",
                  expansions: "author_id", "user.fields" => "username" }
        params[:start_time] = since.utc.iso8601 if since && since > 7.days.ago
        uri = URI(ENDPOINT)
        uri.query = URI.encode_www_form(params)

        body = get_json(uri, headers: { "Authorization" => "Bearer #{token}" })
        usernames = Array(body.dig("includes", "users")).to_h { |user| [ user["id"], user["username"] ] }

        Array(body["data"]).filter_map do |post|
          found_at = Time.zone.parse(post["created_at"])
          next if since && found_at < since

          author = usernames[post["author_id"]]
          Mention::Row.new(url: "https://x.com/#{author || 'i/web'}/status/#{post['id']}", external_id: post["id"],
                           title: nil, author: author, excerpt: post["text"], found_at: found_at)
        end
      end
    end
  end
end
