module Foothold
  module Mentions
    # Reddit's OAuth2 app-only search. Needs a "script" app registered at
    # reddit.com/prefs/apps (free): `feed[:client_id]`/`feed[:client_secret]`,
    # and a `feed[:user_agent]` that identifies the app per Reddit's API rules
    # (e.g. "web:foothold:v1 (by /u/yourname)"). Falls back to
    # FOOTHOLD_REDDIT_CLIENT_ID / FOOTHOLD_REDDIT_CLIENT_SECRET /
    # FOOTHOLD_REDDIT_USER_AGENT when the feed omits them.
    class Reddit < Base
      TOKEN_ENDPOINT = "https://www.reddit.com/api/v1/access_token".freeze
      SEARCH_ENDPOINT = "https://oauth.reddit.com/search".freeze

      def fetch(feed, since:)
        return [] if feed[:query].blank?

        client_id = feed[:client_id].presence || ENV["FOOTHOLD_REDDIT_CLIENT_ID"]
        client_secret = feed[:client_secret].presence || ENV["FOOTHOLD_REDDIT_CLIENT_SECRET"]
        user_agent = feed[:user_agent].presence || ENV["FOOTHOLD_REDDIT_USER_AGENT"]
        return [] if client_id.blank? || client_secret.blank? || user_agent.blank?

        token = fetch_token(client_id, client_secret, user_agent)

        params = { q: feed[:query], sort: "new", restrict_sr: false, limit: 100 }
        uri = URI(SEARCH_ENDPOINT)
        uri.query = URI.encode_www_form(params)
        headers = { "Authorization" => "bearer #{token}", "User-Agent" => user_agent }

        Array(get_json(uri, headers: headers).dig("data", "children")).filter_map do |child|
          post = child["data"]
          next if post.blank?

          found_at = Time.zone.at(post["created_utc"].to_i)
          next if since && found_at < since

          Mention::Row.new(url: "https://www.reddit.com#{post['permalink']}", external_id: post["id"],
                           title: post["title"], author: post["author"], excerpt: post["selftext"],
                           found_at: found_at)
        end
      end

      private

      def fetch_token(client_id, client_secret, user_agent)
        body = post_form(TOKEN_ENDPOINT, { grant_type: "client_credentials" },
                         headers: { "User-Agent" => user_agent }, basic_auth: [client_id, client_secret])
        JSON.parse(body)["access_token"]
      end
    end
  end
end
