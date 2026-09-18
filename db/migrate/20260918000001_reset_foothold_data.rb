# Wipes Foothold's sweep data so the install starts from scratch. Sites and
# Rivals are kept: the operator adds them by hand, and every other table is
# rebuilt by the sweeps. Rivals are marked unchecked so the next weekly sweep
# refreshes their terms.
class ResetFootholdData < ActiveRecord::Migration[8.0]
  TABLES = %w[
    foothold_findings foothold_page_days foothold_readings foothold_rival_terms foothold_leads foothold_mentions
    foothold_referrers foothold_digests foothold_sweep_runs foothold_pages foothold_terms
  ].freeze

  def up
    existing = TABLES.select { |table| table_exists?(table) }
    execute "TRUNCATE #{existing.join(', ')} RESTART IDENTITY CASCADE" if existing.any?
    execute "UPDATE foothold_rivals SET last_checked_at = NULL" if table_exists?(:foothold_rivals)
  end

  def down
  end
end
