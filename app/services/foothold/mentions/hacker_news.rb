module Foothold
  module Mentions
    # Algolia's free Hacker News search API. `feed[:query]` is the phrase
    # to search for, typically the product's name.
    class HackerNews < Base
      ENDPOINT = "https://hn.algolia.com/api/v1/search_by_date".freeze

      def fetch(feed, since:)
        return [] if feed[:query].blank?

        # Quoted: Algolia's default is an OR match across the individual
        # words, which turns a multi-word product name into noise (any
        # story mentioning either word, unrelated to each other). Quoting
        # requires the exact phrase.
        params = { query: %("#{feed[:query]}"), tags: "(story,comment)" }
        params[:numericFilters] = "created_at_i>#{since.to_i}" if since
        uri = URI(ENDPOINT)
        uri.query = URI.encode_www_form(params)

        Array(get_json(uri)["hits"]).filter_map do |hit|
          url = hit["url"].presence || "https://news.ycombinator.com/item?id=#{hit['objectID']}"
          Mention::Row.new(url: url, external_id: hit["objectID"], title: hit["title"] || hit["story_title"],
                           author: hit["author"], excerpt: hit["comment_text"] || hit["story_text"],
                           found_at: Time.zone.at(hit["created_at_i"].to_i))
        end
      end
    end
  end
end
