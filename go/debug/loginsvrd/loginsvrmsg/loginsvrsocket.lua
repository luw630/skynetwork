local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "loginsvrhelper"
local filename = "loginsvrsocket.lua"

local LoginsvrSocket = {}


function LoginsvrSocket.process(session, source, event, ...)
	local f = LoginsvrSocket[event] 
	if f == nil then
		filelog.sys_error(filename.." LoginsvrSocket.process invalid event:"..event)
		return nil
	end
	f(...)	 
end

function LoginsvrSocket.open(fd, ip)
	local server = msghelper:get_server()
	server.tcpmng.open_socket(fd, ip)
end

function LoginsvrSocket.close(fd)
	local server = msghelper:get_server()
	server.tcpmng.close_socket(fd)
end

function LoginsvrSocket.error(fd, msg)
	local server = msghelper:get_server()
	server.tcpmng.close_socket(fd)
end

function LoginsvrSocket.warning(fd, size)
	-- size K bytes havn't send out in fd
	filelog.sys_warning("LoginsvrSocket warning:"..size.." K bytes havn't send out in "..fd)
end

function LoginsvrSocket.data(fd, msg, sz)
end

return LoginsvrSocket