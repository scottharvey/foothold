module Foothold
  # One run of one Sweep source. Carries the watermark (last date fully
  # collected) so the next run knows where to resume, and what the run cost.
  class SweepRun < ApplicationRecord
    STATUSES = %w[running ok failed].freeze

    validates :name, :kind, :started_at, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :ok, -> { where(status: "ok") }
    scope :latest_first, -> { order(started_at: :desc) }

    def self.watermark(name)
      ok.where(name: name).latest_first.pick(:watermark)
    end

    def self.latest(kind)
      where(kind: kind).latest_first.first
    end

    # Wraps one source. The block sets `run.watermark` and adds to `run.detail`;
    # a raise marks the run failed and propagates so the Sweep can log it.
    def self.track(name, kind:)
      run = create!(name: name, kind: kind, started_at: Time.current, watermark: watermark(name))
      yield(run)
      run.update!(status: "ok", finished_at: Time.current)
      run
    rescue StandardError => e
      run&.update!(status: "failed", finished_at: Time.current, detail: run.detail.merge("error" => "#{e.class}: #{e.message}"))
      raise
    end

    def note(**counts)
      counts.each { |key, value| detail[key.to_s] = value }
    end

    def elapsed
      return nil unless finished_at

      finished_at - started_at
    end
  end
end
