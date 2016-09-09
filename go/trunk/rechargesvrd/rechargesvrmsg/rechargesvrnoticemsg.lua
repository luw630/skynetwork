
local filelog = require "filelog"
local filename = "rechargesvrnoticemsg.lua"

local RechargesvrNoticeMsg = {}

function RechargesvrNoticeMsg.process(session, source, event, ...)
	local f = RechargesvrNoticeMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." RechargesvrNoticeMsg.process invalid event:"..event)
		return nil
	end
	f(...)
end

return RechargesvrNoticeMsg