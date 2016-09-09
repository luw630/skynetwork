local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local configdao = require "configdao"
local base = require "base"
local timetool = require "timetool"
local serverbase = require "serverbase"
require "enum"
local params = ...

local Agent = serverbase:new({
		watch_dog = nil,
		client_fd = nil,
		ip="",
		port="",
		uid = 0,
		state = 0,  --登陆状态 0 已经退出 1 正在登陆 2 登陆成功 3 正在退出 
		rid = 0,
	}) 


function Agent:tostring()
	return self.uid..":"..self.rid.." gate agent"
end

local function agent_to_string()
	return Agent:tostring()
end

function  Agent:init()
	msghelper:init(Agent)
	self.eventmng.init(Agent)
	self.eventmng.add_eventbyname("cmd", "agentcmd")
	eventmng.add_eventbyname("notice", "agentnotice")
	eventmng.add_eventbyname("request", "agentrequest")
	eventmng.add_eventbyname("entergame", "entergame")
	Agent.__tostring = agent_to_string						
end

function Agent:tick()
	local now_time = timetool.get_time()
	if self.last_heart_time + configdao.get_common_conf("agent_heart_timeout")  < now_time then
		--心跳超时给玩家做断线处理
		self.eventmng.process(_, _, "lua", "cmd", "disconnect", true)
	end  
end

function Agent:create_session(conf)
	self.client_fd = conf.client
	self.gate_service = conf.gate
	self.watch_dog = conf.watchdog	
	self.last_heart_time= timetool.get_time()
	self.ip, self.port = string.match(conf.ip, "(.+):(%d+)")
	skynet.fork(function()
		while true do
			skynet.sleep(500)
			self:tick()
		end
	end)

	local result = skynet.call(self.gate_service, "lua", "forward", self.client_fd, self.client_fd)
	if not result then
		return false
	end
	self.eventmng.process(_, _, "client", conf.msgname, self.client_fd, conf.msg)
	return true
end

function Agent:reconnect(conf)

	if self.state == EGateAgentState.GATE_AGENTSTATE_UNKNOW 
		or self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTING then
		filelog.sys_error(self:tostring().." this agent is logouting")
		pcall(skynet.send, self.watch_dog, "lua", "cmd", "agentexit", self.client_fd, self.rid)
		return false
	end 

	local result = skynet.call(self.gate_service, "lua", "forward", self.client_fd, self.client_fd)
	if not result then
		filelog.sys_error(self:tostring().." call(conf.gate, 'lua', 'forward', conf.client) failed")
		return false
	end

	--通知先前的设备玩家在其他设备上登陆
	if self.client_fd ~= nil then
		local noticemsg = {}
		--TO ADD 
	end

	self.client_fd = conf.client
	self.gate_service = conf.gate
	self.watch_dog = conf.watchdog	
	self.last_heart_time= timetool.get_time()
	self.ip, self.port = string.match(conf.ip, "(.+):(%d+)")

	self.eventmng.process(_, _, "client", conf.msgname, self.client_fd, conf.msg)
	self.isoffline = false
	--msghelper:write_agentinfo_log(self.last_heart_time.." Agent:reconnect end")
	return true
end

function Agent:agentexit(is_active)

	if self.state == EGateAgentState.GATE_AGENTSTATE_UNKNOW 
		or self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTING then
		return
	end

	--做一些退出前处理
	self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTING


	--2.更新玩家的在线状态数据 send


	--3.通知gatesvrd  agentexit
	if not is_active then
		pcall(skynet.send, self.watch_dog, "lua", "cmd", "agentexit", self.client_fd, self.rid)
	end

	self:clear()
end

function Agent:clear()
	--TO ADD
end

skynet.start(function()
	if params == nil then
		Agent:start()
	else		
		Agent:start(table.unpack(base.strsplit(params, ",")))
	end	
end)
