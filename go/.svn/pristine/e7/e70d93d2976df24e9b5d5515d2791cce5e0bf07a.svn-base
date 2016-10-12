local skynet = require "skynet"
local filelog = require "filelog"
local helperbase = require "helperbase"
local base = require "base"
local filename = "globaldbsvrhelper.lua"

local GlobaldbsvrHelper = helperbase:new({}) 

function GlobaldbsvrHelper:get_redissvrkey_bykey(key)
	local server = self.server
	if key == nil then
		return nil
	end	
	local num
	if type(key) == "string" then
		num = base.strtohash(key)
	else
		num = key
	end	

	local index = num % (#(server.redisdb_service)) + 1
	return server.redisdb_service[index]
end

function GlobaldbsvrHelper:get_mysqlsvrkey_bykey(key)
	local server = self.server
	if key == nil then
		return nil
	end
	local num
	if type(key) == "string" then
		num = base.strtohash(key)
	else
		num = key
	end	
	local index = num % (#(server.mysqldb_service)) + 1
	return server.mysqldb_service[index]
end


return	GlobaldbsvrHelper 