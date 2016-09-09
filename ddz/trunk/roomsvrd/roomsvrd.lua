local skynet = require "skynet"
local filelog = require "filelog"
local eventmng = require "eventmng"
local msghelper = require "roomsvrmsghelper"
local servicepoolmng = require "incrservicepoolmng"
local configtool = require "configtool"
local msgproxy = require "msgproxy"
local timetool = require "timetool"
require "skynet.manager"

local server_id = ...
local svr_conf
local ROOMSVRD = {}
local tablepool
local TableList = {
	--[[
	table_id = {
		table = ,
		isdelete = false,
		serviceid = ,
		identify_code = ,		
	},
	]]
}

--保存当前的随机码
local identify_codes ={
	
}

local rooms_config
local friend_table_id


function  ROOMSVRD.init()

	msghelper.init(ROOMSVRD)
	eventmng.init(ROOMSVRD)
	eventmng.add_eventbyname("cmd", "roomsvrcmdmsg")
	eventmng.add_eventbyname("request", "roomrequestmsg")
	
	--通知tablesvrd自己初始化
	msgproxy.send_broadcastmsgto_tablesvrd("roominit", server_id)
end

function ROOMSVRD.send_msgto_client(msg,...)
end

function ROOMSVRD.send_resmsgto_client(msgname, msg, ...)
end

function ROOMSVRD.send_noticemsgto_client(msgname, msg, ...)
end

function ROOMSVRD.process_client_message(session, source, ...)
end

function ROOMSVRD.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function ROOMSVRD.decode_client_message(...)
end
----------------------------------------------------------------------------------------------------
function ROOMSVRD.init_table_pool()
	tablepool = servicepoolmng:new({}, {service_name="table", service_size=svr_conf.tablesize, incr=100})
end
function ROOMSVRD.set_conf(conf)
	svr_conf = conf
end

function ROOMSVRD.get_conf(conf)
	return svr_conf
end

function ROOMSVRD.generate_identifycode()
	local code = string.match(server_id, "%a*_(%d+)")
	math.randomseed(timetool.get_time())
	while true do		
		for i = 1, 4 do
			code = code..(math.random(0, 9))
		end
		if identify_codes[code] == nil then
			break
		end
		code = string.match(server_id, "%a*_(%d+)")
	end

	return code
end

function ROOMSVRD.load_config()
	local config_filename = svr_conf.tablecfgfile
	if config_filename == nil then
		filelog.sys_error("ROOMSVRD.load_config failed config_filename == nil")
		return
	end
	rooms_config = configtool.load_config(config_filename)

	--将所有已存在的桌子标为可删除
	for id , table_item in pairs(TableList) do
		if table_item ~= nil then
			table_item.isdelete = true
		end
	end

	--创建桌子
	for _ , tablelist_conf in pairs(rooms_config) do
		if tablelist_conf ~= nil and type(tablelist_conf) == "table" then
			local count = 1
			local begin_id = tablelist_conf.begin_id

			while count <= tablelist_conf.table_num do
				if TableList[begin_id] == nil then
					--创建新的
					local tableservice = tablepool:create_service()
					if tableservice ~= nil then
						TableList[begin_id] = {}
						TableList[begin_id].table = tableservice.service
						TableList[begin_id].serviceid = tableservice.id
						TableList[begin_id].isdelete = false
						local result = skynet.call(TableList[begin_id].table, "lua", "cmd", "start", tablelist_conf.table_conf, server_id, begin_id)
						if not result then
							filelog.sys_error("ROOMSVRD roomsvr create table(:"..begin_id..") failed")
							TableList[begin_id] = nil
							tablepool:delete_service(tableservice.id)
						end 
					else
						filelog.sys_error("ROOMSVRD roomsvr's tablepool not enough tableservice!")
					end
				else
					--通知桌子更新配置
					TableList[begin_id].isdelete = false
					skynet.send(TableList[begin_id].table, "lua", "cmd", "reload", tablelist_conf.table_conf)
				end
				begin_id = begin_id + 1
				count = count + 1
			end 
		end
	end

	--删除需要删除的桌子
	for id , table_item in pairs(TableList) do
		if table_item ~= nil and table_item.isdelete then
			skynet.send(TableList[id].table, "lua", "cmd", "delete")			
		end
	end 	
end

function ROOMSVRD.reload_config()
	filelog.sys_info("---------------ROOMSVRD.reload_config--------------")
	ROOMSVRD.load_config()
end

function ROOMSVRD.delete_table(table_id)
	local table = TableList[table_id]
	if table ~= nil then
		tablepool:delete_service(table.serviceid)
		if table.identify_code ~= nil then
			identify_codes[table.identify_code] = nil
		end
		TableList[table_id] = nil
	end
end

function ROOMSVRD.create_friend_table(conf)
	local identify_code = nil
	if rooms_config ~= nil then
		if friend_table_id == nil then
			friend_table_id = rooms_config.uniqueid*100000
		end

		local tableservice = tablepool:create_service()
		if tableservice ~= nil then
			--生成随机码
			identify_code = ROOMSVRD.generate_identifycode()

			TableList[friend_table_id] = {}
			TableList[friend_table_id].table = tableservice.service
			TableList[friend_table_id].serviceid = tableservice.id
			TableList[friend_table_id].isdelete = false
			TableList[friend_table_id].identify_code = identify_code

			conf.identify_code = identify_code
			conf.table_create_time = timetool.get_time()


			local result = skynet.call(TableList[friend_table_id].table, "lua", "cmd", "start", conf, server_id, friend_table_id)
			if not result then
				filelog.sys_error("ROOMSVRD.create_friend_table(:"..friend_table_id..") failed")
				TableList[friend_table_id] = nil
				tablepool:delete_service(tableservice.id)
				return false, identify_code
			end
			friend_table_id = friend_table_id + 1
			identify_codes[identify_code] = true	
		else
			filelog.sys_error("ROOMSVRD.create_friend_table roomsvr's tablepool not enough tableservice!")
			return false, identify_code
		end
		return true, identify_code
	end

	return false, identify_code
end

function ROOMSVRD.tick()
	--发送心跳包
	msgproxy.send_broadcastmsgto_tablesvrd("roomheart", server_id)
end

function ROOMSVRD.get_tablelist()
	return TableList
end

function ROOMSVRD.start_time_tick()
	skynet.fork(function()
		while true do
			skynet.sleep(500)
			ROOMSVRD.tick()
		end
	end)
end

function ROOMSVRD.start()
	--[[skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = ROOMSVRD.decode_client_message,
		dispatch = ROOMSVRD.process_client_message, 
	}]]


	skynet.dispatch("lua", ROOMSVRD.process_other_message)

	ROOMSVRD.start_time_tick()	

	--gate = skynet.newservice("wsgate")
	
end

skynet.start(function()
	ROOMSVRD.init()
	ROOMSVRD.start()
	skynet.register(server_id)
end)
