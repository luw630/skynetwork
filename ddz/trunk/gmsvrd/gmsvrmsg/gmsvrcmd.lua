local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "gmsvrmsghelper"
local filename = "gmsvrcmd.lua"
local CMD = {}

function CMD.process(session, source, subcmd, ...)
	local f = CMD[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."CMD.process invalid subcmd:"..subcmd)
		return nil
	end
	f(...)
end

function CMD.start(conf)
	skynet.ret(skynet.pack(msghelper.open_gate(conf)))	 
end

function CMD.close(fd)	
	skynet.ret(skynet.pack(msghelper.close_client(fd)))	 
end

function CMD.agentfree(fd)
	msghelper.close_agent(fd)	
end

function CMD.agentexit(id)
	msghelper.close_http_session(id)
end

return CMD