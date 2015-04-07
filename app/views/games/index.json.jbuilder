json.array!(@games) do |game|
  json.extract! game, :id, :game_id, :home_team, :visiting_team, :game_date
  json.url game_url(game, format: :json)
end
