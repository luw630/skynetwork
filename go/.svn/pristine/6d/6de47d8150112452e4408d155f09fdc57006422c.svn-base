local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "rechargesvrmsghelper"
local filename = "rechargesvrcmdmsg.lua"
local CMD = {}

function CMD.process(session, source, subcmd, ...)
	local f = CMD[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."RECHARGESVRD CMD.process invalid subcmd:"..subcmd)
		return nil
	end
	f(...)	 
end

function CMD.start(conf)
	msghelper.set_conf(conf)
	skynet.retpack(true)
end

function CMD.reload(conf)
	msghelper.set_conf(conf)	
end

return CMD