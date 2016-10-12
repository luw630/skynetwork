local msghelper = require "gatesvrmsghelper"
local auth = require "auth"
local timetool = require "timetool"

require "enum"

local GatesvrEnterGame = {}

function  GatesvrEnterGame.process(session, source, fd, request)
	local responsemsg = {errcode = EErrCode.ERR_SUCCESS,}
	local server = msghelper.get_server()
	
	if request == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_PARAMS
		responsemsg.errcodedes = "参数为空！"
		msghelper:send_resmsgto_client(fd, "EnterGameRes", responsemsg)
		server.tcpmng.close_socket(fd)
		return
	end	

	--验证玩家登陆的合法性
	if  timetool.get_time() >= request.expiretime then
		--token 过期需要重新验证
		responsemsg.isreauth = EBOOL.TRUE
		msghelper:send_resmsgto_client(fd, "EnterGameRes", responsemsg)
		server.tcpmng.close_socket(fd)
		return		
	end

	if request.uid == nil or request.rid == nil or request.logintoken == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_PARAMS
		responsemsg.errcodedes = "登陆验证失败！"
		msghelper:send_resmsgto_client(fd, "EnterGameRes", responsemsg)
		server.tcpmng.close_socket(fd)
		return		
	end

	if request.rid < 1000000 then
		responsemsg.errcode = EErrCode.ERR_INVALID_PARAMS
		responsemsg.errcodedes = "无效的rid！"
		msghelper:send_resmsgto_client(fd, "EnterGameRes", responsemsg)
		server.tcpmng.close_socket(fd)
		return
	end

	--认证鉴权
	local servertoken = auth.generate_md5token(request.uid.."&"..request.rid.."&"..request.expiretime)
	if servertoken ~= request.logintoken then
		responsemsg.errcode = EErrCode.ERR_INVALID_PARAMS
		responsemsg.errcodedes = "登陆验证失败！"
		msghelper:send_resmsgto_client(fd, "EnterGameRes", responsemsg)
		server.tcpmng.close_socket(fd)
		return
	end

	--认证通过创建player agent
	local result = server.tcpmng.create_session(fd, "EnterGameReq", request)
	if not result then
		responsemsg.errcode = EErrCode.ERR_NET_EXCEPTION
		responsemsg.errcodedes = "网络异常，请重试！"
		msghelper:send_resmsgto_client(fd, "EnterGameRes", responsemsg)
		server.tcpmng.close_socket(fd)
	end
end

return GatesvrEnterGame
