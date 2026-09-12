module Foothold
  class PagesController < ApplicationController
    def show
      @page = @site.pages.find(params[:id])
      @findings = @page.findings.open.order(:check)
    end
  end
end
