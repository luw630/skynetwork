local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablesvrmsghelper"
local commonconst = require "common_const"
local filename = "tablesvrrequestmsg.lua"
local tabletool = require "tabletool"
local base = require "base"
local TablesvrRequestMsg = {}

function TablesvrRequestMsg.process(session, source, event, ...)
	local f = TablesvrRequestMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." TablesvrRequestMsg.process invalid event:"..event)
		base.skynet_retpack(nil)
		return nil
	end
	skynet.ret(skynet.pack(f(...)))	 
end

local function sng_quick_start(request, responsemsg)
	local tablepool = msghelper.get_tablepool()
	local roomsvrs = msghelper.get_roomsvrs()
	for roomsvr_id, roomsvr in pairs(roomsvrs) do
		if roomsvr ~= nil and type(roomsvr) == "table" then
			local roomlist = roomsvr[request.room_type]
			if roomlist ~= nil then
				local gamelist = roomlist[request.game_type]
				if gamelist ~= nil then
					for id, _ in pairs(gamelist) do
						local _table = tablepool[id]
						if _table.distribute_playernum < _table.table_maxplayernum then
							responsemsg.table_id = _table.table_id
							responsemsg.roomsvr_id = _table.roomsvr_id
							responsemsg.table_address = _table.table_address

							--尽量减少多人同时入桌时提示牌桌满的概率，根据实际调整
							_table.distribute_playernum = _table.distribute_playernum + 1
							return true
						end 
					end
				end
			end
		end
	end
	responsemsg.resultdes = "当前没有可用的房间！"
	return false
end

local function private_quick_start(request, responsemsg)
	local identify_codes = msghelper.get_identifycodes()
	local tablepool = msghelper.get_tablepool()
	local table_id = identify_codes[request.identify_code]
	local _table = tablepool[table_id]
	if request.identify_code ~= nil and table_id ~= nil  and tablepool[table_id] ~= nil then
		responsemsg.table_id = _table.table_id
		responsemsg.roomsvr_id = _table.roomsvr_id
		responsemsg.table_address = _table.table_address
		return true		
	end

	responsemsg.resultdes = "请输入正确的房间号码！"	
	return false
end

local function other_quick_start(request, responsemsg)
	local tablepool = msghelper.get_tablepool()
	local table_playernumindexs = msghelper.get_tableplayernumindexs()
	local room_type_list
	local game_type_list
	local table_list
	local _table

	room_type_list = table_playernumindexs[request.room_type]
	if room_type_list == nil then
		responsemsg.resultdes = "当前没有可用的房间！"		
		return false
	end
	game_type_list = room_type_list[request.game_type]
	if game_type_list == nil then
		responsemsg.resultdes = "当前没有可用的房间！"		
		return false
	end

	for i=8, 1, -1 do
		table_list = game_type_list[i]
		for table_id, _ in pairs(table_list) do
			_table = tablepool[table_id]
			if _table ~= nil and i < _table.table_maxplayernum and _table.distribute_playernum < _table.table_maxplayernum then
			    if request.room_type == commonconst.ROOM_SNG_TYPE then
				    if _table.table_state == commonconst.TABLE_STATE_WAIT_MIN_PLAYER 
				    	or _table.table_state == commonconst.TABLE_STATE_GAME_END then
						responsemsg.table_id = _table.table_id
						responsemsg.roomsvr_id = _table.roomsvr_id
						responsemsg.table_address = _table.table_address
						_table.distribute_playernum = _table.distribute_playernum + 1
				        return true
				    end			    	
			    else
					responsemsg.table_id = _table.table_id
					responsemsg.roomsvr_id = _table.roomsvr_id
					responsemsg.table_address = _table.table_address
					_table.distribute_playernum = _table.distribute_playernum + 1			    	
					return true	
			    end
			end
		end
	end

	table_list = game_type_list[10]
	for table_id, _ in pairs(table_list) do
		_table = tablepool[table_id]
		if _table ~= nil then
			responsemsg.table_id = _table.table_id
			responsemsg.roomsvr_id = _table.roomsvr_id
			responsemsg.table_address = _table.table_address
			return true				
		end 
	end

	responsemsg.resultdes = "当前没有可用的房间！"
	return false	
