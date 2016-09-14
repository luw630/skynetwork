local skynet = require "skynet"
local filelog = require "filelog"
local helperbase = require "helperbase"
local msgproxy = require "msgproxy"
local tabletool = require "tabletool"
local timetool = require "timetool"
local filename = "tablestatesvrhelper.lua"
local TableStatesvrHelper = helperbase:new({})

function TableStatesvrHelper:get_roomsvr_states()
	msgproxy.sendrpc_broadcastmsgto_roomsvrd("get_roomsvr_states") 	
end 

function TableStatesvrHelper:clear_roomsvrd(roomsvr_id)
	local server = self.server
	local roomsvrs = server.roomsvrs
	local table_pool = server.table_pool
	local create_table_indexs = server.create_table_indexs
	local createusers_table_indexs = server.createusers_table_indexs
	local tableinfo
	if roomsvrs[roomsvr_id] ~= nil then
		for room_type, room_list in pairs(roomsvrs[roomsvr_id]) do
			if room_list  ~= nil and type(room_list) == "table" then
				for _, game_list in pairs(room_list) do
					for id, _ in pairs(game_list) do						
						tableinfo = table_pool[id]
						table_pool[id] = nil

						--从私人房删除验证码索引
						if tableinfo ~= nil and tableinfo.create_table_id ~= nil then
							create_table_indexs[tableinfo.create_table_id] = nil
						end
						--从创建者索引中删除桌子
						if tableinfo ~=nil and tableinfo.create_user_rid ~= nil then
							local table_ids = createusers_table_indexs[tableinfo.create_user_rid]
							if table_ids ~= nil then
								table_ids[tableinfo.id] = nil
								if tabletool.is_emptytable(table_ids) then
									createusers_table_indexs[tableinfo.create_user_rid] = nil
								end
							end
						end
					end
				end
			end
		end
		roomsvrs[roomsvr_id] = nil
	end
end

function TableStatesvrHelper:tick()
	local now_time = timetool.get_time()
	-- 检查roomsvrd是否过期
	for roomsvr_id, roomsvr in pairs(self.server.roomsvrs) do
		if roomsvr ~= nil then
			if roomsvr.update_time ~= nil and roomsvr.update_time + 300 < now_time then
				self:event_process("lua", "notice", "init", roomsvr_id)
			end
		end
	end
end

function TableStatesvrHelper:start_time_tick()
	skynet.fork(function()
		while true do
			skynet.sleep(1000)
			TableStatesvrHelper:tick()
		end
	end)	
end

return	TableStatesvrHelper 