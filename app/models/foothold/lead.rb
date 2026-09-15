module Foothold
  # A suggested action. Derived by the builders after every Sweep and keyed by
  # kind plus an identity, so the same suggestion is never raised twice.
  class Lead < ApplicationRecord
    # Priority order for the queue.
    KINDS = %w[drop leaky_page not_indexed term_gap page_two title_mismatch track_this new_referrer mention audit alternative_gap page_underperforming].freeze
    # Kinds that describe a condition: the sweep closes them when it clears and
    # reopens them if it is still there a month after the operator resolved them.
    STATE_KINDS = %w[term_gap page_two leaky_page title_mismatch track_this audit not_indexed alternative_gap page_underperforming].freeze
    EVENT_KINDS = (KINDS - STATE_KINDS).freeze
    STATES = %w[open done dismissed].freeze

    belongs_to :site

    validates :kind, inclusion: { in: KINDS }
    validates :state, inclusion: { in: STATES }
    validates :identity, :summary, :opened_at, presence: true

    scope :open, -> { where(state: "open") }
    scope :of_kind, ->(kind) { kind.present? ? where(kind: kind) : all }
    scope :by_priority, -> { order(Arel.sql(priority_sql), opened_at: :desc) }

    def self.priority_sql
      list = KINDS.map { |kind| connection.quote(kind) }.join(", ")
      "array_position(ARRAY[#{list}]::text[], #{table_name}.kind)"
    end

    def self.identity_digest(kind, identity)
      ::Digest::SHA256.hexdigest("#{kind}:#{identity.to_h.transform_keys(&:to_s).sort.to_h.to_json}")
    end

    # The one way a builder raises a lead. New: opened. Open: evidence refreshed.
    # Resolved: reopened only for state kinds after `lead_reopen_days`.
    def self.suggest!(site:, kind:, identity:, summary:, payload: {}, term: nil, page: nil)
      kind = kind.to_s
      lead = find_or_initialize_by(site: site, kind: kind, identity: identity_digest(kind, identity))
      attrs = { summary: summary.to_s.truncate(255), payload: payload, playbook_slug: playbook_for(kind), term_id: term&.id, page_id: page&.id }

      if lead.new_record?
        lead.update!(attrs.merge(state: "open", opened_at: Time.current))
      elsif lead.open?
        lead.update!(attrs)
      elsif lead.reopenable?
        lead.update!(attrs.merge(state: "open", opened_at: Time.current, resolved_at: nil, resolved_by: nil))
      end
      lead
    end

    # Open leads of a state kind that a builder no longer reports are done.
    def self.close_missing!(site:, kind:, keep:)
      site.leads.open.where(kind: kind).where.not(id: keep)
          .update_all(state: "done", resolved_at: Time.current, resolved_by: "sweep", updated_at: Time.current)
    end

    def self.playbook_for(kind)
      Foothold.configuration.playbooks.to_h.find { |key, _| key.to_s == kind }&.last.presence
    end

    def open?
      state == "open"
    end

    def state_based?
      STATE_KINDS.include?(kind)
    end

    def reopenable?
      state_based? && resolved_at.present? && resolved_at < Foothold.threshold(:lead_reopen_days).days.ago
    end

    def resolve!(state, by: "operator")
      update!(state: state, resolved_at: Time.current, resolved_by: by)
    end

    # Bulk equivalent of #resolve!, for the Queue's multi-select actions.
    # Returns the number of leads resolved.
    def self.resolve_many!(site:, ids:, state:, by: "operator")
      site.leads.open.where(id: ids).update_all(state: state, resolved_at: Time.current, resolved_by: by, updated_at: Time.current)
    end

    def term
      Term.find_by(id: term_id) if term_id
    end

    def page
      Page.find_by(id: page_id) if page_id
    end

    def evidence
      payload["evidence"]
    end
  end
end
