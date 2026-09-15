module Foothold
  # What the term list shows for one Term over the last 28 days. Positions come
  # from Search Console when it has seen the Term, otherwise from SERP checks.
  TermSummary = Data.define(:term, :position, :delta, :series, :impressions, :clicks, :signups, :serp_position) do
    # A block passed to Data.define is lexically scoped to Foothold, not to
    # this class, so a plain `DAYS = 28` here would actually define
    # Foothold::DAYS — const_set attaches it to TermSummary itself, where
    # `TermSummary::DAYS` (used outside this block) expects to find it.
    const_set(:DAYS, 28)

    def self.for(terms, today: Date.current)
      terms = terms.to_a
      from = today - (TermSummary::DAYS - 1)
      readings = Reading.where(term_id: terms.map(&:id), date: from..today).chronological.group_by(&:term_id)

      terms.map do |term|
        rows = readings.fetch(term.id, [])
        console = rows.select { |reading| reading.source == "search_console" }
        serp = rows.select { |reading| reading.source == "serp" }
        source = console.any? ? console : serp
        by_date = source.index_by(&:date)
        latest = source.last
        week_ago = source.reverse.find { |reading| reading.date <= today - 7 }

        new(
          term: term,
          position: latest&.position&.to_f,
          delta: (latest && week_ago) ? (latest.position - week_ago.position).to_f.round(1) : nil,
          series: (from..today).map { |date| by_date[date]&.position&.to_f },
          impressions: console.sum(&:impressions),
          clicks: source.sum(&:clicks),
          signups: source.sum(&:signups),
          serp_position: serp.last&.position&.to_f
        )
      end
    end

    # Tracked first, then the busiest, then alphabetical.
    def self.ordered(summaries)
      summaries.sort_by { |summary| [ summary.term.tracked ? 0 : 1, -summary.impressions, summary.term.phrase ] }
    end

    def improving?
      delta && delta < 0
    end
  end
end
