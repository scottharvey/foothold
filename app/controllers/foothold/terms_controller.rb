module Foothold
  class TermsController < ApplicationController
    before_action :set_term, only: %i[show update destroy]

    def index
      @summaries = TermSummary.ordered(TermSummary.for(@site.terms))
      @tracked_count = @summaries.count { |summary| summary.term.tracked? }
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

    def set_term
      @term = @site.terms.find(params[:id])
    end
  end
end
