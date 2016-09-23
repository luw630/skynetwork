local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local msgproxy = require "msgproxy"
local processstate = require "processstate"
local table = table
require "enum"

local processing = processstate:new({timeout=4})
local  CreateFriendTable = {}

--[[
//请求创建朋友桌
message CreateFriendTableReq {
	optional Version version = 1;
	optional int32 room_type = 2;
	optional int32 game_type = 3;
	optional string name = 4;
	optional int32 game_time = 5;            --游戏限时单位s
	optional int32 retain_time = 6;          --朋友桌保留时间单位s
	optional int32 action_timeout = 7;       --玩家操作限时
	optional int32 action_timeout_count = 8; --玩家可操作超时次数
}

//响应创建朋友桌
message CreateFriendTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
	optional string create_table_id = 3; //朋友桌索引号
}
]]

function  CreateFriendTable.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("CreateFriendTable.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "CreateFriendTableRes", responsemsg)		
		return
	end

	if processing:is_processing() then
		responsemsg.errcode = EErrCode.ERR_DEADING_LASTREQ
		responsemsg.errcodedes = "正在处理上一次请求！"
		msghelper:send_resmsgto_client(fd, "CreateFriendTableRes", responsemsg)		
		return
	end

	request.rid = server.rid
	request.playerinfo = {
		rolename = server.info.rolename,
		logo = server.info.logo,
	}
	processing:set_process_state(true)
	responsemsg = msgproxy.sendrpc_reqmsgto_roomsvrd(server.rid, nil, nil, "createfriendtable", request)
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

	msghelper:send_resmsgto_client(fd, "CreateFriendTableRes", responsemsg)
end

return CreateFriendTable

