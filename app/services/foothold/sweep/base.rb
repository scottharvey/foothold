module Foothold
  class Sweep
    class Base
      attr_reader :site, :kind

      def initialize(site:, kind: :nightly)
        @site = site
        @kind = kind
      end

      private

      def config
        Foothold.configuration
      end

      def threshold(key)
        config.threshold(key)
      end

      def today
        Date.current
      end

      # Records a SweepRun around the block. `name` is what the watermark is
      # keyed by, so each source resumes independently.
      def tracked(name, &block)
        SweepRun.track(name, kind: kind, &block)
      end

      def skip(run, reason)
        run.note(skipped: reason)
        Rails.logger.info("[Foothold::Sweep] #{self.class.name} skipped: #{reason}")
      end
    end
  end
end
