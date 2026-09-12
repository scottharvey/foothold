class CreateFootholdFindings < ActiveRecord::Migration[8.0]
  def change
    create_table :foothold_findings do |t|
      t.references :page, null: false, foreign_key: { to_table: :foothold_pages }
      t.string :check, null: false
      t.string :identity, null: false
      t.text :detail
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :foothold_findings, [ :page_id, :check, :identity ], unique: true, name: "index_foothold_findings_on_page_check_identity"
    add_index :foothold_findings, [ :page_id, :resolved_at ]
  end
end
