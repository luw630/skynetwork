local skynet = require "skynet"
local filelog = require "filelog"
local msgproxy = require "msgproxy"
local commonconst = require "common_const"
local timer = require "timer"
local configdao = require "configdao"
local base = require "base"
local playerdatadao = require "playerdatadao"
local tabletool = require "tabletool"
local dblog = require "dblog"
local json = require "cjson"
local timetool = require "timetool"
local robotmng = require "robotmanager"
local commondatadao = require "commondatadao"
require "const.enum"
local game
local service
local writelog_tables
local TablesvrmsgHelper = {}

json.encode_sparse_array(true,1,1)

function TablesvrmsgHelper.init(server)
    if server == nil or type(server) ~= "table" then
        skynet.exit()
    end
    service = server

end

function TablesvrmsgHelper.init_game(game_name)
    game = require(game_name)
    game.init(TablesvrmsgHelper, TablesvrmsgHelper.get_tabledata())    
end


function TablesvrmsgHelper.event_process( ... )
    service.process_other_message(nil, nil, ...)
end

--驱动游戏运行
function TablesvrmsgHelper.gamerun()
    game.gamerun()
end

--执行默认操作
function TablesvrmsgHelper.gamedefaultaction()
    game.gamedefaultaction()
end

--执行弃牌操作
function TablesvrmsgHelper.game_action_fold()
    game.game_action_fold()
end

--执行超时操作
function TablesvrmsgHelper.game_timeout()
    game.game_timeout()
end

--执行连续超时操作处理
function TablesvrmsgHelper.game_continuous_timeout(seat_index)
    game.game_continuous_timeout(seat_index)
end

function TablesvrmsgHelper.doaction(seat_index, action_type, action_num)
    game.ondoaction(seat_index, action_type, action_num)
end

function TablesvrmsgHelper.canceltuoguan(seat_index)
    return game.oncanceltuoguan(seat_index)
end

function TablesvrmsgHelper.dolightcards(seat_index, cards, is_auto)
    game.ondolightcards(seat_index, cards, is_auto)
end

function TablesvrmsgHelper.rebuychips(rid, auto_type, default_value, bottom_value)
    local table_data = TablesvrmsgHelper.get_tabledata()
    if auto_type == 0 then
        table_data.autobuyinplayers[rid] = nil
        return
    end
    local rebuyinfo = {
        auto_type = auto_type,
        default_value = default_value,
        bottom_value = bottom_value,
    }

    table_data.autobuyinplayers[rid] = rebuyinfo
end

function TablesvrmsgHelper.disconnect(seat)
    return game.ondisconnect(seat)
end

function TablesvrmsgHelper.entertable(rid, rolename)
    TablesvrmsgHelper.add_tablestateinfo(ETableStateinfoType.TABLE_STATEINFO_SELFENTER, rid, 0, timetool.get_time(), rolename)    
    game.onentertable(rid)
end

function TablesvrmsgHelper.reentertable(rid, seat_index)
    game.onreentertable(rid, seat_index)
end

function TablesvrmsgHelper.leavetable(rid, rolename)
    if game == nil then
        return
    end

    game.onleavetable(rid)
    
    --讲玩家从旁观队列中删除
    TablesvrmsgHelper.del_wait_player(rid)

    TablesvrmsgHelper.add_tablestateinfo(ETableStateinfoType.TABLE_STATEINFO_LEAVE, rid, 0, timetool.get_time(), rolename)
end

--将玩家从座位上站起
function TablesvrmsgHelper.standup(seat_index, ...)
    game.onstandup(seat_index, ...)        
end

--将玩家从座位上踢出
function TablesvrmsgHelper.kickfromtable(rid)
    return game.kickfromtable(rid)
end

--踢掉桌子上的所有玩家
function TablesvrmsgHelper.kickallplayer()
    local table_data = TablesvrmsgHelper.get_tabledata()
    --踢掉桌位上的玩家
    for seat_index, seat in ipairs(table_data.tableseats) do
        if not TablesvrmsgHelper.is_emptyseat(seat) then
            if game.onkickplayer ~= nil then
                game.onkickplayer(0, seat_index, 0)
            end
        end
    end

    --让旁观中的玩家离开
    for rid, _ in pairs(table_data.wait_list) do
        game.leavetable(rid, 0)
    end
end

--强行站起所有玩家
function TablesvrmsgHelper.standupallplayer()
    local table_data = TablesvrmsgHelper.get_tabledata()

    --让旁观中的玩家离开
    for rid, _ in pairs(table_data.wait_list) do
        game.leavetable(rid)
    end

    -- --站起桌位上的玩家
    for seat_index, seat in ipairs(table_data.tableseats) do
        if not TablesvrmsgHelper.is_emptyseat(seat) then
            game.standup(seat)
        end
    end
end

function TablesvrmsgHelper.startgame()
    TablesvrmsgHelper.add_tablestateinfo(ETableStateinfoType.TABLE_STATEINFO_GAMESTART, 0, 0, timetool.get_time())
    game.onstartgame()
