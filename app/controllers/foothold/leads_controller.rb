module Foothold
  class LeadsController < ApplicationController
    before_action :set_lead

    def done
      @lead.resolve!("done")
      redirect_back_or_to root_path, notice: "Done."
    end

    def dismiss
      @lead.resolve!("dismissed")
      redirect_back_or_to root_path, notice: "Dismissed."
    end

    # For track_this leads: start tracking the term and close the lead.
    def track
      term = @lead.term
      if @lead.kind == "track_this" && term
        term.update!(tracked: true)
        @lead.resolve!("done")
        redirect_back_or_to root_path, notice: "Tracking “#{term.phrase}”."
      else
        redirect_back_or_to root_path, alert: "Nothing to track."
      end
    end

    private

    def set_lead
      @lead = @site.leads.find(params[:id])
    end
  end
end
