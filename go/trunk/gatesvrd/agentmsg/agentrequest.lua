local filelog = require "filelog"
local msghelper = require "agenthelper"
local base = require "base"
require "enum"
local filename = "AgentRequest.lua"

local AgentRequest = {}

function AgentRequest.process(session, source, event, ...)
	local f = AgentRequest[event] 
	if f == nil then
		filelog.sys_error(filename.." AgentRequest.process invalid event:"..event)
		base.skynet_retpack(nil)
		return nil
	end
	f(...)
end

return AgentRequest