local skynet = require "skynet"
local msgproxy = require "msgproxy"
local filelog = require "filelog"
local base = require "base"
local timetool = require "timetool"
local string = string

local protobuf = require "protobuf"
local parser = require "parser"

t = parser.register("addressbook.proto","../../../msgproto")




require "skynet.manager"



local ServerBase = {
	gate_service = nil,
	service_manager = {},
	netpack = nil,
	socket = nil,
	tcpmng = nil,
	eventmng = nil,
	last_heart_time = 0,
	client_fd = nil,
	isoffline = nil, 
}

function ServerBase:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    self.__newindex = self
    return obj
end

function  ServerBase:init()
end

local function decode_client_message(...)
	return ServerBase.requestmsgparser.decode(...)
end

local function encode_client_message(...)
	return ServerBase.requestmsgparser.encode(...)
end

function ServerBase:send_msgto_client(fd, msg,...)
	if fd == nil then
		fd = self.client_fd
	end
	local tmpmsg, sz = self.netpack.pack(msg)
	self.socket.write(fd, tmpmsg, sz)	
end

function ServerBase:send_resmsgto_client(fd, msgname, msg, ...)
	filelog.sys_protomsg(msgname, skynet.self().."_response", msg)
	if isoffline then
		return
	end
	local msgbody
	local status
	local msghead = {
		msgtype = 2,
  		msgname = msgname,  		
	}

	status, msghead = pcall(encode_client_message, "ClientMsgHead", msghead)
	if not status then
		filelog.sys_error("ServerBase:send_resmsgto_client msghead:"..msgname.." failed", msghead)
		return
	end

	status, msgbody = pcall(encode_client_message, msgname, msg)
	if not status then
		filelog.sys_error("ServerBase:send_resmsgto_client msgbody:"..msgname.." failed", msgbody)
		return
	end	
	local encodemsg = string.pack(">s2", msghead)..msgbody
	if encodemsg == nil then
		filelog.sys_error("ServerBase:send_resmsgto_client encodemsg:"..msgname.." failed")
		return
	end

	filelog.sys_protomsg(msgname, skynet.self().."_notice", msghead, string.len(msghead), msgbody, string.len(msgbody), encodemsg, string.len(encodemsg))

	self:send_msgto_client(fd, encodemsg, ...)
end

function ServerBase:send_noticemsgto_client(fd, msgname, msg, ...)
	filelog.sys_protomsg(msgname, skynet.self().."_notice", msg)
	if isoffline then
		return
	end
	local status
	local msgbody
	local msghead = {
		msgtype = 3,
  		msgname = msgname,  		
	}

	status, msghead = pcall(encode_client_message, "ClientMsgHead", msghead)
	if not status then
		filelog.sys_error("ServerBase:send_noticemsgto_client msghead:"..msgname.." failed", msghead)
		return
	end

	status, msgbody = pcall(encode_client_message, msgname, msg)
	if not status then
		filelog.sys_error("ServerBase:send_noticemsgto_client msgbody:"..msgname.." failed", msgbody)
		return
	end

	local encodemsg = string.pack(">s2", msghead)..msgbody
	if encodemsg == nil then
		filelog.sys_error("ServerBase:send_noticemsgto_client encodemsg:"..msgname.." failed")
		return
	end

	filelog.sys_protomsg(msgname, skynet.self().."_notice", msghead, string.len(msghead), msgbody, string.len(msgbody), encodemsg, string.len(encodemsg))	

	self:send_msgto_client(fd, encodemsg, ...)
end

function ServerBase:process_client_message(session, source, ...)
		local msghead, msgbody = ... 
		if msghead ~= nil then
			self.eventmng.process(session, source,"client", msghead.msgname, source, msgbody)
		else
			filelog.sys_error("ServerBase:process_client_message svrd recive invalid client msg")
		end

		self.last_heart_time = timetool.get_time()
end

