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
