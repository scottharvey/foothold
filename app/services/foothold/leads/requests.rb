module Foothold
  module Leads
    # Builds the GitHub issue for an issue verb: the production facts the
    # drafting Action can't get anywhere else, plus house style. The repo is
    # checked out on the Action's side, so paths are hints, not commands.
    module Requests
      module_function

      def build(lead, verb, params = {})
        klass = const_get(verb.to_s.camelize)
        klass.new(lead, params).to_h
      end

      class Base
        attr_reader :lead, :params, :payload

        def initialize(lead, params = {})
          @lead = lead
          @params = params
          @payload = lead.payload
        end

        def to_h
          { title: title, labels: [ "foothold:draft" ], body: body.strip.gsub(/\n{3,}/, "\n\n") + "\n" }
        end

        private

        def config
          Foothold.configuration
        end

        def site_name
          config.site_name
        end

        def style
          rules = Array(config.page_style_guidance).map { |rule| "- #{rule}" }
          rules.empty? ? "" : "Style:\n#{rules.join("\n")}"
        end

        def page_hint(url)
          "The page is served at `#{url}` on #{site_name}. Find its source in the repo (a content file or a view) before changing anything."
        end

        def closing
          "Open a PR; don't merge it yourself."
        end

        def bullet(rows)
          rows.map { |row| "- #{row}" }.join("\n")
        end

        def phrase
          payload["phrase"]
        end
      end

      # term_gap: a cluster of phrases a rival wins under one section.
      class Propose < Base
        def title
          "Propose page: #{payload['domain']}#{payload['path']} covers #{payload['count']} terms we don't"
        end

        def body
          terms = Array(payload["terms"]).first(40)
          urls = Array(payload["urls"]).first(5)
          <<~MARKDOWN
            @claude #{payload['domain']} ranks in Google's top 10 for #{payload['count']} search terms under
            `#{payload['path']}` that #{site_name} does not rank for at all. Combined monthly volume: #{payload['volume_total']}.

            The terms, best first:
            #{bullet(terms.map { |t| "\"#{t['phrase']}\" · #{payload['domain']} ##{t['position']} · volume #{t['volume'] || 'unknown'}" })}
            #{"- and #{payload['count'] - terms.size} more" if payload['count'].to_i > terms.size}

            The rival pages that win them:
            #{bullet(urls.map { |u| "#{u['url']} (#{u['count']} #{'term'.pluralize(u['count'])})" })}

            Decide what #{site_name} should publish to compete, then draft it:

            - If one page can honestly serve most of these queries, draft that page.
            - If the rival wins with a template (one page per word, per topic, per
              comparison), propose the template: a short design note in the PR
              description, the template itself, and two or three real example pages
              drafted from it. Say what data source would drive the rest.
            - Look at two or three of the rival's winning pages first and say in the PR
              what they do well and what they leave out. Match the searcher's intent,
              don't copy the rival.
            - If you conclude these queries aren't ones #{site_name}'s users would type,
              say so in the PR description and stop. That's a valid outcome.

            #{page_hint(payload['path'])}

            #{style}

            #{closing}
          MARKDOWN
        end
      end

      # drop and page_two: a page that should rank better for a phrase.
      class Refresh < Base
        def title
          "Refresh page for \"#{phrase}\": #{payload['landing_url'] || 'no landing page yet'}"
        end

        def body
          position = payload["after"] || payload["average_position"]
          rivals = Array(payload["rivals_above"].presence || payload["top_results"]).first(5)
          reason = if lead.kind == "drop"
            "It fell from #{payload['before']} to #{payload['after']} this week."
          else
            "It averages position #{payload['average_position']} with #{payload['impressions']} impressions in 7 days: one push from page one."
          end
          <<~MARKDOWN
            @claude #{site_name} ranks at position #{position} for "#{phrase}". #{reason}
            #{"Search volume: #{payload['volume']} a month." if payload['volume']}

            #{payload['landing_url'] ? page_hint(payload['landing_url']) : "No page of ours is a clear landing page for this term yet; pick the best existing one or say a new one is needed."}
            #{"The page returned HTTP #{payload['http_status']} on the last audit; fix that first if it isn't 200." if payload['http_status'] && payload['http_status'] != 200}

            #{rivals.any? ? "Pages ranking above us right now:\n#{bullet(rivals.map { |r| "##{r['position']} #{r['url']}#{" · #{r['title']}" if r['title'].present?}" })}" : "Foothold has no SERP snapshot for this term yet."}

            Read the ranking pages, then revise ours so it answers the query better
            than they do: tighten the title and opening to the query, fill the gaps
            they cover and we don't, cut what the searcher didn't ask for, and add
            internal links from related pages. Keep everything factual; don't invent
            features or numbers.

            #{style}

            #{closing}
          MARKDOWN
        end
      end

      # leaky_page and page_underperforming: traffic that doesn't convert.
      class Revise < Base
        def title
          "Revise page: #{payload['url']} gets visits but no signups"
        end

        def body
          queries = Array(payload["queries"]).first(10)
          <<~MARKDOWN
            @claude `#{payload['url']}` on #{site_name} had #{payload['search_visits'] || payload['visits']} search visits and
            #{payload['signups'].to_i} signups in the last #{payload['days'] || 28} days.

            #{queries.any? ? "What people searched to land there:\n#{bullet(queries.map { |q| "\"#{q['phrase']}\" · position #{q['position']} · #{q['impressions']} impressions · #{q['clicks']} clicks" })}" : "Foothold has no query breakdown for this page."}

            #{page_hint(payload['url'])}

            Read the page as one of those searchers would. Then revise it so it
            answers what they were actually looking for and gives them an obvious,
            low-friction next step: a clear call to action that fits the intent,
            near the top and again at the end. If the queries show the page is
            attracting people the product isn't for, say so in the PR and suggest
            what the page should target instead.

            #{style}

            #{closing}
          MARKDOWN
        end
      end

      # not_indexed and audit: mechanical problems with a page.
      class Fix < Base
        def title
          "Fix: #{payload['url']} #{lead.kind == 'not_indexed' ? 'is not indexed' : "has #{payload['count']} audit #{'finding'.pluralize(payload['count'].to_i)}"}"
        end

        def body
          problems = if lead.kind == "not_indexed"
            detail = payload["detail"].to_h
            [ (payload["reason"] unless detail["coverage_state"]) ] + detail.map { |key, value| "#{key.humanize}: #{value}" }
          else
            Array(payload["findings"]).map { |f| "#{f['check'].to_s.humanize}#{": #{f['detail']}" if f['detail'].present?}" }
          end
          <<~MARKDOWN
            @claude Foothold found these problems with `#{payload['url']}` on #{site_name}:
            #{bullet(problems.compact)}

            #{page_hint(payload['url'])}

            Fix each one at its source: the layout, the content file, robots rules,
            the sitemap, or wherever the cause actually is. Don't paper over it in the
            page alone if the same problem would recur elsewhere. For anything you
            can't fix from the repo, say what needs doing in the PR description.

            #{style}

            #{closing}
          MARKDOWN
        end
      end

      # title_mismatch: one line.
      class Retitle < Base
        def proposed
          params[:title].presence || payload["proposed_title"]
        end

        def title
          "Retitle #{payload['url']}: \"#{proposed}\""
        end

        def body
          <<~MARKDOWN
            @claude `#{payload['url']}` on #{site_name} targets the search term "#{phrase}" but its title
            doesn't contain it. Current title: "#{payload['title']}".

            Change the title to: "#{proposed}"

            #{page_hint(payload['url'])}

            Keep the heading and description consistent with the new title if they
            repeat it. If you can word it better, you may, as long as it still reads
            naturally, contains "#{phrase}" near the start and stays under 60 characters.

            #{closing}
          MARKDOWN
        end
      end

      # page_underperforming: a generated page that never earned its keep.
      class Retire < Base
        def title
          "Retire page: #{payload['url']}"
        end

        def body
          <<~MARKDOWN
            @claude `#{payload['url']}` on #{site_name} was generated on #{payload['first_seen_on']} and has had
            #{payload['visits'].to_i} visits and #{payload['signups'].to_i} signups since.
            #{payload['indexed'] ? "Google has it indexed, so it isn't a crawl problem." : "Google never indexed it."}

            #{page_hint(payload['url'])}

            Retire it: remove the content file (or mark it noindex and drop it from
            the sitemap if the site keeps a record of retired pages), and remove any
            internal links pointing at it. Thin pages nobody wants are what turn
            programmatic SEO into spam.

            #{closing}
          MARKDOWN
        end
      end

      # alternative_gap: the original programmatic template.
      class Approve < Base
        def title
          "Draft alternatives page: #{payload['domain']}"
        end

        def body
          terms = Array(payload["terms"])
          lines = terms.first(40).map { |term| "- \"#{term['phrase']}\", position ##{term['position']}, volume #{term['volume'] || 'unknown'}" }
          lines << "- and #{terms.size - 40} more" if terms.size > 40
          <<~MARKDOWN
            @claude Draft a new alternatives page for #{site_name} vs. **#{payload['domain']}**.

            #{payload['domain']} ranks well for terms we don't cover:
            #{lines.join("\n")}

            Add `app/content/alternatives/#{payload['slug']}.md`, following the shape of the
            existing files in that directory (frontmatter: title, term, rival, description;
            markdown body). Pull real product copy from `config/features.yml`.

            This has to read as an actual comparison, not a #{site_name}
            feature description with #{payload['domain']}'s name in the intro. Before writing,
            look up #{payload['domain']}'s real pricing, plans, and feature set from its own
            site. Then:

            - Include a markdown comparison table (features, pricing/plans, platforms,
              or whatever axes actually differ) near the top, right after the intro.
            - Where #{payload['domain']} has a feature we also have, say so ("yes, #{payload['domain']}
              has X too, but ...") instead of ignoring it. Pretending a shared feature
              doesn't exist is the fastest way to lose a reader's trust.
            - Don't declare an overall winner. Say plainly who #{payload['domain']} is
              still the better fit for, alongside who #{site_name}
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

            #{style}

            #{closing}
          MARKDOWN
        end
      end
    end
  end
end
