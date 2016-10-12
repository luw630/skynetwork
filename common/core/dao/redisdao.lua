local skynet = require "skynet"
local filelog = require "filelog"
local filename = "datadbdao.lua"

local DatadbDAO = {}


function  DatadbDAO.save_data(server_id, cmd, data, ...)
	if cmd == nil or data == nil then
		filelog.sys_error(filename.." [BASIC_DatadbDAO] DatadbDAO.save_data invalid params")
	else
		pcall(skynet.send, server_id, "lua", cmd, false, data, ...)
	end	
end

function  DatadbDAO.sync_save_data(server_id, cmd, data, ...)
	if cmd == nil or data == nil then
		filelog.sys_error(filename.." [BASIC_DatadbDAO] DatadbDAO.sync_save_data invalid params")
		return nil
	else
		local status, result, result_data = pcall(skynet.call, server_id, "lua", cmd, true, data, ...)
		if not status then
			filelog.sys_error(filename.." [BASIC_DatadbDAO] DatadbDAO.sync_save_data invalid params", result)
			return nil
		else
			return result, result_data
		end
	end	
end

function  DatadbDAO.query_data(server_id, cmd, data, ...)
	if cmd == nil or data == nil then
		filelog.sys_error(filename.." [BASIC_DatadbDAO] DatadbDAO.query_data invalid params")
		return nil
	end
	local status, result, result_data = pcall(skynet.call, server_id, "lua", cmd, true, data, ...)
	if not status then
		filelog.sys_error(filename.." [BASIC_DatadbDAO] DatadbDAO.sync_save_data invalid params", result)
		return nil
	else
		return result, result_data
	end
end

return DatadbDAO





