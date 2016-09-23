local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local msgproxy = require "msgproxy"
local playerdatadao = require "playerdatadao"
local processstate = require "processstate"
local table = table
require "enum"

local processing = processstate:new({timeout=4})
local  StandupTable = {}

--[[
//请求坐入桌子
message StandupTableReq {
	optional Version version = 1;
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址
}

//响应坐入桌子
message StandupTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述	
}
]]

function  StandupTable.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("StandupTable.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "StandupTableRes", responsemsg)		
		return
	end

	if processing:is_processing() then
		responsemsg.errcode = EErrCode.ERR_DEADING_LASTREQ
		responsemsg.errcodedes = "正在处理上一次请求！"
		msghelper:send_resmsgto_client(fd, "StandupTableRes", responsemsg)		
		return
	end

	if server.roomsvr_id == "" or server.roomsvr_id ~= request.roomsvr_id then
		responsemsg.errcode = EErrCode.ERR_INVALID_PARAMS
		responsemsg.errcodedes = "无效的请求参数！"
		msghelper:send_resmsgto_client(fd, "StandupTableRes", responsemsg)		
		return		
	end

	if server.roomsvr_table_id <= 0 or server.roomsvr_table_id ~= request.id then
		responsemsg.errcode = EErrCode.ERR_INVALID_PARAMS
		responsemsg.errcodedes = "无效的请求参数！"
		msghelper:send_resmsgto_client(fd, "StandupTableRes", responsemsg)		
		return		
	end

	if server.roomsvr_seat_index <= 0 then
		responsemsg.errcode = EErrCode.ERR_HAD_IN_SEAT
		responsemsg.errcodedes = "你已经在座位上，请先站起！"
		msghelper:send_resmsgto_client(fd, "StandupTableRes", responsemsg)		
		return		
	end

	request.rid = server.rid
	request.gatesvr_id = skynet.getenv("svr_id")
	request.agent_address = skynet.self()
	request.playerinfo = {
		rolename = server.info.rolename,
		logo = server.info.logo,
		sex = server.info.sex,
	}	
	processing:set_process_state(true)
	responsemsg = msgproxy.sendrpc_reqmsgto_roomsvrd(nil, server.roomsvr_id, server.roomsvr_table_address, "standuptable", request)
	processing:set_process_state(false)

	if not msghelper:is_login_success() then
		return
	end

	if responsemsg == nil then
		responsemsg = {
			errcode = EGateAgentState.ERR_INVALID_REQUEST,
			errcodedes = "无效的请求!"
		}
	end

	if responsemsg.errcode == EErrCode.ERR_SUCCESS then
		server.roomsvr_seat_index = 0		
		server.online.roomsvr_id = ""
		server.online.roomsvr_table_id = 0
		server.online.roomsvr_table_address = -1
		playerdatadao.save_player_online("update", server.rid, server.online)
	end 

	msghelper:send_resmsgto_client(fd, "StandupTableRes", responsemsg)
end

return StandupTable

