# Wipes every Foothold table so the install starts from scratch. Sweeps
# rebuild everything except Rivals, which the operator adds back by hand.
class ResetFootholdData < ActiveRecord::Migration[8.0]
  TABLES = %w[
    foothold_findings foothold_page_days foothold_readings foothold_rival_terms foothold_leads foothold_mentions
    foothold_referrers foothold_digests foothold_sweep_runs foothold_pages foothold_terms foothold_rivals foothold_sites
  ].freeze

  def up
    existing = TABLES.select { |table| table_exists?(table) }
    execute "TRUNCATE #{existing.join(', ')} RESTART IDENTITY CASCADE" if existing.any?
  end

  def down
  end
end
