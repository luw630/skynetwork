local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "playerstatesvrhelper"
local base = require "base"
local msgproxy = require "msgproxy"
local configdao = require "configdao"
local filename = "playerstatesvrcmd.lua"
local PlayerStatesvrCMD = {}

function PlayerStatesvrCMD.process(session, source, event, ...)
	local f = PlayerStatesvrCMD[event] 
	if f == nil then
		filelog.sys_error(filename.."Loginsvrd PlayerStatesvrCMD.process invalid event:"..event)
		return nil
	end
	f(...)
end

function PlayerStatesvrCMD.start(conf)
	--local server = msghelper:get_server()
	base.skynet_retpack(true)

	--通知所有roomsvrd上报状态信息
	msghelper:get_roomsvr_states()

	msghelper:start_time_tick()
end

function PlayerStatesvrCMD.close(...)
	local server = msghelper:get_server()
	server:exit_service()	
end

function PlayerStatesvrCMD.reload(...)
	base.skynet_retpack(1)
	filelog.sys_error("PlayerStatesvrCMD.reload start")

	configdao.reload()

	skynet.sleep(200)

	msgproxy.reload()
	
	filelog.sys_error("PlayerStatesvrCMD.reload end")
end

return PlayerStatesvrCMD