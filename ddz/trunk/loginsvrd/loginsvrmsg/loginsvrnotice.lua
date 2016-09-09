local filelog = require "filelog"
local msghelper = require "loginsvrhelper"
local base = require "base"
local gatecachedao = require "gatecachedao"
require "enum"

local LoginsvrNotice = {}

function LoginsvrNotice.process(session, source, event, ...)
	local f = LoginsvrNotice[event] 
	if f == nil then
		return
	end
	f(...)
end

function LoginsvrNotice.update_gatesvr_state(gatesvrid, gatesvrinfo)
	if gatesvrid == nil or gatesvrinfo == nil then
		return
	end
	gatecachedao.update(gatesvrid, gatesvrinfo)
end

return LoginsvrNotice