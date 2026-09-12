module Foothold
  module Mentions
    # One class per feed source. `fetch(feed, since:)` returns an array of
    # Mention::Row, newest activity first is not required; dedup is by URL.
    class Base
      def initialize(http: Net::HTTP)
        @http = http
      end

      private

      def get_json(uri)
        JSON.parse(get(uri))
      end

      def get(uri)
        uri = URI(uri)
        response = @http.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 20) { |http| http.get(uri.request_uri, "User-Agent" => "Foothold/#{Foothold::VERSION}") }
        raise "HTTP #{response.code} from #{uri}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end
    end
  end
end
