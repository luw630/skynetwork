local msgproxy = require "msgproxy"
--[[
	主要用于记录全局数据

	key作为每条记录的关键索引，其他需要使用者自己设计
]]
--[[
	request/notice {
		key,	   全局数据key
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

local GlobaldbDao = {}

--key 必须是字符串或数字
function GlobaldbDao.update(key,  noticemsg)
	msgproxy.sendrpc_noticemsgto_globaldbsvrd(key, "dao", "update", noticemsg)
end

function GlobaldbDao.insert(rid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_globaldbsvrd(key, "dao", "insert", noticemsg)
end

function GlobaldbDao.delete(rid,  noticemsg)
	msgproxy.sendrpc_noticemsgto_globaldbsvrd(key, "dao", "delete", noticemsg)
end

function GlobaldbDao.query(rid, requestmsg)
	return msgproxy.sendrpc_reqmsgto_globaldbsvrd(key, "dao", "query", requestmsg)
end

return GlobaldbDao