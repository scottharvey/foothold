module Foothold
  class HomeController < ApplicationController
    def index
      @kinds = @site.leads.open.distinct.pluck(:kind).sort_by { |kind| Lead::KINDS.index(kind) }
      @leads = @site.leads.open.of_kind(params[:kind]).by_priority
      @summaries = TermSummary.ordered(TermSummary.for(@site.terms))
      @tracked_count = @summaries.count { |summary| summary.term.tracked? }
      @rivals = @site.rivals.alphabetical
      @rival_counts = RivalTerm.where(rival_id: @rivals.select(:id)).group(:rival_id).count
      @last_sweep = SweepRun.latest("nightly")
    end
  end
end
