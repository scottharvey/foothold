require "uri"

module Foothold
  # Every URL Foothold stores is a path on the Site, so Search Console pages,
  # Ahoy landing pages and the content inventory all key the same way.
  module Url
    module_function

    def path(value)
      value = value.to_s.strip
      return nil if value.empty?

      uri = URI.parse(value)
      path = uri.path.to_s
      path = "/#{path}" unless path.start_with?("/")
      path = path.chomp("/")
      path.empty? ? "/" : path
    rescue URI::InvalidURIError
      nil
    end

    # Host without a leading www, or nil for a path.
    def domain(value)
      host = URI.parse(value.to_s.strip).host
      host&.delete_prefix("www.")&.downcase
    rescue URI::InvalidURIError
      nil
    end

    def on_site?(value, site_domain)
      host = domain(value) or return false
      site = site_domain.to_s.delete_prefix("www.").downcase.split(":").first
      host == site || host.end_with?(".#{site}")
    end
  end
end
