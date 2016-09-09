local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablestatesvrhelper"
local base = require "base"

local TableStatesvrRequest = {}

function TableStatesvrRequest.process(session, source, event, ...)
	local f = TableStatesvrRequest[event] 
	if f == nil then
		return
	end
	f(...)
end
return TableStatesvrRequest