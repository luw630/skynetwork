local skynet = require "skynet"
local netpack = require "websocketnetpack"
local filelog = require "filelog"
local socket = require "socket"
local eventmng = require "eventmng"
local msghelper = require "gmsvrmsghelper"
local servicepoolmng = require "incrservicepoolmng"
local msgproxy = require "msgproxy"
require "skynet.manager"

--local requestmsghelper
--local noticemsghelper
local gate
local connection = {} --{fd, addr, rid}
local http_sessions = {}
local agentmng
local server_id = ...
local GMSVRD = {}

local function close_agent(fd)
	local c = connection[fd]
	if c ~= nil then
		skynet.call(gate, "lua", "kick", fd)
		local a = c.agent
		if a then
			agentmng:delete_service(a.id)
			c.agent = nil
		end
		connection[fd] = nil
	end
end

local function close_client(fd)
	local c = connection[fd]
	if c ~= nil then
		skynet.call(gate, "lua", "kick", fd)
		local a = c.agent
		if a then
			skynet.send(a.service, "lua", "cmd", "close")
			agentmng:delete_service(a.id)
			c.agent = nil
		end
		connection[fd] = nil
	end
end



-----------------------------GMSVRD-----------------------------
function  GMSVRD.init()
	msghelper.init(GMSVRD)
	eventmng.init(GMSVRD)
	eventmng.add_eventbyname("socket", "gmsvrsocket")
	eventmng.add_eventbyname("cmd", "gmsvrcmd")
end

function GMSVRD.send_msgto_client(msg,...)
end

function GMSVRD.send_resmsgto_client(msgname, msg, ...)
end

function GMSVRD.send_noticemsgto_client(msgname, msg, ...)
end

function GMSVRD.process_client_message(session, source, ...)
end

function GMSVRD.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function GMSVRD.decode_client_message(...)
	
end
------------------------------------------------------------------------
function GMSVRD.open_gate(conf)
	agentmng = servicepoolmng:new({}, {service_name="agent", service_size=conf.agentsize, incr=conf.agentincr})
	GMSVRD.open_http_socket(conf)
	return skynet.call(gate, "lua", "open" , conf)
end

function GMSVRD.create_agent(fd, addr)
	local c = {
		fd = fd,
		ip = addr,
	}
	c.agent = agentmng:create_service()
	if c.agent == nil then
		skynet.call(gate, "lua", "kick", fd)
		filelog.sys_error("not enough idle agent service!!")		
		return		
	end
	connection[fd] = c

	local result = skynet.call(c.agent.service, "lua", "cmd", "start", nil, { gate = gate, client = fd, watchdog = skynet.self()})
	
	if not result then
		skynet.send(c.agent.service, "lua", "cmd", "close")
		agentmng:delete_service(c.agent.id)
		connection[fd] = nil
		skynet.call(gate, "lua", "kick", fd)
		filelog.sys_error("agent service start failed!!")
		return		
	end
end

function GMSVRD.create_clientsession(fd, addr)
	GMSVRD.create_agent(fd, addr)
end

function GMSVRD.close_agent(client_fd)
	close_agent(client_fd)
end

function GMSVRD.close_client(client_fd)
	close_client(client_fd)
end

function GMSVRD.close_http_session(id)
	local http_session = http_sessions[id]
	if http_session ~= nil then
		agentmng:delete_service(id)
		if http_session.client_fd ~= nil then
			socket.close(http_session.client_fd)
		end
		http_sessions[id] = nil
	end
end

function GMSVRD.get_http_sessions()
	return http_sessions
end

function GMSVRD.open_http_socket(conf)
	local ip
	local port
	local svrsocket_fd
	local http_session
	if conf.gmhttpsvr_ip == nil then
		ip = "0.0.0.0"
	else
		ip = conf.gmhttpsvr_ip
	end

	if conf.gmhttpsvr_port == nil then
		port = 8081
	else
		port = conf.gmhttpsvr_port
	end
	svrsocket_fd = socket.listen(ip, port)
	socket.start(svrsocket_fd , function(client_fd, addr)
		http_session = agentmng:create_service()
		if http_session == nil then
			filelog.sys_error("GMSVRD.open_http_socket: agentmng:create_service failed", client_fd, addr)
			socket.close(client_fd)
		else
			skynet.call(http_session.service, "lua", "cmd", "start", http_session.id, {gate = gate, client = client_fd, watchdog = skynet.self()})			
			http_session.client_fd = client_fd
			http_sessions[http_session.id] = http_session
			skynet.send(http_session.service, "lua", "request", "callback", client_fd)
		end
	end)
end

function GMSVRD.start()

	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = GMSVRD.decode_client_message,
		dispatch = GMSVRD.process_client_message, 
	}

	skynet.dispatch("lua", GMSVRD.process_other_message)

	gate = skynet.newservice("wsgate")
	
	msgproxy.init()
end

skynet.start(function()
	GMSVRD.init()
	GMSVRD.start()
	skynet.register(server_id)
end)
