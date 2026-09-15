require "net/http"
require "json"

module Foothold
  # Small client for opening issues via the GitHub REST API. Used to hand a
  # page-draft opportunity to the Claude Code GitHub Action, never to write
  # anything else — Foothold has no reason to touch the repo beyond this.
  class GitHub
    Error = Class.new(StandardError)
    Issue = Data.define(:number, :url)

    ENDPOINT = "https://api.github.com".freeze

    def self.from_env
      token = ENV["FOOTHOLD_GITHUB_TOKEN"]
      repo = ENV["FOOTHOLD_GITHUB_REPO"]
      return nil if token.blank? || repo.blank?

      new(token:, repo:)
    end

    def initialize(token:, repo:, endpoint: ENDPOINT)
      @token = token
      @repo = repo
      @endpoint = URI(endpoint)
    end

    def open_issue(title:, body:, labels: [])
      uri = @endpoint + "/repos/#{@repo}/issues"
      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json",
                                          "Authorization" => "Bearer #{@token}",
                                          "Accept" => "application/vnd.github+json")
      request.body = { title:, body:, labels: }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) { |http| http.request(request) }
      raise Error, "HTTP #{response.code} opening issue: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      Issue.new(number: payload["number"], url: payload["html_url"])
    end
  end
end
