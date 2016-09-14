local logicmng = require "logicmng"
local tabletool = require "tabletool"
local timetool = require "timetool"
local msghelper = require "tablehelper"
local timer = require "timer"
require "enum"
local RoomTableLogic = {}

function RoomTableLogic.init(tableobj, conf, roomsvr_id, gametype, seattype)
	if conf == nil or gametype == nil or roomsvr_id == nil then
		filelog.sys_error("RoomTableLogic.init conf == nil")
		return false
	end
	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic")
	local roomgamelogic = logicmng.get_logicbyname("roomgamelogic")
	tableobj.id = conf.id
	tableobj.svr_id = roomsvr_id

	if conf.room_type == ERoomType.ROOM_TYPE_FRIEND_QUICK 
		or conf.room_type == ERoomType.ROOM_TYPE_FRIEND_SLOW 
		or conf.room_type == ERoomType.ROOM_TYPE_FRIEND_FREE then
		tableobj.state = ETableState.TABLE_STATE_WAIT_START_GAME
	else
		tableobj.state = ETableState.TABLE_STATE_WAIT_MIN_PLAYER
	end

	--初始化座位
	local seatobj = require(seattype)
	local seat
	local count = 1
    while count <= conf.max_player_num do
    	seat = seatobj:new({
    		--Add 座位其他变量
    		pawntype = EPAWNTYPE.PAWN_TYPE_UNKNOW,
    	})
    	roomseatlogic.init(seat, count)
    	table.insert(tableobj.seats, seat) 
		count = count + 1
    end

	tableobj.conf = tabletool.deepcopy(conf)
	local game = require(gametype)
	tableobj.gamelogic = game:new()
	roomgamelogic.init(tableobj.gamelogic, tableobj)

	if conf.retain_time ~= nil and conf.retain_time > 0 then
    	tableobj.delete_table_timer_id = timer.settimer(conf.retain_time*100, "delete_table")
		tableobj.retain_to_time = timetool.get_time() + conf.retain_time
	end

	return true
end

function RoomTableLogic.clear(tableobj)
	tableobj.id = 0
	tableobj.seats = nil --座位信息
	tableobj.waits = nil --旁观队列 
	tableobj.state = 0
	tableobj.sitdown_player_num = 0 --坐下的玩家数
	tableobj.conf = nil
	tableobj.gamelogic = nil
	tableobj.svr_id = ""
	if tableobj.timer_id > 0 then
		timer.cleartimer(tableobj.timer_id)
		tableobj.timer_id = -1
	end

	if tableobj.delete_table_timer_id > 0 then
		timer.cleartimer(tableobj.delete_table_timer_id)
		tableobj.delete_table_timer_id = -1
	end
end

--[[
	seat: nil表示否， 非nil表示是
]]
function RoomTableLogic.entertable(tableobj, request, seat)
	if seat then
		seat.is_tuoguan = EBOOL.FALSE

		--TO ADD 视情况添加解除托管处理 
	else
		local waitinfo = tableobj.waits[request.rid]
		if waitinfo == nil then
			tableobj.waits[request.rid] = {}
			waitinfo = tableobj.waits[request.rid]
			waitinfo.playerinfo = {}
			tableobj.waits[request.rid] = waitinfo			
		end
		waitinfo.rid = request.rid
		waitinfo.gatesvr_id = request.gatesvr_id
		waitinfo.agent_address = request.agent_address
		waitinfo.playerinfo.rolename=request.playerinfo.rolename
		waitinfo.playerinfo.logo=request.playerinfo.rolename
		waitinfo.playerinfo.sex=request.playerinfo.sex
	end
end

function RoomTableLogic.reentertable(tableobj, request, seat)
	
	if seat.is_tuoguan == EBOOL.TRUE then
		seat.is_tuoguan = EBOOL.FALSE
		--TO ADD 添加托管处理
	end

	if tableobj.action_seat_index == seat.index then
		--通知玩家当前该他操作
		local doactionntcmsg = {
			rid = seat.rid,
			roomsvr_seat_index = seat.index,
			action_to_time = tableobj.action_to_time,
		}
		msghelper:sendmsg_to_tableplayer(seat, "DoactionNtc", doactionntcmsg)
	end	
end

function RoomTableLogic.leavetable(tableobj, request, seat)
	tableobj.waits[request.rid] = nil
end

