module Foothold
  module Leads
    # Every lead is scored in the same unit, estimated monthly search visits
    # at stake, so the queue can rank a position drop against a term gap.
    module Score
      module_function

      CTR = { 1 => 0.28, 2 => 0.15, 3 => 0.11, 4 => 0.08, 5 => 0.07, 6 => 0.05, 7 => 0.04, 8 => 0.03, 9 => 0.03, 10 => 0.025 }.freeze
      TARGET_POSITION = 5

      def ctr(position)
        return 0.0 if position.nil?

        position = position.to_f.round
        return CTR.fetch(position) if CTR.key?(position)
        return 0.01 if position <= 20
        return 0.005 if position <= 30

        0.002
      end

      # Monthly visits a phrase with this volume sends at this position.
      def visits(volume, position)
        (volume.to_i * ctr(position)).round(1)
      end

      # Monthly visits gained by moving from one position to another.
      def gain(volume, from:, to:)
        [ visits(volume, to) - visits(volume, from), 0 ].max.round(1)
      end

      # What ranking well for a phrase we don't rank for would be worth.
      def potential(volume)
        visits(volume, TARGET_POSITION)
      end

      # Search Console impressions over `days` scaled to a month.
      def monthly(impressions, days)
        return 0.0 if days.to_i <= 0

        (impressions.to_f / days * 30).round(1)
      end
    end
  end
end
