local skynet = require "skynet"
local netpack = require "websocketnetpack"
local filelog = require "filelog"
local sproto = require "mesproto"
local sprotoloader = require "mesprotoloader"
local socket = require "socket"
local eventmng = require "eventmng"
local msghelper = require "agentmsghelper"
local configdao = require "configdao"
local base = require "base"
local timetool = require "timetool"
local requestmsghelper
--local noticemsghelper
local AGENT = {}
local WATCHDOG
local client_fd
local session_id


local AGENT_DATA = {
	sessiontimeout = 0, --单位s
	sessionbegin_time = 0,
	uid = "",
}
-------------------------AGENT--------------------------------
local function decode_client_message(...)
	return requestmsghelper:decode_requestmsg(...)
end

function  AGENT.init()

	requestmsghelper = sprotoloader.load(1):host "package"
	--noticemsghelper = requestmsghelper:attach(sprotoloader.load(2))

	AGENT_DATA.sessiontimeout = configdao.get_common_conf("agentsessiontimeout")
	if AGENT_DATA.sessiontimeout == nil or AGENT_DATA.sessiontimeout == 0 then
		AGENT_DATA.sessiontimeout = 5
	end 

	msghelper.init(AGENT)

	eventmng.init(AGENT)
	eventmng.add_event("gmcommand")
	eventmng.add_eventbyname("cmd", "agentcmd")
	eventmng.add_eventbyname("request", "agentrequestmsg")
end

function AGENT.send_msgto_client(msg,...)
	local tmpmsg, sz = netpack.pack(msg)
	--socket.write(client_fd, netpack.tostring(tmpmsg, sz))	
	socket.write(client_fd, tmpmsg, sz)	
end

function AGENT.send_resmsgto_client(msgname, msg, ...)
	filelog.sys_protomsg(msgname.."__"..skynet.self().."_response", msg, ...)
	local encodemsg = requestmsghelper:encode_responsemsg(msgname, msg)
	if encodemsg == nil then
		filelog.sys_error("AGENT.send_resmsgto_client encodemsg:"..msgname.." failed")
		return
	end
	AGENT.send_msgto_client(encodemsg, ...)
end

function AGENT.send_noticemsgto_client(msgname, msg, ...)
	filelog.sys_protomsg(msgname.."__"..skynet.self().."_notice", msg)
	local encodemsg = requestmsghelper:encode_responsemsg(msgname, msg)
	if encodemsg == nil then
		filelog.sys_error("AGENT.send_noticemsgto_client encodemsg:"..msgname.." failed")
		return
	end	
	AGENT.send_msgto_client(encodemsg, ...)
end


function AGENT.process_client_message(session, source, ...)
	if client_fd == nil or client_fd ~= source then
		filelog.sys_error("AGENT.process_client_message client_fd == nil or client_fd ~= source")
		return
	end
	eventmng.process(session, source, "client", ...)
end

function AGENT.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function AGENT.decode_client_message(...)
	local result,msgname,msg = base.pcall(decode_client_message, ...)
	if not result then
		filelog.sys_error("AGENT.decode_client_message", msgname)
		return nil, nil
	else
		return msgname, msg
	end
	--return requestmsghelper:decode_requestmsg(...)
end
-----------------------------------------------------------------------------------

function AGENT.tostring()
		
end

function AGENT.get_agentdata()
	return AGENT_DATA
end

function AGENT.start_timer()
	local now_time = timetool.get_time() * 100
	local timeout = AGENT_DATA.sessiontimeout*100 - (now_time - AGENT_DATA.sessionbegin_time)
	skynet.fork(function()
		skynet.sleep(timeout)
		AGENT.timeout()
	end)
end

function AGENT.timeout()
	if session_id == nil then
		AGENT.agentfree()
	else
		AGENT.agentexit()
	end
end

function AGENT.create_clientsession(id, conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	client_fd = fd
	session_id = id

	if session_id == nil then
		local result = skynet.call(gate, "lua", "forward", fd, fd)		
		if not result then
			return false
		end
	end

	AGENT_DATA.sessionbegin_time = timetool.get_time() * 100
	AGENT.start_timer()
 	return true
end

--此接口被调用时说明本服务不在使用
function AGENT.agentfree()
	--做一些退出前处理
	skynet.send(WATCHDOG, "lua", "cmd", "agentfree", client_fd)
	skynet.exit()	
end

function AGENT.agentexit()
	--做一些退出前处理
	skynet.send(skynet.getenv("svr_id"), "lua", "cmd", "agentexit", session_id)
	skynet.exit()	
end

function AGENT.start()

	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = AGENT.decode_client_message,
		dispatch = AGENT.process_client_message, 
	}

	skynet.dispatch("lua", AGENT.process_other_message)	
end

skynet.start(function()
	AGENT.init()
	AGENT.start()
end)
