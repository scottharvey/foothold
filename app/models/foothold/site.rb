module Foothold
  # The one product domain this install watches.
  class Site < ApplicationRecord
    has_many :terms, dependent: :destroy
    has_many :pages, dependent: :destroy
    has_many :rivals, dependent: :destroy
    has_many :leads, dependent: :destroy
    has_many :referrers, dependent: :destroy
    has_many :digests, dependent: :destroy
    has_many :mentions, dependent: :destroy
    has_many :mutes, dependent: :destroy

    validates :domain, presence: true, uniqueness: true

    def self.current
      config = Foothold.configuration
      raise ArgumentError, "Foothold.configuration.site_domain is not set" if config.site_domain.blank?

      find_or_create_by!(domain: config.site_domain) do |site|
        site.name = config.site_name
        site.search_console_property = config.search_console_property
      end
    end

    def property
      search_console_property.presence || Foothold.configuration.search_console_property
    end

    def display_name
      name.presence || domain
    end
  end
end
