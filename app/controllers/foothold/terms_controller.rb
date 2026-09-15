module Foothold
  class TermsController < ApplicationController
    before_action :set_term, only: %i[show update destroy]

    def index
      @tracked_count = @site.terms.tracked.count
      @pagy, page_terms = pagy(ordered_terms)
      @summaries = TermSummary.for(page_terms)
    end

    def show
      @readings = @term.readings.where(date: 90.days.ago.to_date..).order(date: :desc, source: :asc)
      @summary = TermSummary.for([ @term ]).first
    end

    def create
      term = Term.locate(@site, params.dig(:term, :phrase), source: "manual", discovered_on: Date.current, tracked: true)
      if term
        term.update!(tracked: true)
        redirect_to terms_path, notice: "Tracking “#{term.phrase}”."
      else
        redirect_to terms_path, alert: "Enter a phrase to track."
      end
    end

    def update
      @term.update!(tracked: ActiveModel::Type::Boolean.new.cast(params.dig(:term, :tracked)))
      redirect_back_or_to terms_path, notice: @term.tracked? ? "Tracking “#{@term.phrase}”." : "Stopped tracking “#{@term.phrase}”."
    end

    def destroy
      @term.destroy!
      redirect_to terms_path, notice: "Removed “#{@term.phrase}”."
    end

    private

    # Same ordering as TermSummary.ordered (tracked first, then busiest, then
    # alphabetical) computed from a single aggregate query instead of loading
    # every term's readings — building a full TermSummary per term (as the
    # old index did, for every term, before paginating) was what made this
    # page slow to load once rival-discovered terms piled up.
    def ordered_terms
      impressions = Reading.where(term_id: @site.terms.select(:id), source: "search_console",
                                   date: (Date.current - (TermSummary::DAYS - 1))..Date.current)
                            .group(:term_id).sum(:impressions)
      @site.terms.to_a.sort_by { |term| [ term.tracked? ? 0 : 1, -impressions.fetch(term.id, 0), term.phrase ] }
    end

    def set_term
      @term = @site.terms.find(params[:id])
    end
  end
end
