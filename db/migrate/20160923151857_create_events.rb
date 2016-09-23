class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :name
      t.datetime :starts_at
      t.string :state, default: "active", null: false
      t.timestamps
    end
  end
end
