module Foothold
  class ApplicationController < Foothold.configuration.parent_controller.constantize
    include Pagy::Method

    layout Foothold.configuration.layout

    # The host's own guards redirect with host route helpers, which do not
    # resolve inside an isolated engine. Foothold authenticates on its own.
    Foothold.configuration.skip_host_before_actions.each do |name|
      skip_before_action name, raise: false
    end

    before_action :authenticate_foothold!
    before_action :set_site

    private

    def set_site
      @site = Site.current
    end

    def authenticate_foothold!
      instance_exec(&Foothold.configuration.authenticate)
    end
  end
end
