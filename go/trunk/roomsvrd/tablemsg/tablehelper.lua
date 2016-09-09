local skynet = require "skynet"
local filelog = require "filelog"
local msgproxy = require "msgproxy"
local configdao = require "configdao"
local base = require "base"
local tabletool = require "tabletool"
local timetool = require "timetool"
local helperbase = require "helperbase"
require "enum"

local TablesvrHelper = helperbase:new({
    writelog_tables = nil,
    })

function TablesvrHelper:sendmsg_to_alltableplayer(msgname, msg, ...)
    local table_data = self.server.table_data
    --通知座位上的玩家
    for _, seat in ipairs(table_data.seats) do
        if seat.state ~= ESeatState.SEAT_STATE_NO_PLAYER and seat.gatesvr_id ~= "" then
            --filelog.sys_protomsg(msgname..":"..seat.rid, "____"..skynet.self().."_game_notice_____", msg)
            msgproxy.sendrpc_noticemsgto_gatesvrd(seat.gatesvr_id,seat.agent_address, msgname, msg, ...)
        end
    end
    --通知旁观玩家
    for rid, wait in pairs(table_data.waits) do
        --filelog.sys_protomsg(msgname..":"..rid, "____"..skynet.self().."_game_notice_____", msg)
        if wait.gatesvr_id ~= "" then
            msgproxy.sendrpc_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, msgname, msg, ...)
        end
    end
end

function TablesvrHelper:sendmsg_to_tableplayer(seat, msgname, ...)
    if seat.state ~= ESeatState.SEAT_STATE_NO_PLAYER and seat.gatesvr_id ~= "" then
        msgproxy.sendrpc_noticemsgto_gatesvrd(seat.gatesvr_id,seat.agent_address, msgname, ...)
    end
end

function TablesvrHelper:sendmsg_to_waitplayer(wait, msgname, ...)
    if wait.gatesvr_id ~= "" then
        msgproxy.sendrpc_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, msgname, ...)
    end
end

function TablesvrHelper:copy_table_gameinfo(gameinfo)
    --[[local table_data = service.get_tabledata()
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
        TablesvrHelper.copy_seatinfo(seatinfo, seat)
        table.insert(gameinfo.seats, seatinfo)
        if not TablesvrHelper.is_emptyseat(seat) then
            gameinfo.tableplayerinfos[seat.rid] = {}
            TablesvrHelper.copy_tableplayerinfo(gameinfo.tableplayerinfos[seat.rid], seat)
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
    end]]
end

function TablesvrHelper:copy_seatinfo(seatinfo, seat)
    --[[seatinfo.seat_index = seat.index
    seatinfo.state = seat.state
    seatinfo.rid = seat.rid
    seatinfo.chips = seat.chips
    seatinfo.bet_chips = seat.bet_chips
    seatinfo.is_tuoguan = seat.is_tuoguan
    seatinfo.sng_rank = seat.sng_rank]]
end

function TablesvrHelper:copy_tableplayerinfo(tableplayerinfo, seat)
    --[[tableplayerinfo.rid = seat.rid
    tableplayerinfo.rolename = seat.playerinfo.rolename
    tableplayerinfo.logo = seat.playerinfo.logo
    tableplayerinfo.sex = seat.playerinfo.sex
    ]]
end


--用于输出指定table_id桌子的信息，方便定位问题
function TablesvrHelper:write_tableinfo_log(...)
    if self.writelog_tables == nil then
        self.writelog_tables = configdao.get_common_conf("tables")
    end

    if self.writelog_tables == nil then
        return
    end
    if self.writelog_tables[self.server.table_data.id] ~= nil then
        filelog.sys_obj("table", self.server.table_data.id, ...)           
    end 
end

--记录调试日志
function TablesvrHelper:write_debug_log(classname, objname, ...)
    if base.isdebug() then
        filelog.sys_obj(classname, objname, ...)
    end
end

function TablesvrHelper:report_table_state()
    local table_data = self.server.table_data
    --上报table
    local table_state = {
        id = table_data.id,
        state = table_data.state,
        name = table_data.conf.name,
        room_type = table_data.conf.room_type,
        game_type = table_data.conf.game_type,
        max_player_num = table_data.conf.max_player_num,
        cur_player_num = table_data.conf.cur_player_num,
        game_time = table_data.conf.game_time,

        retain_to_time = table_data.retain_to_time,
        create_user_rid = table_data.conf.create_user_rid,
        create_user_rolename = table_data.conf.create_user_rolename,
        create_time = table_data.conf.create_time,
        create_table_id = table_data.conf.create_table_id,
        
        roomsvr_id = table_data.svr_id,
        roomsvr_table_address = skynet.self(),        
    }
    msgproxy.sendrpc_broadcastmsgto_tablesvrd("update", table_data.svr_id, tablestate)
end


return  TablesvrHelper