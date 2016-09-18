local dao = require "dao.logindbdao"
local filelog = require "filelog"
local tonumber = tonumber
local timetool = require "timetool"
local PlayerloginDAO = {}

function PlayerloginDAO.query_player_rid(uid)
	local responsemsg
	if uid == nil then
		filelog.sys_error("PlayerloginDAO.query_player_rid uid == nil")		
		return
	end

	local requestmsg = {
		uid = uid,
		rediscmd = "hget",
		rediskey = "uid:"..uid,
		--都是可选的使用时一定是按顺序添加
		rediscmdopt1 = "rid",

		mysqltable = "role_auth",
		mysqlcondition = {
			uid = uid,
		},
		choosedb = 3,
	}		

	responsemsg = dao.query(uid, requestmsg)

	if responsemsg == nil then
		filelog.sys_error("PlayerloginDAO.query_player_rid failed because cannot access logindbsvrd")
		return nil		
	end

	if not responsemsg.issuccess then
		filelog.sys_error("PlayerloginDAO.query_player_rid failed because logindbsvrd exception")		
		return nil
	end

	if responsemsg.data == nil then
		return nil
	end

	if not responsemsg.isredisormysql then
		rid = tonumber(responsemsg.data)
	else
		rid = responsemsg.data[1].rid
		if rid ~= nil then			
			PlayerloginDAO.save_player_rid(uid, rid)
		end
	end

	return rid
end

function PlayerloginDAO.get_newplayer_rid(uid)
	local requestmsg = {
		uid = uid,
		rediscmd = "spop",
		rediskey = "ridset",
		choosedb = 1,
	}		
	local responsemsg = dao.query(uid, requestmsg)
	if responsemsg == nil then
		filelog.sys_error("PlayerloginDAO.get_newplayer_rid failed for", uid)
		return nil
	end

	if not responsemsg.issuccess then
		filelog.sys_error("PlayerloginDAO.get_newplayer_rid failed because logindbsvrd exception for", uid)
		return nil
	end

	if responsemsg.data == nil or tonumber(responsemsg.data) < 1000000 then
			requestmsg.mysqlcondition = "select max(rid) as maxrid from role_auth"
			requestmsg.choosedb = 2
			responsemsg = dao.query(uid, requestmsg)
			if responsemsg == nil then
				filelog.sys_error("PlayerloginDAO.get_newplayer_rid failed for", uid)
				return nil
			end

			if not responsemsg.issuccess then
				filelog.sys_error("PlayerloginDAO.get_newplayer_rid failed because logindbsvrd exception for", uid)
				return nil
			end

			if responsemsg.data == nil 
				or responsemsg.data[1] == nil 
				or responsemsg.data[1].maxrid == nil then
				return 1000000
			end 

			return (responsemsg.data[1].maxrid + 1)
	end

	return tonumber(responsemsg.data)	
end

--choosedb 1表示redis 2表示mysql 3表示redis和mysql
function PlayerloginDAO.save_player_rid(uid, data, choosedb)
	if uid == nil then
		filelog.sys_error("PlayerloginDAO.save_player_rid uid == nil")
		return
	end
	local noticemsg = {
		uid = uid,
		rediscmd = "hset",
		rediskey = "uid:"..uid,
		--都是可选的使用时一定是按顺序添加
		rediscmdopt1 = "rid",
		rediscmdopt2 = data,
		mysqltable = "role_auth",
		mysqldata = {
			uid=uid,
			rid=data,
			create_time=timetool.get_time(),
		},
		choosedb = 3,
	}
	if choosedb ~= nil then
		noticemsg.choosedb = choosedb
	end
	dao.insert(uid, noticemsg)		
end

return PlayerloginDAO
