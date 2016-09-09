local msgproxy = require "msgproxy"

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

local LogindbDao = {}

function LogindbDao.update(uid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_logindbsvrd(uid, "dao", "update", noticemsg)
end

function LogindbDao.insert(uid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_logindbsvrd(uid, "dao", "insert", noticemsg)
end

function LogindbDao.delete(uid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_logindbsvrd(uid, "dao", "delete", noticemsg)
end

function LogindbDao.query(uid, requestmsg)
	return msgproxy.sendrpc_reqmsgto_logindbsvrd(uid, "dao", "query", requestmsg)
end

return LogindbDao