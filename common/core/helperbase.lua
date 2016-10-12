local skynet = require "skynet"
local filelog = require "filelog"
local filename = "helperbase.lua"

local HelperBase = {
	server = nil,
}

function HelperBase:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    self.__newindex = self
    return obj
end

function HelperBase:init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	HelperBase.server = server
end

function HelperBase:event_process(type, msgname, ...)
	HelperBase.server.eventmng.process(_, _, type, msgname, ...)
end

function HelperBase:send_resmsgto_client(fd, msgname, msg)
	if HelperBase.server ~= nil then
		HelperBase.server:send_resmsgto_client(fd, msgname, msg)
	else
		filelog.sys_error(filename.."HelperBase server == nil")
	end
end

function HelperBase:send_noticemsgto_client(fd, msgname, msg)
	if HelperBase.server ~= nil then
		HelperBase.server:send_noticemsgto_client(fd, msgname, msg)
	else
		filelog.sys_error(filename.."HelperBase server == nil")
	end
end

function HelperBase:get_server()
	return HelperBase.server
end

return	HelperBase  