module Foothold
  module Leads
    # A non-search domain that started sending real traffic this week. An
    # event: identity includes the domain only, so it never resurfaces once
    # resolved, even if the same domain sends more traffic later.
    class NewReferrer < Base
      MIN_VISITS = 2

      def candidates
        site.referrers.not_search_engines.where(first_seen_on: window(7)).where(visits: MIN_VISITS..).filter_map do |referrer|
          next if mutes.domain?(referrer.domain)

          { identity: { domain: referrer.domain }, summary: "New referrer: #{referrer.domain} sent #{referrer.visits} #{'visit'.pluralize(referrer.visits)}",
            score: referrer.visits * 5 + referrer.signups * 50,
            payload: { domain: referrer.domain, url: "https://#{referrer.domain}", visits: referrer.visits, signups: referrer.signups,
                       evidence: "#{referrer.visits} visits, #{referrer.signups} signups", mute_keys: [ "domain:#{referrer.domain}" ] } }
        end
      end
    end
  end
end
