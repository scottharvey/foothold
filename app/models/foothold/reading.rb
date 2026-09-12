module Foothold
  # One observed position for a Term on a date, from one source.
  class Reading < ApplicationRecord
    SOURCES = %w[search_console serp].freeze

    belongs_to :term

    validates :date, presence: true
    validates :source, inclusion: { in: SOURCES }, uniqueness: { scope: %i[term_id date] }

    scope :from_search_console, -> { where(source: "search_console") }
    scope :from_serp, -> { where(source: "serp") }
    scope :chronological, -> { order(:date) }

    def self.record!(term:, date:, source:, **attrs)
      reading = find_or_initialize_by(term:, date:, source:)
      reading.assign_attributes(attrs)
      reading.save! if reading.new_record? || reading.changed?
      reading
    end

    # Copies the day's search visits and signups for the landing page onto
    # every Reading that pointed at it.
    def self.attribute_from!(page_day)
      where(date: page_day.date, landing_url: page_day.page.url)
        .update_all(clicks: page_day.search_visits, signups: page_day.search_signups)
    end
  end
end
