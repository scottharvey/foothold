class AddLeadActionsMutesAndEvidence < ActiveRecord::Migration[8.0]
  def change
    # Leads carry a value score, can be snoozed, and remember what was done
    # about them and what happened afterwards.
    change_table :foothold_leads do |t|
      t.float :score, null: false, default: 0
      t.datetime :snoozed_until
      t.string :action
      t.string :action_url
      t.text :action_note
      t.datetime :acted_at
      t.jsonb :outcome, null: false, default: {}
    end
    add_index :foothold_leads, [ :site_id, :state, :score ]

    # Things the operator never wants to hear about again.
    create_table :foothold_mutes do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.string :key, null: false
      t.string :label
      t.timestamps
    end
    add_index :foothold_mutes, [ :site_id, :key ], unique: true

    # Rival keywords stay on the rival row instead of becoming Terms.
    remove_index :foothold_rival_terms, [ :rival_id, :term_id ]
    remove_reference :foothold_rival_terms, :term, foreign_key: { to_table: :foothold_terms }
    add_column :foothold_rival_terms, :phrase, :string, null: false
    add_column :foothold_rival_terms, :relevant, :boolean
    add_index :foothold_rival_terms, [ :rival_id, :phrase ], unique: true

    # Evidence the actions need: who else is on the SERP, and why a page
    # isn't indexed.
    add_column :foothold_readings, :serp_top, :jsonb, null: false, default: []
    add_column :foothold_pages, :index_detail, :jsonb, null: false, default: {}
  end
end
