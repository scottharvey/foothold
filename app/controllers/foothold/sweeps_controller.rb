module Foothold
  # Sweep history, cost, and the manual triggers for testing against real
  # data: sweep now, weekly audit, and (folded in here rather than its own
  # page) send digest now.
  class SweepsController < ApplicationController
    def index
      @runs = SweepRun.order(id: :desc).limit(50)
      @last_digest = @site.digests.order(week_starting: :desc).first
    end

    def create
      kind = params[:kind].presence || "nightly"
      unless Sweep::KINDS.key?(kind.to_sym)
        return redirect_to sweeps_path, alert: "Unknown sweep #{kind.inspect}."
      end

      Sweep.call(kind)
      redirect_to sweeps_path, notice: "#{kind.humanize} sweep finished."
    end
  end
end
