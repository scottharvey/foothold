class CreateFootholdRivalsAndLeads < ActiveRecord::Migration[8.0]
  def change
    create_table :foothold_rivals do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.string :domain, null: false
      t.string :name
      t.datetime :last_checked_at
      t.timestamps
    end
    add_index :foothold_rivals, [ :site_id, :domain ], unique: true

    create_table :foothold_rival_terms do |t|
      t.references :rival, null: false, foreign_key: { to_table: :foothold_rivals }
      t.references :term, null: false, foreign_key: { to_table: :foothold_terms }
      t.integer :position
      t.string :landing_url
      t.integer :volume
      t.datetime :checked_at
      t.timestamps
    end
    add_index :foothold_rival_terms, [ :rival_id, :term_id ], unique: true

    create_table :foothold_leads do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.string :kind, null: false
      t.string :identity, null: false
      t.string :summary, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :playbook_slug
      t.string :state, null: false, default: "open"
      t.bigint :term_id
      t.bigint :page_id
      t.datetime :opened_at, null: false
      t.datetime :resolved_at
      t.string :resolved_by
      t.timestamps
    end
    add_index :foothold_leads, [ :site_id, :kind, :identity ], unique: true
    add_index :foothold_leads, [ :site_id, :state, :opened_at ]
  end
end
