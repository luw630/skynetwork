local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "loginsvrhelper"
local auth = require "auth"
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
	local server = msghelper.get_server()
	if request == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "loginsvrlogin", responsemsg)
		server.tcpmng.close_socket(fd)
		return
	end

	--校验第三方登录是否成功
	local token = string.sub(request.thirdtoken, -6, -1)
	local data = string.sub(request.thirdtoken, 1, 6)
	local auth_token = auth.generate_thirdauth_md5token(data)
	if token ~= auth_token then
		responsemsg.errcode = EErrCode.ERR_VERIFYTOKEN_FAILED
		responsemsg.errcodedes = "登陆验证失败！"
		msghelper:send_resmsgto_client(fd, "loginsvrlogin", responsemsg)
		server.tcpmng.close_socket(fd)
		return
	end

	server.tcpmng.create_session(fd, request)
end

return LoginsvrLogin
