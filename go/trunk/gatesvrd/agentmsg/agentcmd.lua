local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
--local msgproxy = require "msgproxy"
--local configdao = require "configdao"
local base = require "base"
local timetool = require "timetool"
local filename = "agentcmd.lua"
local AgentCMD = {}

function AgentCMD.process(session, source, event, ...)
	local f = AgentCMD[event] 
	if f == nil then
		filelog.sys_error(filename.." AgentCMD.process invalid event:"..event)
		return nil
	end
	f(...)
end

function AgentCMD.start(conf)
	local server = msghelper:get_server()
	local result = server:create_session(conf)
	base.skynet_retpack(result)
end

function AgentCMD.close(...)
	local server = msghelper:get_server()
	--延迟释放agent保证agent能正常处理完
	skynet.sleep(10)
	server:agentexit(true)
	server:exit_service()
end

function AgentCMD.disconnect(isheart, fd)
	local server = msghelper:get_server()
   	if isheart == nil then
   		isheart = false
   	end

   	if fd ~= server.client_fd then
   		return
   	end

	--如果玩家已经因为心跳超时掉线，则玩家退出
	--[[if server.isoffline then
		server:agentexit()
		return
	end]]

	if server.roomsvr_id == nil or server.roomsvr_id == "" then
		server:agentexit()
		return
	end

	if server.roomsvr_table_id == nil or server.roomsvr_table_id <= 0 then
		server:agentexit()
		return
	end

	if server.roomsvr_table_address < 0 then
		server:agentexit()
		return
	end

	--请求游戏服务器玩家掉线
	--TO ADD
	
	--设置玩家掉线
	server.isoffline = true
	--更新玩家心跳时间
	server.last_heart_time = timetool.get_time()
	--通知主动关掉socket
	if isheart then
		pcall(skynet.send, server.gate_service, "lua", "cmd", "heart_timeout", server.client_fd)
	end
end

function AgentCMD.reconnect(conf)
	local server = msghelper:get_server()
	local result = server:reconnect(conf)
	base.skynet_retpack(result) 
end

return AgentCMD