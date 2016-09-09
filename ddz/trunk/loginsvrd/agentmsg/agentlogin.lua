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
loginsvrlogin 2 {
	request {
		version 0 : VersionType
		deviceinfo 1 : string  #设备信息
		uid 2 : string
		uidtype 3 : string		#登录账号类型 如: 游客: guest 手机: phone 微信: weixin等
		thirdtoken 4 : string 
		username 5 : string	
	}

	response {
	    errcode 0 : integer	   #错误原因 0表示成功
		errcodedes 1 : string  #错误描述
		uid 2 : string
		rid 3 : integer
		logintoken 4 : string     #登录服务器返回的登录token
		expiretime 5 : integer     #过期时间（绝对时间）单位s
		gatesvrs 6 : *GateSvrItem  #gate服务器地址列表 
	}
}
]]

function  LoginsvrLogin.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()
	server.uid = request.uid

	local rid = playerlogindao.query_player_rid(request.uid)
	local nowtime = timetool.get_time()
	local isreg = 0
	if rid == nil then
		rid = playerlogindao.get_newplayer_rid()
		if rid == nil then
			responsemsg.errcode = EErrCode.ERR_ACCESSDATA_FAILED
			responsemsg.errcodedes = "登陆访问数据失败！"
			msghelper:send_resmsgto_client(fd, "loginsvrlogin", responsemsg)
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
		msghelper:send_resmsgto_client(fd, "loginsvrlogin", responsemsg)
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
	msghelper:send_resmsgto_client(fd, "loginsvrlogin", responsemsg)

	gamelog.write_player_loginlog(isreg, request.uid, rid, request.version.regfrom, request.version.platform, request.version.channel, request.version.authtype, request.version.version)

	server:exit_agent()
end

return LoginsvrLogin