function ServerBase:process_other_message(session, source, ...)
	self.eventmng.process(session, source,"lua", ...)
end

function ServerBase:decode_client_message(...)
	local msgbuf, msgsize = ...
	local status
	if msgsize <= 2 then
		filelog.sys_error("ServerBase:decode_client_message invalid msgsize", msgsize)
		return nil, nil		
	end
	msgbuf = skynet.tostring(msgbuf, msgsize)	
	local msgheadsize = msgbuf:byte(1) * 256 + msgbuf:byte(2)
	if msgsize < msgheadsize + 2 then
		filelog.sys_error("ServerBase:decode_client_message invalid package")
		return nil, nil				
	end
	local msghead, msgbody = msgbuf:sub(3,2+msgheadsize), msgbuf:sub(3+msgheadsize)

	status, msghead = pcall(decode_client_message, "ClientMsgHead", msghead, string.len(msghead))
	if not status then
		filelog.sys_error("ServerBase:decode_client_message", msghead)
		return nil, nil		
	end

	status, msgbody = pcall(decode_client_message, msghead.msgname, msgbody, string.len(msgbody))
	if not status then
		filelog.sys_error("ServerBase:decode_client_message", msgbody)
		return nil, nil		
	end

	return msghead, msgbody
end

function ServerBase:exit_service()

	if self.tcpmng ~= nil then
		self.tcpmng.clear()
		--尽量保证先释放socket
		skynet.sleep(5)
	end

	for _, service in pairs(self.service_manager) do
		if self.gate_service ~= nil 
			and service == self.gate_service then
			skynet.kill(service)
		end
	end

	filelog.sys_info("ServerBase:exit_service")
	skynet.exit()
end

------------------------------------------------------------------
local function unpack_client_message(...)
	print("unpack_client_message  "..#{...})
	local x, y = ...
	--print(type(x),y)
	local decode = protobuf.decode("tutorial.Person" , x,y)
	print(decode.name)
	print(decode.id)

	return ServerBase:decode_client_message(...)
end

local function process_client_message(session, source, ...)
	print("process_client_message")
	ServerBase:process_client_message(session, source, ...)
end

local function process_other_message(session, source, ...)
	ServerBase:process_other_message(session, source, ...)
end

--[[
	svr_conf={
		svr_ip = "192.168.6.202",
		svr_port = 8888,
		svr_gate_type = "",
		svr_netpack = "",
		svr_tcpmng = "",
	},
]]
function ServerBase:start(svr_ip, svr_port, svr_gate_type, svr_netpack, svr_tcpmng, svr_id)
	if svr_id ~= nil and svr_id ~= "" then
		print ("server start:", svr_id)
		filelog.sys_info("init server:"..svr_id)
	end

	self.eventmng = require("eventmng")

	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = unpack_client_message,
		dispatch = process_client_message, 
	}

	if svr_netpack ~= nil and svr_netpack ~= "" then
		self.netpack = require(svr_netpack)
		self.socket = require("socket")
		self.pbc = require("pbc")
		self.pbc.init()
		self.requestmsgparser = require("protobuf")
	end

	--注册client消息处理模块
	if svr_ip ~= nil 
		and svr_port ~= nil 
		and svr_gate_type ~= nil
		and svr_ip ~= ""
		and svr_port ~= ""
		and svr_gate_type ~= "" then		
		self.gate_service = skynet.newservice(svr_gate_type)
		self.service_manager[svr_gate_type] = self.gate_service
	end

	if svr_tcpmng ~= nil and svr_tcpmng ~= "" then
		self.tcpmng = require(svr_tcpmng)		
	end

	--注册lua消息处理模块
	skynet.dispatch("lua", process_other_message)

	--初始化核心服务模块
	self:init()

	--初始化
	if svr_id ~= nil and svr_id ~= "" then
		msgproxy.init(svr_id)
		skynet.register(svr_id)
	end	
end

return ServerBase