class ApplicationController < ActionController::Base

def loadGameForDemo
  f1 = File.open("demo_pbp_1b.xml")
  g1 = Nokogiri::XML(f1)
  f1.close
  game_string = g1.css("game").attr("gcd").to_s
  game_date = game_string[0..7].to_date
  game_home_team = game_string[-3..-1]
  game_visiting_team = game_string[9..11]
  if Game.find_by game_date:game_date, home_team:game_home_team
    render 'start_page/home'
  else
    f2 = File.open("demo_pbp_2b.xml")
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
  
  def loadPlayIntoPlayerList(h, e, x)
    @players[h][:plays] << [e[:time_elapsed], x, e[:player_code], e[:description], e[:home_score], e[:visitor_score]]
  end
  
  def addScoreToGameFlow(t, h, v)
    flow_point_time = ((t/@game_flow_scope.to_f)*1298).round.to_s
    pre_score_flow_point = " L" + flow_point_time + " " + @game_flow_path[-3..-1].to_s
    flow_point = " L" + flow_point_time + " " + (115 - (h-v)*@game_flow_vertical_scope).to_s
    @game_flow_path << pre_score_flow_point
    @game_flow_path << flow_point
  end
  
#-----------------------------------------------------------------------------------------------------------------------------------------------award checks  
  def checkAwardSniper(x)
    i = -1
    s = 0
    loop do
      if @players[x][:plays][i] == nil || @players[x][:plays][i][1] == 16
        break
      else
        if @players[x][:plays][i][1] == 15
          s += 1
        end
        i -= 1
      end
    end
    if s > 2
      @players[x][:awards][:sniper] = "bronze"
      if s > 3 
        @players[x][:awards][:sniper] = "silver"
          if s > 4
            @players[x][:awards][:sniper] = "gold"
          end
      end
    end
  end
  
  def checkAwardUtilityMan(x)
    if @players[x][:assists] > 1 && @players[x][:rebounds] > 1 && @players[x][:steals] > 1 && @players[x][:blocks] > 1 && @players[x][:points] > 1
      @players[x][:awards][:utility_man] = "bronze"
      if @players[x][:assists] > 2 && @players[x][:rebounds] > 2 && @players[x][:steals] > 2 && @players[x][:blocks] > 2 && @players[x][:points] > 2
        @players[x][:awards][:utility_man] = "silver"
        if @players[x][:assists] > 3 && @players[x][:rebounds] > 3 && @players[x][:steals] > 3 && @players[x][:blocks] > 3 && @players[x][:points] > 3
          @players[x][:awards][:utility_man] = "gold"
        end
      end
    end
  end
  
  def checkAwardHotHand(x)
    i = -1
    s = 0
    loop do
      if @players[x][:plays][i] == nil || @players[x][:plays][i][1] == 16 || @players[x][:plays][i][1] == 2
        break
      else
        if @players[x][:plays][i][1] == 15 || @players[x][:plays][i][1] == 1
          s += 1
        end
        i -= 1
      end
    end
    if s > 3
      @players[x][:awards][:hot_hand] = "bronze"
      if s > 5 
        @players[x][:awards][:hot_hand] = "silver"
          if s > 7
            @players[x][:awards][:hot_hand] = "gold"
          end
      end
    end
  end
  
  def checkAwardPinpoint(x)
    i = -1
    s = 0
    loop do
      if @players[x][:plays][i] == nil || @players[x][:plays][i][1] == 5
        break
      else
        if @players[x][:plays][i][1] == 22
          s += 1
        end
        i -= 1
      end
    end
    if s > 4
      @players[x][:awards][:pinpoint] = "bronze"
      if s > 6 
        @players[x][:awards][:pinpoint] = "silver"
          if s > 8
            @players[x][:awards][:pinpoint] = "gold"
          end
      end
    end
  end
  
  def checkAwardCleanD(x)
    i = -1
    s = 0
    loop do
      if @players[x][:plays][i] == nil || @players[x][:plays][i][1] == 6
        break
      else
        if @players[x][:plays][i][1] == 21 || @players[x][:plays][i][1] == 23
          s += 1
        end
        i -= 1
      end
    end
    if s > 3
      @players[x][:awards][:clean_d] = "bronze"
      if s > 4 
        @players[x][:awards][:clean_d] = "silver"
          if s > 5
            @players[x][:awards][:clean_d] = "gold"
          end
      end
    end
  end
  
  def checkAwardDirtyWork(x)
    i = -1
    s = 0
    loop do
      if @players[x][:plays][i] == nil || @players[x][:plays][i][1] < 3 || @players[x][:plays][i][1] == 15 || @players[x][:plays][i][1] == 16
        break
      else
        if @players[x][:plays][i][1] == 4 || @players[x][:plays][i][1] == 23 || @players[x][:plays][i][1] == 21
          s += 1
        end
        i -= 1
      end
    end
    if s > 5
      @players[x][:awards][:dirty_work] = "bronze"
      if s > 7 
        @players[x][:awards][:dirty_work] = "silver"
          if s > 9
            @players[x][:awards][:dirty_work] = "gold"
          end
      end
    end
  end
  
  def checkAwardDouble(x)
    s = 0
    t = 0
    if @players[x][:points] > 9
      s += 1
    end
    if @players[x][:rebounds] > 9
      s += 1
    end
    if @players[x][:assists] > 9
      s += 1
    end
    if @players[x][:blocks] > 9
      s += 1
    end
    if @players[x][:steals] > 9
      s += 1
    end
    if s > 1
      @players[x][:awards][:double_double] = "bronze"
      if s > 2 
        @players[x][:awards][:triple_double] = "bronze"
        if @players[x][:points] > 10
          t += 1
        end
        if @players[x][:rebounds] > 10
          t += 1
        end
        if @players[x][:assists] > 10
          t += 1
        end
        if @players[x][:blocks] > 10
          t += 1
        end
        if @players[x][:steals] > 10
          t += 1
        end
        if t > 2
          @players[x][:awards][:triple_double] = "silver"
        end
      end
      if @players[x][:points] > 11
        s += 10
      end
      if @players[x][:rebounds] > 11
        s += 10
      end
      if @players[x][:assists] > 11
        s += 10
      end
      if @players[x][:blocks] > 11
        s += 10
      end
      if @players[x][:steals] > 11
        s += 10
      end
      if s > 20
        @players[x][:awards][:double_double] = "silver"
        if s > 30
          @players[x][:awards][:triple_double] = "gold"
        end
        if @players[x][:points] > 14
          s += 100
        end
        if @players[x][:rebounds] > 14
          s += 100
        end
        if @players[x][:assists] > 14
          s += 100
        end
        if s > 200
          @players[x][:awards][:double_double] = "gold"
        end
      end
    end
  end
  
  def checkAwardOldFashioned(x)
    i = -1
    s = 0
    loop do
      if @players[x][:plays][i] == nil
        break
      else
        if @players[x][:plays][i][1] == 3
          if @players[x][:plays][i-1][1] == 1 && @players[x][:plays][i-1][0] == @players[x][:plays][i][0]
            s += 1
          end
        end
      end
    i -= 1
    end
    if s > 1
      @players[x][:awards][:old_fashioned] = "bronze"
      if s > 2
        @players[x][:awards][:old_fashioned] = "silver"
        if s > 3
          @players[x][:awards][:old_fashioned] = "gold"
        end
      end
    end
  end
  
