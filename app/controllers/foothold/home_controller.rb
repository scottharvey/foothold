module Foothold
  # The Queue: what to do next, best first. Shows a working set the size of
  # `queue_size`; everything else waits, ranked, until something is resolved.
  class HomeController < ApplicationController
    def index
      scope = @site.leads.active.of_kind(params[:kind])
      @kinds = @site.leads.active.distinct.pluck(:kind).sort_by { |kind| Lead::KINDS.index(kind) }
      @snoozed = @site.leads.snoozed.count
      @muted = @site.mutes.count
      @last_sweep = SweepRun.latest("nightly")

      if params[:all].present?
        @pagy, @leads = pagy(scope.by_score)
      else
        @leads = scope.by_score.limit(Foothold.threshold(:queue_size)).to_a
        @waiting = scope.count - @leads.size
      end
    end
  end
end
