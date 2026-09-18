require "foothold/version"
require "foothold/url"
require "foothold/visit"
require "foothold/search_console"
require "foothold/data_for_seo"
require "foothold/git_hub"
require "foothold/relevance"
require "foothold/fetcher"
require "foothold/configuration"
require "foothold/engine"

module Foothold
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    # Resolves a configured host class name. Returns nil when the host does not
    # have that class so a source can skip instead of failing.
    def host_class(name)
      configuration.public_send(name).to_s.safe_constantize
    end

    def threshold(key)
      configuration.threshold(key)
    end
  end
end
