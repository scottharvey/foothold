module Foothold
  class Sweep
    # The phrases each Rival ranks in the top twenty for, refreshed weekly.
    # Phrases stay on the rival row; a Term is only created when the
    # operator tracks one. New phrases are then screened for relevance so
    # dictionary lookups and the like never become leads.
    class RivalTerms < Base
      REFRESH_AFTER = 6.days

      def call
        tracked("rival_terms") do |run|
          client = config.dataforseo_client&.call
          next skip(run, "not configured") unless client

          due = site.rivals.where(last_checked_at: nil).or(site.rivals.where(last_checked_at: ...REFRESH_AFTER.ago)).to_a
          next skip(run, "nothing due") if due.empty?

          due.each { |rival| refresh(client, rival) }
          classified = classify
          run.note(rivals: due.size, requests: client.requests, cost: client.cost.round(4), classified: classified)
          run.watermark = today
        end
      end

      private

      def refresh(client, rival)
        ranked = client.ranked_keywords(rival.domain, location_code: config.location_code, language_code: config.language_code,
                                                      limit: threshold(:rival_keyword_limit))
        now = Time.current
        seen = ranked.filter_map do |row|
          phrase = row.phrase.to_s.squish.downcase
          next if phrase.blank?

          rival.rival_terms.find_or_initialize_by(phrase: phrase)
               .update!(position: row.rank_group, landing_url: row.url, volume: row.volume, checked_at: now)
          phrase
        end
        rival.rival_terms.where.not(phrase: seen).delete_all
        rival.update!(last_checked_at: now)
      end

      # Verdicts are cached per phrase; only new phrases cost a call.
      def classify
        relevance = config.relevance_client&.call
        return 0 unless relevance

        pending = RivalTerm.joins(:rival).where(foothold_rivals: { site_id: site.id }).unclassified.distinct.pluck(:phrase)
        return 0 if pending.empty?

        verdicts = relevance.classify(pending, site_name: config.site_name, description: config.site_description)
        verdicts.each do |phrase, relevant|
          RivalTerm.joins(:rival).where(foothold_rivals: { site_id: site.id }, phrase: phrase).update_all(relevant: relevant)
        end
        verdicts.size
      rescue StandardError => e
        Rails.logger.warn("[Foothold::Sweep::RivalTerms] relevance check failed: #{e.class}: #{e.message}")
        0
      end
    end
  end
end