end

function TablesvrmsgHelper.is_canapplyrobot()
    local table_data = TablesvrmsgHelper.get_tabledata()
    if table_data.table_room_type == commonconst.ROOM_PRIVATE_TYPE
        or table_data.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE
        or table_data.robot_min_num == nil or table_data.robot_max_num == nil 
        or table_data.robot_min_num <= 0 or table_data.robot_max_num <= 0 then
        return false
    end

    if table_data.sitdown_player_num + base.get_random(2, 4) >= table_data.max_player_num then
        return false
    end
    local robot_num = TablesvrmsgHelper.get_robot_num()
    if table_data.robot_max_num <= robot_num then
        return false
    end

    if robot_num ~= 0 and table_data.robot_type == ERobotType.ROBOT_TYPE_PASSIVE and table_data.sitdown_player_num == robot_num then
        return false
    end

    return true    
end

function TablesvrmsgHelper.try_kick_robot()
    local table_data = TablesvrmsgHelper.get_tabledata()

    if table_data.sitdown_player_num <= 2 then
        return
    end

    if table_data.robot_min_num == nil or table_data.robot_max_num == nil then
        --尝试踢掉机器人
        for index, seat in ipairs(table_data.tableseats) do
            if not TablesvrmsgHelper.is_emptyseat(seat) and robotmng.is_robot(seat.rid) then
                TablesvrmsgHelper.kick_robot(index)
            end 
        end
    end

    local robot_num = TablesvrmsgHelper.get_robot_num()
    if robot_num ~= 0 and table_data.robot_max_num~=0 and robot_num > table_data.robot_max_num then
        for index, seat in ipairs(table_data.tableseats) do
            if not TablesvrmsgHelper.is_emptyseat(seat) and robotmng.is_robot(seat.rid) then
                TablesvrmsgHelper.kick_robot(index)
                robot_num = robot_num - 1
                if robot_num <= table_data.robot_max_num then
                    break
                end
            end 
        end
    end

    if TablesvrmsgHelper.is_full() then
        --尝试踢掉一个机器人
        for index, seat in ipairs(table_data.tableseats) do
            if not TablesvrmsgHelper.is_emptyseat(seat) and robotmng.is_robot(seat.rid) then
                TablesvrmsgHelper.kick_robot(index)
                break
            end 
        end
    end

    --清除处于无效旁观的例子
    local del_wait_list={}
    for rid, wait in pairs(table_data.wait_list) do
        if wait.is_robot then
            table.insert(del_wait_list, rid)
        end
    end
    for _, rid in ipairs(del_wait_list) do
        table_data.wait_list[rid] = nil
    end
end

function TablesvrmsgHelper.try_recover_robot()    
    local table_data = TablesvrmsgHelper.get_tabledata()
    for index, seat in ipairs(table_data.tableseats) do
        if seat.is_recoverrobot then
            TablesvrmsgHelper.apply_robot(1, seat.rid)
        end 
    end
end

function TablesvrmsgHelper.apply_robot(robot_num, robot_rid)
    local table_data = TablesvrmsgHelper.get_tabledata()

    if not TablesvrmsgHelper.is_canapplyrobot()then
       return 
    end

    if robot_num == nil or robot_num <= 0 then
        return
    end

    --这部分逻辑需要调整
    local robot_conf = {
        --桌子的配置信息
        table_id = table_data.table_id,
        table_room_type = table_data.table_room_type,
        table_game_type = table_data.table_game_type,
        min_carry = table_data.min_carry,
        max_carry = table_data.max_carry,      
        --server ID和目标服务的地址
        svr_id = skynet.getenv("svr_id"),
        svr_service_address = skynet.self(),
        continue_time = table_data.robot_continue_time,
        enter_maxtime = table_data.robot_enter_maxtime,
        enter_mintime = table_data.robot_enter_mintime,
        big_blinds = table_data.big_blinds,
        robot_rid = robot_rid,
    }

    robotmng.apply_robot(robot_conf, robot_num)
end

function TablesvrmsgHelper.kick_robot(seat_index)
    if seat_index == nil or seat_index <= 0 then
        return
    end

    if game.onkickplayer ~= nil then
        game.onkickplayer(0, seat_index)
    end
end



--玩家坐下
function TablesvrmsgHelper.sitdown(rid, seat_index, carry_chips, rolename)
    local table_data = TablesvrmsgHelper.get_tabledata()
    
    table_data.sitdown_player_num = table_data.sitdown_player_num + 1

    --游戏坐下处理
    game.onsitdown(rid, seat_index)

    local seat = TablesvrmsgHelper.find_player_seat(rid)
    if carry_chips ~= nil and seat.state ~= commonconst.PLAYER_STATE_WAIT_CONFIRM then
        TablesvrmsgHelper.add_tablestateinfo(ETableStateinfoType.TABLE_STATEINFO_SITDOWN, rid, carry_chips, timetool.get_time(), rolename)
    end

    if table_data.applyrobot_timer_id == -1 and TablesvrmsgHelper.is_canapplyrobot() then
        local applyrobottimermsg = {table_id=table_data.table_id, robot_num=1}
        table_data.applyrobot_timer_id = timer.settimer(base.get_random(table_data.robot_enter_mintime, table_data.robot_enter_maxtime) * 100, "applyrobot", applyrobottimermsg)        
    end
    --上报桌子管理服务器， 桌子状态改变
    TablesvrmsgHelper.report_tablestate()

