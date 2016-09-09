local skynet = require "skynet"
local filelog = require "filelog"
local commonconst = require "common_const"
local texascard = require "texascard"
local timer = require "timer"
local base = require "base"
local tabletool = require "tabletool"
local timetool = require "timetool"
local share_record = require "share_record"
local robotmanager = require "robotmanager"

local table_data
local msghelper
local tablestateevent = {}   --桌子状态机
local onegamerecode          --一局游戏玩家历史记录
local system_recovery
local is_norealplayer = true
local tablelog={
    --[[
        table_id = ,
        room_type = ,
        game_type = ,
        system_recovery = ,
        identify_code = "",
        create_rid = ,
        result = {
            {
                index =,
                rid = ,
                card_form = , 
                form_cards = ,
                hole_cards = ,
                chips = ,
                win_chips =, 
                rolename = ,
                timestamp = ,
            }
        },
    ]]
}

local srecord           --记录战绩

local Game = {}

function Game.init(helper, tabledata)
    msghelper = helper
	table_data = tabledata

    --注册桌子状态机
    tablestateevent[commonconst.TABLE_STATE_GAME_START] =  Game.gamestart
    tablestateevent[commonconst.TABLE_STATE_ONE_GAME_START] = Game.gameonestart
    tablestateevent[commonconst.TABLE_STATE_ROUND_START]  = Game.gameroundstart
    tablestateevent[commonconst.TABLE_STATE_ROUND_PRE_START] = Game.gameroundprestart
    tablestateevent[commonconst.TABLE_STATE_CONTINUE_ROUND] = Game.gameroundcontinue
    tablestateevent[commonconst.TABLE_STATE_CONTINUE_ROUND_AND_SITUP] = Game.gameroundcontinue_and_situp
    tablestateevent[commonconst.TABLE_STATE_CONTINUE_ROUND_AND_EXIT] = Game.gameroundcontinue_and_leave
    tablestateevent[commonconst.TABLE_STATE_ROUND_END]  = Game.gameroundend
    tablestateevent[commonconst.TABLE_STATE_GAME_ONE_END] = Game.gameoneend
    tablestateevent[commonconst.TABLE_STATE_GAME_ONE_REAL_END] = Game.gameonerealend
    tablestateevent[commonconst.TABLE_STATE_GAME_END]  = Game.gameend
end

----------------------------------------------------------------------------------------
--驱动游戏运行
function Game.gamerun()
	local f = nil
	while true do
		if table_data.table_state == commonconst.TABLE_STATE_WAIT_MIN_PLAYER then
			break
		end

		f = tablestateevent[table_data.table_state]
		if f == nil then
			break
		end

		f()
	end
end

function Game.gamestart()
    table_data.round_count = 0
    --初始化玩家状态
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_waitfornextroundseat(seat) then
            seat.state = commonconst.PLAYER_STATE_PLAYING
            if not robotmanager.is_robot(seat.rid) then
                is_norealplayer = false
            end
        end
    end

    --设置庄家位置
    for index, seat in ipairs(table_data.tableseats) do
        if Game.is_ingameseat(seat) then
            table_data.button_index = index
        end
    end

    msghelper.set_tablestate(commonconst.TABLE_STATE_ONE_GAME_START)
end

function Game.gameonestart()
    local table_conf = msghelper.get_table_conf()
    srecord = share_record.new(table_data.table_id, msghelper.get_roomsvr(), skynet.self(), {})
    onegamerecode = nil
    tablelog = nil
    onegamerecode = {}

    table_data.table_record_id = srecord.getid()

    tablelog = {
        table_id = table_data.table_id,
        room_type = table_data.table_room_type,
        game_type = table_data.table_game_type,
        identify_code = table_conf.identify_code,
        create_rid = table_conf.table_create_user,
        result = {},
    }
    if tablelog.identify_code == nil then
        tablelog.identify_code = ""
    end 
    if tablelog.create_rid == nil then
        tablelog.create_rid = 0
    end

    system_recovery = 0
    --初始化桌子
    Game.onegameend_inittable()

    --洗牌    
    texascard.cards_shuffle(table_data.deck_cards)
    --table_data.deck_cards={30,18,47,32,28,19,29,2,0}
    --texascard.cardsshuffle_with_prefinedcard(table_data.deck_cards)

    --初始化玩家状态
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_waitfornextroundseat(seat) then
            Game.onegamestart_initseat(seat)
        end
    end

    --尝试给玩家自动买入
    local autorebuyplayer = nil
    local autorebuychips = 0
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_ingameseat(seat) then
           autorebuyplayer = table_data.autobuyinplayers[seat.rid]
           if autorebuyplayer ~= nil and autorebuyplayer.auto_type ~= 0 and seat.outtable_chips >= 0 then
                if autorebuyplayer.auto_type == 1 and seat.chips < autorebuyplayer.default_value then
                    autorebuychips = math.min(autorebuyplayer.default_value - seat.chips, seat.outtable_chips - seat.chips)
                    seat.chips = autorebuychips + seat.chips
                    msghelper.sendmsg_totableplayer(seat, "lockchips", autorebuychips)
                elseif autorebuyplayer.auto_type == 2 and seat.chips < autorebuyplayer.bottom_value then
                    autorebuychips = math.min(autorebuyplayer.default_value - seat.chips, seat.outtable_chips - seat.chips)
                    seat.chips = autorebuychips + seat.chips
                    msghelper.sendmsg_totableplayer(seat, "lockchips", autorebuychips)                
                elseif autorebuyplayer.auto_type == 3 and seat.chips < autorebuyplayer.default_value then
                    autorebuychips = math.min(autorebuyplayer.default_value - seat.chips, seat.outtable_chips - seat.chips)
                    seat.chips = autorebuychips + seat.chips
                    table_data.autobuyinplayers[seat.rid] = nil
                    msghelper.sendmsg_totableplayer(seat, "lockchips", autorebuychips)
                end 
           elseif seat.chips <= 0 then
                --将玩家站起来
                Game.standup(seat)
           end 
        end
    end

    --每局扣除服务费
    local gamedraw = msghelper.get_game_draw()
    if gamedraw ~= 0 then
        for _, seat in ipairs(table_data.tableseats) do
            if Game.is_ingameseat(seat) then
               if  seat.outtable_chips - seat.chips > gamedraw then
                    seat.outtable_chips = seat.outtable_chips - gamedraw
                    msghelper.sendmsg_totableplayer(seat, "outgamedraw", -gamedraw)
               elseif seat.chips > gamedraw + table_data.ante then
                    seat.outtable_chips = seat.outtable_chips - gamedraw
                    seat.chips = seat.chips - gamedraw
                    msghelper.sendmsg_totableplayer(seat, "ingamedraw", -gamedraw)                
               else 
                    --将玩家站起来
                    Game.standup(seat)
               end
            end
        end
    end

    --设置庄家位置
    local is_emptybutton
    is_emptybutton, table_data.button_index = Game.find_nextbutton_index(table_data.button_index)
    --记录每局玩游戏使用的座位从button开始记录
    table_data.gameseat_list = nil
    table_data.gameseat_list = {}
    for i=0, 8 do
        local next_index = (table_data.button_index + i) % 9
        if next_index == 0 then
            next_index = 9
        end
        seat = table_data.tableseats[next_index]
        if is_emptybutton and (i <= 1 or Game.is_ingameseat(seat)) then
            local gameseatinfo = {
                seat_index = next_index,
                rid = seat.rid,
            }
            table.insert(table_data.gameseat_list, gameseatinfo)
        elseif i == 0 or Game.is_ingameseat(seat) then
            local gameseatinfo = {
                seat_index = next_index,
                rid = seat.rid,
            }
            table.insert(table_data.gameseat_list, gameseatinfo)                 
        end
    end


    --确定大小盲注位置
    if Game.get_ingameplayernum() == 2 then
        table_data.small_blinds_index = table_data.button_index
        --table_data.big_blinds_index = Game.find_nextbutton_index(table_data.small_blinds_index)
        table_data.big_blinds_index = Game.find_bigblinds_index()
    else
        --table_data.small_blinds_index = Game.find_nextbutton_index(table_data.button_index)
        --table_data.big_blinds_index = Game.find_nextbutton_index(table_data.small_blinds_index)
        table_data.small_blinds_index = Game.find_smallblinds_index()
        table_data.big_blinds_index = Game.find_bigblinds_index()
    end

    --给玩家发手牌
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_ingameseat(seat) then
            seat.cards = {}
            Game.deal_card(table_data.deck_cards, seat.cards)
            Game.deal_card(table_data.deck_cards, seat.cards)
        end
    end
    table_data.round_count = 0
    msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_PRE_START)
    msghelper.write_tableinfo_log("gameonestart_finish", table_data)     
end

