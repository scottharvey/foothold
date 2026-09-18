module Foothold
  module Leads
    # Carries out one verb on one lead. Issue verbs open a GitHub issue for
    # the Claude Code Action and record its URL on the lead; post verbs are
    # done here. Link and copy verbs never reach this class.
    class Act
      Result = Data.define(:ok, :message) do
        def ok? = ok
      end

      TRACK_NOTE = "Tracking %s".freeze

      def initialize(lead:, verb:, params: {})
        @lead = lead
        @verb = verb.to_s.to_sym
        @params = params.to_h.symbolize_keys
      end

      def call
        action = Actions.find(@lead, @verb)
        return failure("That can't be done from here.") unless action && (action.issue? || action.post?)
        return failure("This lead is already #{@lead.state}.") unless @lead.open?

        action.issue? ? open_issue : send(@verb)
      end

      private

      attr_reader :lead, :params

      def open_issue
        client = Foothold.configuration.github_client&.call
        return failure("GitHub isn't configured.") unless client

        request = Requests.build(lead, @verb, params)
        issue = client.open_issue(**request)
        lead.act!(@verb, url: issue.url, note: request[:title])
        success("Opened #{issue.url}.")
      end

      def track
        phrases = case lead.kind
        when "term_gap"
          Array(lead.payload["terms"]).sort_by { |term| -term["volume"].to_i }
                                     .first(Foothold.threshold(:term_gap_track_limit)).map { |term| term["phrase"] }
        else
          [ lead.term&.phrase ].compact
        end
        return failure("Nothing to track.") if phrases.empty?

        phrases.each do |phrase|
          term = Term.locate(lead.site, phrase, source: lead.kind == "term_gap" ? "rival" : "search_console",
                                                 discovered_on: Date.current, tracked: true)
          term.update!(tracked: true) unless term.tracked?
        end
        note = phrases.size == 1 ? "“#{phrases.first}”" : "#{phrases.size} terms"
        lead.act!(:track, note: format(TRACK_NOTE, note))
        success("Tracking #{note}.")
      end

      def ignore
        phrase = lead.phrase
        return failure("Nothing to ignore.") if phrase.blank?

        Mute.add!(lead.site, "term:#{phrase}")
        lead.act!(:ignore, note: "Muted “#{phrase}”", state: "dismissed")
        success("Ignoring “#{phrase}”.")
      end

      def success(message)
        Result.new(ok: true, message: message)
      end

      def failure(message)
        Result.new(ok: false, message: message)
      end
    end
  end
end