end

function TablesvrmsgHelper.sendmsg_toalltableplayer(msgname, msg, ...)
    local table_data = service.get_tabledata()
    local status = true
    local is_find = false
    --通知座位上的玩家
    for _, seat in ipairs(table_data.tableseats) do
        if seat.state ~= commonconst.PLAYER_STATE_NO_PLAYER and seat.state ~= commonconst.PLAYER_STATE_SNG_OUT then
            --filelog.sys_protomsg(msgname..":"..seat.rid, "____"..skynet.self().."_game_notice_____", msg)
            if msgname == "tablechat" then
                if msg.rid ~= nil and msg.rid == seat.rid then
                    is_find = true
                end
            end

            if seat.gatesvr_id ~= "" then
                if seat.is_robot and not seat.is_recoverrobot then
                    status = msgproxy.sendrpc_noticemsgto_robotsvrd(seat.gatesvr_id,seat.agent_address, msgname, msg, ...)
                elseif not seat.is_robot then
                    msgproxy.send_noticemsgto_gatesvrd(seat.gatesvr_id,seat.agent_address, msgname, msg, ...)
                end

                if not status then
                    seat.is_recoverrobot = true
                end
            end
        end
    end
    --通知旁观玩家
    local wait_list = tabletool.deepcopy(table_data.wait_list)
    for rid, wait in pairs(wait_list) do
        --filelog.sys_protomsg(msgname..":"..rid, "____"..skynet.self().."_game_notice_____", msg)
        if msgname == "tablechat" then
            if msg.rid ~= nil and msg.rid == rid then
                is_find = true
            end
        end

        if table_data.wait_list[rid] ~= nil and  wait.gatesvr_id ~= "" then
            if wait.is_robot and not wait.is_recoverrobot then
                status = msgproxy.sendrpc_noticemsgto_robotsvrd(wait.gatesvr_id,wait.agent_address, msgname, msg, ...)
            elseif not wait.is_robot then
                msgproxy.send_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, msgname, msg, ...)
            end

            if not status then
                wait.is_recoverrobot = true
            end
        end
    end

    if msgname == "tablechat" and not is_find then
        msgproxy.send_noticemsgto_gatesvrd(msg.sourcesvr_id, msg.service_address, msgname, msg, ...)
    end
end

function TablesvrmsgHelper.sendmsg_toallplayer(msgname, callback)
    local table_data = service.get_tabledata()
    local status = true
    --通知座位上的玩家
    for _, seat in ipairs(table_data.tableseats) do
        if seat.state ~= commonconst.PLAYER_STATE_NO_PLAYER and seat.state ~= commonconst.PLAYER_STATE_SNG_OUT then
            if seat.gatesvr_id ~= "" then
                if seat.is_robot and not seat.is_recoverrobot then
                    status = msgproxy.sendrpc_noticemsgto_robotsvrd(seat.gatesvr_id,seat.agent_address, msgname, callback(seat.rid))
                elseif not seat.is_robot then
                    msgproxy.send_noticemsgto_gatesvrd(seat.gatesvr_id,seat.agent_address, msgname, callback(seat.rid))
                end

                if not status then
                   seat.is_recoverrobot = true 
                end 
            end
        end
    end
    --通知旁观玩家
    local wait_list = tabletool.deepcopy(table_data.wait_list)
    for rid, wait in pairs(wait_list) do
        if table_data.wait_list[rid] ~= nil and wait.gatesvr_id ~= "" then
            if wait.is_robot and not wait.is_recoverrobot then
                status = msgproxy.sendrpc_noticemsgto_robotsvrd(wait.gatesvr_id,wait.agent_address, msgname, callback(rid))
            elseif not wait.is_robot then
                msgproxy.send_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, msgname, callback(rid))
            end
            if not status then
                wait.is_recoverrobot = true
            end
        end
    end
end

function TablesvrmsgHelper.sendmsg_totableplayer(seat, msgname, ...)
    local status = true
    if seat.gatesvr_id ~= nil 
        and seat.agent_address ~= nil 
        and seat.gatesvr_id ~= "" then
        if seat.is_robot and not seat.is_recoverrobot then
            status = msgproxy.sendrpc_noticemsgto_robotsvrd(seat.gatesvr_id,seat.agent_address, msgname, ...)
        elseif not seat.is_robot then
            msgproxy.send_noticemsgto_gatesvrd(seat.gatesvr_id,seat.agent_address, msgname, ...)
        end

        if not status then
            seat.is_recoverrobot = true 
        end 
    end
end

