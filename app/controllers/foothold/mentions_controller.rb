module Foothold
  class MentionsController < ApplicationController
    def index
      @mentions = @site.mentions.recent_first.limit(200)
    end
  end
end
