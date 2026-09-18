module Foothold
  module Leads
    # A Page whose title does not contain the Term it targets. Proposes one.
    class TitleMismatch < Base
      MAX_TITLE = 60

      def candidates
        site.pages.in_sitemap.where.not(term_id: nil).where.not(title: [ nil, "" ]).filter_map do |page|
          term = page.term or next
          next if page.title.downcase.include?(term.phrase)

          { identity: { page_id: page.id }, page: page, term: term,
            summary: "#{page.url} targets #{quoted(term.phrase)} but its title doesn't say so",
            score: term.volume ? (score.potential(term.volume) * 0.2).round(1) : 5,
            payload: { url: page.url, title: page.title, phrase: term.phrase, proposed_title: propose(term.phrase, page.title),
                       evidence: "title: #{page.title}" } }
        end
      end

      private

      # The phrase first, then whatever of the old title still fits.
      def propose(phrase, title)
        lead = phrase.split.map(&:capitalize).join(" ")
        rest = title.to_s.sub(/\s*[|·–—-]\s*#{Regexp.escape(site.display_name)}\s*\z/i, "").strip
        candidate = rest.present? && rest.downcase != lead.downcase ? "#{lead}: #{rest}" : lead
        candidate = lead if candidate.length > MAX_TITLE
        candidate.truncate(MAX_TITLE, separator: " ", omission: "")
      end
    end
  end
end
