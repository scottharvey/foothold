require "base64"
require "stringio"

module Foothold
  # Thin wrapper over Google's Search Console client, authenticated with a
  # service account that has been added as a user on the property.
  class SearchConsole
    Row = Data.define(:query, :page, :clicks, :impressions, :position)
    Inspection = Data.define(:verdict, :coverage_state, :robots_txt_state, :indexing_state, :page_fetch_state, :last_crawl_time)

    SCOPE = "https://www.googleapis.com/auth/webmasters.readonly".freeze
    ROW_LIMIT = 25_000

    def self.from_env(json = ENV["FOOTHOLD_GOOGLE_SERVICE_ACCOUNT_JSON"])
      return nil if json.blank?

      json = Base64.decode64(json) unless json.lstrip.start_with?("{")
      require "google/apis/searchconsole_v1"
      require "googleauth"
      service = Google::Apis::SearchconsoleV1::SearchConsoleService.new
      service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: StringIO.new(json), scope: SCOPE)
      new(service)
    end

    def initialize(service)
      @service = service
    end

    # Every query that showed the property on one day, with the page it showed.
    def search_analytics(property, date)
      request = Google::Apis::SearchconsoleV1::SearchAnalyticsQueryRequest.new(
        start_date: date.iso8601, end_date: date.iso8601,
        dimensions: %w[query page], row_limit: ROW_LIMIT, data_state: "final"
      )
      Array(@service.query_searchanalytic(property, request).rows).map do |row|
        Row.new(query: row.keys[0], page: row.keys[1], clicks: row.clicks.to_i, impressions: row.impressions.to_i, position: row.position.to_f)
      end
    end

    # Google's index verdict for one absolute URL. Quota is 2,000 a day.
    def inspect_url(property, url)
      request = Google::Apis::SearchconsoleV1::InspectUrlIndexRequest.new(inspection_url: url, site_url: property)
      status = @service.inspect_url_index(request).inspection_result&.index_status_result
      Inspection.new(verdict: status&.verdict, coverage_state: status&.coverage_state, robots_txt_state: status&.robots_txt_state,
                     indexing_state: status&.indexing_state, page_fetch_state: status&.page_fetch_state, last_crawl_time: status&.last_crawl_time)
    end
  end
end
