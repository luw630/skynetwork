local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local msgproxy = require "msgproxy"
local configdao = require "configdao"
local base = require "base"
local timetool = require "timetool"
local filename = "agentcmd.lua"
local AgentCMD = {}

function AgentCMD.process(session, source, event, ...)
	local f = AgentCMD[event] 
	if f == nil then
		filelog.sys_error(filename.." Agent AgentCMD.process invalid event:"..event)
		return nil
	end
	f(...)
end

function AgentCMD.start(conf)
	local server = msghelper:get_server()
	base.skynet_retpack(server:create_session(conf))
end

function AgentCMD.close(...)
	local server = msghelper:get_server()
	server:exit_agent(true)
	server:exit_service()
end

return AgentCMD