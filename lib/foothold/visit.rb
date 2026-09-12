module Foothold
  # One host visit as the Sweep sees it. `signup` is true when the visitor
  # registered during this visit.
  Visit = Data.define(:landing_path, :referring_domain, :signup, :started_at)
end
