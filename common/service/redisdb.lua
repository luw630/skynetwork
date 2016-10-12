local skynet = require "skynet"
local redis = require "redis"
require "skynet.manager"
local filelog = require "filelog"
local statisticsmng = require "statisticsmng"
local base = require "base"

local filename = "reisdb.lua"
local db
local svr_id=...
local conf
local CMD = {}

function  CMD.init(redisdb_conf)
  	if db ~= nil then
  		setmetatable(CMD, nil)
  		CMD.__index = nil
  		db:disconnect()
  		db = nil
  	end 
    db = redis.connect(redisdb_conf)
    local dbmeta = getmetatable(db)
    setmetatable(CMD, dbmeta)
    CMD.__index = dbmeta
    conf = redisdb_conf
end


function CMD.reload(redisdb_conf)
    if db ~= nil then
      db:disconnect()
      db = nil
    end 
    db = redis.connect(redisdb_conf)
    conf = redisdb_conf 	
end 

function CMD.exit(...)
	setmetatable(CMD, nil)
	CMD.__index = nil
	db:disconnect()
	db = nil
	skynet.exit()
end 

function CMD.start()
	--CMD.init(redisdb_conf)
end

skynet.dispatch("lua", function(session, address,  cmd, isresponse, data, ...)
		--filelog.sys_obj("redisdb", "msg", cmd, isresponse, data, ...)
    --statisticsmng.stat_service_mqlen(svr_id)
	    local f = CMD[cmd]
        if cmd == "init" then
            skynet.retpack(f(isresponse))
            return
        end

		if f ~= nil then
        local result, result_data = base.pcall(f, db, data, ...)
        if not result then
            filelog.sys_obj("redisdb", svr_id, "warn:", cmd, data, ...)
            local result, result_data = base.pcall(CMD.reload, conf)
            if result then
                result, result_data = base.pcall(f, db, data, ...)
                if not result then
                  filelog.sys_obj("redisdb", svr_id, "error:", cmd, data, ...)
                end
            else
                  filelog.sys_obj("redisdb", svr_id, "error:", cmd, data, ...)
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
        filelog.sys_error(filename.." [BASIC_REDISDB] skynet.dispatch invalid func "..cmd)
    end
end)

skynet.start(function()
	--CMD.start()
    if svr_id ~= nil then
        skynet.register(svr_id)
    end
end)


