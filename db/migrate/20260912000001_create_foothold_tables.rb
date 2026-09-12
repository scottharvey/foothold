class CreateFootholdTables < ActiveRecord::Migration[8.0]
  def change
    create_table :foothold_sites do |t|
      t.string :domain, null: false
      t.string :name
      t.string :search_console_property
      t.timestamps
    end
    add_index :foothold_sites, :domain, unique: true

    create_table :foothold_terms do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.string :phrase, null: false
      t.string :source, null: false, default: "manual"
      t.boolean :tracked, null: false, default: false
      t.integer :volume
      t.integer :difficulty
      t.datetime :volume_checked_at
      t.date :discovered_on
      t.timestamps
    end
    add_index :foothold_terms, [ :site_id, :phrase ], unique: true
    add_index :foothold_terms, [ :site_id, :tracked ]

    create_table :foothold_pages do |t|
      t.references :site, null: false, foreign_key: { to_table: :foothold_sites }
      t.string :url, null: false
      t.string :kind, null: false, default: "static"
      t.string :title
      t.text :description
      t.bigint :term_id
      t.date :published_on
      t.boolean :in_sitemap, null: false, default: true
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false
      t.integer :http_status
      t.datetime :crawled_at
      t.string :index_status
      t.datetime :index_checked_at
      t.integer :word_count
      t.integer :inbound_links
      t.timestamps
    end
    add_index :foothold_pages, [ :site_id, :url ], unique: true
    add_index :foothold_pages, [ :site_id, :in_sitemap ]

    create_table :foothold_readings do |t|
      t.references :term, null: false, foreign_key: { to_table: :foothold_terms }
      t.date :date, null: false
      t.string :source, null: false
      t.decimal :position, precision: 6, scale: 1
      t.string :landing_url
      t.integer :impressions, null: false, default: 0
      t.integer :search_clicks, null: false, default: 0
      t.integer :clicks, null: false, default: 0
      t.integer :signups, null: false, default: 0
      t.timestamps
    end
    add_index :foothold_readings, [ :term_id, :date, :source ], unique: true
    add_index :foothold_readings, [ :date, :landing_url ]

    create_table :foothold_page_days do |t|
      t.references :page, null: false, foreign_key: { to_table: :foothold_pages }
      t.date :date, null: false
      t.integer :visits, null: false, default: 0
      t.integer :search_visits, null: false, default: 0
      t.integer :signups, null: false, default: 0
      t.integer :search_signups, null: false, default: 0
      t.timestamps
    end
    add_index :foothold_page_days, [ :page_id, :date ], unique: true

    create_table :foothold_sweep_runs do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.string :status, null: false, default: "running"
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.date :watermark
      t.jsonb :detail, null: false, default: {}
      t.timestamps
    end
    add_index :foothold_sweep_runs, [ :name, :started_at ]
  end
end
