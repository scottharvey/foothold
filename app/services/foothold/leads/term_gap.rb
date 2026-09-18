module Foothold
  module Leads
    # A rival section that wins search terms the Site doesn't rank for. One
    # lead per rival and first path segment, so two thousand dictionary pages
    # are one decision, not two thousand rows.
    class TermGap < Base
      STORED_TERMS = 200

      def candidates
        ranked = RivalTerm.joins(:rival).where(foothold_rivals: { site_id: site.id }).top(10).relevant
                          .where(volume: threshold(:term_gap_min_volume)..).includes(:rival).to_a
        ranked.reject! { |row| mutes.phrase?(row.phrase) || mutes.rival_path?(row.rival.domain, row.landing_url) }
        ranked -= ranked.select { |row| covered.include?(row.phrase) }

        ranked.group_by { |row| [ row.rival_id, row.section ] }.map do |(rival_id, section), rows|
          rival = rows.first.rival
          rows = rows.sort_by { |row| [ -row.volume.to_i, row.position ] }
          volume_total = rows.sum { |row| row.volume.to_i }
          urls = rows.group_by { |row| row.landing_url }.map { |url, group| { url: url, count: group.size } }
                     .sort_by { |entry| -entry[:count] }.first(10)
          terms = rows.first(STORED_TERMS).map { |row| { phrase: row.phrase, position: row.position, volume: row.volume, url: row.landing_url } }
          count = rows.size

          { identity: { rival_id: rival_id, path: section },
            summary: "#{rival.display_name} ranks top 10 for #{count} #{'term'.pluralize(count)} under #{section} that you don't rank for",
            score: rows.sum { |row| score.potential(row.volume) },
            payload: { domain: rival.domain, path: section, rival: rival.display_name, count: count, volume_total: volume_total,
                       terms: terms, urls: urls, phrase: (rows.first.phrase if count == 1),
                       evidence: "#{count} #{'term'.pluralize(count)} · combined volume #{volume_total} · best #{quoted(rows.first.phrase)} ##{rows.first.position}",
                       mute_keys: [ "rival_path:#{rival.domain}#{section}" ] } }
        end
      end

      private

      # Phrases the Site has ranked in the top thirty for in the last four weeks.
      def covered
        @covered ||= Term.where(site_id: site.id)
                         .where(id: Reading.where(date: window(28), position: ..30).select(:term_id))
                         .pluck(:phrase).to_set
      end
    end
  end
end
