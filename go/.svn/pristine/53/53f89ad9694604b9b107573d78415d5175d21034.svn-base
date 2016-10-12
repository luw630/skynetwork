local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local configdao = require "configdao"
local playerdatadao = require "playerdatadao"
local base = require "base"
local timetool = require "timetool"
local serverbase = require "serverbase"
local eventmng = require "eventmng"
local msgproxy = require "msgproxy"
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

		--玩家基本信息
		info = nil,
		money = nil,
		playgame = nil,
		online = nil,

		--渠道版本信息
		platform = 0, --client 平台id(属于哪家公司发行)
  		channel = 0,  --client 渠道id(发行公司的发行渠道)
  		version = "", --client 版本号
  		authtype = 0, --client 账号类型
  		regfrom = 0,  --描述从哪里注册过来的

  		--游戏在线状态信息
  		roomsvr_id = "",
		roomsvr_table_id = 0,
		roomsvr_table_address = -1,
		roomsvr_seat_index = 0,
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
	self.eventmng.add_eventbyname("notice", "agentnotice")
	self.eventmng.add_eventbyname("request", "agentrequest")
	self.eventmng.add_eventbyname("EnterGameReq", "entergame")
	self.eventmng.add_eventbyname("PlayerBaseinfoReq", "playerbaseinfo")
	self.eventmng.add_eventbyname("UpdateinfoReq", "updateinfo")
	self.eventmng.add_eventbyname("HeartReq", "heart")
	self.eventmng.add_eventbyname("CreateFriendTableReq", "createfriendtable")
	self.eventmng.add_eventbyname("GetTableStateByCreateIdReq", "gettabestatebycreateid")
	self.eventmng.add_eventbyname("GetFriendTableListReq", "getfriendtablelist")
	self.eventmng.add_eventbyname("EnterTableReq", "entertable")
	self.eventmng.add_eventbyname("SitdownTableReq", "sitdowntable")
	self.eventmng.add_eventbyname("StandupTableReq", "standuptable")
	self.eventmng.add_eventbyname("LeaveTableReq", "leavetable")
	self.eventmng.add_eventbyname("ReenterTableReq", "reentertable")
	self.eventmng.add_eventbyname("StartGameReq", "startgame")
	self.eventmng.add_eventbyname("DoactionReq", "doaction")
	self.eventmng.add_eventbyname("QiniuUploadReq", "qiniuupload")
	self.eventmng.add_eventbyname("DianMuReq", "requestdmu")
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
	elseif self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTED then
		return false
	end 

	local result = skynet.call(self.gate_service, "lua", "forward", conf.client, conf.client)
	if not result then
		filelog.sys_error(self:tostring().." call(conf.gate, 'lua', 'forward', conf.client) failed")
		return false
	end

	if self.state == EGateAgentState.GATE_AGENTSTATE_UNKNOW 
		or self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTING then
		filelog.sys_error(self:tostring().." this agent is logouting")
		pcall(skynet.send, self.watch_dog, "lua", "cmd", "agentexit", self.client_fd, self.rid)
		return false
	elseif self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTED then
		return false
	end 

	--通知先前的设备玩家在其他设备上登陆
	if self.client_fd ~= nil then
		local noticemsg = {
			rid = self.rid,
		}
		msghelper:send_noticemsgto_client(self.client_fd, "RepeatNtc", noticemsg)
	end

	self.client_fd = conf.client
	self.gate_service = conf.gate
	self.watch_dog = conf.watchdog	
	self.last_heart_time= timetool.get_time()
	self.ip, self.port = string.match(conf.ip, "(.+):(%d+)")
	self.isoffline = false

	self.platform = conf.msg.version.platform
  	self.channel = conf.msg.version.channel
  	self.version = conf.msg.version.version
  	self.authtype = conf.msg.version.authtype
  	self.regfrom = conf.msg.version.regfrom

	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}

	responsemsg.servertime = timetool.get_time()
	responsemsg.roomsvr_id = self.roomsvr_id
	responsemsg.roomsvr_table_address = self.roomsvr_table_address 
	responsemsg.baseinfo = {}
	msghelper:copy_base_info(responsemsg.baseinfo, self.info, self.playgame, self.money)

	msghelper:send_resmsgto_client(self.client_fd, "EnterGameRes", responsemsg)
	--msghelper:write_agentinfo_log(self.last_heart_time.." Agent:reconnect end")
	return true
end

function Agent:agentexit(is_active)

	if self.state == EGateAgentState.GATE_AGENTSTATE_UNKNOW 
		or self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTING
		or self.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTED then
		return
	end

	--做一些退出前处理
	self.state = EGateAgentState.GATE_AGENTSTATE_LOGOUTING


	--2.更新玩家的在线状态数据 send
	if self.roomsvr_id ~= "" 
		and self.roomsvr_table_address >= 0
		and self.roomsvr_table_id > 0 then
		--通知玩家离开桌子
		local leavetablereqmsg = {
			version = {
				platform = self.platform,
	  			channel = self.channel,
	  			version = self.version,
	  			authtype = self.authtype,
	  			regfrom = self.regfrom,
			},
			id = self.roomsvr_table_id,
			roomsvr_id = self.roomsvr_id,
			roomsvr_table_address = self.roomsvr_table_address,
			rid = self.rid,
		}

		msgproxy.sendrpc_reqmsgto_roomsvrd(nil, self.roomsvr_id, self.roomsvr_table_address, "leavetable", leavetablereqmsg)

		if self.state ~= EGateAgentState.GATE_AGENTSTATE_LOGOUTING then
			return
		end

		--重置游戏在线状态信息
  		self.roomsvr_id = ""
		self.roomsvr_table_id = 0
		self.roomsvr_table_address = -1
		self.roomsvr_seat_index = 0
	end

	if self.online ~= nil then
		self.online.roomsvr_id = ""
		self.online.roomsvr_table_id = 0
		self.online.roomsvr_table_address = -1
		self.online.gatesvr_ip = ""
		self.online.gatesvr_port = 0
		self.online.gatesvr_id = ""
		self.online.gatesvr_service_address = -1
		playerdatadao.save_player_online("update", self.rid, self.online)
	end

	--3.通知gatesvrd  agentexit
	if not is_active then
		pcall(skynet.send, self.watch_dog, "lua", "cmd", "agentexit", self.client_fd, self.rid)
	end

	self:clear()
end

function Agent:clear()
	
	--玩家基本信息
	self.info = nil
	self.money = nil
	self.playgame = nil
	self.online = nil
end

skynet.start(function()
	if params == nil then
		Agent:start()
	else		
		Agent:start(table.unpack(base.strsplit(params, ",")))
	end	
end)