function TablesvrmsgHelper.sendmsg_totablewaitplayer(wait, msgname, ...)
    local status = true
    if wait.gatesvr_id ~= nil 
        and wait.agent_address ~= nil 
        and wait.gatesvr_id ~= "" then
        if wait.is_robot and not wait.is_recoverrobot then
            status = msgproxy.sendrpc_noticemsgto_robotsvrd(wait.gatesvr_id,wait.agent_address, msgname, ...)
        elseif not wait.is_robot then
            msgproxy.send_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, msgname, ...)
        end
        if not status then
            wait.is_recoverrobot = true
        end
    end
end

function TablesvrmsgHelper.get_tablestate()
    return service.get_tablestate()
end

function TablesvrmsgHelper.set_tablestate(state)
    service.set_tablestate(state)
end

function TablesvrmsgHelper.get_game_draw()
    local table_data = TablesvrmsgHelper.get_tabledata()
    return math.ceil(table_data.big_blinds * table_data.game_draw_rate  / 100)    
end


function TablesvrmsgHelper.is_emptyseat(seat)
    if seat == nil or seat.rid == 0 or seat.state == commonconst.PLAYER_STATE_NO_PLAYER then
        return true
    end
    return false
end


function TablesvrmsgHelper.copy_tablegameinfo(gameinfo)
    local table_data = service.get_tabledata()
    local conf = service.get_table_conf()
    --桌子配置信息
    gameinfo.table_id = table_data.table_id
    gameinfo.table_room_type = table_data.table_room_type
    gameinfo.small_blinds = table_data.small_blinds
    gameinfo.big_blinds = table_data.big_blinds
    gameinfo.max_player_num = table_data.max_player_num
    gameinfo.min_player_num = table_data.min_player_num
    gameinfo.min_carry = table_data.min_carry
    gameinfo.max_carry = table_data.max_carry
    gameinfo.table_name = table_data.table_name     
    gameinfo.prop_price = table_data.prop_price
    gameinfo.action_internal_time = table_data.action_time_interval*10
    gameinfo.ante = table_data.ante
    --桌子的状态信息
    gameinfo.table_state = table_data.table_state
    gameinfo.button_index = table_data.button_index
    gameinfo.small_blinds_index = table_data.small_blinds_index
    gameinfo.small_blinds_num = table_data.small_blinds
    gameinfo.big_blinds_index = table_data.big_blinds_index
    gameinfo.big_blinds_num = table_data.big_blinds
    gameinfo.community_cards = table_data.community_cards
    gameinfo.action_index = table_data.action_index
    gameinfo.action_timeout = table_data.action_timeout        
    gameinfo.identify_code = conf.identify_code
    gameinfo.create_table_rid = conf.table_create_user
    gameinfo.round_count = table_data.round_count
    if conf.retain_time ~= nil and conf.table_create_time ~= nil then
        gameinfo.table_retain_time = conf.table_create_time + conf.retain_time
    end
    gameinfo.is_control = conf.is_control
    gameinfo.seats = {}
    gameinfo.tableplayerinfos = {}
    gameinfo.table_pots = {}
    for _, seat in ipairs(table_data.tableseats) do
        local seatinfo = {}
        TablesvrmsgHelper.copy_seatinfo(seatinfo, seat)
        table.insert(gameinfo.seats, seatinfo)
        if not TablesvrmsgHelper.is_emptyseat(seat) then
            gameinfo.tableplayerinfos[seat.rid] = {}
            TablesvrmsgHelper.copy_tableplayerinfo(gameinfo.tableplayerinfos[seat.rid], seat)
        end
    end

    for _, pot in ipairs(table_data.pots) do
        local table_pot = {}
        table_pot.total_bet = pot.total_bet
        table_pot.sub_chips_curround = pot.sub_chips_curround
        table.insert(gameinfo.table_pots, table_pot)
    end

    if game ~= nil and game.get_cur_blind_index ~= nil then
        gameinfo.current_blind_index = game.get_cur_blind_index()
    end

    if game ~= nil and game.get_next_blind_index ~= nil then
        gameinfo.next_blind_index = game.get_next_blind_index()
    end
end

function TablesvrmsgHelper.copy_seatinfo(seatinfo, seat)
    seatinfo.seat_index = seat.index
    seatinfo.state = seat.state
    seatinfo.rid = seat.rid
    seatinfo.chips = seat.chips
    seatinfo.bet_chips = seat.bet_chips
    seatinfo.is_tuoguan = seat.is_tuoguan
    seatinfo.sng_rank = seat.sng_rank
end

function TablesvrmsgHelper.copy_tableplayerinfo(tableplayerinfo, seat)
    tableplayerinfo.rid = seat.rid
    tableplayerinfo.rolename = seat.playerinfo.rolename
    tableplayerinfo.logo = seat.playerinfo.logo
    tableplayerinfo.sex = seat.playerinfo.sex
end

function TablesvrmsgHelper.set_table_conf(conf)
    service.set_table_conf(conf)
end

function TablesvrmsgHelper.get_table_conf()
    return service.get_table_conf()
end

