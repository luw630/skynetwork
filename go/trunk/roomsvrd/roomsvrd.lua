local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "roomsvrhelper"
local serverbase = require "serverbase"
local base = require "base"
local table = table

local params = ...

local Roomsvrd = serverbase:new({
	idle_table_mng = nil,
	used_table_pool = {},
	--[[id = {
			table_service = -1,
			isdelete = false,
			table_service_id = -1,
			create_table_id = 0,
		}
	]]
	create_table_ids = {},

	friend_table_id = 0,
})

function Roomsvrd:tostring()
	return "Roomsvrd"
end

local function roomsvrd_to_sring()
	return Roomsvrd:tostring()
end

function Roomsvrd:init()
	msghelper:init(Roomsvrd)
	self.eventmng.init(Roomsvrd)
	self.eventmng.add_eventbyname("cmd", "roomsvrcmd")
	self.eventmng.add_eventbyname("request", "roomsvrrequest")
	self.eventmng.add_eventbyname("notice", "roomsvrnotice")

	Roomsvrd.__tostring = roomsvrd_to_sring
end 

skynet.start(function()  
	if params == nil then
		Roomsvrd:start()
	else		
		Roomsvrd:start(table.unpack(base.strsplit(params, ",")))
	end	
end)