function Game.gameroundprestart()
    --初始化
    table_data.round_end_index = 0    --回合结束位置
    table_data.highest_bet = 0        --本轮最高下注
    table_data.last_raise_diff = 0    --上一次下注差额
    table_data.round_count = table_data.round_count + 1
    --初始化玩家底注
    for _, seat in ipairs(table_data.tableseats) do
        seat.bet_chips = 0
        if Game.is_ingameseat(seat) then
            if table_data.round_count - seat.last_round ~= 1 then
                seat.last_round = seat.last_round + 1
                seat.lastround_betnum = seat.currentround_betnum
            end
            seat.current_round = table_data.round_count
            seat.currentround_betnum = 0
        end
    end

    --设置游戏状态
    msghelper.set_tablestate(commonconst.TABLE_STATE_WAIT_ROUND_START) 

    --第一回合如果前注不为0，则处理前注
    if table_data.round_count == 1 then
        if table_data.ante ~= 0 then 
            for _, seat in pairs(table_data.tableseats) do
                if Game.is_ingameseat(seat) then
                    Game.playersubante(seat, table_data.ante)            
                end
            end
        else
            table_data.round_count = table_data.round_count + 1
            for _, seat in ipairs(table_data.tableseats) do
                if Game.is_ingameseat(seat) then
                    if table_data.round_count - seat.last_round ~= 1 then
                        seat.last_round = seat.last_round + 1
                        seat.lastround_betnum = seat.currentround_betnum
                    end
                    seat.current_round = table_data.round_count
                    seat.currentround_betnum = 0
                end
            end            
        end
        --通知比赛开始
        Game.send_gamestart_notify()        
    end    
    --第一回合扣盲注，发底牌
    if table_data.round_count == 2 then
        --扣大小盲
        Game.playerblind(table_data.tableseats[table_data.small_blinds_index], table_data.small_blinds)
        Game.playerblind(table_data.tableseats[table_data.big_blinds_index], table_data.big_blinds)
        Game.send_bigsmallblind_notify()
        Game.send_holecard_notify()
    elseif table_data.round_count == 3 then
        --第二回合发翻牌
        Game.send_flopcardinfo_notify()
    elseif table_data.round_count == 4 then
        -- 第三回合发转牌
        Game.send_turncardinfo_notify()
    elseif table_data.round_count == 5 then
        -- 第四回合发河牌
        Game.send_rivercardinfo_notify()
    end

    --设置定时器时间单位10ms
    local wait_time = 0
    if table_data.round_count == 1 then
        wait_time = 80
    elseif table_data.round_count == 2 then
        --发手牌
        wait_time = 30 * table_data.sitdown_player_num + 60
    elseif table_data.round_count == 3 then
        --合筹码+翻牌
        wait_time = 80+30+100+30
    elseif table_data.round_count == 6 then
        --合筹码+翻牌
        wait_time = 80 + 100+30
    else
        --合筹码+翻牌
        wait_time = 80 + 100+30
    end

    --设置定时器
    local timerid = timer.settimer(wait_time, "gameroundstart")
    if table_data.table_state ~= commonconst.TABLE_STATE_WAIT_ROUND_START then
        timer.cleartimer(timerid)
    else
        if table_data.timer_id >= 0 then
            timer.cleartimer(table_data.timer_id)
        end
        table_data.timer_id = timerid
    end

    msghelper.write_tableinfo_log("gameroundprestart_finish", table_data)  
end

function Game.gameroundstart()

    --msghelper.write_tableinfo_log("gameroundstart_start", table_data)  
    --判断下一个说话玩家位置
    local next_index
    if table_data.round_count == 1 then
        next_index = Game.find_nextactionplayer_index(table_data.big_blinds_index)
    elseif table_data.round_count == 2 then
        --如果是第一轮，从枪口开始
        next_index = Game.find_nextactionplayer_index(table_data.big_blinds_index)
    elseif Game.get_ingameplayernum() == 2 then
        --第二轮以后且有两个玩家，从大盲开始
        next_index = Game.find_nextactionplayer_index(table_data.small_blinds_index)
    else
        --第二轮以后且有多于两个，从小盲开始
        next_index = Game.find_nextactionplayer_index(table_data.button_index)
    end

    if next_index ~= 0 then
        local next_seat = table_data.tableseats[next_index]
        if Game.get_actionable_playernum() == 1 
            and table_data.highest_bet <= next_seat.bet_chips then
            msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
            return
        elseif Game.get_actionable_playernum() == 1 and next_seat.chips == 0 then
            msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
            return        
        end 
    end

    if table_data.round_count == 1 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END) 
        return        
    end 

    table_data.is_bet = false

    --确定第一个行动玩家
    local index = 1
    if table_data.round_count == 2 then
        --如果是第一轮，从枪口开始
        index = Game.find_nextactionplayer_index(table_data.big_blinds_index)

    elseif Game.get_ingameplayernum() == 2 then
        --第二轮以后且有两个玩家，从大盲开始
        index = Game.find_nextactionplayer_index(table_data.small_blinds_index)
    else
        --第二轮以后且有多于两个，从小盲开始
        index = Game.find_nextactionplayer_index(table_data.button_index)
    end

    --如果没找到玩家，说明回合结束
    if index == 0 or table_data.round_count >= 6  then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
        return
    end
    --设置结束位置
    table_data.round_end_index = index
    --分析可操作行为并通知用户处理
    Game.analyse_and_senddoaction(index)
    msghelper.write_tableinfo_log("gameroundstart_finish", table_data)  
end

function Game.gameroundcontinue()

    local index = table_data.action_index
    local action = table_data.action_type
    local num = table_data.action_num
    local seat = msghelper.get_seat_byindex(index)

    msghelper.write_tableinfo_log("gameroundcontinue_start", table_data)  

    if table_data.timer_id >= 0 then
        timer.cleartimer(table_data.timer_id)
        table_data.timer_id = -1
    end

    --玩家行为处理
    if Game.is_ingameseat(seat) then
        Game.deal_player_action(index, action, num)
    else
        filelog.sys_obj("table", table_data.table_id, "round continue when player not in game, index="..index.." rid="..seat.rid.." action="..action.." num="..num)
    end

    --如果可以结算的玩家小于2个，直接结束回合
    if Game.get_calcpot_playerNum() < 2 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
        return
    end

    --[[local playernum = Game.get_ingameplayernum()
    if playernum == 2 and Game.get_actionable_playernum() < 2 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
        return        
    end]]

    --判断下一个说话玩家位置
    local next_index = Game.find_nextactionplayer_index(index)
    --如果找不到玩家说明回合结束，开始结束逻辑
    if next_index == 0 or table_data.round_count >= 6 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
        return
    end

    local next_seat = table_data.tableseats[next_index]
    if Game.get_actionable_playernum() == 1 
        and table_data.highest_bet <= next_seat.bet_chips then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
        return
    elseif Game.get_actionable_playernum() == 1 and next_seat.chips == 0 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
        return        
    end 
 

    --[[local allplaying = Game.find_playing_seats() 
    if #allplaying == 1 and Game.is_ingame_highest(allplaying[1]) == true then
        table_data.table_state = commonconst.TABLE_STATE_ROUND_END
        return
    end]]
 

    --分析可操作的行为并通知用户处理
    Game.analyse_and_senddoaction(next_index)
    msghelper.write_tableinfo_log("gameroundcontinue_finish", table_data)  

end

function Game.gameroundcontinue_and_situp()
    Game.gameroundcontinue()
    
    --Game.standup(seat)
end

function Game.gameroundcontinue_and_leave()
    local seat = msghelper.get_seat_byindex(table_data.action_index)
    local rid = seat.rid
    -- 先继续回合
    Game.gameroundcontinue()
    -- 玩家被动站起
    Game.standup(seat)
    --玩家被动离开
    Game.leavetable(rid)
end

function Game.gameroundend()
    msghelper.write_tableinfo_log("gameroundend_start", table_data)

    if not table_data.is_passive_lightcards and (Game.get_ingamenotfold_playernum() - Game.get_allin_playernum()) <= 1 and (Game.get_ingameplayernum() - Game.get_ingamefold_playernum()) >= 2 then
        --[[
            #通知玩家量牌
            .Cards {
                seat_index 0 : integer
                cards 1 : *integer
            }

            lightcard 83 {
                response {
                    cards_list 0 : *Cards(seat_index)
                    ispassive 1 : boolean #是否被动亮牌
                }
            }
        ]]
        local noticemsg = {cards_list={}, ispassive=true}
        for index, seat in ipairs(table_data.tableseats) do
            if Game.is_ingameseat(seat) and seat.state ~= commonconst.PLAYER_ACTION_FOLD then
                local playerholecards = {seat_index = index, cards=seat.cards}
                noticemsg.cards_list[index] = playerholecards
            end
        end
        msghelper.sendmsg_toalltableplayer("lightcard", noticemsg)
        srecord.insert("lightcard", noticemsg)
        table_data.is_passive_lightcards = true
    end

    --计算奖池
    if Game.is_hasplayerbet() then
        Game.calcpot_onroundend()
    end

    --如果可以结算的玩家小于2个，直接结束游戏
    if Game.get_calcpot_playerNum() < 2 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_ONE_END)
        return
    end

    --根据回合数决定操作
    if table_data.round_count >= 5 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_ONE_END)
        return
    else
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_PRE_START)
    end
    msghelper.write_tableinfo_log("gameroundend_finish", table_data)  
end

