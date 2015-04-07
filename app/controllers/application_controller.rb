class ApplicationController < ActionController::Base

def loadGame
  f1 = File.open("demo_pbp_1.xml")
  g1 = Nokogiri::XML(f1)
  f1.close
  game_string = g1.css("game").attr("gcd").to_s
  game_date = game_string[0..7].to_date
  game_home_team = game_string[-3..-1]
  game_visiting_team = game_string[9..11]
  if Game.find_by game_date:game_date, home_team:game_home_team
    render 'start_page/home'
  else
    f2 = File.open("demo_pbp_2.xml")
    g2 = Nokogiri::XML(f2)
    f2.close
    f3 = File.open("demo_pbp_3.xml")
    g3 = Nokogiri::XML(f3)
    f3.close
    f4 = File.open("demo_pbp_4.xml")
    g4 = Nokogiri::XML(f4)
    f4.close
    event_stack = g1.css("event") + g2.css("event") + g3.css("event") + g4.css("event")
    Game.create( home_team: game_home_team, visiting_team: game_visiting_team, game_date: game_date )
    event_stack.each do |e|
      d = e.children.to_s
      desc = d[10..-6]
      prd = e.attr("prd").to_i
      gclock = e.attr("game_clock").to_s
      if prd < 5 
        elapsed = (prd*720) - ((gclock[0..1].to_i)*60) - (gclock[3..4].to_i)
      else
        elapsed = 2880 + ((prd-4)*300) - ((gclock[0..1].to_i)*60) - (gclock[3..4].to_i)
      end
      Event.create( event_num: e.attr("eventid"), 
                    player_code: e.attr("player_code"), 
                    team: e.attr("tm"), 
                    home_score: e.attr("htms"), 
                    visitor_score: e.attr("vtms"), 
                    event_type: e.attr("msg_type"), 
                    description: desc,
                    game_id: "",
                    time_elapsed: elapsed,)
    end
    render 'game_page/game'
  end
end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
