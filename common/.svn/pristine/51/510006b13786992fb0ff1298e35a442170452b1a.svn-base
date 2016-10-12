local skynet = require "skynet"
local filelog = require "filelog"
local json = require "cjson"
local mysql = require "mysql"

local filename = "mysqldao.lua"
local MysqlDao = {}

json.encode_sparse_array(true,1,1)


local wrap_val = function(val)
    if type(val) == "number" then
        return tostring(val)
    elseif type(val) == "string" then
        return mysql.quote_sql_str(val)
    elseif type(val) == "boolean" then
    	if val then
    		return 1
    	else
    		return 0
    	end
    elseif type(val) == "table" then
    	return  mysql.quote_sql_str(json.encode(val))
    else
    	return tostring(val)       
    end
end

local function to_update_sql(tablename, tablerecord, condition)
	local sql = "update "..tablename.." set "
	local count = 1
	for k, v in pairs(tablerecord) do
		if count == 1 then
			sql = sql..tostring(k).."="..wrap_val(v)
			count = count + 1
		else
			sql = sql..", "..tostring(k).."="..wrap_val(v)
			count = count + 1
			
		end
	end

	if condition ~= nil and type(condition) == "table" then
		count = 1
		for k, v in pairs(condition) do
			if count == 1 then
				sql = sql.." where "..tostring(k).."="..wrap_val(v)
				count = count + 1
			else
				sql = sql.." and "..tostring(k).."="..wrap_val(v)			
				count = count + 1
			end
		end
	elseif condition ~= nil and type(condition) == "string" then
		sql = sql.." "..condition
	end

	return sql
end 

local function to_select_sql(tablename, condition)
	local sql = "select * from "..tablename
	if condition ~= nil and type(condition) == "table" then
		count = 1
		for k, v in pairs(condition) do
			if count == 1 then
				sql = sql.." where "..tostring(k).."="..wrap_val(v)
				count = count + 1
			else
				sql = sql.." and "..tostring(k).."="..wrap_val(v)			
				count = count + 1
			end
		end
	elseif condition ~= nil and type(condition) == "string" then
		sql = sql.." "..condition
	end
	return sql	
end

local function to_insert_sql(tablename, tablerecord)
	local sql = "insert ignore into "..tablename
	local sql1 = "("
	local sql2 = " values("
	local count = 1
	for k, v in pairs(tablerecord) do
		if count == 1 then
			sql1 = sql1..tostring(k)
			sql2 = sql2..wrap_val(v)
			count = count + 1
		else
			sql1 = sql1..", "..tostring(k)			
			sql2 = sql2..", "..wrap_val(v)
		end
	end
	sql1 = sql1..")"
	sql2 = sql2..")"
	sql = sql..sql1..sql2
	return sql
end

local function to_delete_sql(tablename, condition)
	local sql = "delete ignore from "..tablename
	if condition ~= nil and type(condition) == "table" then
		count = 1
		for k, v in pairs(condition) do
			if count == 1 then
				sql = sql.." where "..tostring(k).."="..wrap_val(v)
				count = count + 1
			else
				sql = sql.." and "..tostring(k).."="..wrap_val(v)			
				count = count + 1
			end
		end
	elseif condition ~= nil and type(condition) == "string" then
		sql = sql.." "..condition
	end
	return sql
end


local function to_count_sql(tablename, condition)
	local sql = "select count(*) as count from "..tablename
	if condition ~= nil and type(condition) == "table" then
		count = 1
		for k, v in pairs(condition) do
			if count == 1 then
				sql = sql.." where "..tostring(k).."="..wrap_val(v)
				count = count + 1
			else
				sql = sql.." and "..tostring(k).."="..wrap_val(v)			
				count = count + 1
			end
		end
	elseif condition ~= nil and type(condition) == "string" then
		sql = sql.." "..condition
	end
	return sql
end

function  MysqlDao.update(mysqlsvr_id, tablename, condition, tablerecord, ...)
	if mysqlsvr_id == nil or tablerecord == nil or tablename == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.update invalid params")
	else
		pcall(skynet.send, mysqlsvr_id, "lua", "query", false, to_update_sql(tablename, tablerecord, condition))
	end	
end

function  MysqlDao.sync_update(mysqlsvr_id, tablename, condition, tablerecord, ...)
	if mysqlsvr_id == nil or tablerecord == nil or tablename == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.update invalid params")
		return false, "invalid params"
	else
		local status, result, result_data = pcall(skynet.call, mysqlsvr_id, "lua", "query", true, to_update_sql(tablename, tablerecord, condition))
		if not status then
			return status, result
		else
			return result, result_data
		end
	end	
end

function  MysqlDao.insert(mysqlsvr_id, tablename, condition, tablerecord, ...)
	if mysqlsvr_id == nil or tablename == nil or tablerecord == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.insert invalid params")
	else	
		pcall(skynet.send, mysqlsvr_id, "lua", "query", false, to_insert_sql(tablename, tablerecord))
	end	
end

function  MysqlDao.sync_insert(mysqlsvr_id, tablename, condition, tablerecord, ...)
	if mysqlsvr_id == nil or tablename == nil or tablerecord == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.insert invalid params")
		return false, "invalid params"
	else	
		return skynet.call(mysqlsvr_id, "lua", "query", true, to_insert_sql(tablename, tablerecord))
	end	
end

function  MysqlDao.select(mysqlsvr_id, tablename, condition, ...)
	if mysqlsvr_id == nil or tablename == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.select invalid params")
		return false, "invalid params"
	end	
	local status, result, result_data = pcall(skynet.call, mysqlsvr_id, "lua", "query", true, to_select_sql(tablename, condition))
	if not status then
		return status, result
	else
		return result, result_data
	end
end

function  MysqlDao.delete(mysqlsvr_id, tablename, condition, ...)
	if mysqlsvr_id == nil or tablename == nil or condition == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.delete invalid params")
	else
		pcall(skynet.send, mysqlsvr_id, "lua", "query", false, to_delete_sql(tablename, condition))
	end	
end

function MysqlDao.count(mysqlsvr_id, tablename, condition, ...)
	if mysqlsvr_id == nil or tablename == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.count invalid params")
		return false, "invalid params"		
	end
	local status, result, result_data = pcall(skynet.call, mysqlsvr_id, "lua", "query", true, to_count_sql(tablename, condition))
	if not status then
		return status, result
	else
		return result, result_data
	end
end

function MysqlDao.query(mysqlsvr_id, sqlstr)
	if mysqlsvr_id == nil or sqlstr == nil then
		filelog.sys_error(filename.." [BASIC_MysqlDao] MysqlDao.query invalid params")
		return false, "invalid params"
	end
	local status, result, result_data = pcall(skynet.call, mysqlsvr_id, "lua", "query", true, sqlstr)
	if not status then
		return status, result
	else
		return result, result_data
	end
end

return MysqlDao





