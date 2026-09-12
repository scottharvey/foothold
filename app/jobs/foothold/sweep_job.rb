module Foothold
  class SweepJob < ActiveJob::Base
    queue_as :default

    def perform(kind = "nightly")
      Sweep.call(kind)
    end
  end
end
