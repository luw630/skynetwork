local roomseatlogic = require "roomseatlogic"
local roomgamelogic = require "roomgamelogic"
local tabletool = require "tabletool"
local timetool = require "timetool"
local timer = require "timer"
require "enum"
local RoomTableLogic = {}

function RoomTableLogic.init(tableobj, conf, roomsvr_id, gametype, seattype)
	if conf == nil or gametype == nil or roomsvr_id == nil then
		filelog.sys_error("RoomTableLogic.init conf == nil")
		return false
	end

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
    	})
    	roomseatlogic.init(seat, count)
    	table.insert(tableobj.seats, seat) 
		count = count + 1
    end

	tableobj.conf = tabletool.deepcopy(conf)
	local game = require(gametype)
	tableobj.gamelogic = game:new()
	roomgamelogic.init(game, tableobj)

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

function RoomTableLogic.get_svr_id(tableobj)
	return tableobj.svr_id
end

function RoomTableLogic.get_sitdown_player_num(tableobj)
	return tableobj.sitdown_player_num
end

return RoomTableLogic