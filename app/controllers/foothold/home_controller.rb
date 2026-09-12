module Foothold
  class HomeController < ApplicationController
    def index
      @summaries = TermSummary.ordered(TermSummary.for(@site.terms))
      @tracked_count = @summaries.count { |summary| summary.term.tracked? }
      @last_sweep = SweepRun.latest("nightly")
    end
  end
end
