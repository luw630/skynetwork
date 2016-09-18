local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local msgproxy = require "msgproxy"
local processstate = require "processstate"
local table = table
require "enum"

local processing = processstate:new({timeout=4})
local  RequestDM = {}

--[[
//玩家请求点目
message DianMuReq {
	optional Version version = 1;	
	optional int32 id = 2;
	optional string roomsvr_id = 3; //房间服务器id
	optional int32  roomsvr_table_address = 4; //桌子的服务器地址	
	optional int32  action_type = 5;
}


//响应玩家请求操作
message DianMuRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述		
}
]]

function  RequestDM.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("RequestDM.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "DianMuRes", responsemsg)		
		return
	end

	if processing:is_processing() then
		responsemsg.errcode = EErrCode.ERR_DEADING_LASTREQ
		responsemsg.errcodedes = "正在处理上一次请求！"
		msghelper:send_resmsgto_client(fd, "DianMuRes", responsemsg)		
		return
	end

	if server.roomsvr_id == "" 
		or server.roomsvr_table_id <= 0 
		or server.roomsvr_table_address < 0
		or server.roomsvr_seat_index <= 0 then
		responsemsg.errcode = EErrCode.ERR_NOT_INTABLE
		responsemsg.errcodedes = "你已经不在桌内！"
		msghelper:send_resmsgto_client(fd, "DianMuRes", responsemsg)		
		return		
	end

	if server.roomsvr_id ~= request.roomsvr_id 
		or server.roomsvr_table_address ~= request.roomsvr_table_address
		or server.roomsvr_table_id ~= request.id then
		responsemsg.errcode = EErrCode.ERR_INVALID_PARAMS
		responsemsg.errcodedes = "无效的参数！"
		msghelper:send_resmsgto_client(fd, "DianMuRes", responsemsg)				
		return
	end

	request.rid = server.rid
	processing:set_process_state(true)
	responsemsg, seatinfo = msgproxy.sendrpc_reqmsgto_roomsvrd(nil, request.roomsvr_id, request.roomsvr_table_address, "requestdm", request)
	processing:set_process_state(false)

	if not msghelper:is_login_success() then
		return
	end

	if responsemsg == nil then
		responsemsg = {
			errcode = EGateAgentState.ERR_INVALID_REQUEST,
			errcodedes = "无效的请求!",
		}
	end

	msghelper:send_resmsgto_client(fd, "DianMuRes", responsemsg)
end

return RequestDM