function TablesvrmsgHelper.get_tabledata()
    return service.get_tabledata()
end

function TablesvrmsgHelper.set_roomsvr(address)
    service.set_roomsvr(address)
end

function TablesvrmsgHelper.get_roomsvr()
    return service.get_roomsvr()
end

function TablesvrmsgHelper.get_game()
    return game
end

function TablesvrmsgHelper.get_robot_num()
    local table_data = TablesvrmsgHelper.get_tabledata()
    local count = 0
    for seat_index, seat in ipairs(table_data.tableseats) do
        if not TablesvrmsgHelper.is_emptyseat(seat) then
            if robotmng.is_robot(seat.rid) then
                count = count + 1
            end
        end
    end
    return count
end

function TablesvrmsgHelper.get_player_num()
    local table_data = TablesvrmsgHelper.get_tabledata()
    return table_data.sitdown_player_num - TablesvrmsgHelper.get_robot_num()
end

--判断玩家是否在桌子里
function TablesvrmsgHelper.is_intable(rid)
    local table_data = service.get_tabledata()
    if table_data.wait_list[rid] ~= nil then
        return true
    end

    if TablesvrmsgHelper.find_player_seat(rid) ~= nil then
        return true
    end

    return false    
end

--是否桌上玩家为空
function TablesvrmsgHelper.is_noplayer()
    local table_data = service.get_tabledata()
    if table_data.sitdown_player_num == 0 then
        return true
    end
    return false        
end

--桌子是否在游戏中
function TablesvrmsgHelper.is_gameend()
    return game.is_gameend()
end

--判断是否有空座位
function TablesvrmsgHelper.is_full()
    local table_data = service.get_tabledata()
    if table_data.sitdown_player_num >= table_data.max_player_num then
        return true
    end
    return false
end
--是否删除桌子
function TablesvrmsgHelper.is_updateconf()
    local table_data = TablesvrmsgHelper.get_tabledata()
    return table_data.isneed_updateconf    
end
--是否删除桌子
function TablesvrmsgHelper.is_deletetable()
    local table_data = TablesvrmsgHelper.get_tabledata()
    return (table_data.isdelete and TablesvrmsgHelper.is_noplayer())   
end
--设置是否
function TablesvrmsgHelper.set_isupdateconf(isupdate)
    local table_data = TablesvrmsgHelper.get_tabledata()
    table_data.isneed_updateconf = isupdate
end

function TablesvrmsgHelper.clear_table()
    service.clear()
    game = nil
end

function TablesvrmsgHelper.find_player_seat(rid)
    local table_data = TablesvrmsgHelper.get_tabledata()
    for index , seat in pairs(table_data.tableseats) do
        if seat.rid == rid and seat.state ~= commonconst.PLAYER_STATE_SNG_OUT then
            return seat
        end
    end
    return nil
end

function TablesvrmsgHelper.add_wait_player(rid, wait_player)
    local table_data = TablesvrmsgHelper.get_tabledata()
    if tabletool.getn(table_data.wait_list) >= table_data.max_wait_num then
        return false
    end
    table_data.wait_list[rid] = wait_player
    return true
end

function TablesvrmsgHelper.del_wait_player(rid)
    local table_data = TablesvrmsgHelper.get_tabledata()
    table_data.wait_list[rid] = nil
end

function TablesvrmsgHelper.find_wait_player(rid)
    local table_data = TablesvrmsgHelper.get_tabledata()
    --找到指定的旁观玩家
    return table_data.wait_list[rid]
end

