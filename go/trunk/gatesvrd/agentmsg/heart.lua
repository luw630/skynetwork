local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local timetool = require "timetool"
require "enum"

local  Heart = {}

--[[
//心跳包请求
message HeartReq {
	optional Version version = 1;	
}
//心跳包响应
message HeartRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
}
]]

function  Heart.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("Heart.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求!"
		msghelper:send_resmsgto_client(fd, "HeartRes", responsemsg)		
		return
	end

	server.last_heart_time = timetool.get_time()
	responsemsg.servertime = timetool.get_time()

	msghelper:send_resmsgto_client(fd, "HeartRes", responsemsg)
end

return Heart

