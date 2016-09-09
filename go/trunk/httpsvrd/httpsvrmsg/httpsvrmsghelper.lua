local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"
local tabletool = require "tabletool"
local base = require "base"
local msgproxy = require "msgproxy"
local filename = "httpsvrmsghelper.lua"
local service
local HttpsvrmsgHelper = {}

function HttpsvrmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function HttpsvrmsgHelper.get_serverid()
	return service.get_serverid()
end

function HttpsvrmsgHelper.get_conf()
	return service.get_conf()
end

function HttpsvrmsgHelper.set_conf(conf)
	service.set_conf(conf)
end

function HttpsvrmsgHelper.init_agent_pool()
	service.init_agent_pool()	
end

function HttpsvrmsgHelper.get_agentpool()
	return service.get_agentpool()
end

function HttpsvrmsgHelper.get_agent_sessions()
	return service.get_agent_sessions()
end

function HttpsvrmsgHelper.delete_agent(id)
	service.delete_agent(id)
end

function HttpsvrmsgHelper.open_websocket()
	service.open_websocket()
end

return	HttpsvrmsgHelper  