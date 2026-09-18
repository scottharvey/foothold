module Foothold
  module Leads
    # A mention from the last 90 days that has not been dealt with. An event:
    # once resolved, it never reopens, even if it is polled again.
    class Mention < Base
      def candidates
        site.mentions.where(found_at: 90.days.ago..).recent_first.filter_map do |mention|
          domain = Url.domain(mention.url)
          next if domain && mutes.domain?(domain)

          verb = mention.linked? ? "Reply to" : "Reply to and ask for a link from"
          fresh = mention.found_at > 7.days.ago
          { identity: { url: mention.url }, summary: "#{verb} #{mention.title.presence || mention.url} (#{mention.source.humanize})",
            score: (mention.linked? ? 15 : 30) + (fresh ? 10 : 0),
            payload: { url: mention.url, domain: domain, source: mention.source, author: mention.author, linked: mention.linked?,
                       link_request: link_request(mention), evidence: mention.excerpt.to_s.truncate(140),
                       mute_keys: [ ("domain:#{domain}" if domain) ].compact } }
        end
      end

      private

      def link_request(mention)
        name = Foothold.configuration.site_name
        who = mention.author.present? ? "Hi #{mention.author}" : "Hi"
        "#{who}, thanks for mentioning #{name}. If it's useful to your readers, would you mind linking the name to https://#{site.domain}? " \
        "It helps people find it, and happy to answer any questions about it."
      end
    end
  end
end
