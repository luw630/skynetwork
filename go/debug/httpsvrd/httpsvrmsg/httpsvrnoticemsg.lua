local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "httpsvrmsghelper"
local msgproxy = require "msgproxy"
local commonconst = require "common_const"

local filename = "httpsvrnoticemsg.lua"
local HttpsvrNoticeMsg = {}

function HttpsvrNoticeMsg.process(session, source, event, ...)
	local f = HttpsvrNoticeMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." HttpsvrNoticeMsg.process invalid event:"..event)
		return nil
	end
	skynet.retpack(true)
	f(...)
end

return HttpsvrNoticeMsg