module Foothold
  class Sweep
    # Refreshes the Site's content inventory from the host. Pages that drop out
    # of the inventory are kept and marked out of the sitemap, never deleted.
    class Inventory < Base
      def call
        tracked("inventory") do |run|
          now = Time.current
          entries = Array(config.pages.call)
          seen = []

          entries.each do |entry|
            url = Url.path(entry[:url]) or next
            seen << url
            page = site.pages.find_or_initialize_by(url: url)
            page.first_seen_at ||= now
            page.last_seen_at = now
            page.in_sitemap = true
            page.kind = entry[:kind].presence || page.kind.presence || "static"
            page.title = entry[:title] if entry.key?(:title)
            page.description = entry[:description] if entry.key?(:description)
            page.published_on = entry[:published_on] if entry.key?(:published_on)
            page.term_id = target_term(entry[:term])&.id if entry.key?(:term)
            page.save! if page.new_record? || page.changed?
          end

          dropped = site.pages.in_sitemap.where.not(url: seen)
          run.note(pages: seen.size, dropped: dropped.count)
          dropped.update_all(in_sitemap: false, updated_at: now)
          run.watermark = today
        end
      end

      private

      def target_term(phrase)
        return nil if phrase.blank?

        term = Term.locate(site, phrase, source: "page", discovered_on: today, tracked: true)
        term.update!(tracked: true) unless term.tracked?
        term
      end
    end
  end
end
