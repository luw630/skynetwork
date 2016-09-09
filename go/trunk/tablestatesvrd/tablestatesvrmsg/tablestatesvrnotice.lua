local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablestatesvrhelper"
local timetool = require "timetool"
local tabletool = require "tabletool"
local base = require "base"

local TableStatesvrNotice = {}

function TableStatesvrNotice.process(session, source, event, ...)
	local f = TableStatesvrNotice[event] 
	if f == nil then
		return
	end
	f(...)
end

function TableStatesvrNotice.init(roomsvr_id)
	msghelper:clear_roomsvrd(roomsvr_id)
end

function TableStatesvrNotice.update(roomsvr_id, tableinfo)
	if roomsvr_id == nil or tableinfo == nil then
		return
	end

	local server = msghelper:get_server()	
	local table_pool = server.table_pool
	local roomsvrs = server.roomsvrs
	local create_table_indexs = server.create_table_indexs
	local pre_table = table_pool[tableinfo.id]
	--这段代码是否需要待定(防止同一个id改变类型索引重复)
	--[[if pre_table ~= nil then
		TableStatesvrNotice.delete(roomsvr_id, tableinfo.id)
	end]]

	--构建索引
	local roomlist
	local gamelist
	local roomsvr
	if roomsvrs[roomsvr_id] == nil then
		roomsvr = {}
		roomsvr.update_time = timetool.get_time()
		roomsvr[tableinfo.room_type] = {}
		
		roomlist = roomsvr[tableinfo.room_type]
		roomlist[tableinfo.game_type] = {}
		
		gamelist = roomlist[tableinfo.game_type]
		gamelist[tableinfo.id] = true
		gamelist.num = tableinfo.cur_player_num
		roomsvrs[roomsvr_id] = roomsvr
	else
		roomsvr = roomsvrs[roomsvr_id]
		roomsvr.update_time = timetool.get_time()
		if roomsvr[tableinfo.room_type] == nil then
			roomsvr[tableinfo.room_type] = {}
			
			roomlist = roomsvr[tableinfo.room_type]
			roomlist[tableinfo.game_type] = {}
			
			gamelist = roomlist[tableinfo.game_type]
			gamelist[tableinfo.id] = true
			gamelist.num = tableinfo.cur_player_num
		else
			roomlist = roomsvr[tableinfo.room_type]
			gamelist = roomlist[tableinfo.game_type]
			if gamelist == nil then
				roomlist[tableinfo.game_type] = {}
				gamelist = roomlist[tableinfo.game_type]
				gamelist.num = 0
			end
			gamelist[tableinfo.id] = true
			if pre_table ~= nil then
				gamelist.num = gamelist.num + tableinfo.cur_player_num - pre_table.cur_player_num			
			else
				gamelist.num = gamelist.num + tableinfo.cur_player_num
			end
		end		
	end

	--构建私人房验证码索引
	if tableinfo.create_table_id ~= nil then
		create_table_indexs[tableinfo.create_table_id] = tableinfo.id
	end

	table_pool[tableinfo.id] = tableinfo	
end

function TableStatesvrNotice.delete(roomsvr_id, id)
	if roomsvr_id == nil or id == nil then
		return
	end

	local server = msghelper:get_server()	
	local table_pool = server.table_pool
	local roomsvrs = server.roomsvrs
	local create_table_indexs = server.create_table_indexs

	local tableinfo = table_pool[id]
	local roomsvr = roomsvrs[roomsvr_id]

	if roomsvr == nil then
		if tableinfo ~= nil then
			table_pool[id] = nil
		end
		return
	end

	local room_list
	local game_list
	local num = 0
	roomsvr.update_time = timetool.get_time()
	if tableinfo ~= nil then
		room_list = roomsvr[tableinfo.room_type]
		if room_list ~= nil then
			game_list = room_list[tableinfo.game_type]
			if game_list ~= nil  and game_list[id] ~= nil then
				game_list[id] = nil
				game_list.num = game_list.num - tableinfo.cur_player_num
			end

			num = game_list.num
			game_list.num = nil
			if tabletool.is_emptytable(game_list) then
				room_list[tableinfo.game_type] = nil
			else
				game_list.num = num
			end

			if tabletool.is_emptytable(room_list) then
				roomsvr[tableinfo.room_type] = nil
			end
		end

		--从私人房删除验证码索引
		if tableinfo.create_table_id ~= nil then
			create_table_indexs[tableinfo.create_table_id] = nil
		end
		table_pool[id] = nil
	else
		for _, roomlist in pairs(roomsvr) do
			if roomlist ~= nil and type(roomlist) == "table" then
				for _, gamelist in pairs(roomlist) do
					if gamelist[id] ~= nil then
						gamelist[id] = nil
						gamelist.num = gamelist.num - tableinfo.cur_player_num
					end
				end				
			end
		end
	end
end

function TableStatesvrNotice.heart(roomsvr_id)
	if roomsvr_id == nil then
		return
	end

	local server = msghelper:get_server()	
	local roomsvrs = server.roomsvrs
	local roomsvr = roomsvrs[roomsvr_id]
	roomsvr.update_time = timetool.get_time()
end

return TableStatesvrNotice