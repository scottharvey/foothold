module Foothold
  class SweepsController < ApplicationController
    def create
      kind = params[:kind].presence || "nightly"
      unless Sweep::KINDS.key?(kind.to_sym)
        return redirect_to root_path, alert: "Unknown sweep #{kind.inspect}."
      end

      Sweep.call(kind)
      redirect_to root_path, notice: "#{kind.humanize} sweep finished."
    end
  end
end
