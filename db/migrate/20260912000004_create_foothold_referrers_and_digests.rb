class CreateFootholdReferrersAndDigests < ActiveRecord::Migration[8.0]
  def change
    create_table :foothold_referrers do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.string :domain, null: false
      t.date :first_seen_on, null: false
      t.date :last_seen_on, null: false
      t.integer :visits, null: false, default: 0
      t.integer :signups, null: false, default: 0
      t.boolean :search_engine, null: false, default: false
      t.timestamps
    end
    add_index :foothold_referrers, [ :site_id, :domain ], unique: true

    create_table :foothold_digests do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.date :week_starting, null: false
      t.string :recipient
      t.datetime :sent_at
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
    add_index :foothold_digests, [ :site_id, :week_starting ], unique: true
  end
end