function Game.gameoneend()
    msghelper.write_tableinfo_log("gameoneend_start", table_data)  
    -- 奖池结算逻辑
    Game.calcpot_ongameend()

    -- 根据奖池发奖金
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_ingameseat(seat) then
            seat.bunko = commonconst.BUNKO_LOSE
        end
    end

    for _, pot in ipairs(table_data.pots) do
        local divide_money = 0
        local seat
        local remainder = 0
        local tmp_index
        if #(pot.win_player_indexes) ~= 0 then
            remainder = pot.total_bet % #(pot.win_player_indexes)
            system_recovery = system_recovery + remainder
            divide_money = math.floor(pot.total_bet / #(pot.win_player_indexes))
        end

        for _, index in ipairs(pot.win_player_indexes) do
            seat = msghelper.get_seat_byindex(index)
            Game.playeraddchip(seat, divide_money)
            seat.bunko = commonconst.BUNKO_WIN
        end

        if #(pot.win_player_indexes) >= 1 then
            tmp_index = math.random(1, #(pot.win_player_indexes))
            seat = msghelper.get_seat_byindex(pot.win_player_indexes[tmp_index])
            Game.playeraddchip(seat, remainder)
        end
    end    

    --通知结果
    Game.send_gameresult_notify()

    msghelper.set_maxcardform_players()

    --更新玩家的游戏数据
    local gamewin_playernum = Game.get_gamewin_playernum()    
    for index, seat in ipairs(table_data.tableseats) do
        if Game.is_ingameseat(seat) then
            seat.outtable_chips = seat.outtable_chips + seat.onegame_winchips
            local resutdata = {}
            resutdata.bunko = seat.bunko
            resutdata.winchips = seat.onegame_winchips
            resutdata.rid = seat.rid
            resutdata.card_form = seat.card_form
            resutdata.form_cards = seat.form_cards
            resutdata.bet_num = seat.bet_num
            resutdata.raise_num = seat.raise_num
            resutdata.call_num = seat.call_num
            resutdata.threebet_num = seat.threebet_num
            resutdata.steal_num = seat.steal_num
            resutdata.continuebet_num = seat.continuebet_num
            resutdata.othercontinuebet_num = seat.othercontinuebet_num
            resutdata.foldtocontinuebet_num = seat.foldtocontinuebet_num
            resutdata.preflopraise_num = seat.preflopraise_num
            resutdata.steal_num = seat.steal_num
            resutdata.othersteal_num = seat.othersteal_num
            resutdata.foldsteal_num = seat.foldsteal_num
            resutdata.winbb = resutdata.winchips // table_data.big_blinds
            resutdata.round = table_data.round_count - 1
            resutdata.room_type = table_data.table_room_type
            resutdata.match_name = table_data.table_name
            resutdata.is_maxcardform = seat.is_maxcardform
            resutdata.table_record_id = table_data.table_record_id
            resutdata.killfew = 0
            resutdata.match_rank = 0

            if seat.bunko == commonconst.BUNKO_WIN then
                resutdata.expchange = (gamewin_playernum + table_data.calculate_win_expbase)*table_data.calculate_win_expratio
            else
                resutdata.expchange = table_data.calculate_lose_exp
            end

            --通知agent更新数据
            msghelper.sendmsg_totableplayer(seat, "gameendcaldata", resutdata)
            Game.add_onegamerecode(seat)
            msghelper.add_recodetotablelog(seat)
        end
    end 

    --通知桌上所有玩家牌桌历史记录
    Game.send_onegamerecode_notify()
    tablelog.system_recovery = system_recovery
    msghelper.write_table_mongolog("tablelog", tablelog)  


    for _, seat in ipairs(table_data.tableseats) do
        --设置状态
        if Game.is_ingameseat(seat) then
            seat.state = commonconst.PLAYER_STATE_WAIT_FOR_NEXT_ONE_GAME
            seat.onegame_winchips = 0
        end
    end

    -- 如果桌子空了直接结束
    if Game.get_waitfornextonegameplayernum() == 0 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_ONE_REAL_END)
        return
    end

    -- 设置游戏状态
    msghelper.set_tablestate(commonconst.TABLE_STATE_WAIT_GAME_END)

    --设置定时器
    -- 翻手牌+合筹码+每个奖池结算 + 比牌
    local wait_time = 45 + 40 + 220 * #(table_data.pots) + 300
    local gameonerealendmsg = {}
    gameonerealendmsg.table_id = table_data.table_id
    local timerid = timer.settimer(wait_time, "gameonerealend", gameonerealendmsg)
    if table_data.table_state ~= commonconst.TABLE_STATE_WAIT_GAME_END then
        timer.cleartimer(timerid)
    else
        if table_data.timer_id >= 0 then
            timer.cleartimer(table_data.timer_id)
        end
        table_data.timer_id = timerid
    end
    
    msghelper.write_tableinfo_log("gameoneend_finish", table_data)
end

function Game.gameonerealend()
    msghelper.write_tableinfo_log("gameonerealend_start", table_data)  

    if table_data.timer_id >= 0 then
        timer.cleartimer(table_data.timer_id)
        table_data.timer_id = -1        
    end
    --发结束通知
    Game.send_gameend_notify()

    -- 桌上玩家处理
    local autorebuyplayer = nil
    for index, seat in pairs(table_data.tableseats) do
        if not Game.is_noplayer(seat) then
            autorebuyplayer = table_data.autobuyinplayers[seat.rid]
            --如果钱不够抽水则踢出座位
            local gamedraw = msghelper.get_game_draw()
            if seat.chips <= gamedraw and (seat.outtable_chips - seat.chips < gamedraw) then
                Game.standup(seat)
            --如果剩余筹码不够小盲和前注则提出
            elseif seat.chips <= 0 and autorebuyplayer == nil then
                Game.standup(seat)
            elseif seat.chips <= 0 and seat.outtable_chips <= 0 then
                Game.standup(seat)
            end
        end 
    end
    
    --一局游戏结束清除数据
    Game.onegameend_inittable()

    --判断是否更新配置
    if msghelper.is_updateconf() then
        msghelper.updateconf()
    end

        --如果桌上正准备删除则踢掉所有玩家
    if table_data.isdelete then
        msghelper.kickallplayer()
        msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_END)
        if table_data.deletetable_timer_id < 0 then
            table_data.deletetable_timer_id = timer.settimer(10, "deletetable")
        end
        return
    end

    --尝试踢掉机器人
    msghelper.try_kick_robot()

    -- 判断玩家数量
    if  Game.get_waitfornextonegameplayernum() < table_data.min_player_num or Game.get_waitfornextonegameplayernum() < 0 then
        msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_END)
        return
    end

    -- 继续下一轮
    msghelper.set_tablestate(commonconst.TABLE_STATE_ONE_GAME_START)

    msghelper.try_recover_robot()

    msghelper.write_tableinfo_log("gameonerealend_finish", table_data)  
end

function Game.gameend()
    msghelper.write_tableinfo_log("gameend_start", table_data)

    onegamerecode = nil
    tablelog = nil
    
--[[
    local rid  
    for _, seat in ipairs(table_data.tableseats) do
        if not Game.is_noplayer(seat) then
            -- 如果是托管的就踢掉
            if seat.is_tuoguan then
                rid = seat.rid
                Game.standup(seat)
                Game.leavetable(rid)
            end
        end
    end
]]

    --设置游戏状态
    msghelper.set_tablestate(commonconst.TABLE_STATE_WAIT_MIN_PLAYER)

    --尝试调度机器人
    if table_data.applyrobot_timer_id == -1 and msghelper.is_canapplyrobot() then
        local applyrobottimermsg = {table_id=table_data.table_id, robot_num=1}
        table_data.applyrobot_timer_id = timer.settimer(base.get_random(table_data.robot_enter_mintime, table_data.robot_enter_maxtime) * 100, "applyrobot", applyrobottimermsg)        
    end

    msghelper.try_recover_robot()

    msghelper.write_tableinfo_log("gameend_finish", table_data)  
end
----------------------------------------玩家操作----------------------------------
function Game.playersubbetchip(seat, num)
    -- 扣钱
    local sub_num = math.min(num, seat.bet_chips)
    seat.bet_chips = seat.bet_chips - sub_num
end

function Game.playeraddchip(seat, num)
    -- 加钱
    seat.chips = seat.chips + num
    seat.onegame_winchips = seat.onegame_winchips + num
end
--算法相关
function Game.calcpot_ongameend()
    --先计算没有fold的玩家的牌型
    for i, seat in ipairs(table_data.tableseats) do
        -- 没下注的不考虑 && 玩家不参与结算的话不考虑
        if Game.is_calcpotseat(seat) then
            texascard.analyse(table_data, i)
        end
    end

    -- 依次算每个奖池的情况
    for _, pot in ipairs(table_data.pots) do
        local player_indexes = pot.player_indexes
        local win_player_index = pot.win_player_indexes 

        -- 先找出最大的
        local max_seat = nil
        for _, index in ipairs(player_indexes) do
            local seat = table_data.tableseats[index]
            if Game.is_calcpotseat(seat) then
                if max_seat == nil or texascard.priocompare(max_seat, seat) < 0 then
                    max_seat = seat
                end
            end
        end
        
        -- 如果没有玩家能获得这个奖池,把钱给其他的玩家
        if max_seat == nil then
            local not_fold_player_num = Game.get_calcpot_playerNum()
            local ingame_player_num = Game.get_ingameplayernum()
            if not_fold_player_num ~= 0 then
                -- 优先给非fold的玩家
                for i, seat in ipairs(table_data.tableseats) do
                    -- 没下注的不考虑 && 玩家不参与结算的话不考虑
                    if Game.is_calcpotseat(seat) then
                        table.insert(win_player_index, i)
                    end
                end
            elseif ingame_player_num ~= 0 then
                -- 不行再发给fold的玩家
                for i, seat in ipairs(table_data.tableseats) do
                    if Game.is_ingameseat(seat) then
                        table.insert(win_player_index, i)
                    end
                end
            end
            -- 因为找不到最大玩家也不用进行后面逻辑了
        else 
            -- 把所有最大的都加入win_palyer_index
            for _, index in ipairs(player_indexes) do
                local seat = table_data.tableseats[index]
                if Game.is_calcpotseat(seat) then
                    if texascard.priocompare(max_seat, seat) == 0 then
                        table.insert(win_player_index, index)
                    end
                end
            end
        end
    end
    
end

