local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "httpsvrmsghelper"
local msgproxy = require "msgproxy"
local commonconst = require "common_const"
local base = require "base"

local filename = "httpsvrrequestmsg.lua"
local HttpsvrRequestMsg = {}

function HttpsvrRequestMsg.process(session, source, event, ...)
	local f = HttpsvrRequestMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." HttpsvrRequestMsg.process invalid event:"..event)
		return nil
	end
	f(session, source, ...)
end

function HttpsvrRequestMsg.webclient(session, source, request)
	local agentpool = msghelper.get_agentpool()
	local agentobj = agentpool:create_service()
	if agentobj == nil then
		filelog.sys_error("HttpsvrRequestMsg.webclient: agentpool:create_service failed", request)
		base.skynet_retpack(nil)
	else
		local agent_sessions = msghelper.get_agent_sessions()
		skynet.call(agentobj.service, "lua", "cmd", "start", agentobj.id)			
		agent_sessions[agentobj.id] = agentobj
		agentobj.responsefunc=skynet.response()

		base.pcall(agentobj.responsefunc, true, skynet.call(agentobj.service, "lua", "request", "webclient", request))
		agentobj.responsefunc = nil
		--base.skynet_retpack(skynet.call(agentobj.service, "lua", "request", "webclient", request))
	end
end

function HttpsvrRequestMsg.versioninfo(session, source, request)
	local agentpool = msghelper.get_agentpool()
	local agentobj = agentpool:create_service()
	if agentobj == nil then
		filelog.sys_error("HttpsvrRequestMsg.versioninfo: agentpool:create_service failed", request)
		base.skynet_retpack(nil)
	else
		local agent_sessions = msghelper.get_agent_sessions()
		skynet.call(agentobj.service, "lua", "cmd", "start", agentobj.id)			
		agent_sessions[agentobj.id] = agentobj
		agentobj.responsefunc=skynet.response()

		base.pcall(agentobj.responsefunc, true, skynet.call(agentobj.service, "lua", "request", "versioninfo", request))
		agentobj.responsefunc = nil
		--base.skynet_retpack(skynet.call(agentobj.service, "lua", "request", "versioninfo", request))
	end
end

function HttpsvrRequestMsg.generate_params(session, source, request, rechargeconf)
	local agentpool = msghelper.get_agentpool()
	local agentobj = agentpool:create_service()
	if agentobj == nil then
		filelog.sys_error("HttpsvrRequestMsg.generate_params: agentpool:create_service failed", request, rechargeconf)
		base.skynet_retpack(nil)
	else
		local agent_sessions = msghelper.get_agent_sessions()
		skynet.call(agentobj.service, "lua", "cmd", "start", agentobj.id)			
		agent_sessions[agentobj.id] = agentobj
		agentobj.responsefunc=skynet.response()

		base.pcall(agentobj.responsefunc, true, skynet.call(agentobj.service, "lua", "request", "generate_params", request, rechargeconf))
		agentobj.responsefunc = nil
		--base.skynet_retpack(skynet.call(agentobj.service, "lua", "request", "versioninfo", request))
	end	
end

return HttpsvrRequestMsg