json.array!(@events) do |event|
  json.extract! event, :id, :event_num, :player_code, :team, :game_id, :event_type, :time_elapsed, :home_score, :visitor_score
  json.url event_url(event, format: :json)
end
