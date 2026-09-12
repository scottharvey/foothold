module Foothold
  # A domain that sent a visitor, as Ahoy saw it.
  class Referrer < ApplicationRecord
    belongs_to :site

    normalizes :domain, with: ->(domain) { domain.to_s.strip.downcase.delete_prefix("www.") }

    validates :domain, presence: true, uniqueness: { scope: :site_id }

    scope :not_search_engines, -> { where(search_engine: false) }
    scope :recent_first, -> { order(last_seen_on: :desc) }

    def self.record!(site:, domain:, date:, visits:, signups:, search_engine:)
      referrer = site.referrers.find_or_initialize_by(domain: domain)
      referrer.first_seen_on ||= date
      referrer.last_seen_on = [ referrer.last_seen_on, date ].compact.max
      referrer.visits += visits
      referrer.signups += signups
      referrer.search_engine ||= search_engine
      referrer.save!
      referrer
    end
  end
end
