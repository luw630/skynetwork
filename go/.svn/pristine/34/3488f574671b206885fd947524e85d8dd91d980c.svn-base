local skynet = require "skynet"
local filelog = require "filelog"
local helperbase = require "helperbase"
local filename = "logindbsvrhelper.lua"

local LogindbsvrHelper = helperbase:new({}) 

function LogindbsvrHelper:get_redissvrid_byuid(uid)
	local server = self.server
	if uid == nil then
		return nil
	end	
	uid = tonumber(uid)
	if uid == nil then
		return nil
	end

	local index = uid % (#(server.redisdb_service)) + 1
	return server.redisdb_service[index]
end

function LogindbsvrHelper:get_mysqlsvrid_byuid(uid)
	local server = self.server
	if uid == nil then
		return nil
	end	
	uid = tonumber(uid)
	if uid == nil then
		return nil
	end

	local index = uid % (#(server.mysqldb_service)) + 1
	return server.mysqldb_service[index]
end


return	LogindbsvrHelper 