module Foothold
  class Engine < ::Rails::Engine
    isolate_namespace Foothold

    # Migrations stay in the engine; the host runs them from here.
    initializer "foothold.migrations" do |app|
      unless app.root.to_s.start_with?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
