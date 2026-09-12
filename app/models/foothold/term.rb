module Foothold
  # A search phrase worth ranking for. Only tracked Terms cost money to check.
  class Term < ApplicationRecord
    SOURCES = %w[search_console page rival manual].freeze

    belongs_to :site
    has_many :readings, dependent: :destroy

    normalizes :phrase, with: ->(phrase) { phrase.to_s.squish.downcase }

    validates :phrase, presence: true, uniqueness: { scope: :site_id }
    validates :source, inclusion: { in: SOURCES }

    scope :tracked, -> { where(tracked: true) }
    scope :alphabetical, -> { order(:phrase) }

    after_destroy { Page.where(term_id: id).update_all(term_id: nil) }

    # Finds the Term for a phrase or creates it from the given source.
    def self.locate(site, phrase, source:, discovered_on: nil, tracked: false)
      normalized = phrase.to_s.squish.downcase
      return nil if normalized.blank?

      site.terms.find_or_create_by!(phrase: normalized) do |term|
        term.source = source
        term.discovered_on = discovered_on
        term.tracked = tracked
      end
    end

    # Terms whose volume and difficulty are worth paying for: tracked ones and
    # the targets of pages.
    def self.worth_pricing(site)
      site.terms.where(tracked: true).or(site.terms.where(id: site.pages.where.not(term_id: nil).select(:term_id)))
    end

    def pages
      site.pages.where(term_id: id)
    end
  end
end
