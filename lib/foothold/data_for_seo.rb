require "net/http"
require "json"

module Foothold
  # Small client for the DataForSEO v3 API. Pay-as-you-go: every call records
  # its cost so the Sweep can show what a run spent.
  class DataForSeo
    Error = Class.new(StandardError)
    Hit = Data.define(:rank_group, :url, :domain)
    Ranked = Data.define(:phrase, :volume, :rank_group, :url)

    ENDPOINT = "https://api.dataforseo.com/v3/".freeze
    OK = 20_000
    PARTIAL_RESULTS = 40_106 # some pages timed out; you're not charged for them and the rest of the result is still usable
    TRANSIENT_SE_ERROR = 40_101 # the search engine itself failed to respond; DataForSEO's own docs say to resubmit
    MAX_ATTEMPTS = 3

    attr_reader :cost, :requests

    def self.from_env
      login = ENV["FOOTHOLD_DATAFORSEO_LOGIN"]
      password = ENV["FOOTHOLD_DATAFORSEO_PASSWORD"]
      return nil if login.blank? || password.blank?

      new(login:, password:)
    end

    def initialize(login:, password:, endpoint: ENDPOINT)
      @login = login
      @password = password
      @endpoint = URI(endpoint)
      @cost = 0.0
      @requests = 0
    end

    # Organic results for one phrase, best first.
    def serp(phrase, location_code:, language_code:, depth:)
      result = post("serp/google/organic/live/regular",
                    [ { keyword: phrase, location_code:, language_code:, device: "desktop", depth: } ]).first
      Array(result&.dig("items")).select { |item| item["type"] == "organic" }.map do |item|
        Hit.new(rank_group: item["rank_group"], url: item["url"], domain: item["domain"])
      end
    end

    # { phrase => [ volume, difficulty ] } for up to 1,000 phrases.
    def volumes(phrases, location_code:, language_code:)
      body = [ { keywords: phrases, location_code:, language_code: } ]
      volumes = post("keywords_data/google_ads/search_volume/live", body)
                  .to_h { |row| [ row["keyword"], row["search_volume"] ] }
      difficulty = Array(post("dataforseo_labs/google/bulk_keyword_difficulty/live", body).first&.dig("items"))
                     .to_h { |row| [ row["keyword"], row["keyword_difficulty"] ] }
      phrases.to_h { |phrase| [ phrase, [ volumes[phrase], difficulty[phrase] ] ] }
    end

    # Terms a domain ranks in the top 20 for.
    def ranked_keywords(domain, location_code:, language_code:, limit:)
      body = [ {
        target: domain, location_code:, language_code:, limit:,
        filters: [ [ "ranked_serp_element.serp_item.rank_group", "<=", 20 ] ],
        order_by: [ "ranked_serp_element.serp_item.rank_group,asc" ]
      } ]
      Array(post("dataforseo_labs/google/ranked_keywords/live", body).first&.dig("items")).map do |item|
        Ranked.new(
          phrase: item.dig("keyword_data", "keyword"),
          volume: item.dig("keyword_data", "keyword_info", "search_volume"),
          rank_group: item.dig("ranked_serp_element", "serp_item", "rank_group"),
          url: item.dig("ranked_serp_element", "serp_item", "url")
        )
      end
    end

    private

    # Returns the flattened result arrays of every task in the response.
    # Retries the whole request when the search engine itself failed, since
    # DataForSEO's own docs say that's transient and worth resubmitting.
    def post(path, tasks, attempt: 1)
      uri = @endpoint + path
      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json", "User-Agent" => "Foothold/1.0", "Accept" => "application/json")
      request.basic_auth(@login, @password)
      request.body = tasks.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60) { |http| http.request(request) }
      raise Error, "HTTP #{response.code} from #{path}" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      @requests += 1
      @cost += payload["cost"].to_f
      raise Error, "#{path}: #{payload['status_message']}" unless payload["status_code"] == OK

      Array(payload["tasks"]).flat_map do |task|
        next Array(task["result"]) if task["status_code"] == OK || task["status_code"] == PARTIAL_RESULTS
        if task["status_code"] == TRANSIENT_SE_ERROR && attempt < MAX_ATTEMPTS
          sleep(attempt)
          return post(path, tasks, attempt: attempt + 1)
        end

        raise Error, "#{path}: #{task['status_message']}"
      end
    end
  end
end
