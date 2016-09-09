local skynet = require "skynet"
local filelog = require "filelog"
local base = require "base"
local msghelper = require "gatesvrmsghelper"
local serverbase = require "serverbase"
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
	self.eventmng.add_eventbyname("entergame", "gatesvrentergame")
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
end)