module Foothold
  module Leads
    # A rival ranks well for several relevant terms and we have no
    # alternatives page pointing prospective switchers at us instead.
    class AlternativeGap < Base
      def candidates
        site.rivals.includes(:rival_terms).filter_map do |rival|
          next if covered?(rival)

          terms = qualifying_terms(rival)
          next if terms.size < threshold(:alternative_min_rival_terms)

          { identity: { rival_id: rival.id },
            summary: "#{rival.display_name} ranks for #{terms.size} #{'term'.pluralize(terms.size)} with no alternatives page pointing at us",
            score: terms.sum { |rival_term| score.potential(rival_term.volume) },
            payload: {
              domain: rival.domain,
              slug: slug_for(rival),
              evidence: "#{terms.size} qualifying terms, best position ##{terms.map(&:position).compact.min}",
              terms: terms.first(100).map { |rt| { "phrase" => rt.phrase, "position" => rt.position.to_i, "volume" => rt.volume } }
            } }
        end
      end

      private

      def qualifying_terms(rival)
        rival.rival_terms.select do |rival_term|
          rival_term.position.present? && rival_term.position <= threshold(:alternative_rival_position) &&
            rival_term.relevant != false && !mutes.phrase?(rival_term.phrase)
        end.sort_by { |rival_term| -rival_term.volume.to_i }
      end

      def covered?(rival)
        site.pages.exists?(kind: "alternative", url: "/alternatives/#{slug_for(rival)}")
      end

      def slug_for(rival)
        rival.domain.parameterize
      end
    end
  end
end
