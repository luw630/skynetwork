local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablestatesvrhelper"
local base = require "base"

local TableStatesvrRequest = {}

function TableStatesvrRequest.process(session, source, event, ...)
	local f = TableStatesvrRequest[event] 
	if f == nil then
		return
	end
	f(...)
end

function TableStatesvrRequest.gettablestatebycreateid(request)
	local server = msghelper:get_server()	
	local table_pool = server.table_pool
	local create_table_indexs = server.create_table_indexs
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local id = create_table_indexs[request.create_table_id]
	local tableinfo = table_pool[id]

	if id == nil or tableinfo == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_CREATETABLEID
		responsemsg.errcodedes = "无效的桌号！"
		base.skynet_retpack(responsemsg)
		return
	end
	responsemsg.tablestate = tableinfo
	base.skynet_retpack(responsemsg)
end

function TableStatesvrRequest.getfriendtablelist(request)
	local server = msghelper:get_server()	
	local table_pool = server.table_pool
	local tableinfo
	local createusers_table_indexs = server.createusers_table_indexs

	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}

	if createusers_table_indexs[request.rid] == nil then
		responsemsg.tablelist = {}
		base.skynet_retpack(responsemsg)
		return
	end

	responsemsg.tablelist = {}	
	for id, _ in pairs(createusers_table_indexs[request.rid]) do
		tableinfo = table_pool[id]
		if tableinfo ~= nil then
			table.insert(responsemsg.tablelist, tableinfo)
		end
	end

	base.skynet_retpack(responsemsg)
end

return TableStatesvrRequest