--[[

]]
function RoomTableLogic.sitdowntable(tableobj, request, seat)
	tableobj.waits[request.rid] = nil

	seat.rid = request.rid
	seat.gatesvr_id=request.gatesvr_id
	seat.agent_address = request.agent_address
	seat.playerinfo.rolename=request.playerinfo.rolename
	seat.playerinfo.logo=request.playerinfo.logo
	seat.playerinfo.sex=request.playerinfo.sex
	seat.state = ESeatState.SEAT_STATE_WAIT_START

	local noticemsg = {
		rid = seat.rid,
		seatinfo = {},
		tableplayerinfo = {},
	}
	msghelper:copy_seatinfo(noticemsg.seatinfo, seat)
	msghelper:copy_tableplayerinfo(noticemsg.tableplayerinfo, seat)
	msghelper:sendmsg_to_alltableplayer("SitdownTableNtc", noticemsg)

	if seat.is_tuoguan == EBOOL.TRUE then
		seat.is_tuoguan = EBOOL.FALSE
		--TO ADD 添加托管处理
	end

	local roomgamelogic = logicmng.get_logicbyname("roomgamelogic")

	roomgamelogic.onsitdowntable(tableobj.gamelogic, seat)

	msghelper:report_table_state()
end

function RoomTableLogic.standuptable(tableobj, request, seat)
	local roomgamelogic = logicmng.get_logicbyname("roomgamelogic")
	if tableobj.state == ETableState.TABLE_STATE_WAIT_CLIENT_ACTION 
		and tableobj.action_seat_index == seat.index then
		tableobj.action_type = EActionType.ACTION_TYPE_STANDUP
		roomgamelogic.run(tableobj.gamelogic)
	end

	if roomgamelogic.is_ingame(tableobj.gamelogic, seat) then
		--TO ADD 通知保存需要保存的数据
	end

	tableobj.sitdown_player_num = tableobj.sitdown_player_num - 1 

	local noticemsg = {
		rid = seat.rid, 
		roomsvr_seat_index = seat.index,
		state = seat.state,
		reason = EStandupReason.STANDUP_REASON_ONSTANDUP,
	}
	msghelper:sendmsg_to_alltableplayer("StandupTableNtc", noticemsg)

	seat.state = ESeatState.SEAT_STATE_PLAYING

	if tableobj.waits[seat.rid] == nil then
		local waitinfo = {
			playerinfo = {},
		}
		tableobj.waits[seat.rid] = waitinfo

		waitinfo.rid = request.rid
		waitinfo.gatesvr_id = request.gatesvr_id
		waitinfo.agent_address = request.agent_address
		waitinfo.playerinfo.rolename=request.playerinfo.rolename
		waitinfo.playerinfo.logo=request.playerinfo.rolename
		waitinfo.playerinfo.sex=request.playerinfo.sex
	end

	--初始化座位数据
	roomgamelogic.standup_clear_seat(tableobj.gamelogic, seat)

	msghelper:report_table_state()
end

function RoomTableLogic.startgame(tableobj, request)
	if RoomTableLogic.is_canstartgame(tableobj) then
		local roomgamelogic = logicmng.get_logicbyname("roomgamelogic")
		tableobj.state = ETableState.TABLE_STATE_GAME_START
		roomgamelogic.run(tableobj.gamelogic)
	else
		table_data.state = ETableState.TABLE_STATE_WAIT_MIN_PLAYER
	end
end

function RoomTableLogic.doaction(tableobj, request, seat)
	tableobj.action_type = request.action_type
	tableobj.action_x = request.action_x
	tableobj.action_y = request.action_y
	tableobj.state = ETableState.TABLE_STATE_CONTINUE
	local roomgamelogic = logicmng.get_logicbyname("roomgamelogic")
	roomgamelogic.run(tableobj.gamelogic)
end

function RoomTableLogic.disconnect(tableobj, request, seat)
	seat.gatesvr_id = ""
	seat.agent_address = -1
	seat.is_tuoguan = EBOOL.TRUE

	--TO ADD添加玩家掉线处理
end

function RoomTableLogic.get_svr_id(tableobj)
	return tableobj.svr_id
end

function RoomTableLogic.get_sitdown_player_num(tableobj)
	return tableobj.sitdown_player_num
end

--根据指定桌位号获得一张空座位
function RoomTableLogic.get_emptyseat_by_index(tableobj, index)
	local roomseatlogic = logicmng.get_logicbyname("roomseatlogic")
	if index == nil or index <= 0 or index > tableobj.conf.max_player_num then
		for index, seat in pairs(tableobj.seats) do
			if roomseatlogic.is_empty(seat) then
				return seat
			end
		end
	else
		local seat = tableobj.seats[index]
		if roomseatlogic.is_empty(seat) then
			return seat
		end
	end
	return nil
end

function RoomTableLogic.get_seat_by_rid(tableobj, rid)
	for index, seat in pairs(tableobj.seats) do
		if rid == seat.rid then
			return seat
		end
	end
	return nil
end

--判断桌子是否满了
function RoomTableLogic.is_full(tableobj)
	return (tableobj.sitdown_player_num >= tableobj.conf.max_player_num)
end

--判断当前是否能够开始游戏
function RoomTableLogic.is_canstartgame(tableobj)
	return RoomTableLogic.is_full(tableobj)
end

return RoomTableLogic