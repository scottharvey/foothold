module Foothold
  # Something the operator never wants a lead about again. Keys are typed so
  # a builder can ask "is this term, page, rival section or domain muted?"
  # without knowing which lead kinds care.
  #
  #   term:<phrase>              any lead about this exact phrase
  #   phrase:<glob>              any lead about a phrase matching, e.g. "* in english"
  #   page:<path>                any lead about this page
  #   rival_path:<domain><path>  term gaps under this rival section, e.g. rival.com/vocabulary
  #   domain:<domain>            referrers and mentions from this domain
  class Mute < ApplicationRecord
    TYPES = %w[term phrase page rival_path domain].freeze

    belongs_to :site

    validates :key, presence: true, uniqueness: { scope: :site_id }, format: { with: /\A(#{TYPES.join('|')}):.+\z/ }

    scope :newest_first, -> { order(created_at: :desc) }

    def self.label_for(key)
      type, value = key.split(":", 2)
      case type
      when "term" then "Term “#{value}”"
      when "phrase" then "Phrases matching “#{value}”"
      when "page" then "Page #{value}"
      when "rival_path" then "Rival section #{value}"
      when "domain" then "Domain #{value}"
      else key
      end
    end

    def self.add!(site, key)
      site.mutes.find_or_create_by!(key: key) { |mute| mute.label = label_for(key) }
    end

    def self.matcher(site)
      Matcher.new(site.mutes.pluck(:key))
    end

    def type
      key.split(":", 2).first
    end

    # Answers mute questions for one builder run from a single query.
    class Matcher
      def initialize(keys)
        @keys = keys.to_set
        @patterns = keys.filter_map { |key| glob(key.delete_prefix("phrase:")) if key.start_with?("phrase:") }
        @paths = keys.filter_map { |key| key.delete_prefix("rival_path:") if key.start_with?("rival_path:") }
      end

      def empty?
        @keys.empty?
      end

      def muted?(*keys)
        keys.flatten.compact.any? { |key| @keys.include?(key) }
      end

      def phrase?(phrase)
        phrase = phrase.to_s
        muted?("term:#{phrase}") || @patterns.any? { |pattern| pattern.match?(phrase) }
      end

      def page?(path)
        muted?("page:#{path}")
      end

      def domain?(domain)
        muted?("domain:#{domain}")
      end

      def rival_path?(domain, url)
        return false if @paths.empty?

        target = "#{domain}#{Url.path(url) || '/'}"
        @paths.any? do |prefix|
          prefix = prefix.chomp("/")
          target == prefix || target.start_with?("#{prefix}/")
        end
      end

      private

      def glob(pattern)
        Regexp.new("\\A#{Regexp.escape(pattern).gsub('\*', '.*')}\\z", Regexp::IGNORECASE)
      end
    end
  end
end
