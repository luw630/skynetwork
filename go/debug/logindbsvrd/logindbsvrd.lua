local skynet = require "skynet"
local msghelper = require "logindbsvrhelper"
local base = require "base"
local serverbase = require "serverbase"
require "skynet.manager"

local params = ...

local Logindbsvrd = serverbase:new({
	redisdb_service = {},
	mysqldb_service = {},
})

function Logindbsvrd:tostring()
	return "Logindbsvrd"
end

local function logindbsvrd_to_sring()
	return Logindbsvrd:tostring()
end

function  Logindbsvrd:init()
	msghelper:init(Logindbsvrd)
	self.eventmng.init(Logindbsvrd)
	self.eventmng.add_eventbyname("cmd", "logindbsvrcmd")
	self.eventmng.add_eventbyname("dao", "logindbsvrdao")
	
	Logindbsvrd.__tostring = logindbsvrd_to_sring
end 

skynet.start(function()  
	if params == nil then
		Logindbsvrd:start()
	else		
		Logindbsvrd:start(table.unpack(base.strsplit(params, ",")))
	end	
end)
