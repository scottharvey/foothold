module Foothold
  class Sweep
    # Pulls every query Google showed the Site for, one day at a time. Search
    # Console data is final about two days late, so the sweep stops there.
    class SearchConsole < Base
      LAG_DAYS = 2

      def call
        tracked("search_console") do |run|
          client = config.search_console_client&.call
          next skip(run, "not configured") unless client

          last = run.watermark
          start = last ? last + 1 : today - threshold(:search_console_backfill_days)
          finish = today - LAG_DAYS
          next skip(run, "nothing new") if start > finish

          readings = (start..finish).sum { |date| collect(client, date) }
          run.note(days: (start..finish).count, readings: readings)
          run.watermark = finish
        end
      end

      private

      def collect(client, date)
        rows = client.search_analytics(site.property, date)
        rows.group_by { |row| row.query.to_s.squish.downcase }.count do |query, group|
          impressions = group.sum(&:impressions)
          next false if impressions < threshold(:discover_min_impressions)

          best = group.min_by(&:position)
          term = Term.locate(site, query, source: "search_console", discovered_on: date) or next false
          landing = Url.path(best.page)
          reading = Reading.record!(term: term, date: date, source: "search_console",
                                    position: best.position.round(1), landing_url: landing,
                                    impressions: impressions, search_clicks: group.sum(&:clicks))
          attribute(reading, landing, date)
          true
        end
      end

      # Visits for this day were counted before the Reading existed.
      def attribute(reading, landing, date)
        day = PageDay.joins(:page).find_by(date: date, foothold_pages: { site_id: site.id, url: landing })
        reading.update_columns(clicks: day.search_visits, signups: day.search_signups) if day
      end
    end
  end
end
