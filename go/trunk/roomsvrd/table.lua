local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local serverbase = require "serverbase"
local base = require "base"
local tableobj = require "object.tableobj"
local table = table

local params = ...

local Table = serverbase:new({
	table_data = tableobj:new({
		--添加桌子的变量
		delete_table_timer_id = -1,
		retain_to_time = 0,		
	}),
})

function Table:tostring()
	return "Table"
end

local function table_to_sring()
	return Table:tostring()
end

function Table:init()
	msghelper:init(Table)
	self.eventmng.init(Table)
	self.eventmng.add_eventbyname("cmd", "tablecmd")
	self.eventmng.add_eventbyname("request", "tablerequest")
	self.eventmng.add_eventbyname("notice", "tablenotice")
	self.eventmng.add_eventbyname("timer", "tabletimer")
	Table.__tostring = table_to_sring
end 

skynet.start(function()  
	if params == nil then
		Table:start()
	else		
		Table:start(table.unpack(base.strsplit(params, ",")))
	end	
end)