--短连接管理
local incrservicepoolmng = require "incrservicepoolmng"
local filelog = require "filelog"
local skynet = require "skynet"
local base = require "base"
local timetool = require "timetool"

local ShortTcpMng = {
	connections = {},
	agentpool = nil,
	server=nil,
}

function ShortTcpMng.init(server, agentmodule, agentsize, agentincr, netpackmodule)
 	ShortTcpMng.agentpool = incrservicepoolmng:new({}, {service_name=agentmodule, service_size=agentsize, incr=agentincr}, netpackmodule)
	ShortTcpMng.server = server
	skynet.fork(function()
		local now_time
		while true do
			skynet.sleep(12000)
			now_time = timetool.get_time()
			for fd, c in pairs(ShortTcpMng.connections) do
				if c.agent == nil then
					if c.time+120 <= now_time then
						pcall(skynet.call, server.gate_service, "lua", "kick", fd)
						c.isclose = true
						filelog.sys_warning("delete zombie connection", fd, c)
					end
				end
			end
		end
	end)
end

function ShortTcpMng.open_socket(fd, ip)
 	local server = ShortTcpMng.server
	local status, result = base.pcall(skynet.call, server.gate_service, "lua", "forward", fd)
	
	if not status then
		pcall(skynet.call, server.gate_service, "lua", "kick", fd)
		return		
	end

	if not result then
		pcall(skynet.call, server.gate_service, "lua", "kick", fd)
		return
	end

	local c = {
		fd = fd,
		ip = ip,
		time = timetool.get_time(),
	}
	ShortTcpMng.connections[fd] = c

	filelog.sys_info("New client from : " ..ip.." fd:"..fd)
end

function ShortTcpMng.close_socket(fd)
	--如果对应的服务存在通知服务玩家掉线
	local server = ShortTcpMng.server
	local c = ShortTcpMng.connections[fd]
	if c ~= nil then
		if not c.isclose then
			pcall(skynet.call, server.gate_service, "lua", "kick", fd)		
		else
			filelog.sys_warning("has kick ShortTcpMng.close_socket")
		end
	end

	if c ~= nil and c.agent ~= nil then
		pcall(skynet.send, c.agent, "lua", "cmd", "close")		
	end

	ShortTcpMng.connections[fd] = nil
end

--表示agent已经退出后的处理
function ShortTcpMng.agentexit(fd)
	local server = ShortTcpMng.server
	local c = ShortTcpMng.connections[fd]
	if c ~= nil then
		pcall(skynet.call, server.gate_service, "lua", "kick", fd)
		if c.agent ~= nil then
			pcall(skynet.send, c.agent, "lua", "cmd", "close")
		end
		ShortTcpMng.connections[fd] = nil
	end 
end

function ShortTcpMng.create_session(fd, msgname, request)
 	local result = false
	local status = false
	local server = ShortTcpMng.server
	--判断是否断线重连
	local agentservice = ShortTcpMng.agentpool:create_service()
	if agentservice == nil then
		filelog.sys_error("ShortTcpMng.create_session not enough agentservice")		
		return false
	end
	
	status, result = pcall(skynet.call, agentservice.service, "lua", "cmd", "start", {ip=ShortTcpMng.connections[fd].ip, gate = server.gate_service, client = fd, watchdog = skynet.self(), msgname=msgname, msg=request})
	if not status then
		filelog.sys_error("ShortTcpMng.create_session agent start failed", result)
		pcall(skynet.kill, agentservice.service) 
		ShortTcpMng.close_socket(fd)
		return false		
	end

	if not result then
		filelog.sys_error("ShortTcpMng.create_session agent start failed", result)
		pcall(skynet.kill, agentservice.service)
		ShortTcpMng.close_socket(fd)
		return false		
	end

	if ShortTcpMng.connections[fd] == nil then
		filelog.sys_warning("ShortTcpMng.create_session new connection[fd] == nil", fd)
		pcall(skynet.send, agentservice.service, "lua", "cmd", "close")
		return false
	end

	ShortTcpMng.connections[fd].agent = agentservice.service

	return result
end

function ShortTcpMng.clear()
	for fd, _ in pairs(ShortTcpMng.connections) do
	   ShortTcpMng.close_socket(fd)
	end

	if ShortTcpMng.agentpool ~= nil then
		local iter = ShortTcpMng.agentpool:idle_service_iter()
		local service = iter()
		while service do
			pcall(skynet.send, service, "lua", "cmd", "close")
			service = iter()
		end
	end
end 

return ShortTcpMng