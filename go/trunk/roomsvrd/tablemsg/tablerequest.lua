local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local timer = require "timer"
local timetool = require "timetool"
local configdao = require "configdao"
local base = require "base"
local msgproxy = require "msgproxy"
local logicmng = require "logicmng"
local filename = "tablerequest.lua"

require "enum"

local TableRequest = {}

function TableRequest.process(session, source, event, ...)
	local f = TableRequest[event] 
	if f == nil then
		filelog.sys_error(filename.." TableRequest.process invalid event:"..event)
		base.skynet_retpack(nil)
        return nil
	end
	f(...)
end

function TableRequest.disconnect(request)
	local result
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	if request.id ~= table_data.id then
		base.skynet_retpack(false)		
		return
	end

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat == nil then
		base.skynet_retpack(false)		
		return		
	end

	if seat.gatesvr_id ~= request.gatesvr_id 
		or seat.agent_address ~= request.agent_address then
		base.skynet_retpack(false)		
		return		
	end
	base.skynet_retpack(true)
	
	roomtablelogic.disconnect(table_data, request, seat)
end
--[[
//请求进入桌子
message EnterTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址 
}

//响应进入桌子
message EnterTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述	
	optional GameInfo gameinfo = 3;
}
]]
function TableRequest.entertable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seatinfo, seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	
	if request.id ~= table_data.id then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg, nil)		
		return
	end

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat ~= nil then
		seatinfo = {
			index = seat.index,
		}
		seat.gatesvr_id=request.gatesvr_id
		seat.agent_address = request.agent_address
		seat.playerinfo.rolename=request.playerinfo.rolename
		seat.playerinfo.logo=request.playerinfo.logo
		seat.playerinfo.sex=request.playerinfo.sex
	end

	responsemsg.gameinfo = {}
	msghelper:copy_table_gameinfo(responsemsg.gameinfo)
	base.skynet_retpack(responsemsg, seatinfo)
	roomtablelogic.entertable(table_data, request, seat)
end

function TableRequest.reentertable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seatinfo, seat, waitinfo
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)
    waitinfo = table_data.waits[request.rid]
	if seat ~= nil then
		seatinfo = {
			index = seat.index,
		}
		seat.gatesvr_id=request.gatesvr_id
		seat.agent_address = request.agent_address
		seat.playerinfo.rolename=request.playerinfo.rolename
		seat.playerinfo.logo=request.playerinfo.logo
		seat.playerinfo.sex=request.playerinfo.sex
	elseif waitinfo ~= nil then
		waitinfo.gatesvr_id=request.gatesvr_id
		waitinfo.agent_address = request.agent_address
		waitinfo.playerinfo.rolename=request.playerinfo.rolename
		waitinfo.playerinfo.logo=request.playerinfo.logo
		waitinfo.playerinfo.sex=request.playerinfo.sex		
	end

	if waitinfo == nil and seat == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		base.skynet_retpack(responsemsg, seatinfo)
		return
	end

	responsemsg.gameinfo = {}
	msghelper:copy_table_gameinfo(responsemsg.gameinfo)
	base.skynet_retpack(responsemsg, seatinfo)
	if seat ~= nil then
		roomtablelogic.reentertable(table_data, request, seat)	 
	end
end

--[[
//请求离开桌子
message LeaveTableReq {
	optional Version version = 1;	
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
}

//响应离开桌子
message LeaveTableReq {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述			
}
]]
function TableRequest.leavetable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	if request.id ~= table_data.id then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)		
		return
	end

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat == nil then
		roomtablelogic.leavetable(table_data, request, seat)
		base.skynet_retpack(responsemsg)		
		return
	end

	base.skynet_retpack(responsemsg)	
	roomtablelogic.standuptable(table_data, request, seat)
	roomtablelogic.leavetable(table_data, request, seat)	
end

