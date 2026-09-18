module Foothold
  # A phrase a Rival ranks for, as of the last weekly check. Stays on the
  # rival: it only becomes one of the Site's Terms when the operator tracks it.
  class RivalTerm < ApplicationRecord
    belongs_to :rival

    normalizes :phrase, with: ->(phrase) { phrase.to_s.squish.downcase }

    validates :phrase, presence: true, uniqueness: { scope: :rival_id }

    scope :top, ->(limit) { where(position: ..limit) }
    scope :relevant, -> { where(relevant: [ true, nil ]) }
    scope :unclassified, -> { where(relevant: nil) }

    # The rival section the landing page lives in: the first path segment.
    def section
      path = Url.path(landing_url) || "/"
      segment = path.split("/").reject(&:empty?).first
      segment ? "/#{segment}" : "/"
    end
  end
end
