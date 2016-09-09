local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "recordsvrmsghelper"
local filename = "recordsvrcmdmsg.lua"
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
	msghelper.set_conf(conf)
	skynet.retpack(true)
	httpc.dns()
	msghelper.readmq()
end

function CMD.reload(conf)
	if conf ~= nil then
		msghelper.set_conf(conf)
	end
	skynet.retpack(true)
end

return CMD