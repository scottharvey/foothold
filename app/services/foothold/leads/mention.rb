module Foothold
  module Leads
    # A mention from the last 90 days that has not been dealt with. An event:
    # once resolved, it never reopens, even if it is polled again.
    class Mention < Base
      def candidates
        site.mentions.where(found_at: 90.days.ago..).recent_first.filter_map do |mention|
          verb = mention.linked? ? "Reply to" : "Reply to and ask for a link from"
          { identity: { url: mention.url }, summary: "#{verb} #{mention.title.presence || mention.url} (#{mention.source.humanize})",
            payload: { url: mention.url, source: mention.source, author: mention.author, linked: mention.linked?,
                      evidence: mention.excerpt.to_s.truncate(140) } }
        end
      end
    end
  end
end
