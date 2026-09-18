module Foothold
  # Asks Claude whether a batch of search phrases are ones a prospective
  # customer of the Site would type. Used once per rival phrase, cached on
  # the row, so the term gap builder can ignore dictionary lookups and other
  # traffic the product could never convert.
  class Relevance
    Error = Class.new(StandardError)

    DEFAULT_MODEL = "claude-opus-5".freeze
    BATCH = 50

    def self.from_env
      key = ENV["FOOTHOLD_ANTHROPIC_API_KEY"].presence || ENV["ANTHROPIC_API_KEY"].presence
      return nil if key.blank?

      require "anthropic"
      new(client: Anthropic::Client.new(api_key: key), model: ENV["FOOTHOLD_RELEVANCE_MODEL"].presence || DEFAULT_MODEL)
    end

    def initialize(client:, model: DEFAULT_MODEL)
      @client = client
      @model = model
    end

    # { phrase => true | false } for every phrase Claude gave a verdict on.
    # Phrases it left out stay unclassified, so a bad batch never marks
    # anything.
    def classify(phrases, site_name:, description:)
      phrases.each_slice(BATCH).each_with_object({}) do |batch, verdicts|
        verdicts.merge!(classify_batch(batch, site_name:, description:))
      end
    end

    private

    def classify_batch(phrases, site_name:, description:)
      message = @client.messages.create(
        model: @model,
        max_tokens: 4000,
        system_: [ { type: "text", text: system_prompt(site_name, description) } ],
        messages: [ { role: "user", content: phrases.map { |phrase| "- #{phrase}" }.join("\n") } ]
      )
      raise Error, "refused: #{message.stop_details&.explanation}" if message.stop_reason == :refusal

      text = message.content.filter_map { |block| block.text if block.type == :text }.join
      parse(text, phrases)
    end

    def system_prompt(site_name, description)
      <<~PROMPT
        You screen Google search queries for #{site_name}, #{description.presence || 'a software product'}.

        For each query, decide whether the person typing it could plausibly be a
        prospective customer of that product: they are looking for a product,
        service, comparison, guide or answer that the product genuinely addresses.

        Not relevant: dictionary lookups and single-word translations, homework
        answers, queries about a different product category, queries about a
        specific other brand with no comparison intent, and anything the product
        could not honestly serve.

        Reply with JSON only: an object whose keys are the queries exactly as
        given and whose values are true or false.
      PROMPT
    end

    def parse(text, phrases)
      json = text[/\{.*\}/m] or return {}
      verdicts = JSON.parse(json)
      phrases.each_with_object({}) do |phrase, result|
        verdict = verdicts[phrase]
        result[phrase] = verdict if [ true, false ].include?(verdict)
      end
    rescue JSON::ParserError
      {}
    end
  end
end
