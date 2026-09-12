module Foothold
  # Where a Rival ranks for a Term, as of the last weekly check.
  class RivalTerm < ApplicationRecord
    belongs_to :rival
    belongs_to :term

    validates :term_id, uniqueness: { scope: :rival_id }

    scope :top, ->(limit) { where(position: ..limit) }
  end
end
