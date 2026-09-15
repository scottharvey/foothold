module Foothold
  module ApplicationHelper
    LEAD_VARIANTS = {
      "drop" => :error, "leaky_page" => :warning, "not_indexed" => :error, "term_gap" => :info, "page_two" => :success,
      "title_mismatch" => :warning, "track_this" => :neutral, "new_referrer" => :primary, "mention" => :primary, "audit" => :warning,
      "alternative_gap" => :info, "page_underperforming" => :warning
    }.freeze

    def lead_variant(lead)
      LEAD_VARIANTS.fetch(lead.kind, :neutral)
    end

    # Plain-language SEO background per lead kind, for an operator who isn't
    # an SEO. "what" explains the signal itself; "why" explains why it's
    # worth acting on; "tip" is a generic starting point (kept separate from
    # config.playbooks, which is host-specific how-to, not general theory).
    LEAD_EXPLANATIONS = {
      "drop" => {
        what: "One of your tracked search terms fell in Google's rankings this week compared to last week.",
        why: "A lower position usually means fewer people see the page for that search, which usually means fewer clicks. Search traffic is heavily front-loaded onto the first few results, so even a few places' drop can cost real visits.",
        tip: "Check whether the page still exists and loads correctly, whether its content is still accurate and up to date, and whether a competitor recently published something stronger for the same term. Rankings also dip on their own sometimes and recover — a single week's drop isn't always a fire."
      },
      "leaky_page" => {
        what: "A page is getting real search traffic but nobody who lands on it signs up.",
        why: "This is the frustrating kind of SEO problem: the ranking work paid off (people are finding the page), but the page itself isn't convincing them to do anything once they arrive. Traffic without conversion is a leak, not a win.",
        tip: "Read the page as if you were the searcher: does it answer what they were likely looking for, and is there an obvious, low-friction next step (a signup button, a clear call to action)? Mismatched intent or a buried/missing CTA are the usual culprits."
      },
      "not_indexed" => {
        what: "Google hasn't added this page to its index, even though it's been in your sitemap for a while.",
        why: "A page that isn't indexed cannot appear in search results at all, for any term — it's invisible to Google entirely, regardless of how good the content is.",
        tip: "Check Google Search Console for the specific reason (a noindex tag, a robots.txt block, being flagged as duplicate/thin content, or simply not yet crawled). Once the cause is fixed, you can request indexing directly from Search Console rather than waiting."
      },
      "term_gap" => {
        what: "A competitor ranks in the top 10 for a search term that you don't rank for at all (outside the top 30).",
        why: "This is one of the clearest signals in SEO: if a rival can rank for it, the term is provably winnable, and you're leaving that traffic on the table with no page competing for it.",
        tip: "Look at what the top-ranking page actually covers, then decide whether an existing page of yours could be expanded to target the term, or whether it deserves a new page of its own."
      },
      "page_two" => {
        what: "A term is averaging a position just outside page one (roughly 11th-20th) with enough search volume to matter.",
        why: "Click-through rate falls off sharply after the first page of results — being 11th gets a small fraction of the clicks that being in the top 3 does. Terms sitting just off page one are usually the cheapest wins available, since you're already close.",
        tip: "Small, targeted improvements often move the needle here: freshen the content, tighten it to better match what the query is actually asking for, or get a link or two pointing at the page."
      },
      "title_mismatch" => {
        what: "A page's HTML title tag doesn't contain the phrase the page is meant to target.",
        why: "The title tag does double duty: it's one of the strongest signals Google uses to understand what a page is about, and it's also the clickable blue headline shown in search results. Missing the target phrase can hurt both the ranking and the click-through rate.",
        tip: "Rewrite the title so it naturally reads well for a human AND includes the target phrase, ideally near the start."
      },
      "track_this" => {
        what: "Google is already showing your site for this search term often enough to notice, but Foothold isn't tracking it yet.",
        why: "Untracked terms are blind spots — the term might be trending up, might be worth a dedicated page, or might just be noise, but you won't know its trend until you start watching it.",
        tip: "Track it, watch its position over the next few weeks, and decide from there whether it deserves content of its own."
      },
      "new_referrer" => {
        what: "A website you don't control started sending you real visitors this week, other than a search engine.",
        why: "Someone linked to you or mentioned you somewhere. Beyond the direct traffic, a link from another site can also be a positive signal to Google about your site's credibility, depending on the source.",
        tip: "Look at where the traffic is coming from. If it's a person or a community, a reply or a thank-you can turn a one-off mention into an ongoing relationship."
      },
      "mention" => {
        what: "Your product's name showed up somewhere on the web — a forum post, a review, a social post — that Foothold is watching.",
        why: "Mentions are a reputation signal even when they aren't a link: they show up in searches for your product name, shape what people think before they visit your site, and an unlinked mention can often be turned into a linked one just by asking.",
        tip: "Reply where it makes sense to. If the mention doesn't already link to your site, a polite ask for a link is a normal, low-pressure request in most communities."
      },
      "audit" => {
        what: "The weekly technical audit found one or more open issues on this page (things like broken links, missing image text, or a title/description that's too short or too long).",
        why: "These are hygiene issues rather than content problems — they don't affect whether the page's writing is good, but they can quietly cap how well the page ranks or how accessible it is, even when the content itself is strong.",
        tip: "Open the page for the specific list of findings and work through them; most are quick, mechanical fixes rather than rewrites."
      },
      "alternative_gap" => {
        what: "A rival ranks in the top positions for several terms you track, and there's no page on your site positioning you as an alternative to them.",
        why: "People searching \"[rival] alternative\" or the rival's own ranking terms are already comparison-shopping — a page that meets them there is one of the highest-intent pages a product can have.",
        tip: "Approve to open a GitHub issue with the rival's real ranking data; a draft PR follows for you to review before anything goes live."
      },
      "page_underperforming" => {
        what: "A generated alternatives page has had its grace period and still has no real traffic, or has traffic but nobody who lands on it signs up.",
        why: "A generated page that isn't earning its keep is exactly what turns programmatic SEO into low-quality spam if left alone — better to revise or remove it than let it sit.",
        tip: "Check whether the page ever got indexed at all (a traffic problem) or reads poorly once someone's on it (a conversion problem), then revise the content or noindex it."
      }
    }.freeze

    def lead_explanation(lead)
      LEAD_EXPLANATIONS[lead.kind]
    end

    # Where a lead points: Foothold's own Page/Term screens, plus whatever
    # external URL its payload carries (a mention's actual post, a page-two
    # landing URL not yet in the page index, or a new referrer's own site).
    def lead_where_links(lead)
      payload = lead.payload
      links = []
      links << { label: "Foothold page: #{lead.page.url}", url: page_path(lead.page) } if lead.page
      links << { label: "Foothold term: #{lead.term.phrase}", url: term_path(lead.term) } if lead.term
      links << { label: payload["url"], url: payload["url"], external: true } if payload["url"].present?
      links << { label: payload["landing_url"], url: payload["landing_url"], external: true } if lead.page.blank? && payload["landing_url"].present?
      links << { label: "https://#{payload['domain']}", url: "https://#{payload['domain']}", external: true } if payload["domain"].present?
      links
    end

    # Payload fields not already surfaced elsewhere on the lead's detail page
    # (evidence, and whatever lead_where_links already turned into a link).
    def lead_detail_rows(lead)
      lead.payload.except("evidence", "url", "domain", "landing_url", "rivals", "phrase", "terms")
    end

    SWEEP_STATUS_VARIANTS = { "ok" => :success, "failed" => :error, "running" => :warning }.freeze

    def sweep_status_variant(run)
      SWEEP_STATUS_VARIANTS.fetch(run.status, :neutral)
    end

    # A short "key: value" line from a run's detail. An error, when present,
    # takes priority over whatever else the run noted before it failed.
    def sweep_detail(run)
      return run.detail["error"] if run.detail["error"].present?

      run.detail.map { |key, value| "#{key}: #{value}" }.join(", ").presence || "–"
    end

    # A source that was skipped (no credential configured) has nothing to
    # report; fade it so real activity stands out.
    def sweep_skipped?(run)
      run.detail["skipped"].present?
    end

    def sweep_episode_variant(episode)
      episode.any? { |run| run.status == "failed" } ? :error : :success
    end

    # Page links for a Pagy result, styled to match Foothold's own daisyUI
    # chrome. Foothold doesn't rely on the host defining its own `pagy_nav` —
    # this gem depends on pagy directly and renders its own.
    def foothold_pagy_nav(pagy)
      return "" if pagy.pages <= 1

      a = pagy.send(:a_lambda)
      html = +'<nav class="flex justify-center my-4" aria-label="Pages"><div class="join">'
      html << (pagy.previous ? a.(pagy.previous, "«", classes: "join-item btn btn-sm") : '<span class="join-item btn btn-sm btn-disabled">«</span>')
      pagy.send(:series).each do |item|
        html << case item
        when Integer then a.(item, classes: "join-item btn btn-sm")
        when String then %(<span class="join-item btn btn-sm btn-active" aria-current="page">#{item}</span>)
        when :gap then '<span class="join-item btn btn-sm btn-disabled">&hellip;</span>'
        end
      end
      html << (pagy.next ? a.(pagy.next, "»", classes: "join-item btn btn-sm") : '<span class="join-item btn btn-sm btn-disabled">»</span>')
      html << "</div></nav>"
      html.html_safe
    end

    def playbook_url(lead)
      builder = Foothold.configuration.playbook_url
      return nil if lead.playbook_slug.blank? || builder.nil?

      instance_exec(lead.playbook_slug, &builder)
    end

    # Keeps LastPass and 1Password from decorating fields that are not logins.
    def plain_field
      { "data-lpignore" => "true", "data-1p-ignore" => "", autocomplete: "off" }
    end

    # "3 days ago" with the exact time on hover.
    def foothold_ago(time)
      return "" if time.nil?

      tag.time("#{time_ago_in_words(time)} ago", datetime: time.iso8601, title: time.strftime("%-d %b %Y %H:%M"))
    end

    def position_text(position)
      return "–" if position.nil?

      position == position.floor ? position.to_i.to_s : format("%.1f", position)
    end

    # A signed change in position. Negative is better, so it is shown as an improvement.
    def delta_badge(delta)
      return "" if delta.nil? || delta.zero?

      improving = delta.negative?
      render Ui::BadgeComponent.new(variant: improving ? :success : :error, soft: true, size: :sm,
                                    text: "#{improving ? '▲' : '▼'} #{position_text(delta.abs)}")
    end

    # Inline SVG trend of positions, one point per day. Position 1 sits at the
    # top, so an upward line is an improvement. Gaps stay gaps.
    def sparkline(values, width: 120, height: 28, label: "Position trend")
      present = values.compact
      return tag.span("–", class: "opacity-40") if present.empty?

      pad = 3
      min, max = present.min, present.max
      span = (max - min).zero? ? 1.0 : (max - min).to_f
      step = values.size > 1 ? width.to_f / (values.size - 1) : 0.0
      points = values.each_with_index.map do |value, index|
        next nil if value.nil?

        [ (index * step).round(1), (pad + (value - min) / span * (height - pad * 2)).round(1) ]
      end
      segments = points.slice_when { |a, b| a.nil? || b.nil? }.reject { |segment| segment.first.nil? }
      last = points.compact.last

      description = "#{label}: #{position_text(present.first)} to #{position_text(present.last)} over #{values.size} days"
      tag.svg(viewBox: "0 0 #{width} #{height}", width: width, height: height, role: "img", "aria-label": description,
              class: "text-primary shrink-0", preserveAspectRatio: "none") do
        safe_join([
          tag.title(description),
          *segments.map do |segment|
            if segment.size == 1
              tag.circle(cx: segment[0][0], cy: segment[0][1], r: 1.5, fill: "currentColor")
            else
              tag.polyline(points: segment.map { |x, y| "#{x},#{y}" }.join(" "), fill: "none", stroke: "currentColor", "stroke-width": 1.5, "stroke-linejoin": "round", "stroke-linecap": "round")
            end
          end,
          tag.circle(cx: last[0], cy: last[1], r: 2, fill: "currentColor")
        ])
      end
    end
  end
end