function Game.calcpot_onroundend()
    local bet_info = {}
    local tmpmap = {}
    --对玩家筹码去重
    for _, seat in ipairs(table_data.tableseats) do
        -- 没下注的不考虑 && 玩家不参与结算的话不考虑
        if seat.bet_chips ~= 0 and Game.is_calcpotseat(seat) then
            tmpmap[seat.bet_chips] = true
        end
    end    
    -- 把玩家按下注额从小到大排列
    for bet_chips, _ in pairs(tmpmap) do
            table.insert(bet_info, bet_chips)
    end    
    table.sort(bet_info, function(value1, value2)
                            return (value1 < value2) 
                         end)
    -- 如果是第一轮，保证至少一个大盲的底池
    if tabletool.is_emptytable(bet_info) and table_data.round_count == 2 then
        table.insert(bet_info, table_data.big_blinds)
    end

    -- 分别计算奖池
    for i, bet in ipairs(bet_info) do
        -- 扣的钱是当前奖池减去上一个奖池的差额
        local sub_chips = 0
        if i == 1 then
            sub_chips = bet
        else
            local bet_beforeindex = i - 1
            sub_chips = bet - bet_info[bet_beforeindex]
        end

        --第一个池子都合并到之前底池中，其他的池子都要新建边池
        local is_new_pot = false
        if #(table_data.pots) == 0 then
            is_new_pot = true
        end
        if i  ~= 1 then 
            is_new_pot = true
        end
        -- 检查上一个奖池是否有allin的玩家
        if i == 1 and #(table_data.pots) ~= 0 then
            local pot = table_data.pots[#(table_data.pots)]
            for _, index in ipairs(pot.player_indexes) do
                local seat = msghelper.get_seat_byindex(index)
                if seat.state == commonconst.PLAYER_STATE_ALL_IN and seat.bet_chips == 0 then
                    is_new_pot = true
                    break
                end
            end
        end

        if is_new_pot then
            local pot = {
                player_indexes = {}, 
                win_player_indexes = {},
                total_bet = 0,
                sub_chips_curround = 0,
                curround = table_data.round_count,
            }

            for i, seat in ipairs(table_data.tableseats) do
                if seat.bet_chips ~= 0 and Game.is_calcpotseat(seat) then                  
                    table.insert(pot.player_indexes, seat.index)
                end
            end
            table.insert(table_data.pots, pot)
        end

        --保存每轮池子的扣除额
        local pot = table_data.pots[#(table_data.pots)]
        pot.sub_chips_curround = sub_chips
        --从每个玩家身上都扣除钱
        for i, seat in ipairs(table_data.tableseats) do
            if seat.bet_chips ~= 0 then                 
                --有些fold玩家可能下注钱小于要扣的钱
                local real_sub_chips = math.min(sub_chips, seat.bet_chips)
                Game.playersubbetchip(seat, real_sub_chips)
                -- 添加到奖池中
                pot.total_bet = pot.total_bet + real_sub_chips
            end
        end
    end

    -- 把还没扣完的钱都扣到最新奖池
    for i, seat in ipairs(table_data.tableseats) do
        if seat.bet_chips ~= 0 then                 
            --有些fold玩家可能下注钱小于要扣的钱
            local real_sub_chips = seat.bet_chips
            Game.playersubbetchip(seat, real_sub_chips)
            local pot = table_data.pots[#(table_data.pots)]
            -- 添加到奖池中
            pot.total_bet = pot.total_bet + real_sub_chips
        end
    end

    -- 广播奖池信息
    Game.send_potsinfo_notify()
end


function Game.playersubchip(seat, num)
    --扣钱
    local sub_num = math.min(num, seat.chips)
    seat.chips = seat.chips - sub_num

    --增加每轮下注额
    seat.bet_chips = seat.bet_chips + sub_num
    seat.onegame_winchips = seat.onegame_winchips - sub_num

    --设置状态
    if seat.chips == 0 then
        seat.state =  commonconst.PLAYER_STATE_ALL_IN
    end
end
function Game.playerbet(seat, num)
    --输入检查
    if seat.chips < num then
        return false
    end
    -- 扣减
    Game.playersubchip(seat, num)

    --更新最高下注
    table_data.highest_bet = seat.bet_chips

    --更新加注额
    table_data.last_raise_diff = num

    --更新结束位置
    table_data.round_end_index = seat.index

    seat.bet_num = seat.bet_num + 1

    if seat.current_round == table_data.round_count then
        seat.currentround_betnum = seat.currentround_betnum + 1
    end
    
    if seat.currentround_betnum > 2 then
       seat.threebet_num = 1 
    end

    if seat.last_round ~= 0 and seat.lastround_betnum > 0 then
        seat.continuebet_num = seat.continuebet_num + 1
    end

    if msghelper.is_othercontinue_bet(seat.rid) then
        seat.othercontinuebet_num = seat.othercontinuebet_num + 1
    end

    if msghelper.is_steal(seat.index) then
        seat.steal_num = 1
    end

    if table_data.round_count <= 2 then
        seat.preflopraise_num = seat.preflopraise_num + 1
    end
    return true
end

function Game.playersubante(seat, num)
    --扣减
    Game.playersubchip(seat, num)
    table_data.highest_bet = math.max(table_data.highest_bet,seat.bet_chips)
    return true    
end

function Game.playerbetblind(seat, num)
    --扣减
    Game.playersubchip(seat, num)

    --更新最高下注
    table_data.highest_bet = num

    --更新加注额
    table_data.last_raise_diff = num

    return true
end

function Game.playerraise(seat, num)
    if seat.chips < num then
        return false
    end

    --扣钱
    Game.playersubchip(seat, num)

    --更新加注额
    table_data.last_raise_diff = seat.bet_chips - table_data.highest_bet

    --更新最高下注
    table_data.highest_bet = seat.bet_chips

    --更新结束位置
    table_data.round_end_index = seat.index

    seat.raise_num = seat.raise_num + 1
    if seat.current_round == table_data.round_count then
        seat.currentround_betnum = seat.currentround_betnum + 1
    end
    
    if seat.currentround_betnum > 2 then
       seat.threebet_num = 1 
    end
    if seat.last_round ~= 0 and seat.lastround_betnum > 0 then
        seat.continuebet_num = seat.continuebet_num + 1
    end

    if msghelper.is_othercontinue_bet(seat.rid) then
        seat.othercontinuebet_num = seat.othercontinuebet_num + 1
    end

    if msghelper.is_steal(seat.index) then
        seat.steal_num = 1
    end

    if table_data.round_count <= 2 then
        seat.preflopraise_num = seat.preflopraise_num + 1
    end
    return true
end

function Game.playercall(seat, num)
    num = table_data.highest_bet - seat.bet_chips

    --输入检查
    if seat.chips < num then
        return false
    end

    --扣钱
    Game.playersubchip(seat, num)

    seat.call_num = seat.call_num + 1
    return true
end

function Game.playercheck(seat)
    return true
end

function Game.playerfold(seat)
    --设置状态
    seat.state =  commonconst.PLAYER_STATE_FOLD
    seat.bunko = commonconst.BUNKO_LOSE
    if msghelper.is_othercontinue_bet(seat.rid) then
        seat.foldtocontinuebet_num = seat.foldtocontinuebet_num + 1
    end

    if msghelper.is_othersteal(seat.index) then
        seat.foldsteal_num = seat.foldsteal_num + 1
    end

    return true
end

function Game.playerallin(seat, num)
    num = seat.chips
    --扣钱
    Game.playersubchip(seat, num)

    if num > table_data.last_raise_diff then
        seat.raise_num = seat.raise_num + 1
        if table_data.round_count <= 2 then
            seat.preflopraise_num = seat.preflopraise_num + 1
        end
    else
        seat.call_num = seat.call_num + 1
    end 

    --更新加注额
    local raise_diff = seat.bet_chips - table_data.highest_bet
    if raise_diff < 0 then
        raise_diff = 0
    end
    if raise_diff > table_data.last_raise_diff then
        table_data.last_raise_diff = raise_diff
    end

    --更新最高下注
    if seat.bet_chips > table_data.highest_bet then    
        table_data.highest_bet = seat.bet_chips
        table_data.round_end_index = seat.index
    end

    if seat.current_round == table_data.round_count then
        seat.currentround_betnum = seat.currentround_betnum + 1
    end
    
    if seat.currentround_betnum > 2 then
       seat.threebet_num = 1 
    end
    if seat.last_round ~= 0 and seat.lastround_betnum > 0 then
        seat.continuebet_num = seat.continuebet_num + 1
    end

    if msghelper.is_othercontinue_bet(seat.rid) then
        seat.othercontinuebet_num = seat.othercontinuebet_num + 1
    end

    if msghelper.is_steal(seat.index) then
        seat.steal_num = 1
    end

    return true
end

function Game.playerblind(seat, num)
    if msghelper.is_emptyseat(seat) then
        return true
    end
    --扣钱
    Game.playersubchip(seat, num)
    --更新最高下注
    --注意这里就算玩家不够大小盲，后续跟牌也要按照大小盲注来算
    table_data.highest_bet = math.max(table_data.highest_bet, num)

    --更新加注额
    table_data.last_raise_diff = num

    return true
end

----------------------------------------玩家操作end-------------------------------

--判断是否允许玩家操作
function Game.is_action_allowed(message, action)
    for i = 1, #(message.allow_actions) do
        if message.allow_actions[i] == action then
            return true
        end
    end
    return false
end
--
function Game.deal_player_action(index, action, num)
    --分析操作类型，对错误操作进行修正
    local notify = {allow_actions = {}}
    local seat = msghelper.get_seat_byindex(index)
    
    Game.analyse_allow_action(index, notify)
    --如果不允许做一个默认操作
    if not Game.is_action_allowed(notify, action) then

        if  table_data.round_count > 2 and not table_data.is_bet  and action == commonconst.PLAYER_ACTION_CALL then
            action = commonconst.PLAYER_ACTION_BET
            table_data.is_bet = true
        else
            if Game.is_action_allowed(notify, commonconst.PLAYER_ACTION_CHECK) then
                action = commonconst.PLAYER_ACTION_CHECK
            elseif Game.is_action_allowed(notify, commonconst.PLAYER_ACTION_CALL) then
                action = commonconst.PLAYER_ACTION_CALL
            else
                action = commonconst.PLAYER_ACTION_FOLD
            end            
        end
    --检查下注额
    elseif action == commonconst.PLAYER_ACTION_BET or action == commonconst.PLAYER_ACTION_RAISE then
        if num < notify.bet_min then 
            num = notify.bet_min
        end
        if num > notify.bet_max then 
            num = notify.bet_max
        end
    end
    
    --处理玩家行为
    local result = false

    if action == commonconst.PLAYER_ACTION_BET then
        result = Game.playerbet(seat, num)         
    elseif action == commonconst.PLAYER_ACTION_CALL then
        result = Game.playercall(seat, num)                
    elseif action == commonconst.PLAYER_ACTION_CHECK then
        result = Game.playercheck(seat)                
    elseif action == commonconst.PLAYER_ACTION_FOLD then
        result = Game.playerfold(seat)                 
    elseif action == commonconst.PLAYER_ACTION_RAISE then
        result = Game.playerraise(seat, num)               
    elseif action == commonconst.PLAYER_ACTION_ALL_IN then
        result = Game.playerallin(seat, num)               
    else 
        --其余行为只作日志用
    end

    if not result then
        --出错的话默认弃牌
        Game.playerfold(seat)
        action = commonconst.PLAYER_ACTION_FOLD
        num = 0
    else
        if msghelper.is_othersteal(index) then
            seat.othersteal_num = seat.othersteal_num + 1
        end 
    end

    --通知行为结果
    local actionresultmsg = {}
    actionresultmsg.rid = seat.rid
    actionresultmsg.seat_index = seat.index
    actionresultmsg.action_type = action
    actionresultmsg.action_num = num
    actionresultmsg.chips = seat.chips
    actionresultmsg.bet_chips = seat.bet_chips

    msghelper.sendmsg_toalltableplayer("actionresult", actionresultmsg) 

    srecord.insert("actionresult", actionresultmsg)
end
--分析玩家可操作的行为
function Game.analyse_allow_action(index, doactionmsg)
    local seat = msghelper.get_seat_byindex(index)
    local diff_chips = table_data.highest_bet - seat.bet_chips

    doactionmsg.call_num = 0
    doactionmsg.bet_min = 0
    doactionmsg.bet_max = 0

    --没人下注的情况
    if table_data.highest_bet == 0 then
        doactionmsg.bet_min = table_data.big_blinds
        --doactionmsg.bet_max = math.min(seat.chips, Game.get_otherplayer_maxchip(index))
        doactionmsg.bet_max = seat.chips

        if seat.chips > doactionmsg.bet_min then
            table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_BET)
        end
        --允许allin
        if doactionmsg.bet_max == seat.chips then
            table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_ALL_IN)
        end
        table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_CHECK)
        table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_FOLD)
    --有人下注的情况
    else
        doactionmsg.bet_min = diff_chips + table_data.last_raise_diff
        --doactionmsg.bet_max = math.min(seat.chips, Game.get_otherplayer_maxchipwithbetchips(index) - seat.bet_chips)
        doactionmsg.bet_max = seat.chips
        if doactionmsg.bet_min > doactionmsg.bet_max then        
            doactionmsg.bet_min = doactionmsg.bet_max
        end
        if diff_chips == 0 then
            table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_CHECK)
        end
        if diff_chips ~= 0 and seat.chips > diff_chips then
            table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_CALL)
            doactionmsg.call_num = diff_chips
        else
        
            --在不能call的时候用call_num保存
            doactionmsg.call_num = 0
        end

        --允许加注
        if seat.chips >= doactionmsg.bet_min
            and doactionmsg.bet_max > diff_chips
            and seat.chips  > table_data.big_blinds 
            and seat.chips > doactionmsg.call_num + diff_chips then
            table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_RAISE)
        end

        --允许allin
        if doactionmsg.bet_max == seat.chips then
            table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_ALL_IN)
        end
        table.insert(doactionmsg.allow_actions, commonconst.PLAYER_ACTION_FOLD)
    end
