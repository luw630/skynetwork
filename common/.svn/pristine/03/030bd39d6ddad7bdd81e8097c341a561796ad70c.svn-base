local skynet = require "skynet"
local filelog = require "filelog"
local timetool = require "timetool"

local filename = "dblog.lua"

local  MongoLog = {}
local svr_id = ".mongolog"

function MongoLog.dblog_write(tablename, data)
    if tablename == nil then
        filelog.sys_error(filename.." [BASIC_MONGOLOG] MongoLog.dblog_write invalid tablename")
        return
    end
    if data == nil or type(data) ~= "table" then
        filelog.sys_error(filename.." [BASIC_MONGOLOG] MongoLog.dblog_write invalid data")
        return
    end
    data.time_stamp=os.time()
    skynet.send(svr_id, "lua", "writelog", tablename, data)
end

function MongoLog.dblog_reload()
    skynet.send(svr_id, "lua", "reload")
end

function MongoLog.dblog_exit()
    skynet.send(svr_id, "lua", "exit")
end

return MongoLog