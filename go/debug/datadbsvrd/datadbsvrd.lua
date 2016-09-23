local skynet = require "skynet"
local msghelper = require "datadbsvrhelper"
local base = require "base"
local serverbase = require "serverbase"
require "skynet.manager"

local params = ...

local Datadbsvrd = serverbase:new({
	redisdb_service = {},
	mysqldb_service = {},
})

function Datadbsvrd:tostring()
	return "datadbsvrd"
end

local function datadbsvrd_to_sring()
	return Datadbsvrd:tostring()
end

function  Datadbsvrd:init()
	msghelper:init(Datadbsvrd)
	self.eventmng.init(Datadbsvrd)
	self.eventmng.add_eventbyname("cmd", "datadbsvrcmd")
	self.eventmng.add_eventbyname("dao", "datadbsvrdao")
	Datadbsvrd.__tostring = datadbsvrd_to_sring
end 

skynet.start(function()  
	if params == nil then
		Datadbsvrd:start()
	else		
		Datadbsvrd:start(table.unpack(base.strsplit(params, ",")))
	end	
end)
