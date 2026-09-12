module Foothold
  module Leads
    # One builder per lead kind. `candidates` returns the suggestions the data
    # supports right now; the base raises them and closes the rest.
    class Base
      attr_reader :site

      def self.kind
        name.demodulize.underscore
      end

      def initialize(site:)
        @site = site
      end

      def kind
        self.class.kind
      end

      def call
        kept = candidates.map { |candidate| Lead.suggest!(site: site, kind: kind, **candidate).id }
        Lead.close_missing!(site: site, kind: kind, keep: kept) if Lead::STATE_KINDS.include?(kind)
        kept.size
      end

      private

      def today
        Date.current
      end

      def threshold(key)
        Foothold.threshold(key)
      end

      # The last `days` days, today included.
      def window(days)
        (today - (days - 1))..today
      end

      def quoted(phrase)
        "“#{phrase}”"
      end
    end
  end
end
