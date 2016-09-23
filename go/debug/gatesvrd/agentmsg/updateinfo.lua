local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local playerdatadao = require "playerdatadao"
local table = table
require "enum"

local  Updateinfo = {}

--[[
//请求更新玩家信息
message UpdateinfoReq {
	optional Version version = 1;
	optional string rolename = 2; //昵称
    optional string logo = 3;  //logo
    optional string phone = 4; //手机号
    optional int32  sex = 5;   //性别
}

//响应更新玩家信息
message UpdateinfoRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
	optional string rolename = 3; //昵称
    optional string logo = 4;  //logo
    optional string phone = 5; //手机号
    optional int32  sex = 6;   //性别
}
]]

function  Updateinfo.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("Updateinfo.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求!"
		msghelper:send_resmsgto_client(fd, "UpdateinfoRes", responsemsg)		
		return
	end

	local ismodify = false
	if server.info.rolename ~= request.rolename then
		ismodify = true
		server.info.rolename = request.rolename
	end 

	if server.info.logo ~= request.logo then
		ismodify = true
		server.info.logo = request.logo		
	end

	if server.info.phone ~= request.phone then
		ismodify = true
		server.info.phone = request.phone
	end

	if server.info.sex ~= request.sex then
		ismodify = true
		server.info.sex = request.sex
	end

	responsemsg.rolename = server.info.rolename
	responsemsg.logo = server.info.logo
	responsemsg.phone = server.info.phone
	responsemsg.sex = server.info.sex

	if ismodify then
		playerdatadao.save_player_info("update", server.rid, server.info)
	end
	msghelper:send_resmsgto_client(fd, "UpdateinfoRes", responsemsg)
end

return Updateinfo

