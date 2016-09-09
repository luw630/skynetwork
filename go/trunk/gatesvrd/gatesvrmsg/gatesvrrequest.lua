local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "gatesvrmsghelper"
local filename = "gatesvrrequestmsg.lua"

local GatesvrRequestMsg = {}

function GatesvrRequestMsg.process(session, source, event, ...)
	local f = GatesvrRequestMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." GatesvrRequestMsg.process invalid event:"..event)
		base.skynet_retpack(nil)
		return nil
	end
	f(...)
end

return GatesvrRequestMsg