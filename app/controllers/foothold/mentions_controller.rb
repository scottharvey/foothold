module Foothold
  class MentionsController < ApplicationController
    def index
      @pagy, @mentions = pagy(@site.mentions.recent_first)
    end
  end
end
