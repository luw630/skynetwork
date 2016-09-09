local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "gatesvrmsghelper"
local msgproxy = require "msgproxy"
local base = require "base"
local configdao = require "configdao"
require "enum"

local GatesvrNotice = {}

function GatesvrNotice.process(session, source, event, ...)
	local f = GatesvrNotice[event] 
	if f == nil then
		return
	end
	f(...)
end

function GatesvrNotice.get_gatesvr_state(...)
    local gatesvrs = configdao.get_svrs("gatesvrs")
    local gatesvr = gatesvrs[skynet.getenv("svr_id")]
    local server = msghelper:get_server()
	
	local gatesvrstate = {
		ip = gatesvr.svr_ip,
		port = gatesvr.svr_port,
		onlinenum = server.tcpmng.agentnum,
	}
	msgproxy.sendrpc_broadcastmsgto_loginsvrd("update_gatesvr_state", skynet.getenv("svr_id"), gatesvrstate)
end

return GatesvrNotice