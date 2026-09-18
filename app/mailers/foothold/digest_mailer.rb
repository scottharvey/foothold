module Foothold
  class DigestMailer < Foothold.configuration.parent_mailer.to_s.presence&.safe_constantize.then { |klass| klass || ActionMailer::Base }
    helper Foothold::ApplicationHelper

    def weekly(digest)
      @digest = digest
      counts = digest.counts
      subject = "[Foothold] Week of #{digest.week_starting.strftime('%-d %b')}: " \
                "#{counts.fetch('open_leads', 0)} #{'lead'.pluralize(counts.fetch('open_leads', 0))}, " \
                "#{digest.movers_up.size} up, #{digest.movers_down.size} down"
      mail(to: digest.recipient, subject: subject)
    end
  end
end
