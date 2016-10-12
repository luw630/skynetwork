local msgproxy = require "msgproxy"

--[[
	request/notice {
		rid,	   玩家的角色id
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

local DatadbDao = {}

function DatadbDao.update(rid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_datadbsvrd(rid, "dao", "update", noticemsg)
end

function DatadbDao.insert(rid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_datadbsvrd(rid, "dao", "insert", noticemsg)
end

function DatadbDao.delete(rid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_datadbsvrd(rid, "dao", "delete", noticemsg)
end

function DatadbDao.query(rid, requestmsg)
	return msgproxy.sendrpc_reqmsgto_datadbsvrd(rid, "dao", "query", requestmsg)
end

return DatadbDao