module Foothold
  class Sweep
    # A paid position check for every tracked Term, once a day.
    class Serp < Base
      def call
        tracked("serp") do |run|
          client = config.dataforseo_client&.call
          next skip(run, "not configured") unless client
          next skip(run, "already checked today") if run.watermark == today

          terms = site.terms.tracked.order(:created_at).limit(threshold(:max_tracked_terms))
          terms.each { |term| check(client, term) }

          run.note(terms: terms.size, requests: client.requests, cost: client.cost.round(4))
          run.watermark = today
        end
      end

      private

      def check(client, term)
        hits = client.serp(term.phrase, location_code: config.location_code, language_code: config.language_code, depth: threshold(:serp_depth))
        hit = hits.find { |candidate| Url.on_site?(candidate.url, site.domain) }
        Reading.record!(term: term, date: today, source: "serp", position: hit&.rank_group, landing_url: hit && Url.path(hit.url))
      end
    end
  end
end
