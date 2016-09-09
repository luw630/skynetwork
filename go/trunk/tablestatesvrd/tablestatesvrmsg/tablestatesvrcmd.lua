local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablestatesvrhelper"
local base = require "base"
local filename = "tablestatesvrcmd.lua"
local TableStatesvrCMD = {}

function TableStatesvrCMD.process(session, source, event, ...)
	local f = TableStatesvrCMD[event] 
	if f == nil then
		filelog.sys_error(filename.."Loginsvrd TableStatesvrCMD.process invalid event:"..event)
		return nil
	end
	f(...)
end

function TableStatesvrCMD.start(conf)
	--local server = msghelper:get_server()
	base.skynet_retpack(true)

	--通知所有roomsvrd上报状态信息
	msghelper:get_roomsvr_states()

	msghelper:start_time_tick()
end

function TableStatesvrCMD.close(...)
	local server = msghelper:get_server()
	server:exit_service()	
end

return TableStatesvrCMD