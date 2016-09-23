local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agentmsghelper"
local filename = "agentcmd.lua"
local CMD = {}

function CMD.process(session, source, subcmd, ...)
	local f = CMD[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."CMD.process invalid subcmd:"..subcmd)
		return nil
	end
	f(...)
end

function CMD.start(session_id, conf)
	local result = msghelper.create_clientsession(session_id, conf)
	skynet.ret(skynet.pack(result))	 	
end

function CMD.disconnect(...)
end

function CMD.close(...)
	skynet.exit()	
end

return CMD