end

function TablesvrRequestMsg.quick_start(request)

	local responsemsg = {issucces = true, }
	local isfind = false

	if request.room_type == commonconst.ROOM_PRIVATE_TYPE
		or request.room_type == commonconst.ROOM_FRIEND_SNG_TYPE
	then
		isfind = private_quick_start(request, responsemsg)
	else
		isfind = other_quick_start(request, responsemsg)
	end

	if isfind then
		return responsemsg
	else
		filelog.sys_error(filename.." not enough table")
		responsemsg.issucces = false
		return responsemsg
	end
end

local function get_sngtables(request, responsemsg)
	local game_type_list = {}
	local tablepool = msghelper.get_tablepool()
	local roomsvrs = msghelper.get_roomsvrs()
	for roomsvr_id, roomsvr in pairs(roomsvrs) do
		if roomsvr ~= nil and type(roomsvr) == "table" then
			local roomlist = roomsvr[request.room_type]
			if roomlist ~= nil then
				for gametype, gamelist in pairs(roomlist) do
					for id, _ in pairs(gamelist) do
						if id ~= "num" then
							if game_type_list[gametype] == nil then
								responsemsg.tablelist[id] = tablepool[id]
								responsemsg.tablelist[id].sng_totalplayernum = gamelist.num
								game_type_list[gametype] = id
							else
								local tableid = game_type_list[gametype]
								local tatolnum = responsemsg.tablelist[tableid].sng_totalplayernum
								responsemsg.tablelist[tableid].sng_totalplayernum = tatolnum + gamelist.num
							end
							break
						end
					end						
				end
			end
		end
	end
end

local function get_common_tables(request, responsemsg)
	local game_type_list = {}
	local tablepool = msghelper.get_tablepool()
	local roomsvrs = msghelper.get_roomsvrs()
    
	local table_playernumindexs = msghelper.get_tableplayernumindexs()
	local room_type_list = table_playernumindexs[request.room_type]

	local room_types = {commonconst.ROOM_PRIMARY_TYPE, commonconst.ROOM_MIDDLE_TYPE, commonconst.ROOM_ADVANCE_TYPE, commonconst.ROOM_MASTER_TYPE, commonconst.ROOM_DUEL_TYPE}
	for _, room_type in ipairs(room_types) do
		for roomsvr_id, roomsvr in pairs(roomsvrs) do
			if roomsvr ~= nil and type(roomsvr) == "table" then
				local roomlist = roomsvr[room_type]
				if roomlist ~= nil then
					for gametype, gamelist in pairs(roomlist) do
						for id, _ in pairs(gamelist) do
							if id ~= "num" then
								if game_type_list[commonconst.GAME_CHIPS_TYPE] == nil then
									responsemsg.tablelist[id] = tablepool[id]
									responsemsg.tablelist[id].sng_totalplayernum = gamelist.num
								   game_type_list[commonconst.GAME_CHIPS_TYPE] = id
								else
									local tableid = room_type_list[commonconst.GAME_CHIPS_TYPE]
									local tatolnum = responsemsg.tablelist[tableid].sng_totalplayernum
									responsemsg.tablelist[tableid].sng_totalplayernum = tatolnum + gamelist.num
								end
								break
							end
						end						
					end
				end
			end
		end
		game_type_list[commonconst.GAME_CHIPS_TYPE] = nil	
	end
end

