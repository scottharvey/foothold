require "net/http"

module Foothold
  # Fetches one of the Site's own pages for the weekly audit. Only ever points
  # at the configured site_domain, never at a rival or an arbitrary URL.
  class Fetcher
    Response = Data.define(:status, :body, :final_url, :redirected)

    MAX_REDIRECTS = 3
    TIMEOUT = 10

    def get(url, redirects: MAX_REDIRECTS)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri, "User-Agent" => "Foothold/#{Foothold::VERSION}")
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: TIMEOUT, read_timeout: TIMEOUT) { |http| http.request(request) }

      if response.is_a?(Net::HTTPRedirection) && redirects.positive? && response["location"]
        location = URI.join(uri, response["location"])
        result = get(location, redirects: redirects - 1)
        return Response.new(status: result.status, body: result.body, final_url: result.final_url, redirected: true)
      end

      Response.new(status: response.code.to_i, body: response.body.to_s, final_url: uri.to_s, redirected: false)
    rescue StandardError => e
      Response.new(status: nil, body: e.message, final_url: uri.to_s, redirected: false)
    end
  end
end
