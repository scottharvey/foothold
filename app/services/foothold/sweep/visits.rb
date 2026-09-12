module Foothold
  class Sweep
    # Reads the host's visits one day at a time, counts them per landing page
    # and copies search visits and signups onto that day's Readings.
    class Visits < Base
      def call
        tracked("visits") do |run|
          last = run.watermark
          start = last ? last + 1 : today - threshold(:search_console_backfill_days)
          finish = today - 1
          next skip(run, "nothing new") if start > finish

          days = (start..finish).sum { |date| collect(date) }
          run.note(days: (start..finish).count, page_days: days)
          run.watermark = finish
        end
      end

      private

      def collect(date)
        Array(config.visits.call(date)).group_by(&:landing_path).count do |path, visits|
          next false if path.blank?

          page = Page.discover(site, path)
          search = visits.select { |visit| config.search_engine?(visit.referring_domain) }
          day = page.page_days.find_or_initialize_by(date: date)
          day.update!(visits: visits.size, search_visits: search.size, signups: visits.count(&:signup), search_signups: search.count(&:signup))
          Reading.attribute_from!(day)
          true
        end
      end
    end
  end
end
