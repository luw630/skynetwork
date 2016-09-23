local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local configdao = require "configdao"
local base = require "base"
local timetool = require "timetool"
local serverbase = require "serverbase"

local params = ...

local Agent = serverbase:new({
		watch_dog = nil,
		client_fd = nil,
		ip="",
		port="",
		uid = 0, 
	}) 


function Agent:tostring()
	return "login agent"
end

local function agent_to_string()
	return Agent:tostring()
end

function  Agent:init()
	msghelper:init(Agent)
	self.eventmng.init(Agent)
	self.eventmng.add_eventbyname("cmd", "agentcmd")
	self.eventmng.add_eventbyname("LoginReq", "agentlogin")

	Agent.__tostring = agent_to_string						
end

function Agent:tick()
	--做一些定时检查，循环间隔是 5s
	local now_time = timetool.get_time()
	if self.last_heart_time + configdao.get_common_conf("agent_heart_timeout") < now_time then
		--心跳超时给玩家做断线处理
		Agent:exit_agent()
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

function Agent:clear()
	
end

--此接口被调用时本服务一定退出
function Agent:exit_agent(is_active)	
	--3.通知hallsvrd  exit
	if not is_active then
		skynet.send(self.watch_dog, "lua", "cmd", "agentexit", self.client_fd)
	end

	self:clear()
end


skynet.start(function()
	if params == nil then
		Agent:start()
	else		
		Agent:start(table.unpack(base.strsplit(params, ",")))
	end	
end)
