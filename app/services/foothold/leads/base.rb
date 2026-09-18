module Foothold
  module Leads
    # One builder per lead kind. `candidates` returns the suggestions the data
    # supports right now, each with a score; the base drops muted ones,
    # raises the rest and closes what is no longer reported.
    class Base
      attr_reader :site

      def self.kind
        name.demodulize.underscore
      end

      def initialize(site:, mutes: nil)
        @site = site
        @mutes = mutes
      end

      def kind
        self.class.kind
      end

      def call
        kept = candidates.reject { |candidate| muted?(candidate) }
                         .map { |candidate| Lead.suggest!(site: site, kind: kind, **candidate).id }
        Lead.close_missing!(site: site, kind: kind, keep: kept) if Lead::STATE_KINDS.include?(kind)
        kept.size
      end

      private

      def mutes
        @mutes ||= Mute.matcher(site)
      end

      # A candidate is muted by its term, its page, or any key it names.
      def muted?(candidate)
        return false if mutes.empty?

        term = candidate[:term]
        page = candidate[:page]
        (term && mutes.phrase?(term.phrase)) || (page && mutes.page?(page.url)) || mutes.muted?(candidate.dig(:payload, :mute_keys))
      end

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

      def score
        Score
      end

      # The most recent SERP snapshot for a term, as stored by the Serp sweep.
      def latest_serp(term_id)
        Reading.from_serp.where(term_id: term_id).where.not(serp_top: []).order(date: :desc).first
      end

      def volume_of(term)
        term&.volume
      end
    end
  end
end