local function get_tables(request, responsemsg)
	local tablepool = msghelper.get_tablepool()
	local roomsvrs = msghelper.get_roomsvrs()
	for roomsvr_id, roomsvr in pairs(roomsvrs) do
		if roomsvr ~= nil and type(roomsvr) == "table" then
			local roomlist = roomsvr[request.room_type]
			if roomlist ~= nil then
				for _, gamelist in pairs(roomlist) do
					for id, _ in pairs(gamelist) do
						if id ~= "num" then
							responsemsg.tablelist[id] = tablepool[id]
						end
					end						
				end
			end
		end
	end
end


function TablesvrRequestMsg.get_tables(request)

	local responsemsg = {issucces = true, room_type = request.room_type, tablelist = {}, }
	if request.room_type == 0 then
		get_common_tables(request, responsemsg)
	else
		if request.room_type == commonconst.ROOM_SNG_TYPE then
			get_sngtables(request, responsemsg)
		else
			get_tables(request, responsemsg)
		end
	end

	return responsemsg
end

function TablesvrRequestMsg.getfriendtables(request)
	local responsemsg = {issucces = true, room_type = request.room_type, tablelist = {}, }
	local tablepool = msghelper.get_tablepool()
	local friendtable_rid_indexs = msghelper.get_friendtable_rid_indexs()
	local friend_table_list

	for _, rid in pairs(request.friends.friends) do
		friend_table_list = friendtable_rid_indexs[rid]
		if friend_table_list ~= nil then
			for id, _ in pairs(friend_table_list) do
				responsemsg.tablelist[id] = tablepool[id]
			end
		end
	end

	friend_table_list = friendtable_rid_indexs[request.rid]
	if friend_table_list ~= nil then
		for id, _ in pairs(friend_table_list) do
			responsemsg.tablelist[id] = tablepool[id]
		end
	end

	local friendsignup_rid_indexs = msghelper.get_friendsignup_rid_indexs()
	local friend_signup_list = friendsignup_rid_indexs[request.rid]
	if friend_signup_list then
		for id, _ in pairs(friend_signup_list) do
			responsemsg.tablelist[id] = tablepool[id]
		end
	end

	if request.friend_table_list ~= nil then
		for id, _ in pairs(request.friend_table_list) do
			responsemsg.tablelist[id] = tablepool[id]
		end		
	end

	return responsemsg
end

--获得指定玩家创建桌子数
function TablesvrRequestMsg.friendtablenum(rid)
	local friendtable_rid_indexs = msghelper.get_friendtable_rid_indexs()
	local friend_table_list = friendtable_rid_indexs[rid]
	
	if friend_table_list == nil then
		return 0
	else
		return tabletool.getn(friend_table_list)
	end
end

--查询指定桌号的桌子
function TablesvrRequestMsg.get_tablebyid(table_id)
	local tablepool = msghelper.get_tablepool()
	return tablepool[table_id]
end

--查询指定类型玩法的人数
function TablesvrRequestMsg.get_game_online_count(room_type)
	local roomsvrs = msghelper.get_roomsvrs()

	local count = 0
	for _, roomsvr in pairs(roomsvrs) do
		local roomlist = roomsvr[room_type]
		if roomlist then
			for _, gamelist in pairs(roomlist) do
				count = count + gamelist.num
			end
		end
	end

	return count
end

--查询指定类型玩法的牌桌和人数
function TablesvrRequestMsg.get_table_list(room_type)
	local table_playernumindexs = msghelper.get_tableplayernumindexs()
	local tablepool = msghelper.get_tablepool()

	local list = {}
	local room = {}
	local count = {}
	local room_type_list = table_playernumindexs[room_type]
	if room_type_list then
		for _, game_list in pairs(room_type_list) do
			for player_count, table_list in pairs(game_list) do
				if player_count~=10 then
					for table_id in pairs(table_list) do
						if tablepool[table_id] ~= nil then
							table.insert(list, table_id)
							table.insert(room, tablepool[table_id].roomsvr_id)
							table.insert(count, player_count)
						end
					end
				end
			end
		end
	end

	return list, room, count
end

return TablesvrRequestMsg