module Foothold
  # One entry in the Site's own content inventory, keyed by path.
  class Page < ApplicationRecord
    KINDS = %w[blog feature static discovered].freeze

    belongs_to :site
    has_many :page_days, dependent: :destroy
    has_many :findings, dependent: :destroy

    validates :url, presence: true, uniqueness: { scope: :site_id }
    validates :kind, inclusion: { in: KINDS }

    scope :in_sitemap, -> { where(in_sitemap: true) }

    def term
      Term.find_by(id: term_id) if term_id
    end

    # A page first seen by the visits sweep rather than the inventory.
    def self.discover(site, url)
      now = Time.current
      site.pages.find_or_create_by!(url: url) do |page|
        page.kind = "discovered"
        page.in_sitemap = false
        page.first_seen_at = now
        page.last_seen_at = now
      end
    end
  end
end
