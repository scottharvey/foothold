module Foothold
  class Sweep
    # The Terms each Rival ranks in the top twenty for, refreshed weekly.
    class RivalTerms < Base
      REFRESH_AFTER = 6.days

      def call
        tracked("rival_terms") do |run|
          client = config.dataforseo_client&.call
          next skip(run, "not configured") unless client

          due = site.rivals.where(last_checked_at: nil).or(site.rivals.where(last_checked_at: ...REFRESH_AFTER.ago)).to_a
          next skip(run, "nothing due") if due.empty?

          due.each { |rival| refresh(client, rival) }
          run.note(rivals: due.size, requests: client.requests, cost: client.cost.round(4))
          run.watermark = today
        end
      end

      private

      def refresh(client, rival)
        ranked = client.ranked_keywords(rival.domain, location_code: config.location_code, language_code: config.language_code,
                                                      limit: threshold(:rival_keyword_limit))
        now = Time.current
        ranked.each do |row|
          term = Term.locate(site, row.phrase, source: "rival", discovered_on: today) or next
          term.update!(volume: row.volume) if term.volume.nil? && row.volume
          rival.rival_terms.find_or_initialize_by(term_id: term.id)
               .update!(position: row.rank_group, landing_url: row.url, volume: row.volume, checked_at: now)
        end
        rival.update!(last_checked_at: now)
      end
    end
  end
end
