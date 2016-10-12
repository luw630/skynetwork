local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablehelper"
local serverbase = require "serverbase"
local base = require "base"
local tableobj = require "object.tableobj"
local goboard = require "chessboard"
local table = table

local params = ...

local Table = serverbase:new({
	table_data = tableobj:new({
		--添加桌子的变量
		delete_table_timer_id = -1,
		retain_to_time = 0,    --桌子保留到的时间(linux时间擢)
		action_seat_index = 0, --当前操作玩家的座位号
		action_to_time = 0,    --当前操作玩家的到期时间
		gogame = goboard:new(), --棋牌
		action_type = 0,       --玩家操作类型		
		action_x = -1,
		action_y = -1,	
	}),

	logicmng = require("logicmng")
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

	self.logicmng.add_logic("roomtablelogic")
	self.logicmng.add_logic("roomseatlogic")
	self.logicmng.add_logic("roomgamelogic")

	--初始化棋盘
	self.table_data.gogame:InitGoBoard(1, 2)
end 

skynet.start(function()  
	if params == nil then
		Table:start()
	else		
		Table:start(table.unpack(base.strsplit(params, ",")))
	end	
end)