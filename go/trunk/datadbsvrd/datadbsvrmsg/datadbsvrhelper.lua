local skynet = require "skynet"
local filelog = require "filelog"
local helperbase = require "helperbase"
local filename = "datadbsvrhelper.lua"

local DatadbsvrHelper = helperbase:new({}) 

function DatadbsvrHelper:get_redissvrid_byrid(rid)
	local server = self.server
	if rid == nil then
		return nil
	end	
	rid = tonumber(rid)
	if rid == nil then
		return nil
	end

	local index = rid % (#(server.redisdb_service)) + 1
	return server.redisdb_service[index]
end

function DatadbsvrHelper:get_mysqlsvrid_byrid(rid)
	local server = self.server
	if rid == nil then
		return nil
	end	
	rid = tonumber(rid)
	if rid == nil then
		return nil
	end

	local index = rid % (#(server.mysqldb_service)) + 1
	return server.mysqldb_service[index]
end


return	DatadbsvrHelper 