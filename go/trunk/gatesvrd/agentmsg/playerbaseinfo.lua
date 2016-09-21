local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local playerdatadao = require "playerdatadao"
local table = table
require "enum"

local  PlayerBaseinfo = {}

--[[
//请求玩家基本信息
message PlayerBaseinfoReq {
	optional Version version = 1;
	optional int32 rid = 2;
}

//响应玩家的基本信息
message PlayerBaseinfoRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
	optional PlayerBaseinfo baseinfo = 3; //
}
]]

function  PlayerBaseinfo.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()

	--检查当前登陆状态
	if not msghelper:is_login_success() then
		filelog.sys_warning("PlayerBaseinfo.process invalid server state", server.state)
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求!"
		msghelper:send_resmsgto_client(fd, "PlayerBaseinfoRes", responsemsg)		
		return
	end

	local status, info, playgame, money
	if request.rid == server.rid then
		info = server.info
		playgame = server.playgame
	else
		status, info = playerdatadao.query_player_info(request.rid)
		status, playgame = playerdatadao.query_player_playgame(request.rid)
	end

	if not msghelper:is_login_success() then
		return
	end
	responsemsg.baseinfo = {}
	msghelper:copy_base_info(responsemsg.baseinfo, info, playgame, money)
	msghelper:send_resmsgto_client(fd, "PlayerBaseinfoRes", responsemsg)
end

return PlayerBaseinfo

