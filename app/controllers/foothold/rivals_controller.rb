module Foothold
  class RivalsController < ApplicationController
    def create
      rival = @site.rivals.create(domain: params.dig(:rival, :domain))
      if rival.persisted?
        redirect_to root_path(anchor: "rivals"), notice: "Added #{rival.domain}. Its terms arrive with the weekly sweep."
      else
        redirect_to root_path(anchor: "rivals"), alert: rival.errors.full_messages.to_sentence
      end
    end

    def destroy
      rival = @site.rivals.find(params[:id])
      rival.destroy!
      redirect_to root_path(anchor: "rivals"), notice: "Removed #{rival.domain}."
    end
  end
end
