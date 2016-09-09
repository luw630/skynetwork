local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local timer = require "timer"
require "enum"

local filename = "tabletimer.lua"

local TableTimer = {}

function TableTimer.process(session, source, event, ...)
	local f = TableTimerMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." TableTimer.process invalid event:"..event)
		return nil
	end
	f(...)	 
end

function TableTimer.doaction(timerid, request)
  
end

function TableTimer.delete_table(timerid, request)
    local server = msghelper:get_server()    
    local table_data = server.table_data
    if table_data.delete_table_timer_id == timerid then
        table_data.delete_table_timer_id = -1
        msghelper:event_process("lua", "cmd", "delete")
    end 
end

return TableTimer