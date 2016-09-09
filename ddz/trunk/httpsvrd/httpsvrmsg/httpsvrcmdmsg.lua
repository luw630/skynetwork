local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "httpsvrmsghelper"
local filename = "httpsvrcmdmsg.lua"
local httpc = require "http.httpc"
local CMD = {}

function CMD.process(session, source, subcmd, ...)
	local f = CMD[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."IMSVRD CMD.process invalid subcmd:"..subcmd)
		return nil
	end
	f(...)	 
end

function CMD.start(conf)
	skynet.retpack(true)
	if conf.dns_server == nil or conf.dns_port == nil then
		httpc.dns()
	else
		httpc.dns(conf.dns_server, conf.dns_port)
	end

	msghelper.set_conf(conf)
	msghelper.init_agent_pool()
	msghelper.open_websocket()
end

function CMD.reload(conf)	
	if conf ~= nil then
		if conf.dns_server ~= nil and conf.dns_port ~= nil then
			httpc.dns(conf.dns_server, conf.dns_port)
		end
		msghelper.set_conf(conf)
	end
	skynet.retpack(true)
end

function CMD.agentexit(client_fd)
	msghelper.delete_agent(client_fd)
end

return CMD