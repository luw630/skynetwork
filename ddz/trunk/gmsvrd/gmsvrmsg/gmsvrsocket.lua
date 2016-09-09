local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "gmsvrmsghelper"
local filename = "gmsvrsocket.lua"

local SOCKET = {}


function SOCKET.process(session, source, subcmd, ...)
	local f = SOCKET[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."SOCKET.process invalid subcmd:"..subcmd)
		return nil
	end

	f(...)	 
end

function SOCKET.open(fd, addr)
	msghelper.create_clientsession(fd, addr)
end

function SOCKET.close(fd)
	msghelper.close_client(fd)
end

function SOCKET.error(fd, msg)
	msghelper.close_client(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	filelog.sys_warning("socket warning:"..size.." K bytes havn't send out in "..fd)
end

function SOCKET.data(fd, msg, sz)
end

return SOCKET