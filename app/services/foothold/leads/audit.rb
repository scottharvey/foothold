module Foothold
  module Leads
    # One lead per Page carrying unresolved findings, so a broken page is one
    # item in the queue rather than one per problem.
    class Audit < Base
      def candidates
        Finding.open.joins(:page).where(foothold_pages: { site_id: site.id }).group(:page_id).count.filter_map do |page_id, count|
          page = site.pages.find(page_id)
          findings = Finding.open.where(page_id: page_id).order(:check).map { |finding| { check: finding.check, detail: finding.detail } }
          checks = findings.map { |finding| finding[:check].humanize }.uniq.to_sentence
          term = page.term

          { identity: { page_id: page_id }, page: page, term: term,
            summary: "#{page.url} has #{count} #{'finding'.pluralize(count)}: #{checks}",
            score: count * 5 + (term&.volume ? (score.potential(term.volume) * 0.1).round(1) : 0),
            payload: { url: page.url, count: count, checks: checks, findings: findings, phrase: term&.phrase,
                       evidence: "#{count} #{'finding'.pluralize(count)}" } }
        end
      end
    end
  end
end
