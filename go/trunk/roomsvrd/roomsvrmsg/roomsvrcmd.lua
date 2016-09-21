local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "roomsvrhelper"
local msgproxy = require "msgproxy"
local base = require "base"
local filename = "roomsvrcmd.lua"
local RoomsvrCMD = {}

function RoomsvrCMD.process(session, source, event, ...)
	local f = RoomsvrCMD[event] 
	if f == nil then
		filelog.sys_error(filename.."RoomsvrCMD.process invalid event:"..event)
		return nil
	end
	f(...)	 
end

function RoomsvrCMD.delete_table(id)
	msghelper:delete_table(id)
end

function RoomsvrCMD.start(conf)
	local server = msghelper:get_server()
	server.friend_table_id = string.match(skynet.getenv("svr_id"), "%a*_(%d+)")
	server.friend_table_id = math.floor(server.friend_table_id * 100000)

	msghelper:set_idle_table_pool(conf)

	base.skynet_retpack(true)
	--通知tablesvrd自己初始化
	msgproxy.sendrpc_broadcastmsgto_tablesvrd("init", skynet.getenv("svr_id"))

	msghelper:start_time_tick()	
end

function RoomsvrCMD.close(...)
	local server = msghelper:get_server()
	server:exit_service()	
end

function RoomsvrCMD.reload(conf)
	--[[if conf ~= nil then
		msghelper.set_conf(conf)
	end
	skynet.retpack(msghelper.reload_config())
	]]
end

return RoomsvrCMD