module Foothold
  class MutesController < ApplicationController
    def index
      @pagy, @mutes = pagy(@site.mutes.newest_first)
    end

    def create
      mute = @site.mutes.create(key: params.dig(:mute, :key).to_s.strip, label: Mute.label_for(params.dig(:mute, :key).to_s.strip))
      if mute.persisted?
        redirect_to mutes_path, notice: "Muted #{mute.label.downcase}."
      else
        redirect_to mutes_path, alert: "A mute looks like term:phrase, phrase:* in english, page:/path, rival_path:rival.com/section or domain:example.com."
      end
    end

    def destroy
      mute = @site.mutes.find(params[:id])
      mute.destroy!
      redirect_to mutes_path, notice: "Unmuted #{mute.label.to_s.downcase}. Leads it hid return with the next sweep."
    end
  end
end
