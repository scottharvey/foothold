module Foothold
  class Sweep
    # Monthly volume and difficulty for the Terms worth paying for.
    class Volumes < Base
      def call
        tracked("volumes") do |run|
          client = config.dataforseo_client&.call
          next skip(run, "not configured") unless client

          stale = Term.worth_pricing(site).where(volume_checked_at: nil)
                      .or(Term.worth_pricing(site).where(volume_checked_at: ...threshold(:volume_refresh_days).days.ago))
          terms = stale.order(:id).to_a
          next skip(run, "nothing stale") if terms.empty?

          terms.each_slice(threshold(:volume_batch_size)) { |batch| price(client, batch) }
          run.note(terms: terms.size, requests: client.requests, cost: client.cost.round(4))
          run.watermark = today
        end
      end

      private

      def price(client, batch)
        prices = client.volumes(batch.map(&:phrase), location_code: config.location_code, language_code: config.language_code)
        now = Time.current
        batch.each do |term|
          volume, difficulty = prices[term.phrase]
          term.update!(volume: volume, difficulty: difficulty, volume_checked_at: now)
        end
      end
    end
  end
end
