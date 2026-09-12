module Foothold
  # A place on the web where the product was named.
  class Mention < ApplicationRecord
    SOURCES = %w[google_alerts hacker_news app_store bluesky reddit github].freeze

    belongs_to :site

    validates :source, inclusion: { in: SOURCES }
    validates :url, :found_at, presence: true

    scope :recent_first, -> { order(found_at: :desc) }
    scope :unlinked, -> { where(linked: false) }

    Row = Data.define(:url, :external_id, :title, :author, :excerpt, :found_at) do
      def linked?(domain)
        excerpt.to_s.include?(domain) || title.to_s.include?(domain)
      end
    end

    def self.record!(site:, source:, row:)
      mention = site.mentions.find_or_initialize_by(source: source, url: row.url)
      return mention if mention.persisted?

      mention.assign_attributes(external_id: row.external_id, title: row.title, author: row.author,
                                excerpt: row.excerpt, found_at: row.found_at, linked: row.linked?(site.domain))
      mention.save!
      mention
    end
  end
end
