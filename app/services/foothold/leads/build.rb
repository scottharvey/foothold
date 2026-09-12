module Foothold
  module Leads
    # Runs every builder after a Sweep. Each is isolated so one failure does
    # not stop the rest.
    class Build < Sweep::Base
      BUILDERS = [ Drop, LeakyPage, TermGap, PageTwo, TitleMismatch, TrackThis, NewReferrer ].freeze

      def call
        tracked("leads") do |run|
          counts = BUILDERS.to_h { |builder| [ builder.kind.to_sym, build(builder) ] }
          run.note(**counts, open: site.leads.open.count)
          run.watermark = today
        end
      end

      private

      def build(builder)
        builder.new(site: site).call
      rescue StandardError => e
        Rails.logger.error("[Foothold::Leads] #{builder.name} failed: #{e.class}: #{e.message}")
        raise if Rails.env.test?
        nil
      end
    end
  end
end
