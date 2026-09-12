module Foothold
  class DigestsController < ApplicationController
    # "Send digest now": builds and delivers the current week's digest,
    # regardless of whether it was already sent, for previewing on real data.
    def create
      digest = Digest.build!(site: @site)
      DigestMailer.weekly(digest).deliver_later
      digest.update!(sent_at: Time.current)
      redirect_to root_path, notice: "Digest sent to #{digest.recipient}."
    end
  end
end
