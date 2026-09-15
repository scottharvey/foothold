module Foothold
  # Sweep history, cost, and the manual triggers for testing against real
  # data: sweep now, weekly audit, and (folded in here rather than its own
  # page) send digest now.
  class SweepsController < ApplicationController
    # One click runs several sources back to back (inventory, visits, search
    # console...). Group consecutive same-kind runs into one episode so the
    # page reads as "what happened last time", not a flat log per source.
    EPISODE_GAP = 5.minutes

    def index
      runs = SweepRun.order(id: :desc).limit(200).to_a
      episodes = runs.slice_when { |a, b| a.kind != b.kind || (a.started_at - b.started_at).abs > EPISODE_GAP }.to_a
      @pagy, @episodes = pagy(episodes)
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
