module Foothold
  module Leads
    # A Page whose title does not contain the Term it targets.
    class TitleMismatch < Base
      def candidates
        site.pages.in_sitemap.where.not(term_id: nil).where.not(title: [ nil, "" ]).filter_map do |page|
          term = page.term or next
          next if page.title.downcase.include?(term.phrase)

          { identity: { page_id: page.id }, page: page, term: term,
            summary: "#{page.url} targets #{quoted(term.phrase)} but its title doesn't say so",
            payload: { url: page.url, title: page.title, phrase: term.phrase, evidence: "title: #{page.title}" } }
        end
      end
    end
  end
end
