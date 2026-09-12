module Foothold
  # Visits to one Page on one day, from the host's analytics. The source of
  # truth for clicks and signups; Readings copy their share from here.
  class PageDay < ApplicationRecord
    belongs_to :page

    validates :date, presence: true, uniqueness: { scope: :page_id }
  end
end
