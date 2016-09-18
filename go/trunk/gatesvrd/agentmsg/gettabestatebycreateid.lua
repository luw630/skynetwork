local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local msgproxy = require "msgproxy"
local table = table
require "enum"

local  GetTableStateByCreateId = {}

--[[
//根据创建桌子号获取桌子状态请求
message GetTableStateByCreateIdReq {
	optional Version version = 1;
	optional string create_table_id = 2; 
}

//根据创建桌子号获取桌子状态响应
message GetTableStateByCreateIdRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
	optional TableStateItem tablestate = 3; //桌子状态
}
]]

function  GetTableStateByCreateId.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("GetTableStateByCreateId.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "GetTableStateByCreateIdRes", responsemsg)		
		return
	end

	if request == nil 
		or request.create_table_id == nil 
		or request.create_table_id == "" then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求参数！"
		msghelper:send_resmsgto_client(fd, "GetTableStateByCreateIdRes", responsemsg)		
		return		
	end

	request.rid = server.rid
	responsemsg = msgproxy.sendrpc_reqmsgto_tablesvrd(server.rid, "gettablestatebycreateid", request)

	if not msghelper:is_login_success() then
		return
	end

	if responsemsg == nil then
		responsemsg = {
			errcode = EErrCode.ERR_INVALID_REQUEST,
			errcodedes = "无效的请求!"
		}
	end
	msghelper:send_resmsgto_client(fd, "GetTableStateByCreateIdRes", responsemsg)
end

return GetTableStateByCreateId

