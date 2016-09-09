--[[
	游戏流水日志模块
]]
local dblog = require "dblog"

local GameLog = {}

function GameLog.write_player_moneylog(rid, reason, num, beforetotal, aftertotal)
	local data = {
		rid=rid,
		reason=reason,
		num=num,
		beforetotal=beforetotal,
		aftertotal=aftertotal,
	}
	dblog.dblog_write("money", data)
end

--isreg 1 表示新注册， 0 表示已经注册账号
function GameLog.write_player_loginlog(isreg, uid, rid, regfrom, platform, channel, authtype, version)
	local data = {
		uid = uid,
		rid = rid,
		regfrom = regfrom,
		platform = platform,
		channel = channel,
		authtype = authtype,
		isreg = isreg,
		version = version,
	}
	dblog.dblog_write("playerslogin", data)	
end


return GameLog