local skynet = require "skynet"
local commondatadao = require "commondatadao"
local playerdatadao = require "playerdatadao"
local filelog = require "filelog"
local service
local RoomsvrmsgHelper = {}

function RoomsvrmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function RoomsvrmsgHelper.reload_config()
	service.reload_config()
end

function RoomsvrmsgHelper.delete_table(table_id)
	service.delete_table(table_id)
end

function RoomsvrmsgHelper.get_tablelist()
	return service.get_tablelist()
end

function RoomsvrmsgHelper.create_friend_table(conf)
	return service.create_friend_table(conf)
end

function RoomsvrmsgHelper.create_friend_sng_table(conf)
	--此处可复用create_friend_table
	return service.create_friend_table(conf)
end

function RoomsvrmsgHelper.set_conf(conf)
	service.set_conf(conf)
end

function RoomsvrmsgHelper.get_conf()
	service.get_conf()
end

function RoomsvrmsgHelper.load_config()
	service.load_config()
end

function RoomsvrmsgHelper.init_table_pool()
	service.init_table_pool()
end

function RoomsvrmsgHelper.recover_friendtable_records()
	local records = commondatadao.query_friendtable_records()
	if records == nil then
		return
	end

	local is_findcreate_rid = false
	for _, record in pairs(records) do
		is_findcreate_rid = false
		for rid, _ in pairs(record.player_list) do
			if rid == record.create_user_rid then
				is_findcreate_rid = true
			end
			playerdatadao.save_player_tablerecorditem(rid, record)
		end
		if not is_findcreate_rid then
			playerdatadao.save_player_tablerecorditem(record.create_user_rid, record)
		end
		commondatadao.delete_friendtable_record(tostring(record.create_user_rid)..tostring(record.create_time))
	end
end

return	RoomsvrmsgHelper  