--[[
//请求坐入桌子
message SitdownTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
	optional int32  roomsvr_seat_index = 5; //指定桌位号
}

//响应坐入桌子
message SitdownTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述	
}
]]
function TableRequest.sitdowntable(request)
 	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seatinfo, seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat ~= nil then
		seatinfo = {
			index = seat.index
		}
		seat.gatesvr_id=request.gatesvr_id
		seat.agent_address = request.agent_address
		seat.playerinfo.rolename=request.playerinfo.rolename
		seat.playerinfo.logo=request.playerinfo.logo
		seat.playerinfo.sex=request.playerinfo.sex
		base.skynet_retpack(responsemsg, seatinfo)
	else
		if roomtablelogic.is_full(table_data) then
			responsemsg.errcode = EErrCode.ERR_TABLE_FULL
			responsemsg.errcodedes = "当前桌子已经满了！"
			base.skynet_retpack(responsemsg, seatinfo)
			return
		end

		seat = roomtablelogic.get_emptyseat_by_index(table_data, request.roomsvr_seat_index)
		if seat == nil then
			responsemsg.errcode = EErrCode.ERR_NO_EMPTY_SEAT
			responsemsg.errcodedes = "当前桌子没有空座位了！"
			base.skynet_retpack(responsemsg, seatinfo)
			return			
		end
		seatinfo = {
			index = seat.index,
		}

		--增加桌子人数计数 
		table_data.sitdown_player_num = table_data.sitdown_player_num + 1		
	end
	base.skynet_retpack(responsemsg, seatinfo)

	roomtablelogic.sitdowntable(table_data, request, seat)

end

--[[
//请求从桌子站起
message StandupTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
}

//响应从桌子站起
message StandupTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述		
}
]]
function TableRequest.standuptable(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local seat
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")

	seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)

	if seat == nil then
		responsemsg.errcode = EErrCode.ERR_HAD_STANDUP
		responsemsg.errcodedes = "你已经站起了！"
		base.skynet_retpack(responsemsg)
		return
	end

	base.skynet_retpack(responsemsg)

	roomtablelogic.standuptable(table_data, request, seat)
end
--[[
//桌主请求开始游戏
message StartGameReq {
	optional Version version = 1;	
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址	
}

//响应桌主开始游戏
message StartGameRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述		
}
]]
function TableRequest.startgame(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data

	if table_data.state ~= ETableState.TABLE_STATE_WAIT_GAME_START then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
		return		
	end
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	if roomtablelogic.get_sitdown_player_num(table_data) < table_data.conf.max_player_num then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "人数不够！"
		base.skynet_retpack(responsemsg)
		return	
	end
	base.skynet_retpack(responsemsg)
	roomtablelogic.startgame(table_data, request)
end

function TableRequest.requestdm(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	local seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)
	if seat == nil then
		responsemsg.errcode = EErrCode.ERR_HAD_STANDUP
		responsemsg.errcodedes = "玩家不在座位上！"
		base.skynet_retpack(responsemsg)
		return
	end

	--filelog.sys_info("doaction", table_data.state,table_data.action_seat_index, seat)
	if roomtablelogic.is_onegameend(table_data) == true then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
	end

	base.skynet_retpack(responsemsg)
	roomtablelogic.requestdm(table_data, request, seat)	
end

function TableRequest.doaction(request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS, 
	}
	local server = msghelper:get_server()
	local table_data = server.table_data
	local roomtablelogic = logicmng.get_logicbyname("roomtablelogic")
	local seat = roomtablelogic.get_seat_by_rid(table_data, request.rid)
	if seat == nil then
		responsemsg.errcode = EErrCode.ERR_HAD_STANDUP
		responsemsg.errcodedes = "玩家不在座位上！"
		base.skynet_retpack(responsemsg)
		return
	end

	--filelog.sys_info("doaction", table_data.state,table_data.action_seat_index, seat)
	if table_data.state ~= ETableState.TABLE_STATE_WAIT_CLIENT_ACTION
		or table_data.action_seat_index ~= seat.index then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效请求！"
		base.skynet_retpack(responsemsg)
		return		
	end

	if request.action_type == EActionType.ACTION_TYPE_LAOZI 
		and table_data.gogame:CanMove(seat.index,request.action_x,request.action_y) == 0 then
		responsemsg.errcode = EErrCode.ERR_CANNOT_MOVE
		responsemsg.errcodedes = "不能落子！"
		base.skynet_retpack(responsemsg)
		return		
	end


	base.skynet_retpack(responsemsg)
	roomtablelogic.doaction(table_data, request, seat)		
end

return TableRequest