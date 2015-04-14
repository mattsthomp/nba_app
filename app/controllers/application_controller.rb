class ApplicationController < ActionController::Base

def loadGameForDemo
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
    Game.create( game_id: game_string, home_team: game_home_team, visiting_team: game_visiting_team, game_date: game_date )
    event_stack.each do |e|
      d = e.children.to_s
      desc = d[11..-6]
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
                    game_id: game_string,
                    time_elapsed: elapsed )
    end
    render 'game_page/game'
  end
end

def runDemo
  play_count = (params[:status].to_i) + 10
  
  player_array = [:nicolas_batum, :lamarcus_aldridge, :wesley_matthews, :robin_lopez, :damian_lillard, :arron_afflalo,
                  :steve_blake, :chris_kaman, :meyers_leonard, :dorell_wright, :alonzo_gee, :allen_crabbe, :cj_mccollum, 
                  :russell_westbrook, :serge_ibaka, :kyle_singler, :nick_collison, :andre_roberson, :dion_waiters, 
                  :mitch_mcgary, :anthony_morrow, :dj_augustin, :perry_jones, :enes_kanter, :jeremy_lamb ] 
  @players = {}
  
  player_array.each do |p|
    @players[p] = { :minutes => 0, :oboards => 0, :dboards => 0, :assists => 0, :steals => 0, :blocks => 0, :turnovers => 0,
                      :fouls => 0, :made2pt => 0, :missed2pt => 0, :made3pt => 0, :missed3pt => 0, :madeft => 0, :missedft => 0, :ingame => "out", :plays => [] }
  end
  
  @players[:nicolas_batum][:ingame] = "in"
  @players[:lamarcus_aldridge][:ingame] = "in"
  @players[:wesley_matthews][:ingame] = "in"
  @players[:robin_lopez][:ingame] = "in"
  @players[:damian_lillard][:ingame] = "in"
  @players[:russell_westbrook][:ingame] = "in"
  @players[:serge_ibaka][:ingame] = "in"
  @players[:kyle_singler][:ingame] = "in"
  @players[:nick_collison][:ingame] = "in"
  @players[:andre_roberson][:ingame] = "in"
  
  event_array = Event.where(game_id: '20150227/OKCPOR').first(play_count)
  @marker = event_array.last
  event_array.each do |e|   
    first_player = e[:player_code].to_sym
    if e[:event_type] == 2   # ----------------------------------------------------------------------------------missed shots and blocks
      if e[:description].include?("Block:")
        x = e[:description].split("Block:")
        y = x[1].split("(")
        z = y[0].strip.downcase
        player_array.each do |h|
          if z == h.to_s.split("_")[1] 
            @players[h][:blocks] += 1
            @players[h][:plays] << [e[:time_elapsed], 21, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
          end
        end
      end
      if e[:description].include?("3pt")
        @players[first_player][:missed3pt] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 16, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      else
        @players[first_player][:missed2pt] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 2, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      end
    elsif e[:event_type] == 4   # ----------------------------------------------------------------------------------------------rebounds
      if first_player == :""
        # count team rebounds?
      else
        @players[first_player][:dboards] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 4, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      end
    elsif e[:event_type] == 1  # --------------------------------------------------------------------------------made shots and assists
      if e[:description].include?("Assist:")
        x = e[:description].split("Assist:")
        y = x[1].split("(")
        z = y[0].strip.downcase
        player_array.each do |h|
          if z == h.to_s.split("_")[1]
            @players[h][:assists] += 1
            @players[h][:plays] << [e[:time_elapsed], 22, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
          end
        end
      end
      if e[:description].include?("3pt")
        @players[first_player][:made3pt] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 15, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      else
        @players[first_player][:made2pt] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 1, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      end
    elsif e[:event_type] == 3  # -----------------------------------------------------------------------------------------free throws
      if e[:description].include?("Missed")
        @players[first_player][:missedft] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 17, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      else
        @players[first_player][:madeft] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 3, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      end
    elsif e[:event_type] == 6  # -------------------------------------------------------------------------------------------fouls
      if e[:description].include?("Technical")
      else
        @players[first_player][:fouls] += 1
        @players[first_player][:plays] << [e[:time_elapsed], 19, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      end
    elsif e[:event_type] == 5  # --------------------------------------------------------------------------------turnovers and steals
       if e[:description].include?("Steal:")
         x = e[:description].split("Steal:")
         y = x[1].split("(")
         z = y[0].strip.downcase
         player_array.each do |h|
           if z == h.to_s.split("_")[1]
             @players[h][:steals] += 1
             @players[h][:plays] << [e[:time_elapsed], 23, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
           end
         end
       end
       if first_player == :""
         # - team turnover
       else
         @players[first_player][:turnovers] += 1
         @players[first_player][:plays] << [e[:time_elapsed], 5, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
       end
    elsif e[:event_type] == 8  # ----------------------------------------------------------------------------------------------subs
      @players[first_player][:ingame] = "out"
      @players[first_player][:plays] << [e[:time_elapsed], 8, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
      x = (e[:description].split("replaced by "))[1].strip.downcase
      player_array.each do |h|
        if x == h.to_s.split("_")[1]
          @players[h][:ingame] = "in"
          @players[h][:plays] << [e[:time_elapsed], 24, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
        end
      end
    elsif e[:event_type] == 9  # --------------------------------------------------------------------------------------timeouts
    elsif e[:event_type] == 12  # ------------------------------------------------------------------------------------start period
    elsif e[:event_type] == 13  # ---------------------------------------------------------------------------------------end period
    elsif e[:event_type] == 7  # ----------------------------------------------------------------------------------------violations
    elsif e[:event_type] == 10  # ---------------------------------------------------------------------------------------jump ball
    end
  end
  @counter = play_count.to_s
  render 'game_page/game'
end


  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
