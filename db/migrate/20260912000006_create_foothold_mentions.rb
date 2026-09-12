class CreateFootholdMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :foothold_mentions do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.string :source, null: false
      t.string :url, null: false
      t.string :external_id
      t.string :title
      t.string :author
      t.text :excerpt
      t.datetime :found_at, null: false
      t.boolean :linked, null: false, default: false
      t.timestamps
    end
    add_index :foothold_mentions, [ :site_id, :source, :url ], unique: true, name: "index_foothold_mentions_on_site_source_url"
    add_index :foothold_mentions, [ :site_id, :found_at ]
  end
end
