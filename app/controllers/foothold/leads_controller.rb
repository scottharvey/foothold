module Foothold
  class LeadsController < ApplicationController
    before_action :set_lead, except: %i[bulk_done bulk_dismiss]

    def show
    end

    def done
      @lead.resolve!("done")
      redirect_back_or_to root_path, notice: "Done."
    end

    def dismiss
      @lead.resolve!("dismissed")
      redirect_back_or_to root_path, notice: "Dismissed."
    end

    # For track_this leads: start tracking the term and close the lead.
    def track
      term = @lead.term
      if @lead.kind == "track_this" && term
        term.update!(tracked: true)
        @lead.resolve!("done")
        redirect_back_or_to root_path, notice: "Tracking “#{term.phrase}”."
      else
        redirect_back_or_to root_path, alert: "Nothing to track."
      end
    end

    def bulk_done
      bulk_resolve!("done")
    end

    def bulk_dismiss
      bulk_resolve!("dismissed")
    end

    # For alternative_gap leads: open a GitHub issue with the rival's real
    # ranking data so Claude's GitHub Action can draft the page, then close
    # the lead — GitHub owns tracking "is this drafted yet" from here.
    def approve
      return redirect_back_or_to(root_path, alert: "Nothing to approve.") unless @lead.kind == "alternative_gap"

      client = Foothold.configuration.github_client&.call
      return redirect_back_or_to(root_path, alert: "GitHub isn't configured.") unless client

      issue = client.open_issue(**issue_request(@lead))
      @lead.resolve!("done")
      redirect_back_or_to root_path, notice: "Opened #{issue.url}."
    end

    private

    def bulk_resolve!(state)
      ids = Array(params[:lead_ids]).reject(&:blank?)
      return redirect_back_or_to(root_path, alert: "Select at least one lead.") if ids.empty?

      count = Lead.resolve_many!(site: @site, ids: ids, state: state)
      redirect_back_or_to root_path, notice: "#{count} #{'lead'.pluralize(count)} #{state}."
    end

    # The production facts the drafting step can't get anywhere else — it has
    # the repo checked out already for the template and config/features.yml.
    def issue_request(lead)
      payload = lead.payload
      terms = Array(payload["terms"])
      lines = terms.map { |term| "- \"#{term['phrase']}\", position ##{term['position']}, volume #{term['volume'] || 'unknown'}" }
      style = Array(Foothold.configuration.page_style_guidance).map { |rule| "- #{rule}" }

      {
        title: "Draft alternatives page: #{payload['domain']}",
        labels: [ "foothold:draft" ],
        body: <<~MARKDOWN
          @claude Draft a new alternatives page for #{Foothold.configuration.site_name} vs. **#{payload['domain']}**.

          #{payload['domain']} ranks well for terms we don't cover:
          #{lines.join("\n")}

          Add `app/content/alternatives/#{payload['slug']}.md`, following the shape of the
          existing files in that directory (frontmatter: title, term, rival, description;
          markdown body). Pull real product copy from `config/features.yml`.

          This has to read as an actual comparison, not a #{Foothold.configuration.site_name}
          feature description with #{payload['domain']}'s name in the intro. Before writing,
          look up #{payload['domain']}'s real pricing, plans, and feature set from its own
          site. Then:

          - Include a markdown comparison table (features, pricing/plans, platforms,
            or whatever axes actually differ) near the top, right after the intro.
          - Where #{payload['domain']} has a feature we also have, say so ("yes, #{payload['domain']}
            has X too, but ...") instead of ignoring it. Pretending a shared feature
            doesn't exist is the fastest way to lose a reader's trust.
          - Don't declare an overall winner. Say plainly who #{payload['domain']} is
            still the better fit for, alongside who #{Foothold.configuration.site_name}
            fits better. Pages that recommend both products for different people convert
            better than pages that only attack the competitor.
          - If #{payload['domain']}'s users would need to bring existing data over
            (decks, notes, whatever the category's data unit is), and `config/features.yml`
            documents an import path for it, call that out specifically as the switching
            story. That's the single most useful thing to a reader who already uses
            #{payload['domain']} and is deciding whether leaving is worth the hassle.
          - Add a short FAQ section (3-4 Q&As) covering things a switcher would ask:
            pricing, migrating/importing existing data, free plan availability, etc.
          - Close with a one-line call to action linking to sign-up or the relevant
            product page.

          Only state #{payload['domain']}'s pricing or capabilities you actually verified
          on its site. If something isn't verifiable, leave it out rather than guess, and
          never adjust either product's real pricing to make the comparison look better.

          Where a screenshot would genuinely help (a side-by-side comparison, a
          specific screen the rival doesn't have), add it to frontmatter as
          `screenshots: [{basename: short-slug, alt: "what it shows"}]` — one to
          three is plenty. A placeholder box renders automatically until a real
          screenshot replaces it; don't invent image files or reference paths
          that don't exist.

          Style:
          #{style.join("\n")}

          Open a PR; don't merge it yourself.
        MARKDOWN
      }
    end

    def set_lead
      @lead = @site.leads.find(params[:id])
    end
  end
end
