local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local msgproxy = require "msgproxy"
local table = table
require "enum"

local  GetFriendTableList = {}

--[[
//取得创建桌列表请求
message GetFriendTableListReq {
	optional Version version = 1;
}

//取得创建桌列表响应
message GetFriendTableListRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述	
	repeated TableStateItem tablelist = 3; //桌子状态列表
}
]]

function  GetFriendTableList.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("GetFriendTableList.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "GetFriendTableListRes", responsemsg)		
		return
	end

	request.rid = server.rid
	responsemsg = msgproxy.sendrpc_reqmsgto_tablesvrd(server.rid, "getfriendtablelist", request)

	if not msghelper:is_login_success() then
		return
	end

	if responsemsg == nil then
		responsemsg = {
			errcode = EErrCode.ERR_INVALID_REQUEST,
			errcodedes = "无效的请求!"
		}
	end

	msghelper:send_resmsgto_client(fd, "GetFriendTableListRes", responsemsg)
end

return GetFriendTableList

