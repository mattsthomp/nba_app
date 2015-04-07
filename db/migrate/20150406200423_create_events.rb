class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :event_num
      t.string :player_code
      t.string :team
      t.string :game_id
      t.integer :event_type
      t.integer :time_elapsed
      t.integer :home_score
      t.integer :visitor_score

      t.timestamps null: false
    end
  end
end
