local skynet = require "skynet"
local eventmng = require "eventmng"
local msghelper = require "tablesvrmsghelper"
local timetool = require "timetool"
local commonconst = require "common_const"
require "skynet.manager"

local svr_id = ...
local table_pool = {
	--[[
		table_id = {
			table_id = 0,
			table_name = "",
			table_room_type = 0,
			table_game_type = 0,
			table_curplayernum = 0,
			table_maxplayernum = 0,
			table_mincarry = 0,
			table_maxcarry = 0, 
			table_small_blind = 0,
			table_big_blind = 0,
			table_ante = 0,
			roomsvr_id = "",
			table_state = 0,
    		--SNG
    		award_template_index = 0,
    		service_charge = 100,   --服务费
        	signup_fee = {},
			
			--朋友桌
			table_retain_time = 0, --朋友桌保留时间
			table_create_time = 0, --牌桌创建时间
			table_create_user=0,   --创建者rid
			table_createuser_logo = "",
			table_createuser_name = "",
			table_identify_code = "", --朋友桌验证码			
			table_player_list = {
				[rid] = {
					logo="",
					rolename="",
				}
			}, 
	]]
}

--服务器serverid、房间类型、游戏类型相关的索引
local roomsvrs = {
	--[[
		roomsvr_id = {
			room_type_id = {
				game_type_id = {
					num=0,		--累计在线人数
					table_id1,
					table_id2
				},
			},
			last_heart_time = 0,
		},
	]]
}

--和桌子人数对应的索引
local function BuildTablePlayernumIndexs()
	--[=[
	[CommonConst.ROOM_PRIMARY_TYPE] = {
		[CommonConst.GAME_CHIPS_TYPE] = {
			1,2,...10 指人数
		    [1]={
				--[[
					table_id=true,
				]]
			},
			[2]={},
			……
			[10]={},
		},
	]=]
	local t = {}
	for room_type = commonconst.ROOM_PRIMARY_TYPE, commonconst.ROOM_FRIEND_SNG_TYPE do
		t[room_type] = {}
		for game_type = commonconst.GAME_CHIPS_TYPE, commonconst.GAME_ADVANCE_TYPE do
			t[room_type][game_type] = {}
			for playernum = 1, 10 do
				t[room_type][game_type][playernum] = {}
			end
		end
	end
	return t
end

--和桌子人数对应的索引
local table_playernum_indexs = BuildTablePlayernumIndexs()

--私人场验证码索引
local identify_codes = {
	--[[
		[identify_code] = table_id,
	]]
}

--朋友桌以创建者rid做为索引
local friendtable_rid_indexs = {
	--[[
		[rid] = {
			table_id = true,
		}
	]]	
}

--报名者rid做为索引
local friendsignup_rid_indexs = {
	--[[
		[rid] = {
			table_id = true,
		}
	]]	
}


local TABLESVRD = {}


function  TABLESVRD.init()

	msghelper.init(TABLESVRD)

	eventmng.init(TABLESVRD)
	eventmng.add_eventbyname("notice", "tablesvrnoticemsg")
	eventmng.add_eventbyname("request", "tablesvrrequestmsg")
end

function TABLESVRD.send_msgto_client(msg,...)
end

function TABLESVRD.send_resmsgto_client(msgname, msg, ...)
end

function TABLESVRD.send_noticemsgto_client(msgname, msg, ...)
end

function TABLESVRD.process_client_message(session, source, ...)
end

function TABLESVRD.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function TABLESVRD.decode_client_message(...)
end
----------------------------------------------------------------------------------------------------
function TABLESVRD.get_tablepool()
	return table_pool
end

function TABLESVRD.get_roomsvrs()
	return roomsvrs
end

function TABLESVRD.get_identifycodes()
	return identify_codes
end

function TABLESVRD.get_tableplayernumindexs()
	return table_playernum_indexs
end

function TABLESVRD.get_friendtable_rid_indexs()
	return friendtable_rid_indexs
end

function TABLESVRD.get_friendsignup_rid_indexs()
	return friendsignup_rid_indexs
end

function TABLESVRD.tick()
	local now_time = timetool.get_time() * 100
	-- 检查roomsvrd是否过期
	for roomsvr_id, roomsvr in pairs(roomsvrs) do
		if roomsvr ~= nil then
			if roomsvr.last_heart_time ~= nil and roomsvr.last_heart_time * 100 + 3000 < now_time then
				eventmng.process(_, _, "lua", "notice", "roominit", roomsvr_id)
			end
		end
	end


end
function TABLESVRD.start_time_tick()
	skynet.fork(function()
		while true do
			skynet.sleep(500)
			TABLESVRD.tick()
		end
	end)
end
function TABLESVRD.start()

	--[[skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = TABLESVRD.decode_client_message,
		dispatch = TABLESVRD.process_client_message, 
	}]]


	skynet.dispatch("lua", TABLESVRD.process_other_message)

	--gate = skynet.newservice("wsgate")
	
end

skynet.start(function()
	TABLESVRD.init()
	TABLESVRD.start()
	skynet.register(svr_id)
end)