end
--分析玩家可以操作的行为
function Game.analyse_and_senddoaction(index)
    local seat = msghelper.get_seat_byindex(index)
    local timeout = timetool.get_time() + table_data.action_time_interval / 100
    local noticemsg = {allow_actions = {}}

    noticemsg.rid = seat.rid
    noticemsg.seat_index = index
    noticemsg.timeout = timeout
    Game.analyse_allow_action(index, noticemsg)
    msghelper.sendmsg_toalltableplayer("doaction", noticemsg)

    srecord.insert("doaction", noticemsg)

    -- 设置table状态
    if table_data.timer_id >= 0 then
        timer.cleartimer(table_data.timer_id)
        table_data.timer_id = -1
    end
    table_data.action_timeout = timeout
    table_data.action_index = index
    msghelper.set_tablestate(commonconst.TABLE_STATE_WAIT_CLIENT_ACTION)

    --设置玩家操作定时器
    local doaction_timermsg = {}
    doaction_timermsg.rid = seat.rid
    doaction_timermsg.seat_index = index
    local timerid = timer.settimer(table_data.action_time_interval, "doaction", doaction_timermsg)
    if table_data.table_state ~= commonconst.TABLE_STATE_WAIT_CLIENT_ACTION and table_data.action_index ~= index then
        timer.cleartimer(timerid)
        return
    end 
    table_data.timer_id = timerid

    --对玩家进行托管处理
    if seat.is_tuoguan then
        --默认出牌处理
        Game.gamedefaultaction()
        msghelper.set_tablestate(commonconst.TABLE_STATE_CONTINUE_ROUND)        
    end
end
-----------------------------------------------------------------------------
--处理玩家主动做操作
function Game.ondoaction(seat_index, action_type, action_num)
    table_data.action_type = action_type
    table_data.action_num = action_num
    msghelper.set_tablestate(commonconst.TABLE_STATE_CONTINUE_ROUND)
    msghelper.write_tableinfo_log("ondoaction", table_data)
    Game.gamerun()
end

--处理玩家取消托管
function Game.oncanceltuoguan(seat_index)
    local seat = msghelper.get_seat_byindex(seat_index)
    if seat.is_tuoguan then
        seat.is_tuoguan = nil
        seat.timeout_times = nil
        --通知桌内所有玩家某玩家取消托管
        local noticemsg = {}
        noticemsg.rid = seat.rid
        noticemsg.is_tuoguan = false
        msghelper.sendmsg_toalltableplayer("playertuoguan", noticemsg)
        return true
    end
end

--处理玩家亮牌
function Game.ondolightcards(seat_index, cards, is_auto)
    --[[
        #通知玩家量牌
        .Cards {
            seat_index 0 : integer
            cards 1 : *integer
        }

        lightcard 83 {
            response {
                cards_list 0 : *Cards(seat_index)
                ispassive 1 : boolean #是否被动亮牌
            }
        }
    ]]
    local noticemsg = {cards_list={}, ispassive=false}
    local playerholecards = {seat_index = seat_index, cards = cards}    
    noticemsg.cards_list[seat_index] = playerholecards
    msghelper.sendmsg_toalltableplayer("lightcard", noticemsg)
    srecord.insert("lightcard", noticemsg)
end

--掉线处理
function Game.ondisconnect(seat)
    msghelper.write_tableinfo_log("ondisconnect", table_data)
    --掉线不做任何处理
    return true
end

--玩家主动操作
function Game.onentertable(rid)
    msghelper.write_tableinfo_log("onentertable", table_data)
end
--玩家主动操作
function Game.onreentertable(rid, seat_index)
    local seat = table_data.tableseats[seat_index]

    local noticemsg = {}
    noticemsg.rid = rid
    noticemsg.seat_index = table_data.action_index
    noticemsg.allow_actions = {}
    noticemsg.holecards = {}
    noticemsg.timeout = table_data.action_timeout

    Game.oncanceltuoguan(seat_index)
        
    if #seat.cards >= 2 then
        noticemsg.holecards = seat.cards
    end

    if table_data.action_index == seat_index then
        Game.analyse_allow_action(seat_index, noticemsg)
    end

    msghelper.sendmsg_totableplayer(seat, "reconnecttable", noticemsg)

    msghelper.write_tableinfo_log("onreentertable", table_data)
end

--玩家被动离开
function Game.leavetable (rid)

    --通知agent 被从桌子踢出
    local noticemsg = {}
    noticemsg.table_id = table_data.table_id
    noticemsg.roomsvr_id = msghelper.get_roomsvr()
    noticemsg.table_address = skynet.self()
    local conf = msghelper.get_table_conf()
    noticemsg.fromrid = conf.table_create_user
    noticemsg.fromlogo = conf.table_create_user_logo
    noticemsg.fromrolename = conf.table_create_user_rolename
     
    if table_data.wait_list[rid] ~= nil then
        msghelper.sendmsg_totablewaitplayer(table_data.wait_list[rid], "kickedfromtable", noticemsg)
        --将玩家从旁观队列移除
        table_data.wait_list[rid] = nil
    end
end
--玩家主动离开
function Game.onleavetable(rid)
    msghelper.write_tableinfo_log("onleavetable", table_data) 
end

function Game.onkickplayer(fromrid, seat_index)
    msghelper.write_tableinfo_log("kickplayer", table_data) 

    -- 通知桌内玩家
    local seat = table_data.tableseats[seat_index]

    if msghelper.is_emptyseat(seat) then
        return
    end
    
    local noticemsg = {}
    noticemsg.seat_index = seat.index
    noticemsg.rid = seat.rid    --agent需要根据这个确定是否清楚桌位信息
    seat.bunko =  commonconst.BUNKO_UNKNOWN
    seat.card_form = commonconst.CARD_FORM_UNKONWN


    --通知agent更新数据
    if Game.is_ingameseat(seat) then

        msghelper.add_recodetotablelog(seat)

        local resutdata = {}
        resutdata.bunko = seat.bunko
        resutdata.winchips = seat.onegame_winchips
        resutdata.rid = seat.rid
        resutdata.card_form = seat.card_form
        resutdata.form_cards = {}
        resutdata.expchange = 0
        resutdata.bet_num = seat.bet_num
        resutdata.raise_num = seat.raise_num
        resutdata.call_num = seat.call_num
        resutdata.threebet_num = seat.threebet_num
        resutdata.steal_num = seat.steal_num
        resutdata.continuebet_num = seat.continuebet_num
        resutdata.othercontinuebet_num = seat.othercontinuebet_num
        resutdata.foldtocontinuebet_num = seat.foldtocontinuebet_num
        resutdata.preflopraise_num = seat.preflopraise_num
        resutdata.steal_num = seat.steal_num
        resutdata.othersteal_num = seat.othersteal_num
        resutdata.foldsteal_num = seat.foldsteal_num
        resutdata.winbb = resutdata.winchips // table_data.big_blinds
        resutdata.round = table_data.round_count - 1
        resutdata.room_type = table_data.table_room_type
        resutdata.match_name = table_data.table_name
        resutdata.is_maxcardform = false
        resutdata.table_record_id = table_data.table_record_id
        resutdata.killfew = 0
        resutdata.match_rank = 0
        --注意playerstandup要比standup先发送
        msghelper.sendmsg_totableplayer(seat, "playerstandup", resutdata)
        Game.add_onegamerecode(seat)

    end

    --msghelper.sendmsg_toalltableplayer("standup", noticemsg)

    noticemsg.seat_state = commonconst.PLAYER_STATE_NO_PLAYER
    msghelper.sendmsg_toalltableplayer("standup", noticemsg)

    -- 加入等待列表
    if table_data.wait_list[seat.rid] == nil then
        local wait_player = {
            rid=seat.rid,
            gatesvr_id = seat.gatesvr_id,
            agent_address = seat.agent_address,
            rolename = seat.playerinfo.rolename,
            logo = seat.playerinfo.logo,
            sex = seat.playerinfo.sex,
            is_robot = seat.is_robot,
        }
        table_data.wait_list[seat.rid] = wait_player    
    end

    --玩家离开座位重置座位数据
    table_data.sitdown_player_num = table_data.sitdown_player_num - 1
    if table_data.sitdown_player_num < 0 then
        table_data.sitdown_player_num = 0
    end

    Game.playerstandup_clearseat(seat)

    msghelper.report_tablestate()
    
    Game.leavetable(noticemsg.rid)

    --尝试调度机器人
    if table_data.applyrobot_timer_id == -1 and msghelper.is_canapplyrobot() then
        local applyrobottimermsg = {table_id=table_data.table_id, robot_num=1}
        table_data.applyrobot_timer_id = timer.settimer(base.get_random(table_data.robot_enter_mintime, table_data.robot_enter_maxtime) * 100, "applyrobot", applyrobottimermsg)        
    end
    
    msghelper.write_tableinfo_log("kickplayer", table_data)  
