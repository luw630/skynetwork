local skynet = require "skynet"
local msghelper = require "globaldbsvrhelper"
local base = require "base"
local serverbase = require "serverbase"
require "skynet.manager"

local params = ...

local Globaldbsvrd = serverbase:new({
	redisdb_service = {},
	mysqldb_service = {},
})

function Globaldbsvrd:tostring()
	return "Globaldbsvrd"
end

local function globaldbsvrd_to_sring()
	return Globaldbsvrd:tostring()
end

function  Globaldbsvrd:init()
	msghelper:init(Globaldbsvrd)
	self.eventmng.init(Globaldbsvrd)
	self.eventmng.add_eventbyname("cmd", "globaldbsvrcmd")
	self.eventmng.add_eventbyname("dao", "globaldbsvrdao")
	Globaldbsvrd.__tostring = globaldbsvrd_to_sring
end 

skynet.start(function()  
	if params == nil then
		Globaldbsvrd:start()
	else		
		Globaldbsvrd:start(table.unpack(base.strsplit(params, ",")))
	end	
end)
