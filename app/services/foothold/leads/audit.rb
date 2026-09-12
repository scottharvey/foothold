module Foothold
  module Leads
    # One lead per Page carrying unresolved findings, so a broken page is one
    # item in the queue rather than one per problem.
    class Audit < Base
      def candidates
        Finding.open.joins(:page).where(foothold_pages: { site_id: site.id }).group(:page_id).count.filter_map do |page_id, count|
          page = site.pages.find(page_id)
          checks = Finding.open.where(page_id: page_id).pluck(:check).uniq.map(&:humanize).to_sentence

          { identity: { page_id: page_id }, page: page,
            summary: "#{page.url} has #{count} #{'finding'.pluralize(count)}: #{checks}",
            payload: { url: page.url, count: count, checks: checks, evidence: "#{count} #{'finding'.pluralize(count)}" } }
        end
      end
    end
  end
end
