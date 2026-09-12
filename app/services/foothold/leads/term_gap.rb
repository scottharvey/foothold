module Foothold
  module Leads
    # A Rival is in the top ten for a Term the Site has not ranked in the top
    # thirty for in the last four weeks.
    class TermGap < Base
      def candidates
        ranked = RivalTerm.joins(:rival).where(foothold_rivals: { site_id: site.id }).top(10)
                          .includes(:rival, :term).group_by(&:term_id)

        ranked.filter_map do |term_id, rows|
          next if Reading.where(term_id: term_id, date: window(28), position: ..30).exists?

          term = rows.first.term
          rows = rows.sort_by(&:position)
          best = rows.first
          volume = term.volume || best.volume
          rivals = rows.map { |row| { domain: row.rival.domain, position: row.position, url: row.landing_url } }
          evidence = rivals.map { |rival| "#{rival[:domain]} ##{rival[:position]}" }.join(", ")
          evidence += " · volume #{volume}" if volume

          { identity: { term_id: term_id }, term: term,
            summary: "#{quoted(term.phrase)} ranks ##{best.position} for #{best.rival.domain} and nowhere for you",
            payload: { phrase: term.phrase, rivals: rivals, volume: volume, evidence: evidence } }
        end
      end
    end
  end
end
