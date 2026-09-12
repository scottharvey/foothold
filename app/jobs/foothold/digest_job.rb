module Foothold
  # Sends this week's digest once. Safe to run more than once: a week that
  # already has `sent_at` is skipped.
  class DigestJob < ActiveJob::Base
    queue_as :default

    def perform(week_starting = Date.current.beginning_of_week)
      week_starting = week_starting.to_date
      digest = Digest.build!(week_starting: week_starting)
      return if digest.sent?

      DigestMailer.weekly(digest).deliver_later
      digest.update!(sent_at: Time.current)
    end
  end
end
