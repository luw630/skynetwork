local skynet = require "skynet"
local filelog = require "filelog"

local filename = "gmsvrmsghelper.lua"
local service
local GmsvrmsgHelper = {}

function GmsvrmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function GmsvrmsgHelper.close_client(fd)
	service.close_client(fd)
end

function GmsvrmsgHelper.close_agent(fd)
	service.close_agent(fd)
end

function GmsvrmsgHelper.create_clientsession(fd, addr)
	service.create_clientsession(fd, addr)
end

function GmsvrmsgHelper.open_gate(conf)
	return service.open_gate(conf)
end

function GmsvrmsgHelper.close_http_session(id)
	service.close_http_session(id)
end

function GmsvrmsgHelper.get_http_sessions()
	return service.get_http_sessions()
end


return	GmsvrmsgHelper  
