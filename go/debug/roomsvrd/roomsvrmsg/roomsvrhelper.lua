local skynet = require "skynet"
local filelog = require "filelog"
local helperbase = require "helperbase"
local msgproxy = require "msgproxy"
local servicepoolmng = require "incrservicepoolmng"
local timetool = require "timetool"
local math = math
local string = string

local filename = "roomsvrhelper.lua"

local RoomsvrHelper = helperbase:new({})

function RoomsvrHelper:start_time_tick()
	skynet.fork(function()
		while true do
			skynet.sleep(3000)
			--发送心跳包
			msgproxy.sendrpc_broadcastmsgto_tablesvrd("heart", skynet.getenv("svr_id"))
		end
	end)	
end

function RoomsvrHelper:set_idle_table_pool(conf)
	self.server.idle_table_mng = servicepoolmng:new({}, {service_name="table", service_size=conf.tablesize, incr=conf.tableinrc})
end

function RoomsvrHelper:generate_create_table_id()
	local code = string.match(skynet.getenv("svr_id"), "%a*_(%d+)")
	math.randomseed(timetool.get_time())
	while true do		
		for i = 1, 4 do
			code = code..(math.random(0, 9))
		end
		if self.server.create_table_ids[code] == nil then
			break
		end
		code = string.match(skynet.getenv("svr_id"), "%a*_(%d+)")
	end
	return code
end

function RoomsvrHelper:delete_table(id)
	local tableinfo = self.server.used_table_pool[id]
	if tableinfo ~= nil then
		if tableinfo.create_table_id ~= nil then
			self.server.create_table_ids[tableinfo.create_table_id] = nil
		end
		self.server.used_table_pool[id] = nil
	end
end

function RoomsvrHelper:create_friend_table(conf)
	local tableservice = self.server.idle_table_mng:create_service()
	local create_table_id
	local tableinfo
	if tableservice ~= nil then
		--生成随机码
		create_table_id = self:generate_create_table_id()

		self.server.used_table_pool[self.server.friend_table_id] = {}
		tableinfo = self.server.used_table_pool[self.server.friend_table_id]
		tableinfo.table_service = tableservice.service
		tableinfo.isdelete = false
		tableinfo.table_service_id = tableservice.id
		tableinfo.create_table_id = create_table_id

		conf.create_table_id = create_table_id
		conf.create_time = timetool.get_time()
		conf.id = self.server.friend_table_id
		local result = skynet.call(tableinfo.table_service, "lua", "cmd", "start", conf, skynet.getenv("svr_id"))
		if not result then
			filelog.sys_error("RoomsvrHelper:create_friend_table(:"..self.server.friend_table_id..") failed")
			pcall(skynet.kill, tableinfo.table_service)
			self.server.used_table_pool[self.server.friend_table_id] = nil
			return false, create_table_id

		end
		self.server.friend_table_id = self.server.friend_table_id + 1
		self.server.create_table_ids[create_table_id] = true	
	else
		filelog.sys_error("RoomsvrHelper:create_friend_table roomsvr's idle_table_mng not enough tableservice!")
		return false, create_table_id
	end

	return true, create_table_id
end

return	RoomsvrHelper 