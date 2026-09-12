module Foothold
  # The only way outside data enters Foothold. Runs the sources for one kind of
  # sweep in a fixed order. Each source is isolated so one failure does not stop
  # the rest, and each records a SweepRun with its watermark and cost.
  class Sweep
    KINDS = {
      nightly: [ Sweep::Inventory, Sweep::Visits, Sweep::SearchConsole, Sweep::Serp, Sweep::Volumes ],
      weekly: [],
      monthly: []
    }.freeze

    def self.call(kind = :nightly)
      new(kind).call
    end

    def initialize(kind = :nightly)
      @kind = kind.to_sym
      @sources = KINDS.fetch(@kind) { raise ArgumentError, "unknown sweep kind #{kind.inspect}" }
    end

    def call
      site = Site.current
      @sources.each { |source| run(source, site) }
      run(Sweep::PruneRuns, site)
      self
    end

    private

    def run(source, site)
      source.new(site: site, kind: @kind).call
    rescue StandardError => e
      Rails.logger.error("[Foothold::Sweep] #{source.name} failed: #{e.class}: #{e.message}")
      raise if Rails.env.test?
    end
  end
end
