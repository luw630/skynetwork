local filelog = require "filelog"
local msghelper = require "tablehelper"
local filename = "tablenotice.lua"
local TableNotice = {}

function TableNotice.process(session, source, event, ...)
	local f = TableNotice[event] 
	if f == nil then
		filelog.sys_error(filename.." TableNotice.process invalid event:"..event)
		return nil
	end
	f(...)
end

function TableNotice.get_roomsvr_state( ... )
	msghelper:report_table_state()
end


return TableNotice