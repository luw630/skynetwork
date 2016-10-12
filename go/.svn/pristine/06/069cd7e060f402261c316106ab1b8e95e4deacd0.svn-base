local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local playerlogindao =  require "dao.playerlogindao"
local configdao = require "configdao"
local tabletool = require "tabletool"
local timetool = require "timetool"
local auth = require "auth"
local gatecachedao = require "gatecachedao"
local gamelog = require "gamelog"
local table = table

require "enum"
local  LoginsvrLogin = {}

--[[
//请求登陆loginsvrd
message LoginReq {
	optional string deviceinfo = 1; //设备信息
	optional string uid = 2;
	optional integer uidtype = 3; //登录账号类型 如: 游客: guest 手机: phone 微信: weixin等
	optional string thirdtoken = 4; 
	optional string username = 5;	
}
//响应登陆loginsvrd
message LoginRes {
	optional integer errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
	optional string uid = 3;
	optional string rid = 4;
	optional string logintoken = 5;   //登录服务器返回的登录token
	optional integer expiretime = 6;  //过期时间（绝对时间）单位s
	repeated GateSvrItem gatesvrs = 7;//gate服务器地址列表 
}
]]

function  LoginsvrLogin.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
		errcodedes = "",
	}
	local server = msghelper:get_server()
	server.uid = request.uid

	local rid = playerlogindao.query_player_rid(request.uid)
	local nowtime = timetool.get_time()
	local isreg = 0
	if rid == nil then
		rid = playerlogindao.get_newplayer_rid(request.uid)
		if rid == nil then
			responsemsg.errcode = EErrCode.ERR_ACCESSDATA_FAILED
			responsemsg.errcodedes = "登陆访问数据失败！"
			msghelper:send_resmsgto_client(fd, "LoginRes", responsemsg)
			server:exit_agent()
			return
		end
		playerlogindao.save_player_rid(request.uid, rid)
		isreg = 1
	end

	--获取gate列表
	local gatesvrlist = gatecachedao.query()
	if tabletool.is_emptytable(gatesvrlist) then
		responsemsg.errcode = EErrCode.ERR_NOGATESVR
		responsemsg.errcodedes = "服务器正在维护中，敬请谅解！"
		msghelper:send_resmsgto_client(fd, "LoginRes", responsemsg)
		server:exit_agent()
		return
	end

	responsemsg.gatesvrs = {}
	for _, gatesvrinfo in pairs(gatesvrlist) do
		table.insert(responsemsg.gatesvrs, gatesvrinfo) 
	end
	table.sort(responsemsg.gatesvrs, function (data1, data2)
		return data1.onlinenum < data2.onlinenum
	end)

	--响应client		
	responsemsg.uid = request.uid
	responsemsg.expiretime = nowtime + configdao.get_common_conf("logintokentimeout")
	responsemsg.rid = rid
	responsemsg.logintoken = auth.generate_md5token(request.uid.."&"..rid.."&"..responsemsg.expiretime)
	msghelper:send_resmsgto_client(fd, "LoginRes", responsemsg)

	gamelog.write_player_loginlog(isreg, request.uid, rid, request.version.regfrom, request.version.platform, request.version.channel, request.version.authtype, request.version.version)

	server:exit_agent()
end

return LoginsvrLogin