end

--玩家被动从座位上站起
function Game.standup(seat, reason)
    msghelper.write_tableinfo_log("standup_start", table_data) 

    if msghelper.is_emptyseat(seat) then
        return
    end

    -- 通知桌内玩家
    local noticemsg = {}
    noticemsg.seat_index = seat.index
    noticemsg.reason = reason or 0
    noticemsg.rid = seat.rid    --agent需要根据这个确定是否清楚桌位信息

    seat.bunko =  commonconst.BUNKO_UNKNOWN
    seat.card_form = commonconst.CARD_FORM_UNKONWN

    --通知agent更新数据
    if Game.is_ingameseat(seat) then

        msghelper.add_recodetotablelog(seat)

        local resutdata = {}
        resutdata.bunko = seat.bunko
        resutdata.winchips = seat.onegame_winchips
        resutdata.rid = seat.rid
        resutdata.card_form = seat.card_form
        resutdata.form_cards = {}
        resutdata.expchange = 0
        resutdata.bet_num = seat.bet_num
        resutdata.raise_num = seat.raise_num
        resutdata.call_num = seat.call_num
        resutdata.threebet_num = seat.threebet_num
        resutdata.steal_num = seat.steal_num
        resutdata.continuebet_num = seat.continuebet_num
        resutdata.othercontinuebet_num = seat.othercontinuebet_num
        resutdata.foldtocontinuebet_num = seat.foldtocontinuebet_num
        resutdata.preflopraise_num = seat.preflopraise_num
        resutdata.steal_num = seat.steal_num
        resutdata.othersteal_num = seat.othersteal_num
        resutdata.foldsteal_num = seat.foldsteal_num
        resutdata.winbb = resutdata.winchips // table_data.big_blinds
        resutdata.round = table_data.round_count - 1
        resutdata.room_type = table_data.table_room_type
        resutdata.match_name = table_data.table_name
        resutdata.is_maxcardform = false
        resutdata.table_record_id = table_data.table_record_id
        resutdata.killfew = 0
        resutdata.match_rank = 0
        --注意playerstandup要比standup先发送
        msghelper.sendmsg_totableplayer(seat, "playerstandup", resutdata)

        Game.add_onegamerecode(seat)

    end

    --msghelper.sendmsg_toalltableplayer("standup", noticemsg)

    noticemsg.seat_state = commonconst.PLAYER_STATE_NO_PLAYER
    msghelper.sendmsg_toalltableplayer("standup", noticemsg)

    -- 加入等待列表
    if table_data.wait_list[seat.rid] == nil then
        local wait_player = {
            rid = seat.rid,
            gatesvr_id = seat.gatesvr_id,
            agent_address = seat.agent_address,
            rolename = seat.playerinfo.rolename,
            logo = seat.playerinfo.logo,
            sex = seat.playerinfo.sex,
            is_robot = seat.is_robot,
        }
        table_data.wait_list[seat.rid] = wait_player    
    end

    --玩家离开座位重置座位数据
    table_data.sitdown_player_num = table_data.sitdown_player_num - 1
    if table_data.sitdown_player_num < 0 then
        table_data.sitdown_player_num = 0
    end

    Game.playerstandup_clearseat(seat)

    msghelper.report_tablestate()

    --尝试调度机器人
    if table_data.applyrobot_timer_id == -1 and msghelper.is_canapplyrobot() then
        local applyrobottimermsg = {table_id=table_data.table_id, robot_num=1}
        table_data.applyrobot_timer_id = timer.settimer(base.get_random(table_data.robot_enter_mintime, table_data.robot_enter_maxtime) * 100, "applyrobot", applyrobottimermsg)        
    end
    msghelper.write_tableinfo_log("standup_finish", table_data)  
end
--将玩家主动从座位上站起
function Game.onstandup(seat_index, reason)
    local seat = msghelper.get_seat_byindex(seat_index)

    msghelper.write_tableinfo_log("onstandup_start", table_data) 

    if msghelper.is_emptyseat(seat) then
        return
    end
    
    -- 如果这个时候正在等待这个玩家操作，则默认让他fold
    if table_data.table_state == commonconst.TABLE_STATE_WAIT_CLIENT_ACTION and  table_data.action_index == seat_index then
        table_data.action_type = commonconst.PLAYER_ACTION_FOLD
        table_data.action_num = 0
        msghelper.set_tablestate(commonconst.TABLE_STATE_CONTINUE_ROUND_AND_SITUP)
        Game.gamerun()
    end
    
    -- 通知桌内玩家
    local noticemsg = {}
    noticemsg.seat_index = seat.index
    noticemsg.reason = reason

    seat.bunko =  commonconst.BUNKO_UNKNOWN
    seat.card_form = commonconst.CARD_FORM_UNKONWN
    --通知agent更新数据
    if Game.is_ingameseat(seat) then

        msghelper.add_recodetotablelog(seat)

        local resutdata = {}
        resutdata.bunko = seat.bunko
        resutdata.winchips = seat.onegame_winchips
        resutdata.rid = seat.rid
        resutdata.card_form = seat.card_form
        resutdata.form_cards = {}
        resutdata.expchange = 0
        resutdata.bet_num = seat.bet_num
        resutdata.raise_num = seat.raise_num
        resutdata.call_num = seat.call_num
        resutdata.threebet_num = seat.threebet_num
        resutdata.steal_num = seat.steal_num
        resutdata.continuebet_num = seat.continuebet_num
        resutdata.othercontinuebet_num = seat.othercontinuebet_num
        resutdata.foldtocontinuebet_num = seat.foldtocontinuebet_num
        resutdata.preflopraise_num = seat.preflopraise_num
        resutdata.steal_num = seat.steal_num
        resutdata.othersteal_num = seat.othersteal_num
        resutdata.foldsteal_num = seat.foldsteal_num
        resutdata.winbb = resutdata.winchips // table_data.big_blinds
        resutdata.round = table_data.round_count - 1
        resutdata.room_type = table_data.table_room_type
        resutdata.match_name = table_data.table_name
        resutdata.is_maxcardform = false
        resutdata.table_record_id = table_data.table_record_id
        resutdata.killfew = 0
        resutdata.match_rank = 0
        --注意playerstandup要比standup先发送
        msghelper.sendmsg_totableplayer(seat, "playerstandup", resutdata)
        seat.cards = {}
        Game.add_onegamerecode(seat)
    else
        seat.cards = {}
    end

    noticemsg.seat_state = commonconst.PLAYER_STATE_NO_PLAYER
    msghelper.sendmsg_toalltableplayer("standup", noticemsg)
    seat.state = commonconst.PLAYER_STATE_NO_PLAYER

    -- 加入等待列表
    -- 玩家没有状态的不能进入等待列表
    if table_data.wait_list[seat.rid] == nil then
        local wait_player = {
            rid = seat.rid,
            gatesvr_id = seat.gatesvr_id,
            agent_address = seat.agent_address,
            rolename = seat.playerinfo.rolename,
            logo = seat.playerinfo.logo,
            sex = seat.playerinfo.sex,
            is_robot = seat.is_robot,
        }
        
        table_data.wait_list[seat.rid] = wait_player    
    end

    -- !!注意清除数据必须放在逻辑处理之后
    -- 玩家离开座位重置座位数据
    table_data.sitdown_player_num = table_data.sitdown_player_num - 1
    if table_data.sitdown_player_num < 0 then
        table_data.sitdown_player_num = 0
    end

    Game.playerstandup_clearseat(seat)
    -- 更新房间列表
    msghelper.report_tablestate()

    -- 如果站起后,只有一个玩家了，就直接结束
    if not Game.is_gameend() and Game.get_calcpot_playerNum() == 1 
        and table_data.table_state ~= commonconst.TABLE_STATE_GAME_ONE_REAL_END then
        msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_END)
        Game.gamerun()
    end

    --尝试调度机器人
    if table_data.applyrobot_timer_id == -1 and msghelper.is_canapplyrobot() then
        local applyrobottimermsg = {table_id=table_data.table_id, robot_num=1}
        table_data.applyrobot_timer_id = timer.settimer(base.get_random(table_data.robot_enter_mintime, table_data.robot_enter_maxtime) * 100, "applyrobot", applyrobottimermsg)        
    end

    msghelper.write_tableinfo_log("onstandup_finish", table_data) 
end

--桌主开始游戏
function Game.onstartgame()
    local count = Game.get_waitfornextonegameplayernum()
    if table_data.table_state == commonconst.TABLE_STATE_WAIT_GAME_START and count >= table_data.min_player_num then
        msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_START)
        Game.gamerun()
    elseif table_data.table_state == commonconst.TABLE_STATE_WAIT_GAME_START then
        msghelper.set_tablestate(commonconst.TABLE_STATE_WAIT_MIN_PLAYER)
    end  
end

--玩家主动坐下
function Game.onsitdown(rid, seat_index)

    local seat = msghelper.get_seat_byindex(seat_index)
    seat.state = commonconst.PLAYER_STATE_WAIT_FOR_NEXT_ONE_GAME
    seat.bet_chips = 0
    --通知座位上所有玩家有玩家坐下
    local playersitdownmsg = {
        rid = seat.rid,
        seat = {},
        tableplayerinfo = {},
    }
    --写状态日志
    msghelper.write_tableinfo_log("Game.onsitdown", table_data) 

    msghelper.copy_seatinfo(playersitdownmsg.seat, seat)
    msghelper.copy_tableplayerinfo(playersitdownmsg.tableplayerinfo, seat)
    msghelper.sendmsg_toalltableplayer("playersitdown", playersitdownmsg)

    --判断游戏开始
    local count = Game.get_waitfornextonegameplayernum()

    if table_data.table_state == commonconst.TABLE_STATE_WAIT_MIN_PLAYER and count >= table_data.min_player_num then
        msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_START)
        Game.gamerun()
    end 
