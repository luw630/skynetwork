local skynet = require "skynet"
local filelog = require "filelog"
local socket = require "socket"
local eventmng = require "eventmng"
local msghelper = require "agentmsghelper"
local base = require "base"
local configdao = require "configdao"

local AGENT = {}

local session_id
local AGENT_DATA = {
	sessionbegin_time = 0,
}
-------------------------AGENT--------------------------------
local function decode_client_message(...)
end

function  AGENT.init()
	msghelper.init(AGENT)
	eventmng.init(AGENT)
	eventmng.add_eventbyname("request", "agentrequestmsg")
	eventmng.add_eventbyname("cmd", "agentcmdmsg")
end

function AGENT.send_msgto_client(msg,...)
end

function AGENT.send_resmsgto_client(msgname, msg, ...)
end

function AGENT.send_noticemsgto_client(msgname, msg, ...)
end

function AGENT.process_client_message(session, source, ...)
end

function AGENT.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function AGENT.decode_client_message(...)
end
-----------------------------------------------------------------------------------

function AGENT.tostring()
		
end

function AGENT.get_agentdata()
	return AGENT_DATA
end

function AGENT.check_timeout()	
	local now_time = skynet.time() * 100
	local sessiontimeout = configdao.get_common_conf("agentsessiontimeout")
	local timeout = sessiontimeout*100 - (now_time - AGENT_DATA.sessionbegin_time)
	skynet.fork(function()
		skynet.sleep(timeout)
		AGENT.timeout()
	end)
end

function AGENT.timeout()
	msghelper.write_http_info("AGENT.timeout")
	AGENT.agentexit()
end

--此接口被调用时说明本服务不在使用
function AGENT.agentexit()
	--做一些退出前处理
	skynet.send(skynet.getenv("svr_id"), "lua", "cmd", "agentexit", session_id)
	skynet.exit()	
end

function AGENT.get_session_id()
	return session_id
end

function AGENT.set_session_id(id)
	session_id = id
end
function AGENT.start()
	skynet.dispatch("lua", AGENT.process_other_message)	
end

skynet.start(function()
	AGENT.init()
	AGENT.start()
end)
