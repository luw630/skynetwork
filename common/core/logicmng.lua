local skynet = require "skynet"
local filelog = require "filelog"
local base = require "base"
local logicpool = {}
local LogicMng = {}
local service

local filename = "LogicMng.lua"

local function add_logic(name, logic)
	logicpool[name] = require(logic)
end

function  LogicMng.add_logic(logic)
	add_logic(logic, logic)	
end

function  LogicMng.add_logicbyname(name, logic)
	add_logic(name, logic)	
end

function LogicMng.get_logicbyname(name)
	return logicpool[name]
end

function LogicMng.reload()
	--TO ADD
	--添加热更新机制
end


return LogicMng
