local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "loginsvrhelper"
local auth = require "auth"
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
	}
	local server = msghelper.get_server()
	if request == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求！"
		msghelper:send_resmsgto_client(fd, "LoginRes", responsemsg)
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
		msghelper:send_resmsgto_client(fd, "LoginRes", responsemsg)
		server.tcpmng.close_socket(fd)
		return
	end

	server.tcpmng.create_session(fd, "LoginReq", request)
end

return LoginsvrLogin
