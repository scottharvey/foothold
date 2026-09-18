module Foothold
  class LeadsController < ApplicationController
    before_action :set_lead, except: %i[bulk_done bulk_dismiss]

    def show
      @outcome = @lead.outcome
    end

    # Carries out one of the lead's verbs: opens the GitHub issue, starts
    # tracking, or mutes the term.
    def act
      result = Leads::Act.new(lead: @lead, verb: params[:verb], params: params.slice(:title).permit(:title)).call
      redirect_back_or_to root_path, **(result.ok? ? { notice: result.message } : { alert: result.message })
    end

    def done
      @lead.resolve!("done", note: params[:note])
      redirect_back_or_to root_path, notice: "Done."
    end

    def dismiss
      @lead.resolve!("dismissed")
      redirect_back_or_to root_path, notice: "Dismissed. It won't come back."
    end

    def snooze
      @lead.snooze!
      redirect_back_or_to root_path, notice: "Snoozed until #{@lead.snoozed_until.to_date.strftime('%-d %b')}."
    end

    # Mutes one of the lead's mute options and closes every open lead that
    # option covers, so the queue clears now rather than at the next sweep.
    def mute
      option = @lead.mute_options.find { |candidate| candidate[:key] == params[:key] }
      return redirect_back_or_to(lead_path(@lead), alert: "Pick something to mute.") unless option

      Mute.add!(@site, option[:key])
      closed = @site.leads.open.select { |lead| lead.mute_options.any? { |candidate| candidate[:key] == option[:key] } }
      Lead.resolve_many!(site: @site, ids: closed.map(&:id), state: "dismissed")
      redirect_to root_path, notice: "Muted #{option[:label].downcase}. #{closed.size} #{'lead'.pluralize(closed.size)} closed."
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
