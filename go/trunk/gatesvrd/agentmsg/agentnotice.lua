local filelog = require "filelog"
local msghelper = require "agenthelper"
local base = require "base"
require "enum"

local AgentNotice = {}

function AgentNotice.process(session, source, event, ...)
	local f = AgentNotice[event] 
	if f == nil then
		f = AgentNotice["other"]
		f(event, ...)
		return
	end
	f(...)
end


function AgentNotice.other(msgname, noticemsg)
	msghelper:send_noticemsgto_client(nil, msgname, noticemsg)
end

return AgentNotice