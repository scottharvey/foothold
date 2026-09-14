module Foothold
  class LeadsController < ApplicationController
    before_action :set_lead, except: %i[bulk_done bulk_dismiss]

    def show
    end

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

    def bulk_done
      bulk_resolve!("done")
    end

    def bulk_dismiss
      bulk_resolve!("dismissed")
    end

    private

    def bulk_resolve!(state)
      ids = Array(params[:lead_ids]).reject(&:blank?)
      return redirect_back_or_to(root_path, alert: "Select at least one lead.") if ids.empty?

      count = Lead.resolve_many!(site: @site, ids: ids, state: state)
      redirect_back_or_to root_path, notice: "#{count} #{'lead'.pluralize(count)} #{state}."
    end

    def set_lead
      @lead = @site.leads.find(params[:id])
    end
  end
end
