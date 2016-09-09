local skynet = require "skynet"


local service
local TablesvrmsgHelper = {}

function TablesvrmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function TablesvrmsgHelper.get_tablepool()
	return service.get_tablepool()
end

function TablesvrmsgHelper.get_roomsvrs()
	return service.get_roomsvrs()
end

function TablesvrmsgHelper.get_identifycodes()
	return service.get_identifycodes()
end

function TablesvrmsgHelper.get_tableplayernumindexs()
	return service.get_tableplayernumindexs()
end

function TablesvrmsgHelper.get_friendtable_rid_indexs()
	return service.get_friendtable_rid_indexs()
end

function TablesvrmsgHelper.get_friendsignup_rid_indexs()
	return service.get_friendsignup_rid_indexs()
end


function TablesvrmsgHelper.clear_roomsvr(roomsvr_id)
	local roomsvrs = TablesvrmsgHelper.get_roomsvrs()
	local tablepool = TablesvrmsgHelper.get_tablepool()
	if roomsvrs[roomsvr_id] ~= nil then
		for roomtype, roomtypelist in pairs(roomsvrs[roomsvr_id]) do
			if roomtypelist  ~= nil and type(roomtypelist) == "table" then
				for table_id, _ in pairs(roomtypelist) do
					tablepool[table_id] = nil
				end
			end
		end
		roomsvrs[roomsvr_id] = nil
	end
end

return	TablesvrmsgHelper  