function TablesvrmsgHelper.get_seat_byindex(index)
    local table_data = TablesvrmsgHelper.get_tabledata()
    local table_conf = TablesvrmsgHelper.get_table_conf()
    if index <= 0  then
        --如果是决斗场特殊处理
        if table_data.table_room_type == commonconst.ROOM_DUEL_TYPE then
            if TablesvrmsgHelper.is_emptyseat(table_data.tableseats[4]) then
                return table_data.tableseats[4]
            end

            if TablesvrmsgHelper.is_emptyseat(table_data.tableseats[5]) then
                return table_data.tableseats[5]
            end
        else
            --先随机找一个空座位
            math.randomseed(timetool.get_time())
            index = math.random(math.min(table_conf.max_player_num, #(table_data.tableseats)))
            --index = math.random(#(table_data.tableseats))
            local tmpseat = table_data.tableseats[index]
            if TablesvrmsgHelper.is_emptyseat(tmpseat) then
                return tmpseat
            else
                for _, seat in pairs(table_data.tableseats) do
                    if TablesvrmsgHelper.is_emptyseat(seat) then
                        return seat
                    end 
                end            
            end            
        end
    else
        return table_data.tableseats[index]
    end

    return nil
end

--用于输出指定table_id桌子的信息，方便定位问题
function TablesvrmsgHelper.write_tableinfo_log(...)
    if writelog_tables == nil then
        writelog_tables = configdao.get_common_conf("tables")
    end

    if writelog_tables == nil then
        return
    end
    local table_data = TablesvrmsgHelper.get_tabledata()

    if writelog_tables[table_data.table_id] ~= nil then
        filelog.sys_obj("table", table_data.table_id, ...)           
    end 
end

--记录调试日志
function TablesvrmsgHelper.write_debug_log(classname, objname, ...)
    if base.isdebug() then
        filelog.sys_obj(classname, objname, ...)
    end
end

--给锁定筹码玩家退还筹码
function TablesvrmsgHelper.refund_fixedchips()
    local table_data = service.get_tabledata()
    local table_conf = service.get_table_conf()
    local onlineinfo
    local noticemsg = {
        table_id = table_data.table_id,
        table_create_time = table_conf.table_create_time,
    }
    for rid, _ in pairs(table_data.tablesrecord) do
        onlineinfo = playerdatadao.query_playeronline(rid)
        noticemsg.rid = rid
        if onlineinfo ~= nil and onlineinfo.gatesvr_id ~= "" then
            msgproxy.send_noticemsgto_gatesvrd(
                onlineinfo.gatesvr_id, 
                onlineinfo.gatesvr_service_address, "refund_fixedchips", noticemsg)
        end
    end    
end

--给指定家退还锁定筹码玩
function TablesvrmsgHelper.refund_user_fixedchips(rid)
    local table_data = service.get_tabledata()
    local table_conf = service.get_table_conf()

    local noticemsg = {
        rid = rid,
        table_id = table_data.table_id,
        table_create_time = table_conf.table_create_time,
    }

    local onlineinfo = playerdatadao.query_playeronline(rid)
    if onlineinfo ~= nil and onlineinfo.gatesvr_id ~= "" then
        msgproxy.send_noticemsgto_gatesvrd(
            onlineinfo.gatesvr_id, 
            onlineinfo.gatesvr_service_address, "refund_fixedchips", noticemsg)
    end
end

--完成玩家重购，写入锁定筹码扣除玩家聚众币
function TablesvrmsgHelper.save_user_rebuychips(rid, chips, fixedchips)
    local table_data = service.get_tabledata()
    local table_conf = service.get_table_conf()

    local noticemsg = {
        rid = rid,
        table_id = table_data.table_id,
        table_create_time = table_conf.table_create_time,
        chips = chips,
        fixedchips = fixedchips,
    }

    local onlineinfo = playerdatadao.query_playeronline(rid)
    if onlineinfo ~= nil and onlineinfo.gatesvr_id ~= "" then
        msgproxy.send_noticemsgto_gatesvrd(
            onlineinfo.gatesvr_id, 
            onlineinfo.gatesvr_service_address, "save_user_rebuychips", noticemsg)
    end
end

--发送消息给指定rid玩家
function TablesvrmsgHelper.sendmsg_totableplayer_rid(rid, msgname, msg, ...)
    local onlineinfo = playerdatadao.query_playeronline(rid)
    if onlineinfo ~= nil and onlineinfo.gatesvr_id ~= "" then
        msgproxy.send_noticemsgto_gatesvrd(
            onlineinfo.gatesvr_id, 
            onlineinfo.gatesvr_service_address, msgname, msg, ...)
    end

    return onlineinfo ~= nil and onlineinfo.gatesvr_id ~= "" 
end

--给玩家记录战绩
function TablesvrmsgHelper.save_tablesrecord()
    local table_data = service.get_tabledata()
    local table_conf = service.get_table_conf()
    local is_find_createrid = false
    if (table_data.table_room_type == commonconst.ROOM_PRIVATE_TYPE or table_data.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE) and not table_data.save_tablesrecord then
        table_data.save_tablesrecord = true

        local table_record_item = {}
        table_record_item.table_room_type = table_data.table_room_type

        table_record_item.retain_time = table_conf.retain_time
        if table_data.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE then
            table_record_item.retain_time = timetool.get_time() - table_conf.table_create_time
            table_record_item.signup_fees = {{id=1, num=table_conf.signup_cost}}
        end
        
        table_record_item.create_time = table_conf.table_create_time
        table_record_item.create_user_rid = table_conf.table_create_user
        table_record_item.create_user_rolename = table_conf.table_create_user_rolename
        table_record_item.create_user_logo = table_conf.table_create_user_logo
        table_record_item.player_list = table_data.tablesrecord
                
        for rid, _ in pairs(table_data.tablesrecord) do
            if rid == table_conf.table_create_user then
                is_find_createrid = true
            end
            playerdatadao.save_player_tablerecorditem(rid, table_record_item)
        end

        if not is_find_createrid then
            playerdatadao.save_player_tablerecorditem(table_conf.table_create_user, table_record_item)                        
        end

        commondatadao.delete_friendtable_record(tostring(table_record_item.create_user_rid)..tostring(table_record_item.create_time))
    end
end

function TablesvrmsgHelper.updateconf()
    local table_conf = TablesvrmsgHelper.get_table_conf()

    TablesvrmsgHelper.init_tabledata_conf(table_conf)

    TablesvrmsgHelper.set_isupdateconf(false)
    --上报状态
    TablesvrmsgHelper.report_tablestate()
end

function TablesvrmsgHelper.init_tabledata_conf(conf)
    local table_data = service.get_tabledata()
    table_data.table_room_type = conf.table_room_type
    table_data.small_blinds = conf.small_blinds
    table_data.min_player_num = conf.min_player_num
    table_data.max_player_num = conf.max_player_num
    table_data.big_blinds = conf.big_blinds
    table_data.min_carry = conf.min_carry
    table_data.max_carry =  conf.max_carry
    table_data.game_draw_rate = conf.game_draw_rate
    table_data.prop_price = conf.prop_price
    table_data.table_name = conf.table_name 
    table_data.calculate_win_expbase = conf.calculate_win_expbase
    table_data.calculate_win_expratio = conf.calculate_win_expratio
    table_data.calculate_lose_exp = conf.calculate_lose_exp      
    table_data.everyday_max_exp = conf.everyday_max_exp
    table_data.max_wait_num = conf.max_wait_num
    table_data.action_time_interval = conf.action_timeout
    table_data.table_game_type = conf.table_game_type
    table_data.ante = conf.ante
    table_data.continuous_timeout = conf.continuous_timeout or 2
    table_data.robot_type = conf.robot_type
    table_data.robot_level = conf.robot_level
    table_data.robot_min_num = conf.robot_min_num
    table_data.robot_max_num = conf.robot_max_num
    table_data.robot_continue_time = conf.robot_continue_time
    table_data.robot_enter_maxtime = conf.robot_enter_maxtime
    table_data.robot_enter_mintime = conf.robot_enter_mintime

    --SNG相关配置
    table_data.service_charge = conf.service_charge
    if conf.signup_fee ~= nil then
        for _, value in ipairs(conf.signup_fee) do
            local propitem = tabletool.deepcopy(value)
            table.insert(table_data.signup_fee, propitem)
        end
    end
    table_data.blind_template_index = conf.blind_template_index
    table_data.award_template_index = conf.award_template_index
    table_data.sng_initcarry = conf.sng_initcarry 
end

function TablesvrmsgHelper.report_tablestate()
    local table_data = service.get_tabledata()
    local table_conf = service.get_table_conf()
    --上报table
    local tablestate = {
            table_id = table_data.table_id,
            table_name = table_data.table_name,
            table_room_type = table_data.table_room_type,
            table_curplayernum = table_data.sitdown_player_num,
            table_maxplayernum = table_data.max_player_num,
            table_mincarry = table_data.min_carry,
            table_maxcarry = table_data.max_carry, 
            table_small_blind = table_data.small_blinds,
            table_big_blind = table_data.big_blinds,
            roomsvr_id = service.get_roomsvr(),
            service_charge = table_data.service_charge,
            signup_fee = table_data.signup_fee,
            award_template_index = table_data.award_template_index,
            table_game_type = table_data.table_game_type,
            table_ante = table_data.ante,
            table_state = table_data.table_state,
            table_address = skynet.self(),            
    }

    if table_data.table_room_type == commonconst.ROOM_PRIVATE_TYPE
        or table_data.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE
    then
            tablestate.table_retain_time = table_conf.retain_time
            tablestate.table_create_time = table_conf.table_create_time
            tablestate.table_create_user= table_conf.table_create_user
            tablestate.table_createuser_name = table_conf.table_create_user_rolename
            tablestate.table_createuser_logo = table_conf.table_create_user_logo

            tablestate.table_identify_code = table_conf.identify_code
            tablestate.table_is_control = table_conf.is_control
            tablestate.table_signup_cost = table_conf.signup_cost
            tablestate.table_initial_chips = table_conf.initial_chips
            tablestate.table_service_fee = table_conf.service_fee
            
            tablestate.table_player_list = {}
            local playerinfo
            for _, seat in pairs(table_data.tableseats) do
                if not TablesvrmsgHelper.is_emptyseat(seat) then
                    playerinfo = {}
                    playerinfo.logo = seat.playerinfo.logo
                    playerinfo.rid = seat.rid
                    playerinfo.rolename = seat.playerinfo.rolename
                    tablestate.table_player_list[seat.rid] = playerinfo
                end
            end
    end

    msgproxy.send_broadcastmsgto_tablesvrd("tableupdate", service.get_roomsvr(), tablestate)
end


function TablesvrmsgHelper.report_signup(rid)
    local table_data = service.get_tabledata()
    local tablestate = {
        table_id = table_data.table_id,
        rid = rid,
    }
    msgproxy.send_broadcastmsgto_tablesvrd("tablesignup", service.get_roomsvr(), tablestate)
end

function TablesvrmsgHelper.report_signup_clear(rids)
    local table_data = service.get_tabledata()
    local tablestate = {
        table_id = table_data.table_id,
        rids = rids,
    }
    msgproxy.send_broadcastmsgto_tablesvrd("tablesignupclear", service.get_roomsvr(), tablestate)
end

function TablesvrmsgHelper.add_recodetotablelog(seat)
    local tablelog = game.get_tablelog()
    local onerecode = {}
    onerecode.index = seat.index
    onerecode.rid = seat.rid
    onerecode.card_form = seat.card_form
    onerecode.form_cards = seat.form_cards
    onerecode.hole_cards = seat.cards
    onerecode.chips = seat.chips
    onerecode.win_chips = seat.onegame_winchips
    onerecode.rolename = seat.playerinfo.rolename
    onerecode.timestamp = timetool.get_time()
    table.insert(tablelog.result, onerecode) 
end

function TablesvrmsgHelper.add_tablestateinfo(msgtype, rid, chips, timestamp, rid_name)
    if msgtype == nil or msgtype == 0 then
        return
    end
    local table_data = TablesvrmsgHelper.get_tabledata()
    if table_data.table_room_type == commonconst.ROOM_PRIVATE_TYPE then
        local stateinfo = {msgtype=msgtype, rid=rid, chips=chips, timestamp=timestamp, rid_name=rid_name}
        table.insert(table_data.tablestateinfos, stateinfo)
    end
end

function TablesvrmsgHelper.add_onetablerecord(rid, record)
    return game.add_onetablerecord(rid, record)
end

function TablesvrmsgHelper.write_table_mongolog(logname, log)
    if type(log) ~= "table" or logname == nil then
        return
    end
    for key, value in pairs(log) do
        if type(value) == "table" then
            log[key]=json.encode(value)
        end
    end

    dblog.dblog_write(logname, log)
end


function TablesvrmsgHelper.friendtablerebuy(seat, chips)
    return game.onfriendtablerebuy(seat, chips)
end

function TablesvrmsgHelper.friendsngsign(rid)
    return game.onfriendsngsign(rid)
end

function TablesvrmsgHelper.signup(rid)
    return game.onsignup(rid)
end

function TablesvrmsgHelper.checkgamerun()
    game.checkgamerun()
end

function TablesvrmsgHelper.getfriendsngrules()
    return game.getfriendsngrules()
end

function TablesvrmsgHelper.sharerecord()
    return game.check_share()
end

function TablesvrmsgHelper.get_add_time_cost()
    if game.get_add_time_cost ~= nil then
        return game.get_add_time_cost()
    end
    return nil
end

--是否他人持续加注
function TablesvrmsgHelper.is_othercontinue_bet(rid)
    local table_data = TablesvrmsgHelper.get_tabledata()
    for _, seat in ipairs(table_data.tableseats) do
        if game.is_ingameseat(seat) 
            and seat.rid ~= rid then
            if seat.current_round > 0 
                and seat.currentround_betnum > 0 
                and seat.last_round > 0
                and seat.lastround_betnum > 0 then
                return true
            end 
        end
    end
    return false 
end

--是否面对他人偷盲
function TablesvrmsgHelper.is_othersteal(seat_index)
    local table_data = TablesvrmsgHelper.get_tabledata()
    local seat = table_data.tableseats[table_data.small_blinds_index]
    if table_data.small_blinds_index ~= seat_index 
        and seat.current_round > 0 
        and seat.currentround_betnum > 0 then        
        return true
    end

    seat = table_data.tableseats[table_data.button_index]
    if table_data.button_index ~= seat_index 
        and seat.current_round > 0
        and seat.currentround_betnum > 0 then
        return true
    end

    local next_index = table_data.button_index - 1
    if next_index <= 0 then
        next_index = 9
    end
    seat = table_data.tableseats[next_index]
    if next_index ~= seat_index 
        and seat.current_round > 0
        and seat.currentround_betnum > 0 then
        return true
    end
    return false
end
--是否偷盲
function TablesvrmsgHelper.is_steal(seat_index)
    local table_data = TablesvrmsgHelper.get_tabledata()
    if table_data.small_blinds_index == seat_index then
        return true
    end

    if table_data.button_index == seat_index then
        return true
    end

    local next_index = table_data.button_index - 1
    if next_index <= 0 then
        next_index = 9
    end
    if next_index == seat_index then
        return true
    end
    return false  
end

function TablesvrmsgHelper.set_maxcardform_players()
    local table_data = TablesvrmsgHelper.get_tabledata()
    local game = TablesvrmsgHelper.get_game()
    --找到牌型最大的玩家
    local gamewinchips = {}
    for index, seat in ipairs(table_data.tableseats) do
        if game.is_ingameseat(seat) then
            if gamewinchips[seat.onegame_winchips] == nil then
                gamewinchips[seat.onegame_winchips] = {}
            end
            table.insert(gamewinchips[seat.onegame_winchips], index)
        end        
    end

    local max_win_chips = 0
    for win_chips, indexs in pairs(gamewinchips) do
        if max_win_chips < win_chips then
            max_win_chips = win_chips
        end
    end

    if gamewinchips[max_win_chips] == nil then
        return
    end
    
    for _, index in ipairs(gamewinchips[max_win_chips]) do  
        table_data.tableseats[index].is_maxcardform = true
    end
end

return  TablesvrmsgHelper