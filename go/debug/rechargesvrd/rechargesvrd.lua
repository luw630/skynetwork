local skynet = require "skynet"
local filelog = require "filelog"
local eventmng = require "eventmng"
local msghelper = require "rechargesvrmsghelper"
local msgproxy = require "msgproxy"
require "skynet.manager"

local server_id = ...

local svr_conf
local RECHARGESVRD = {}


function  RECHARGESVRD.init()

	msghelper.init(RECHARGESVRD)

	eventmng.init(RECHARGESVRD)
	eventmng.add_eventbyname("notice", "rechargesvrnoticemsg")
	eventmng.add_eventbyname("request", "rechargesvrrequestmsg")
	eventmng.add_eventbyname("cmd", "rechargesvrcmdmsg")
end

function RECHARGESVRD.send_msgto_client(msg,...)
end

function RECHARGESVRD.send_resmsgto_client(msgname, msg, ...)
end

function RECHARGESVRD.send_noticemsgto_client(msgname, msg, ...)
end

function RECHARGESVRD.process_client_message(session, source, ...)
end

function RECHARGESVRD.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function RECHARGESVRD.decode_client_message(...)
end

function RECHARGESVRD.set_conf(conf)
	svr_conf = conf
end

function RECHARGESVRD.get_conf()
	return svr_conf
end
----------------------------------------------------------------------------------------------------
function RECHARGESVRD.start()

	--[[skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = RECHARGESVRD.decode_client_message,
		dispatch = RECHARGESVRD.process_client_message, 
	}]]

	skynet.dispatch("lua", RECHARGESVRD.process_other_message)

	--gate = skynet.newservice("wsgate")
	msgproxy.init()	
end

skynet.start(function()
	RECHARGESVRD.init()
	RECHARGESVRD.start()
	skynet.register(server_id)
end)
