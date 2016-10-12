local skynet = require "skynet"
local filelog = require "filelog"
local base = require "base"
local msghelper = require "gatesvrmsghelper"
local serverbase = require "serverbase"
local timetool = require "timetool"
require "skynet.manager"

local params = ...

local Gatesvrd = serverbase:new({})

function Gatesvrd:tostring()
	return "Gatesvrd"
end

local function gatesvrd_to_sring()
	return Gatesvrd:tostring()
end

function  Gatesvrd:init()
	msghelper:init(Gatesvrd)
	self.eventmng.init(Gatesvrd)
	self.eventmng.add_eventbyname("cmd", "gatesvrcmd")
	self.eventmng.add_eventbyname("socket", "gatesvrsocket")
	self.eventmng.add_eventbyname("EnterGameReq", "gatesvrentergame")
	self.eventmng.add_eventbyname("request", "gatesvrrequest")
	self.eventmng.add_eventbyname("notice", "gatesvrnotice")
	Gatesvrd.__tostring = gatesvrd_to_sring
end

skynet.start(function()
	if params == nil then
		Gatesvrd:start()
	else		
		Gatesvrd:start(table.unpack(base.strsplit(params, ",")))
	end

	--定时上报当前玩家的在线状态
	skynet.fork(function()
      while true do
        skynet.sleep(2500)
        msghelper:event_process("lua", "notice", "get_gatesvr_state")
      end
    end)    	
end)