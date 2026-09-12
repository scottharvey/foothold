module Foothold
  # The Queue: what to do next. The page an operator opens to triage.
  class HomeController < ApplicationController
    def index
      @kinds = @site.leads.open.distinct.pluck(:kind).sort_by { |kind| Lead::KINDS.index(kind) }
      @leads = @site.leads.open.of_kind(params[:kind]).by_priority
      @last_sweep = SweepRun.latest("nightly")
    end
  end
end
