local skynet = require "skynet"
local filelog = require "filelog"
local channel = require "channel"
local filename = "agentmsghelper.lua"
local service
local AgentmsgHelper = {}


function AgentmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function AgentmsgHelper.agentexit()
	return service.agentexit()
end

function AgentmsgHelper.get_agentdata()
	return service.get_agentdata()
end

function AgentmsgHelper.load_channel()
	--[[local config_filename = "./agentmsg/channel.lua"
	local file = io.open(config_filename, "r")
	local data = file:read("*all")
    local ftmp = load(data, "@"..config_filename, "t")
    if ftmp == nil then
    	filelog.sys_error(filename.." AgentmsgHelper.load_channel load "..config_filename.." failed")
        return
    end

    channel = ftmp()]]
end

function AgentmsgHelper.check_timeout()
	service.check_timeout()
end

function AgentmsgHelper.write_http_info(...)
	filelog.sys_obj("http", "payinfo", ...)
end

function AgentmsgHelper.write_httpclient_info(...)
	filelog.sys_obj("http", "webclient", ...)
end

function AgentmsgHelper.get_channel_byurl(url)
	return channel:get_channel_byurl(url)
end

function AgentmsgHelper.get_session_id()
	return service.get_session_id()
end

function AgentmsgHelper.set_session_id(id)
	service.set_session_id(id)
end

function AgentmsgHelper.get_channel_byid(id)
	return channel:get_channel_byid(id)
end
return	AgentmsgHelper  