end
-------------------------------------------------------------------------------------
--------------------------------------辅助函数---------------------------------------
function Game.gamedefaultaction()
    -- 如果可以看牌就看牌，不行就弃牌
    local notify = {allow_actions = {}}
    local seat = msghelper.get_seat_byindex(table_data.action_index)
    Game.analyse_allow_action(seat.index, notify)

    for _, allow_action in ipairs(notify.allow_actions) do
        if allow_action == commonconst.PLAYER_ACTION_CHECK then
            table_data.action_type = commonconst.PLAYER_ACTION_CHECK
            table_data.action_num = 0
            return
        end
    end
    table_data.action_type = commonconst.PLAYER_ACTION_FOLD
    table_data.action_num = 0
end

--弃牌
function Game.game_action_fold()
    table_data.action_type = commonconst.PLAYER_ACTION_FOLD
    table_data.action_num = 0
end

--连续超时
function Game.game_continuous_timeout(seat_index)
    local seat = msghelper.get_seat_byindex(seat_index)
    local rid = seat.rid

    if seat.timeout_times ~= nil and seat.timeout_times >= table_data.continuous_timeout then
        --强制站起
        Game.onstandup(seat_index, 1) --1代表因为挂机被踢出

        --玩家被动离开
        Game.leavetable(rid)

        --执行连续超时动作
        seat.timeout_times = nil
    else
        msghelper.set_tablestate(commonconst.TABLE_STATE_CONTINUE_ROUND)
        msghelper.gamerun()
    end
end

--超时
function Game.game_timeout()
    --记录超时次数
    local seat = msghelper.get_seat_byindex(table_data.action_index)
    seat.timeout_times = seat.timeout_times or 0
    seat.timeout_times = seat.timeout_times + 1
end

--通知游戏结束
function Game.send_gameend_notify()
    local noticemsg = {}
    noticemsg.roomsvr_id = msghelper.get_roomsvr()
    noticemsg.table_id = table_data.table_id
    noticemsg.table_address = skynet.self()
    msghelper.sendmsg_toalltableplayer("gameend", noticemsg)
end
--通知游戏结果
function Game.send_gameresult_notify()
     
    local noticemsg = {player_results = {}, pot_results = {}}
    for _, seat in ipairs(table_data.tableseats) do
        local result = {}
        result.state = seat.state
        result.index = seat.index
        result.rid = seat.rid
        result.chips = seat.chips
        result.card_form = seat.card_form
        result.win_chips = seat.onegame_winchips
        local calc_pot_player_num = Game.get_calcpot_playerNum()
        if Game.is_calcpotseat(seat) and calc_pot_player_num ~= 1 then
            result.hole_cards = seat.cards
            result.form_cards = seat.form_cards
        end        
        table.insert(noticemsg.player_results, result)
    end

    for _, pot in ipairs(table_data.pots) do
        local pot_result = {}
        pot_result.total_bet = pot.total_bet
        pot_result.win_player_indexes = pot.win_player_indexes
        table.insert(noticemsg.pot_results, pot_result)
    end
    noticemsg.table_record_id = table_data.table_record_id

    msghelper.sendmsg_toalltableplayer("gameresult", noticemsg)

    srecord.insert("gameresult", noticemsg, is_norealplayer)
end 
--通知游戏开始
function Game.send_gamestart_notify()
    local noticemsg = {gameinfo = {}}
    noticemsg.roomsvr_id = msghelper.get_roomsvr()
    noticemsg.table_id = table_data.table_id
    noticemsg.table_address = skynet.self()
    msghelper.copy_tablegameinfo(noticemsg.gameinfo)
    msghelper.sendmsg_toalltableplayer("gamestart", noticemsg)

    srecord.insert("gamestart", noticemsg)
end

--[[
#通知桌子当前的最新状态信息
.SeatInfo {
    seat_index 0 : integer #座位号
    state 1 : integer #座位状态
    rid 2 : integer   #rid
    chips 3 : integer #玩家拥有的筹码
    bet_chips 4 : integer  #玩家已下筹码
    is_tuoguan 5 : boolean #玩家是否托管
    sng_rank 6 : integer   #玩家SNG的排名
}
#通知座位信息
seatsinfo 85 {
    response {
        seats 0 : *SeatInfo
    }       
}
]]
--通知大小盲
function Game.send_bigsmallblind_notify()
    local noticemsg = {
        seats = {}
    }
    local seatinfo = {}
    local seat = table_data.tableseats[table_data.small_blinds_index]
    msghelper.copy_seatinfo(seatinfo, seat)
    table.insert(noticemsg.seats, seatinfo)
    seatinfo = {}
    seat = table_data.tableseats[table_data.big_blinds_index]
    msghelper.copy_seatinfo(seatinfo, seat)
    table.insert(noticemsg.seats, seatinfo)
    msghelper.sendmsg_toalltableplayer("seatsinfo", noticemsg)

    srecord.insert("seatsinfo", noticemsg)
end

--通知发底牌
function Game.send_holecard_notify()
    local noticemsg = {}

    local holecard_record = {}

    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_ingameseat(seat) then
            noticemsg.hole_cards = seat.cards
            filelog.sys_protomsg("holecard:"..seat.rid, "____"..skynet.self().."_game_notice_____", noticemsg)
            msghelper.sendmsg_totableplayer(seat, "holecard", noticemsg)

            holecard_record[seat.rid] = seat.cards
        end
    end

    --通知旁观玩家
    noticemsg = {}
    for rid, wait in pairs(table_data.wait_list) do
        filelog.sys_protomsg("holecard:"..rid, "____"..skynet.self().."_game_notice_____", noticemsg)
        msghelper.sendmsg_totablewaitplayer(wait, "holecard", noticemsg)      
    end

    srecord.insert("holecard", holecard_record)
end

--通知奖池信息
function Game.send_potsinfo_notify()
    local noticemsg = { pots = {}}
    for _, pot in ipairs(table_data.pots) do
        local table_pot = {}
        table_pot.total_bet = pot.total_bet
        table_pot.sub_chips_curround = pot.sub_chips_curround
        table.insert(noticemsg.pots, table_pot)
    end 

    msghelper.sendmsg_toalltableplayer("potsinfo", noticemsg)
    srecord.insert("potsinfo", noticemsg)
end

--通知翻牌信息
function Game.send_flopcardinfo_notify()
    local noticemsg = {flop_cards = {}}
    Game.deal_card(table_data.deck_cards, table_data.community_cards)
    Game.deal_card(table_data.deck_cards, table_data.community_cards)
    Game.deal_card(table_data.deck_cards, table_data.community_cards)

    table.insert(noticemsg.flop_cards, table_data.community_cards[1])
    table.insert(noticemsg.flop_cards, table_data.community_cards[2])
    table.insert(noticemsg.flop_cards, table_data.community_cards[3])

    msghelper.sendmsg_toalltableplayer("flopcardinfo", noticemsg)
    srecord.insert("flopcardinfo", noticemsg)
end

--通知转牌信息
function Game.send_turncardinfo_notify()
    local noticemsg = {}
    Game.deal_card(table_data.deck_cards, table_data.community_cards)
    noticemsg.turn_card = table_data.community_cards[4]
    msghelper.sendmsg_toalltableplayer("turncardinfo", noticemsg)
    srecord.insert("turncardinfo", noticemsg)
end

--通知河牌信息
function Game.send_rivercardinfo_notify()
    local noticemsg = {}
    Game.deal_card(table_data.deck_cards, table_data.community_cards)
    noticemsg.river_card = table_data.community_cards[5]
    msghelper.sendmsg_toalltableplayer("rivercardinfo", noticemsg)
    srecord.insert("rivercardinfo", noticemsg)
end

--通知牌桌所有玩家当前局的牌桌历史
function Game.send_onegamerecode_notify()
    local noticemsg = { 
        onegamerecode = onegamerecode,
        system_recovery=system_recovery,
        table_record_id = table_data.table_record_id,
    }
    msghelper.sendmsg_toalltableplayer("reviewboard", noticemsg)    
    srecord.insert("reviewboard", noticemsg)
end
--给玩家发牌
function Game.deal_card(deck_cards, cards)
    table.insert(cards, deck_cards[1])
    table.remove(deck_cards, 1)
end


--取得当前等待游戏开始的玩家数
function Game.get_waitfornextonegameplayernum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if seat.state == commonconst.PLAYER_STATE_WAIT_FOR_NEXT_ONE_GAME then
            count = count + 1
        end
    end
    return count
end
--取得当前在游戏中的玩家数
function Game.get_ingameplayernum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_ingameseat(seat) then
            count = count + 1
        end
    end
    return count    
end

--取得当前可以操作的玩家数
function Game.get_actionable_playernum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_actionableseat(seat) then
            count = count + 1
        end
    end
    return count
end

--取得当局获得胜利的玩家数
function Game.get_gamewin_playernum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if seat.bunko == commonconst.BUNKO_WIN then
            count = count + 1
        end
    end
    return count    
end

--取得其他玩家的最大筹码
function Game.get_otherplayer_maxchip(index)
    local max_chip = 0
    for i, seat in ipairs(table_data.tableseats) do
        if i ~= index and Game.is_calcpotseat(seat) then
            if seat.chips > max_chip then 
                max_chip = seat.chips
            end
        end
    end
    return max_chip
end
function Game.get_otherplayer_maxchipwithbetchips(index)
    local max_chip = 0
    local total_chip = 0
    for i, seat in ipairs(table_data.tableseats) do
        if i ~= index and Game.is_calcpotseat(seat) then
            total_chip = seat.chips + seat.bet_chips
            if total_chip > max_chip then 
                max_chip = total_chip
            end
        end
    end
    return max_chip
end

function Game.get_calcpot_playerNum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if Game.is_calcpotseat(seat) then
            count = count + 1
        end
    end
    return count
end

function Game.get_allin_playernum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if seat.state == commonconst.PLAYER_STATE_ALL_IN then
            count = count + 1
        end
    end
    return count
end

function Game.get_ingamenotfold_playernum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if seat.state == commonconst.PLAYER_STATE_ALL_IN or seat.state == commonconst.PLAYER_STATE_PLAYING then
            count = count + 1
        end
    end
    return count
