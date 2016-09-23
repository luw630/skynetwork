local skynet = require "skynet"
local filelog = require "filelog"
local eventmng = require "eventmng"
local msghelper = require "recordsvrmsghelper"
local msgproxy = require "msgproxy"
require "skynet.manager"

local RECORDSVRD = {}
local server_id = ...
local svr_conf

function  RECORDSVRD.init()

	msghelper.init(RECORDSVRD)
	eventmng.init(RECORDSVRD)
	eventmng.add_eventbyname("cmd", "recordsvrcmdmsg")
end

function RECORDSVRD.send_msgto_client(msg,...)
end

function RECORDSVRD.send_resmsgto_client(msgname, msg, ...)
end

function RECORDSVRD.send_noticemsgto_client(msgname, msg, ...)
end

function RECORDSVRD.process_client_message(session, source, ...)
end

function RECORDSVRD.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function RECORDSVRD.decode_client_message(...)
end
----------------------------------------------------------------------------------------------------
function RECORDSVRD.set_conf(conf)
	svr_conf = conf
end

function RECORDSVRD.get_conf()
	return svr_conf
end

function RECORDSVRD.get_serverid()
	return server_id
end

function RECORDSVRD.start()
	skynet.dispatch("lua", RECORDSVRD.process_other_message)

	msgproxy.init()	
end

skynet.start(function()
	RECORDSVRD.init()
	RECORDSVRD.start()
	skynet.register(server_id)
end)
