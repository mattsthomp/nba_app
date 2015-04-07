class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :game_id
      t.string :home_team
      t.string :visiting_team
      t.date :game_date

      t.timestamps null: false
    end
  end
end
