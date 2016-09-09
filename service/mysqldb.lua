local skynet = require "skynet"
local mysql = require "mysql"
require "skynet.manager"
local filelog = require "filelog"
local statisticsmng = require "statisticsmng"
local base = require "base"

local filename = "mysqldb.lua"
local db
local mysql_conf
local svr_id=...
local CMD = {}

function  CMD.init(conf)
    if db ~= nil then
        db:disconnect()
        db = nil
    end 
    conf.on_connect = function (db)
        db:query("set names utf8");
    end
    db=mysql.connect(conf)
    if not db then
        filelog.sys_error(filename.." [BASIC_MYSQLDB] failed to connect")
        skynet.exit()
        return
    end
    mysql_conf = conf
end


function CMD.reload(conf)
    local status, err = base.pcall(CMD.init, conf) 
    if not status then
        filelog.sys_error("mysqldb reload", err)
    end
end 

function CMD.exit(...)
	db:disconnect()
	db = nil
	skynet.exit()
end 

function CMD.start(...)
end

function CMD.query(sqlstr)
    return base.pcall(db.query, db, sqlstr)    
end

skynet.dispatch("lua", function(session, address,  cmd, isresponse, sqlstr)
		--statisticsmng.stat_service_mqlen(svr_id)
        --filelog.sys_obj("mysqldb", svr_id, sqlstr)
	    local f = CMD[cmd]
        if cmd == "init" then
            local status, err = base.pcall(f, isresponse)
            skynet.retpack(status)
            if not status then
                filelog.sys_error("mysqldb "..svr_id.." init failed", err)
            end 
            return
        end
		if f ~= nil then
            local result, result_data = f(sqlstr)
            if not result then
                filelog.sys_obj("mysqldb", svr_id, "warn:", cmd, sqlstr)
                CMD.reload(mysql_conf)
                result, result_data = f(sqlstr)
                if not result then
                    filelog.sys_obj("mysqldb", svr_id, "error:", cmd, sqlstr)                    
                end
                if isresponse then
                    base.pcall(skynet.retpack, result, result_data)
                else
                    --To do
                end                
            else
                if isresponse then
                    base.pcall(skynet.retpack, result, result_data)
                else
                    --To do
                end                
            end

 
        else
            filelog.sys_error(filename.." [BASIC_MYSQLDB] skynet.dispatch invalid func "..cmd)
        end
end)

skynet.start(function()
	CMD.start()
    if svr_id ~= nil then
        skynet.register(svr_id)
    end
end)


