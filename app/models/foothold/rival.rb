module Foothold
  # A competitor domain whose ranking Terms are compared with the Site's.
  class Rival < ApplicationRecord
    belongs_to :site
    has_many :rival_terms, dependent: :destroy

    normalizes :domain, with: ->(domain) { domain.to_s.strip.downcase.sub(%r{\Ahttps?://}, "").delete_prefix("www.").split("/").first.to_s }

    validates :domain, presence: true, uniqueness: { scope: :site_id }, format: { with: /\A[a-z0-9.-]+\.[a-z]{2,}\z/, message: "must be a domain like example.com" }

    scope :alphabetical, -> { order(:domain) }

    def display_name
      name.presence || domain
    end
  end
end
