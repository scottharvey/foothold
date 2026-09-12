module Foothold
  module ApplicationHelper
    LEAD_VARIANTS = {
      "drop" => :error, "leaky_page" => :warning, "not_indexed" => :error, "term_gap" => :info, "page_two" => :success,
      "title_mismatch" => :warning, "track_this" => :neutral, "new_referrer" => :primary, "mention" => :primary, "audit" => :warning
    }.freeze

    def lead_variant(lead)
      LEAD_VARIANTS.fetch(lead.kind, :neutral)
    end

    # The host's how-to for this lead, resolved in the view so main_app routes work.
    def page_url_for(lead)
      page = lead.page
      page && page_path(page)
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
