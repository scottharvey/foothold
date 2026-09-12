module Foothold
  module Mentions
    # One class per feed source. `fetch(feed, since:)` returns an array of
    # Mention::Row, newest activity first is not required; dedup is by URL.
    class Base
      def initialize(http: Net::HTTP)
        @http = http
      end

      private

      def get_json(uri, headers: {})
        JSON.parse(get(uri, headers: headers))
      end

      def get(uri, headers: {})
        request(Net::HTTP::Get.new(URI(uri)), headers: headers)
      end

      # Basic-auth'd form POST, for OAuth2 client_credentials token exchanges.
      def post_form(uri, params, headers: {}, basic_auth: nil)
        req = Net::HTTP::Post.new(URI(uri))
        req.basic_auth(*basic_auth) if basic_auth
        req.body = URI.encode_www_form(params)
        request(req, headers: headers)
      end

      def request(req, headers: {})
        uri = req.uri
        req["User-Agent"] = "Foothold/#{Foothold::VERSION}"
        headers.each { |key, value| req[key] = value }
        response = @http.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 20) { |http| http.request(req) }
        raise "HTTP #{response.code} from #{uri}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end
    end
  end
end
