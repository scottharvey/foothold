module Foothold
  class RivalsController < ApplicationController
    def index
      @pagy, @rivals = pagy(@site.rivals.alphabetical)
      @rival_counts = RivalTerm.where(rival_id: @rivals.map(&:id)).group(:rival_id).count
    end

    def create
      rival = @site.rivals.create(domain: params.dig(:rival, :domain))
      if rival.persisted?
        redirect_to rivals_path, notice: "Added #{rival.domain}. Its terms arrive with the weekly sweep."
      else
        redirect_to rivals_path, alert: rival.errors.full_messages.to_sentence
      end
    end

    def destroy
      rival = @site.rivals.find(params[:id])
      rival.destroy!
      redirect_to rivals_path, notice: "Removed #{rival.domain}."
    end
  end
end
