local skynet = require "skynet"
local msghelper = require "loginsvrhelper"
local base = require "base"
local serverbase = require "serverbase"
require "skynet.manager"

local params = ...

local Loginsvrd = serverbase:new({})

function Loginsvrd:tostring()
	return "Loginsvrd"
end

local function loginsvrd_to_sring()
	return Loginsvrd:tostring()
end

function  Loginsvrd:init()
	msghelper:init(Loginsvrd)
	self.eventmng.init(Loginsvrd)
	self.eventmng.add_eventbyname("cmd", "loginsvrcmd")
	self.eventmng.add_eventbyname("socket", "loginsvrsocket")
	self.eventmng.add_eventbyname("LoginReq", "loginsvrlogin")
	self.eventmng.add_eventbyname("notice", "loginsvrnotice")
	Loginsvrd.__tostring = loginsvrd_to_sring
end

skynet.start(function()
	if params == nil then
		Loginsvrd:start()
	else		
		Loginsvrd:start(table.unpack(base.strsplit(params, ",")))
	end	
end)
