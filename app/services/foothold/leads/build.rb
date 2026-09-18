module Foothold
  module Leads
    # Runs every builder after a Sweep. Each is isolated so one failure does
    # not stop the rest. Mutes are read once and shared.
    class Build < Sweep::Base
      BUILDERS = [ Drop, LeakyPage, NotIndexed, TermGap, PageTwo, TitleMismatch, TrackThis, NewReferrer, Mention, Audit,
                   AlternativeGap, PageUnderperforming ].freeze

      def call
        tracked("leads") do |run|
          mutes = Mute.matcher(site)
          counts = BUILDERS.to_h { |builder| [ builder.kind.to_sym, build(builder, mutes) ] }
          run.note(**counts, open: site.leads.open.count)
          run.watermark = today
        end
      end

      private

      def build(builder, mutes)
        builder.new(site: site, mutes: mutes).call
      rescue StandardError => e
        Rails.logger.error("[Foothold::Leads] #{builder.name} failed: #{e.class}: #{e.message}")
        raise if Rails.env.test?
        nil
      end
    end
  end
end
