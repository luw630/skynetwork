local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local timer = require "timer"
local timetool = require "timetool"
local configdao = require "configdao"
local base = require "base"
local msgproxy = require "msgproxy"
local filename = "tablerequest.lua"

require "enum"

local TableRequest = {}

function TableRequest.process(session, source, event, ...)
	local f = TableRequest[event] 
	if f == nil then
		filelog.sys_error(filename.." TableRequest.process invalid event:"..event)
        return nil
	end
	f(...)
end

function TableRequest.disconnect(request)

end

function TableRequest.entertable(request)
 
end

function TableRequest.reentertable(request)
 
end

function TableRequest.leavetable(request)
 
end

function TableRequest.sitdowntable(request)
 
end

return TableRequest