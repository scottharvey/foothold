module Foothold
  # A problem the weekly audit observed on a Page. Kept between runs so a
  # finding is raised once and resolved once it stops appearing.
  class Finding < ApplicationRecord
    CHECKS = %w[status title_length description_length h1_count canonical img_alt broken_link redirected_link thin orphan].freeze

    belongs_to :page

    validates :check, inclusion: { in: CHECKS }
    validates :identity, :first_seen_at, :last_seen_at, presence: true

    scope :open, -> { where(resolved_at: nil) }

    def self.observe!(page:, check:, identity:, detail: nil)
      now = Time.current
      finding = find_or_initialize_by(page: page, check: check, identity: identity)
      finding.first_seen_at ||= now
      finding.last_seen_at = now
      finding.detail = detail
      finding.resolved_at = nil
      finding.save! if finding.new_record? || finding.changed?
      finding
    end

    # Marks every open finding for this Page and check not in `keep` resolved.
    def self.resolve_missing!(page:, check:, keep:)
      open.where(page: page, check: check).where.not(id: keep).update_all(resolved_at: Time.current, updated_at: Time.current)
    end

    def description
      "#{check.humanize}#{": #{detail}" if detail.present?}"
    end
  end
end
