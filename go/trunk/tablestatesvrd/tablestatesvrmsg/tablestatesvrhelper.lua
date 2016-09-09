local skynet = require "skynet"
local filelog = require "filelog"
local helperbase = require "helperbase"
local msgproxy = require "msgproxy"
local filename = "tablestatesvrhelper.lua"

local TableStatesvrHelper = helperbase:new({})

function TableStatesvrHelper:get_roomsvr_states()
	msgproxy.sendrpc_broadcastmsgto_roomsvrd("get_roomsvr_states") 	
end 

function TableStatesvrHelper:clear_roomsvrd(roomsvr_id)
	local server = self.server
	local roomsvrs = server.roomsvrs
	local table_pool = server.table_pool
	if roomsvrs[roomsvr_id] ~= nil then
		for room_type, room_list in pairs(roomsvrs[roomsvr_id]) do
			if room_list  ~= nil and type(room_list) == "table" then
				for _, game_list in pairs(room_list) do
					for id, _ in pairs(game_list) do						
						table_pool[id] = nil
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
	for roomsvr_id, roomsvr in pairs(self.roomsvrs) do
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