# -----------------------------------------------------------------------------------------------------------------------------------------------end award checks  
  play_count = (params[:status].to_i) + 10
  
  home_player_array = [:meyers_leonard, :dorell_wright, :alonzo_gee, :allen_crabbe, :cj_mccollum, :nicolas_batum, :lamarcus_aldridge, 
                       :wesley_matthews, :robin_lopez, :damian_lillard, :arron_afflalo, :steve_blake, :chris_kaman]
  
  visitor_player_array = [:russell_westbrook, :serge_ibaka, :kyle_singler, :nick_collison, :andre_roberson, :dion_waiters, 
                  :mitch_mcgary, :anthony_morrow, :dj_augustin, :perry_jones, :enes_kanter, :jeremy_lamb ]                
                  
  player_array = home_player_array + visitor_player_array
                  
  @players = {}
  
  
  player_array.each do |p|
    @players[p] = {   :team => "por", :minutes => 0, :points => 0, :rebounds => 0, :assists => 0, :steals => 0, :blocks => 0, :turnovers => 0,
                      :fouls => 0, :made2pt => 0, :missed2pt => 0, :made3pt => 0, :missed3pt => 0, :madeft => 0, :missedft => 0, :ingame => "out", :plays => [], 
                      :awards => { :sniper => "none", :utility_man => "none", :double_double => "none", :triple_double => "none", :hot_hand => "none", :pinpoint => "none", 
                                   :clean_d => "none", :stockton => "none", :malone => "none", :dirty_work => "none", :share_the_rock => "none", :no_soup_for_you => "none", 
                                   :old_fashioned => "none", :one_man_show => "none", :iso_joe => "none", :feed_me => "none" } }
  end
  
   visitor_player_array.each do |p|
    @players[p][:team] = "okc" 
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
  
  @event_array = Event.where(game_id: '20150227/OKCPOR').first(play_count)
  @marker = @event_array.last
  @game_flow_path = "M0 115"
  @game_flow_vertical_scope = 8
  @game_flow_scope = 1440
  @event_array.each do |e|   
    first_player = e[:player_code].to_sym
    if e[:event_type] == 2   # ----------------------------------------------------------------------------------missed shots and blocks
      if e[:description].include?("Block:")
        x = e[:description].split("Block:")
        y = x[1].split("(")
        z = y[0].strip.downcase
        player_array.each do |h|
          if z == h.to_s.split("_")[1] 
            @players[h][:blocks] += 1
            loadPlayIntoPlayerList(h, e, 21)
            checkAwardCleanD(h)
            checkAwardDirtyWork(h)
            if @players[h][:blocks] > 9
              checkAwardDouble(h)
            end
          end
        end
      end
      if e[:description].include?("3pt")
        @players[first_player][:missed3pt] += 1
        loadPlayIntoPlayerList(first_player, e, 16)
      else
        @players[first_player][:missed2pt] += 1
        loadPlayIntoPlayerList(first_player, e, 2)
      end
    elsif e[:event_type] == 4   # ----------------------------------------------------------------------------------------------rebounds
      if first_player == :""
        # count team rebounds?
      else
        @players[first_player][:rebounds] += 1
        loadPlayIntoPlayerList(first_player, e, 4)
        checkAwardDirtyWork(first_player)
        if @players[first_player][:rebounds] > 9
          checkAwardDouble(first_player)
        end
      end
    elsif e[:event_type] == 1  # --------------------------------------------------------------------------------made shots and assists
      if e[:description].include?("Assist:")
        x = e[:description].split("Assist:")
        y = x[1].split("(")
        z = y[0].strip.downcase
        player_array.each do |h|
          if z == h.to_s.split("_")[1]
            @players[h][:assists] += 1
            loadPlayIntoPlayerList(h, e, 22)
            if @players[h][:assists] > 1
              checkAwardUtilityMan(h)
              checkAwardPinpoint(h)
              if @players[h][:assists] > 9
                checkAwardDouble(h)
              end
            end
          end
        end
      end
      if e[:description].include?("3pt")
        @players[first_player][:made3pt] += 1
        @players[first_player][:points] += 3
        loadPlayIntoPlayerList(first_player, e, 15)
        addScoreToGameFlow(e[:time_elapsed], e[:home_score], e[:visitor_score])
        if @players[first_player][:made3pt] > 2
          checkAwardSniper(first_player)
        end
        if @players[first_player][:points] > 9 && @players[first_player][:points] < 13
          checkAwardDouble(first_player)
        end
      else
        @players[first_player][:made2pt] += 1
        @players[first_player][:points] += 2
        loadPlayIntoPlayerList(first_player, e, 1)
        addScoreToGameFlow(e[:time_elapsed], e[:home_score], e[:visitor_score])
        if @players[first_player][:points] > 9 && @players[first_player][:points] < 12
          checkAwardDouble(first_player)
        end
      end
      if @players[first_player][:points] > 7
        checkAwardHotHand(first_player)
      end
    elsif e[:event_type] == 3  # -----------------------------------------------------------------------------------------free throws
      if e[:description].include?("Missed")
        @players[first_player][:missedft] += 1
        loadPlayIntoPlayerList(first_player, e, 17)
      else
        @players[first_player][:madeft] += 1
        @players[first_player][:points] += 1
        loadPlayIntoPlayerList(first_player, e, 3)
        addScoreToGameFlow(e[:time_elapsed], e[:home_score], e[:visitor_score])
        if @players[first_player][:points] == 10
          checkAwardDouble(first_player)
        end
        if @players[first_player][:points] > 8
          checkAwardOldFashioned(first_player)
        end
      end
    elsif e[:event_type] == 6  # -------------------------------------------------------------------------------------------fouls
      if e[:description].include?("Technical")
      else
        @players[first_player][:fouls] += 1
        loadPlayIntoPlayerList(first_player, e, 19)
      end
    elsif e[:event_type] == 5  # --------------------------------------------------------------------------------turnovers and steals
       if e[:description].include?("Steal:")
         x = e[:description].split("Steal:")
         y = x[1].split("(")
         z = y[0].strip.downcase
         player_array.each do |h|
           if z == h.to_s.split("_")[1]
             @players[h][:steals] += 1
             loadPlayIntoPlayerList(h, e, 23)
             checkAwardCleanD(h)
             checkAwardDirtyWork(h)
             if @players[h][:steals] > 9
               checkAwardDouble(h)
             end
           end
         end
       end
       if first_player == :""
         # - team turnover
       else
         @players[first_player][:turnovers] += 1
         loadPlayIntoPlayerList(first_player, e, 5)
       end
    elsif e[:event_type] == 8  # ----------------------------------------------------------------------------------------------subs
      @players[first_player][:ingame] = "out"
      loadPlayIntoPlayerList(first_player, e, 8)
      x = (e[:description].split("replaced by "))[1].strip.downcase
      player_array.each do |h|
        if x == h.to_s.split("_")[1]
          @players[h][:ingame] = "in"
          loadPlayIntoPlayerList(h, e, 24)
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
