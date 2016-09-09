local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablesvrmsghelper"
local commonconst = require "common_const"
local filename = "tablesvrnoticemsg.lua"
local tabletool = require "tabletool"
local timetool = require "timetool"
local TablesvrNoticeMsg = {}

function TablesvrNoticeMsg.process(session, source, event, ...)
	local f = TablesvrNoticeMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." TablesvrNoticeMsg.process invalid event:"..event)
		return nil
	end
	f(...)
end

function TablesvrNoticeMsg.roominit(roomsvr_id)
	msghelper.clear_roomsvr(roomsvr_id)
end

--处理roomsvr上报的全量table状态列表
function TablesvrNoticeMsg.report(roomsvr_id, table_list)
	if roomsvr_id == nil or table_list == nil then
		--filelog.sys_error(filename.." roomsvr_id == nil or table_list == nil")
		return
	end	

	for _, _table in pairs(table_list) do
		TablesvrNoticeMsg.tableupdate(roomsvr_id, _table)
	end
end
--更新桌子的状态
function TablesvrNoticeMsg.tableupdate(roomsvr_id, _table)
	if roomsvr_id == nil or _table == nil then
		--filelog.sys_error(filename.." roomsvr_id == nil or _table == nil")
		return
	end
	local tablepool = msghelper.get_tablepool()

	local pre_table = tablepool[_table.table_id]
	--这段代码是否需要待定(防止同一个id改变类型索引重复)
	--[[if pre_table ~= nil then
		TablesvrNoticeMsg.tabledelete(roomsvr_id, table.table_id)
	end]]

	_table.distribute_playernum = _table.table_curplayernum

	--构建索引
	local roomsvrs = msghelper.get_roomsvrs()
	if roomsvrs[roomsvr_id] == nil then
		local roomsvr = {}
		roomsvr.last_heart_time = timetool.get_time()
		roomsvr[_table.table_room_type] = {}
		local roomlist = roomsvr[_table.table_room_type]
		roomlist[_table.table_game_type] = {}
		local gamelist = roomlist[_table.table_game_type]
		gamelist[_table.table_id] = true
		gamelist.num = _table.table_curplayernum
		roomsvrs[roomsvr_id] = roomsvr
	else
		local roomsvr = roomsvrs[roomsvr_id]
		roomsvr.last_heart_time = timetool.get_time()
		if roomsvr[_table.table_room_type] == nil then
			roomsvr[_table.table_room_type] = {}
			local roomlist = roomsvr[_table.table_room_type]
			roomlist[_table.table_game_type] = {}
			local gamelist = roomlist[_table.table_game_type]
			gamelist[_table.table_id] = true
			gamelist.num = _table.table_curplayernum
		else
			local roomlist = roomsvr[_table.table_room_type]
			local gamelist = roomlist[_table.table_game_type]
			if gamelist == nil then
				roomlist[_table.table_game_type] = {}
				gamelist = roomlist[_table.table_game_type]
				gamelist.num = 0
			end
			gamelist[_table.table_id] = true
			if pre_table ~= nil then
				gamelist.num = gamelist.num + _table.table_curplayernum - pre_table.table_curplayernum			
			else
				gamelist.num = gamelist.num + _table.table_curplayernum
			end
		end		
	end

	--构建私人房验证码索引
	if _table.table_identify_code ~= nil then
		local identify_codes = msghelper.get_identifycodes()
		identify_codes[_table.table_identify_code] = _table.table_id
	end

	--以创建者rid构建私人房索引
	if (_table.table_room_type == commonconst.ROOM_PRIVATE_TYPE or _table.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE) and _table.table_create_user ~= nil then
		local friendtable_rid_indexs = msghelper.get_friendtable_rid_indexs()
		if friendtable_rid_indexs[_table.table_create_user] == nil then
			friendtable_rid_indexs[_table.table_create_user] = {}
		end
		local friend_table_list = friendtable_rid_indexs[_table.table_create_user]
		friend_table_list[_table.table_id] = true
	end

	--构建以桌子人数座位关键字的索引
	local table_playernumindexs = msghelper.get_tableplayernumindexs()
	local room_type_list
	local game_type_list
	local playernum = 0
	local table_list
	if pre_table ~= nil then
		playernum = pre_table.table_curplayernum
		if playernum == 0 then
			playernum = 10
		end
		room_type_list = table_playernumindexs[pre_table.table_room_type]
		if room_type_list ~= nil then
			game_type_list = room_type_list[pre_table.table_game_type]
			if game_type_list ~= nil then
				table_list = game_type_list[playernum]
				table_list[pre_table.table_id] = nil				
			end
		end
	end
	playernum = _table.table_curplayernum
	if playernum == 0 then
		playernum = 10
	end
	room_type_list = table_playernumindexs[_table.table_room_type]
	if room_type_list ~= nil then
		game_type_list = room_type_list[_table.table_game_type]
		if game_type_list ~= nil then
			table_list = game_type_list[playernum]
			table_list[_table.table_id] = true
		end
	end


	tablepool[_table.table_id] = _table
	
	--filelog.sys_protomsg("tablesvrd roomsvrs", roomsvrs)
