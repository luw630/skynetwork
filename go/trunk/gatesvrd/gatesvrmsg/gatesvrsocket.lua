local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "gatesvrmsghelper"
local filename = "gatesvrsocket.lua"

local GatesvrSocket = {}


function GatesvrSocket.process(session, source, event, ...)
	local f = GatesvrSocket[event] 
	if f == nil then
		filelog.sys_error(filename.." GatesvrSocket.process invalid event:"..event)
		return nil
	end
	f(...)	 
end

function GatesvrSocket.open(fd, ip)
	local server = msghelper:get_server()
	server.tcpmng.open_socket(fd, ip)
end

function GatesvrSocket.close(fd)
	filelog.sys_info("GatesvrSocket.close ", fd)
	local server = msghelper:get_server()
	server.tcpmng.close_socket(fd)
end

function GatesvrSocket.error(fd, msg)
	filelog.sys_info("GatesvrSocket.error", fd, msg)
	local server = msghelper:get_server()
	server.tcpmng.close_socket(fd)
end

function GatesvrSocket.warning(fd, size)
	-- size K bytes havn't send out in fd
	filelog.sys_warning("GatesvrSocket warning:"..size.." K bytes havn't send out in "..fd)
end

function GatesvrSocket.data(fd, msg, sz)
end

return GatesvrSocket