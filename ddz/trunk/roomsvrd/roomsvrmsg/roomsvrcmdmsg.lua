local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "roomsvrmsghelper"
local filename = "roomsvrcmdmsg.lua"
local CMD = {}

function CMD.process(session, source, subcmd, ...)
	local f = CMD[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."ROOMSVRD CMD.process invalid subcmd:"..subcmd)
		return nil
	end
	f(...)	 
end

function CMD.delete_table(table_id)
	msghelper.delete_table(table_id)
end

function CMD.start(conf)	
	msghelper.set_conf(conf)
	msghelper.init_table_pool()
	msghelper.load_config()
	skynet.retpack(true)
	msghelper.recover_friendtable_records()	
end

function CMD.reload(conf)
	if conf ~= nil then
		msghelper.set_conf(conf)
	end
	skynet.retpack(msghelper.reload_config())
end

return CMD