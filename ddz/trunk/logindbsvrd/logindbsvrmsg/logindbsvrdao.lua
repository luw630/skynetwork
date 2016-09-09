local filelog = require "filelog"
local skynet = require "skynet"
local redisdao = require "dao.redisdao"
local msghelper = require "logindbsvrhelper"
local mysqldao = require "dao.mysqldao"
local base = require "base"
local tabletool = require "tabletool"

local LogindbsvrDao = {}

function LogindbsvrDao.process(session, source, event, ...)
	local f = LogindbsvrDao[event] 
	if f == nil then
		filelog.sys_error(filename.."Logindbsvrd LogindbsvrDao.process invalid event:"..event)
		return nil
	end
	f(...)
end

--[[
	request {
		uid,	   玩家的账号id
		rediscmd,  redis操作命令
		rediskey,  redis数据key
		--都是可选的使用时一定是按顺序添加
		rediscmdopt1, redis命令选项1
		rediscmdopt2, redis命令选项2
		rediscmdopt3,
		rediscmdopt4,
		rediscmdopt5,

		mysqltable,  mysql数据表名
		mysqldata, mysqldata表示存入mysql的数据, 一定是table
		mysqlcondition, 是一个表格或是字符串（字符串表示完整sql语句）
		choosedb, 1 表示redis， 2表示mysql，3表示redis+mysql
	}

	response {
		issuccess, 表示成功或失败
		isredisormysql, true表示返回的是mysql数据 false表示是redis数据（业务层可能要进行不同的处理）
		data, 返回的数据
	}
]]

local function get_redis_cmds(request)
	if request.rediscmd == nil 
		or request.rediskey == nil then
		return ""
	end

	if  request.rediscmdopt5 ~= nil then
		return request.rediscmd, request.rediskey, request.rediscmdopt1, request.rediscmdopt2, request.rediscmdopt3, request.rediscmdopt4, request.rediscmdopt5 
	end

	if request.rediscmdopt4 ~= nil then
		return request.rediscmd, request.rediskey, request.rediscmdopt1, request.rediscmdopt2, request.rediscmdopt3, request.rediscmdopt4 		
	end

	if request.rediscmdopt3 ~= nil then
		return request.rediscmd, request.rediskey, request.rediscmdopt1, request.rediscmdopt2, request.rediscmdopt3 		
	end

	if request.rediscmdopt2 ~= nil then
		return request.rediscmd, request.rediskey, request.rediscmdopt1, request.rediscmdopt2 				
	end

	if request.rediscmdopt1 ~= nil then
		return request.rediscmd, request.rediskey, request.rediscmdopt1 				
	end

	return request.rediscmd, request.rediskey
end

function LogindbsvrDao.query(request)
	local response = {issuccess = true}
	local status
	local data

	if request.choosedb  == 1 
		or request.choosedb  == 3 then
		status, data = redisdao.query_data(msghelper:get_redissvrid_byuid(request.uid), get_redis_cmds(request))
		response.isredisormysql = false
		if not status then
			filelog.sys_error("LogindbsvrDao.query redisdao.query_data failed", data)
			response.issuccess = false
			base.skynet_retpack(response)
			return
		end
		if request.choosedb  == 1 then
			response.data = data
			base.skynet_retpack(response)
			return				
		end
	end

	if data == nil 
		or (type(data) == "table" and tabletool.tabletool.is_emptytable(data)) then
		--说明缓存中没有
		if type(request.mysqlcondition) == "table" then
			status, data = mysqldao.select(msghelper:get_mysqlsvrid_byuid(request.uid), request.mysqltable, request.mysqlcondition)
		else
			status, data = mysqldao.query(msghelper:get_mysqlsvrid_byuid(request.uid), request.mysqlcondition)
		end
		response.isredisormysql = true
		if not status then
			filelog.sys_error("LogindbsvrDao.query mysqldao.select failed", data)
			response.issuccess = false
			base.skynet_retpack(response)
			return			
		end

		if tabletool.is_emptytable(data) then
			data = nil
		end		
	end

	response.data = data
	base.skynet_retpack(response)	
end

function LogindbsvrDao.update(request)
	if request.choosedb  == 1 
		or request.choosedb  == 3 then
		redisdao.save_data(msghelper:get_redissvrid_byuid(request.uid), get_redis_cmds(request))		
 	end

 	if request.choosedb  == 3 
		or request.choosedb  == 2 then
		mysqldao.update(msghelper:get_mysqlsvrid_byuid(request.uid), request.mysqltable, request.mysqlcondition, request.mysqldata)
	end
end

function LogindbsvrDao.delete(request)
	if request.choosedb  == 1 
		or request.choosedb  == 3 then
		redisdao.save_data(msghelper:get_redissvrid_byuid(request.uid), get_redis_cmds(request))
	end

 	if request.choosedb  == 3 
		or request.choosedb  == 2 then
		mysqldao.delete(msghelper:get_mysqlsvrid_byuid(request.uid), request.mysqltable, request.mysqlcondition)
	end
end

function LogindbsvrDao.insert(request)
	if request.choosedb  == 1 
		or request.choosedb  == 3 then
		redisdao.save_data(msghelper:get_redissvrid_byuid(request.uid), get_redis_cmds(request))	
	end
 	if request.choosedb  == 3 
		or request.choosedb  == 2 then
		mysqldao.insert(msghelper:get_mysqlsvrid_byuid(request.uid), request.mysqltable, request.mysqlcondition, request.mysqldata)
	end
end

return LogindbsvrDao