end

function Game.get_ingamefold_playernum()
    local count = 0
    for _, seat in ipairs(table_data.tableseats) do
        if seat.state == commonconst.PLAYER_STATE_FOLD then
            count = count + 1
        end
    end
    return count    
end

function Game.is_hasplayerbet()
    for _, seat in ipairs(table_data.tableseats) do
        if seat.bet_chips ~= 0 then
            return true
        end
    end
    return false
end

function Game.is_waitfornextroundseat(seat)
    return (seat.state == commonconst.PLAYER_STATE_WAIT_FOR_NEXT_ONE_GAME)
end

function Game.is_ingameseat(seat)
    if seat.state ~= commonconst.PLAYER_STATE_NO_PLAYER and seat.state ~= commonconst.PLAYER_STATE_WAIT_FOR_NEXT_ONE_GAME then
        return true
    end
    return false
end

function Game.is_noplayer(seat)
    if seat.state == commonconst.PLAYER_STATE_NO_PLAYER then
        return true
    end
    return false
end

function Game.is_actionableseat(seat)
    if seat.state == commonconst.PLAYER_STATE_PLAYING then
        return true
    end
    return false
end

function Game.is_calcpotseat(seat)
    return (seat.state == commonconst.PLAYER_STATE_PLAYING or seat.state == commonconst.PLAYER_STATE_ALL_IN)
end

--是否游戏结束
function Game.is_gameend()
    local tablestate = table_data.table_state 
    if tablestate == commonconst.TABLE_STATE_WAIT_MIN_PLAYER or tablestate == commonconst.TABLE_STATE_GAME_END then
        return true
    end
    return false
end

--指定座位是否在上一局游戏中
function Game.is_inlastgameseats(index)
    for _, gameseatinfo in pairs(table_data.gameseat_list) do
        if gameseatinfo.seat_index == index then
            return true
        end
    end
    return false
end

--找到下一个庄家位置
function Game.find_nextbutton_index(index)
    local seat 
    local ingame_player_num = Game.get_ingameplayernum()
    --设置庄家位置
    for i=1, #(table_data.tableseats)-1 do
        local next_index = (index + i) % 9
        if next_index == 0 then
            next_index = 9
        end
        seat = msghelper.get_seat_byindex(next_index)
        if (ingame_player_num == 2 or tabletool.is_emptytable(table_data.gameseat_list)) and Game.is_ingameseat(seat) then
            return false, next_index
        elseif ingame_player_num > 2 and not tabletool.is_emptytable(table_data.gameseat_list) then
            --空button
            --计算上局button位后连续被打掉的玩家数
            local out_player_num = 0
            local gameseatinfo
            local tmp_index
            local is_out_smallblind = false
            for i = 2, #(table_data.gameseat_list) do
                gameseatinfo = table_data.gameseat_list[i]
                if table_data.tableseats[gameseatinfo.seat_index].rid ~= gameseatinfo.rid then
                    out_player_num = out_player_num + 1
                    if i == 2 and gameseatinfo.rid ~= 0 then
                        is_out_smallblind = true
                    end
                    tmp_index = i
                else
                    tmp_index = i
                    break
                end

            end
            if out_player_num >= 3 and is_out_smallblind then
                return true, table_data.gameseat_list[tmp_index-2].seat_index
            elseif  out_player_num == 2 and is_out_smallblind then
                return true, table_data.gameseat_list[2].seat_index
            else
                return false, table_data.gameseat_list[2].seat_index                
            end 
        end
    end
    return false, 0
end

--找到小盲位置
function Game.find_smallblinds_index()
    local seat 
    local ingame_player_num = Game.get_ingameplayernum()
    --设置庄家位置
    for i=1, #(table_data.tableseats)-1 do
        local next_index = (table_data.button_index + i) % 9
        if next_index == 0 then
            next_index = 9
        end
        seat = msghelper.get_seat_byindex(next_index)
        if ingame_player_num == 2 and Game.is_ingameseat(seat) then
            return next_index
        elseif Game.is_inlastgameseats(next_index) or Game.is_ingameseat(seat) then
            return next_index
        end
    end
    return 0
end

--找到大盲位置
function Game.find_bigblinds_index()
    local seat 
    --设置庄家位置
    for i=1, #(table_data.tableseats)-1 do
        local next_index = (table_data.small_blinds_index + i) % 9
        if next_index == 0 then
            next_index = 9
        end
        seat = msghelper.get_seat_byindex(next_index)
        if Game.is_ingameseat(seat) then
            return next_index
        end
    end
    return 0    
end

--找到下一个行动玩家的位置
function Game.find_nextactionplayer_index(index)
    local seat 
    --设置庄家位置
    for i=1, #(table_data.tableseats) - 1 do
        local next_index = (index + i) % 9
        if next_index == 0 then
            next_index = 9
        end
        if next_index == table_data.round_end_index then
            return 0
        end
        seat = msghelper.get_seat_byindex(next_index)
        if Game.is_actionableseat(seat) then
            return next_index
        end
    end
    return 0
end

--找到所有正在游戏的玩家（不包含ALLIN的玩家）
function Game.find_playing_seats()
   local allplayingseats = {}
   for _, seat in ipairs(table_data.tableseats) do
        if seat.state == commonconst.PLAYER_STATE_PLAYING then
            table.insert(allplayingseats, seat)
        end
    end
   return allplayingseats
end

--座位是否是当前还在游戏中的玩家最高的
function Game.is_ingame_highest(playerseat)
   local allingameseats = {}
   for _, seat in ipairs(table_data.tableseats) do
        if seat.state == commonconst.PLAYER_STATE_PLAYING or seat.state == commonconst.PLAYER_STATE_ALL_IN then
            table.insert(allingameseats, seat)
        end
   end

   if #allingameseats > 0 then
       table.sort(allingameseats, function(seat1, seat2)
            return seat1.bet_chips > seat2.bet_chips
       end)
       
       if playerseat.bet_chips >= allingameseats[1].bet_chips then
            return true
       else
            return false
       end
   else
        return true
   end
end
function Game.add_onegamerecode(seat)
    local onerecode = {}
    onerecode.index = seat.index
    onerecode.rid = seat.rid
    onerecode.card_form = seat.card_form
    onerecode.form_cards = seat.form_cards
    onerecode.hole_cards = seat.cards
    onerecode.chips = seat.chips
    onerecode.win_chips = seat.onegame_winchips
    onerecode.rolename = seat.playerinfo.rolename

    table.insert(onegamerecode, onerecode)
end

function Game.playerstandup_clearseat(seat)
    table_data.autobuyinplayers[seat.rid] = nil
    seat.cards = {}
    seat.bunko = commonconst.BUNKO_UNKNOWN
    seat.card_form = commonconst.CARD_FORM_UNKONWN
    seat.state = commonconst.PLAYER_STATE_NO_PLAYER
    seat.rid = 0
    seat.form_cards = {}
    seat.gatesvr_id = ""
    seat.agent_address = nil
    seat.carry_chips = 0        --坐下时携带进桌的筹码
    seat.chips = 0              --玩家在牌桌内的筹码
    seat.sng_rank = 0           --玩家SNG的排名
    seat.playerinfo = {}
    seat.onegame_winchips = 0
    seat.outtable_chips = 0
    seat.is_tuoguan = false
    seat.is_robot = false
    seat.is_recoverrobot = nil
    seat.bet_num = 0
    seat.raise_num = 0
    seat.call_num = 0
    seat.threebet_num = 0
    seat.steal_num = 0
    seat.continuebet_num = 0
    seat.current_round = 0
    seat.currentround_betnum = 0
    seat.lastround_betnum = 0
    seat.last_round = 0
    seat.othercontinuebet_num = 0
    seat.foldtocontinuebet_num = 0
    seat.preflopraise_num = 0
    seat.steal_num = 0
    seat.othersteal_num = 0
    seat.foldsteal_num = 0
    seat.is_maxcardform = false              
end



--游戏结束初始化table
function Game.onegameend_inittable()

    table_data.small_blinds_index = 0 --小盲注位置
    table_data.small_blinds_num = 0   --小盲注筹码
    table_data.big_blinds_index = 0   --大盲注位置
    table_data.big_blinds_num = 0     --大盲注筹码
    table_data.action_index = 0       --当前操作玩家的座位号
    table_data.action_timeout = 0     --当前操作玩家到期时间
    table_data.round_count = 0        --记录桌子当前游戏轮数
    table_data.community_cards = nil
    table_data.community_cards = {}   --公共牌
    table_data.is_passive_lightcards = false
    table_data.action_type = 0        --玩家操作类型
    table_data.action_num = 0         --玩家操作数量
    table_data.timer_id = -1          --记录桌子的定时器id
    table_data.round_end_index = 0    --回合结束位置
    table_data.highest_bet = 0        --本轮最高下注
    table_data.last_raise_diff = 0    --上一次下注差额
    table_data.deck_cards = nil    
    table_data.deck_cards = {}        --牌堆
    table_data.pots = nil
    table_data.pots = {}              --记录奖池
    table_data.is_bet = false
end

--游戏开始时初始化座位
function Game.onegamestart_initseat(seat)
    seat.card_form = commonconst.CARD_FORM_UNKONWN
    seat.form_cards = {}
    seat.cards = {} 
    seat.state = commonconst.PLAYER_STATE_PLAYING
    seat.bunko = commonconst.BUNKO_LOSE
    seat.sng_rank = 0
    seat.bet_chips = 0      --玩家已下筹码
    seat.onegame_winchips = 0
    seat.bet_num = 0
    seat.raise_num = 0
    seat.call_num = 0
    seat.threebet_num = 0
    seat.steal_num = 0
    seat.continuebet_num = 0
    seat.current_round = 0
    seat.currentround_betnum = 0
    seat.lastround_betnum = 0
    seat.last_round = 0
    seat.othercontinuebet_num = 0
    seat.foldtocontinuebet_num = 0
    seat.preflopraise_num = 0
    seat.steal_num = 0
    seat.othersteal_num = 0
    seat.foldsteal_num = 0              
    seat.is_maxcardform = false
end

function Game.get_tablelog()
    return tablelog
end

function Game.check_share()
    -- return true, record_id
    -- return false
    return srecord.query_status()
end

return Game