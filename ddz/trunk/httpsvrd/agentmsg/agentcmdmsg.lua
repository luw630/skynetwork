local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agentmsghelper"
local timetool = require "timetool"
local filename = "agentcmd.lua"
local httpc = require "http.httpc"

local CMD = {}

function CMD.process(session, source, subcmd, ...)
	local f = CMD[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."CMD.process invalid subcmd:"..subcmd)
		return nil
	end
	f(...)
end

function CMD.start(session_id)
	msghelper.set_session_id(session_id)
	msghelper.load_channel()
	local agent_data = msghelper.get_agentdata()
	agent_data.sessionbegin_time = timetool.get_time() * 100
	httpc.dns()
	skynet.retpack(true)
end
function CMD.reload(conf)
	msghelper.load_channel()
	skynet.retpack(true)
end

return CMD