end


--报名索引
function TablesvrNoticeMsg.tablesignup(roomsvr_id, _table)
	local friendsignup_rid_indexs = msghelper.get_friendsignup_rid_indexs()
	local rid = _table.rid
	if friendsignup_rid_indexs[rid] == nil then
		friendsignup_rid_indexs[rid] = {}
	end
	local friend_signup_list = friendsignup_rid_indexs[rid]
	friend_signup_list[_table.table_id] = true
end

--清除报名索引
function TablesvrNoticeMsg.tablesignupclear(roomsvr_id, _table)
	local friendsignup_rid_indexs = msghelper.get_friendsignup_rid_indexs()
	for _, rid in ipairs(_table.rids) do
		if friendsignup_rid_indexs[rid] then
			friendsignup_rid_indexs[rid][_table.table_id] = nil
		end
	end
end

function TablesvrNoticeMsg.tabledelete(roomsvr_id, table_id)
	if roomsvr_id == nil or table_id == nil then
		--filelog.sys_error(filename.." roomsvr_id == nil or table_id == nil")
		return
	end
	local roomsvrs = msghelper.get_roomsvrs()
	local tablepool = msghelper.get_tablepool()
	local table_playernumindexs = msghelper.get_tableplayernumindexs()

	local _table = tablepool[table_id]
	local roomsvr = roomsvrs[roomsvr_id]

	if roomsvrs[roomsvr_id] == nil then
		if table ~= nil then
			tablepool[table_id] = nil
		end
		return
	end

	roomsvr.last_heart_time = timetool.get_time()
	if _table ~= nil then
		local room_list = roomsvr[_table.table_room_type]
		if room_list ~= nil then
			local game_list = room_list[_table.table_game_type]
			if game_list ~= nil  and game_list[table_id] ~= nil then
				game_list[table_id] = nil
				game_list.num = game_list.num - tablepool[table_id].table_curplayernum
			else
				for _, gamelist in pairs(room_list) do
					if game_list[table_id] ~= nil then
						gamelist[table_id] = nil
						game_list.num = game_list.num - tablepool[table_id].table_curplayernum
					end
				end				
			end

			if #game_list == 0 then
				room_list[_table.table_game_type] = nil
			end

			if #room_list == 0 then
				roomsvr[_table.table_room_type] = nil
			end
		end

		--从私人房删除验证码索引
		if _table.table_identify_code ~= nil then
			local identify_codes = msghelper.get_identifycodes()
			identify_codes[_table.table_identify_code] = nil
		end

		--从创建者rid索引删除table_id
		if _table.table_room_type == commonconst.ROOM_PRIVATE_TYPE
			or _table.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE
		then
			local friendtable_rid_indexs = msghelper.get_friendtable_rid_indexs()
			if friendtable_rid_indexs[_table.table_create_user] ~= nil then
				local friend_table_list = friendtable_rid_indexs[_table.table_create_user]
				friend_table_list[_table.table_id] = nil
				if tabletool.getn(friend_table_list) == 0 then
					friendtable_rid_indexs[_table.table_create_user] = nil
				end
			end
		end

		local room_type_list = table_playernumindexs[_table.table_room_type]
		if room_type_list then
			for _, game_list in pairs(room_type_list) do
				for player_count, table_list in pairs(game_list) do
					if player_count~=10 then
						table_list[table_id] = nil
					end
				end
			end
		end

		tablepool[table_id] = nil
	else
		for _, roomlist in pairs(roomsvr) do
			if roomlist ~= nil and type(roomlist) == "table" then
				for _, gamelist in pairs(roomlist) do
					if gamelist[table_id] ~= nil then
						gamelist[table_id] = nil
						gamelist.num = gamelist.num - tablepool[table_id].table_curplayernum
					end
				end				
			end
		end
	end
end

function TablesvrNoticeMsg.roomheart(roomsvr_id)
	if roomsvr_id == nil then
		--filelog.sys_error(filename.." roomsvr_id == nil")
		return
	end

	local roomsvrs = msghelper.get_roomsvrs()
	if roomsvrs[roomsvr_id]  ~= nil then
		roomsvrs[roomsvr_id].last_heart_time = timetool.get_time()
	end
end

return TablesvrNoticeMsg