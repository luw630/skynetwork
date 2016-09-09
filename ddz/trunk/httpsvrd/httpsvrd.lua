local skynet = require "skynet"
local filelog = require "filelog"
local eventmng = require "eventmng"
local msghelper = require "httpsvrmsghelper"
local msgproxy = require "msgproxy"
local incrservicepoolmng = require "incrservicepoolmng"
local socket = require "socket"
local base = require "base"
require "skynet.manager"

local HTTPSVRD = {}
local server_id = ...
local svr_conf
local agentpool
local agent_sessions = {}

function  HTTPSVRD.init()

	msghelper.init(HTTPSVRD)
	eventmng.init(HTTPSVRD)
	eventmng.add_eventbyname("cmd", "httpsvrcmdmsg")
	eventmng.add_eventbyname("request", "httpsvrrequestmsg")
	eventmng.add_eventbyname("notice", "httpsvrnoticemsg")
end

function HTTPSVRD.send_msgto_client(msg,...)
end

function HTTPSVRD.send_resmsgto_client(msgname, msg, ...)
end

function HTTPSVRD.send_noticemsgto_client(msgname, msg, ...)
end

function HTTPSVRD.process_client_message(session, source, ...)
end

function HTTPSVRD.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function HTTPSVRD.decode_client_message(...)
end
----------------------------------------------------------------------------------------------------
function HTTPSVRD.set_conf(conf)
	svr_conf = conf
end

function HTTPSVRD.get_conf()
	return svr_conf
end

function HTTPSVRD.get_serverid()
	return server_id
end

function HTTPSVRD.init_agent_pool()
	--初始化agent池子
	agentpool = incrservicepoolmng:new({}, {service_name="agent", service_size=svr_conf.agentsize, incr=svr_conf.agentincr})
	--agentpool = incrservicepoolmng:new({}, {service_name="agent", service_size=200, incr=100})
end

function HTTPSVRD.delete_agent(id)
	local agentobj = agent_sessions[id]
	if agentobj ~= nil then
		agentpool:delete_service(id)
		if agentobj.client_fd ~= nil then
			socket.close(agentobj.client_fd)
		end
		if agentobj.responsefunc ~= nil then
			base.pcall(agentobj.responsefunc, true, nil)
		end 
		agent_sessions[id] = nil
	end
end

function HTTPSVRD.get_agentpool()
	return agentpool
end

function HTTPSVRD.get_agent_sessions()
	return agent_sessions
end

function HTTPSVRD.open_websocket()
	local ip
	local port
	local svrsocket_fd
	local agentobj
	if svr_conf.svr_ip == nil then
		ip = "0.0.0.0"
	else
		ip = svr_conf.svr_ip
	end

	if svr_conf.svr_port == nil then
		port = 8080
	else
		port = svr_conf.svr_port
	end
	svrsocket_fd = socket.listen(ip, port)
	socket.start(svrsocket_fd , function(client_fd, addr)
		agentobj = agentpool:create_service()
		if agentobj == nil then
			filelog.sys_error("HTTPSVRD.open_websocket: agentpool:create_service failed", client_fd, addr)
			socket.close(client_fd)
		else
			skynet.call(agentobj.service, "lua", "cmd", "start", agentobj.id)			
			agentobj.client_fd = client_fd
			agent_sessions[agentobj.id] = agentobj
			skynet.send(agentobj.service, "lua", "request", "callback", client_fd)
		end
	end)
end

function HTTPSVRD.start()
	--[[skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = HTTPSVRD.decode_client_message,
		dispatch = HTTPSVRD.process_client_message, 
	}]]


	skynet.dispatch("lua", HTTPSVRD.process_other_message)

	--gate = skynet.newservice("wsgate")
	msgproxy.init()
	--HTTPSVRD.init_agent_pool()
	--local agentobj = agentpool:create_service()
	--skynet.call(agentobj.service, "lua", "cmd", "start", agentobj.id)			
	--skynet.send(agentobj.service, "lua", "request", "callback", 1)
				
end

skynet.start(function()
	HTTPSVRD.init()
	HTTPSVRD.start()
	skynet.register(server_id)
end)
