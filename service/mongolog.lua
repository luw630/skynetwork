local skynet = require "skynet"
local mongo = require "mongo"
local base = require "base"
require "skynet.manager"

local filelog = require "filelog"
local timetool = require "timetool"

local mongolog_conf
local currenttime
local currentdbname
local svr_id=...
local mongoclient 

local CMD = {}

local function free_mongo()
	if mongoclient ~= nil then
		mongoclient:logout()
		mongoclient:disconnect()
		mongoclient = nil
	end
end

local function get_currentdbname(time_stamp)
	if currenttime == nil or currenttime <= 0 then
		currenttime = time_stamp
		currentdbname = os.date("%Y_%m_%d", currenttime)
		return currentdbname 
	end

    local daynum = timetool.get_diffdate_day(currenttime, time_stamp)
	if daynum >= 1 then
		currenttime = time_stamp
		currentdbname = os.date("%Y_%m_%d", currenttime)
		free_mongo()
		mongoclient = mongo.client(mongolog_conf)
		return currentdbname
	end
	return currentdbname
end

function CMD.init(conf)
	if conf ~= nil then
		mongolog_conf = conf
	end
	free_mongo()
    mongoclient = mongo.client(mongolog_conf)	
end

function CMD.reload(conf)
	CMD.init(mongolog_conf)
end

function CMD.exit(...)
    free_mongo()
    skynet.exit()
end

function CMD.start(...)
	--CMD.init(...)
end

function CMD.writelog(tablename, data)
	local mongodb = mongoclient:getDB(get_currentdbname(data.time_stamp))
	local collection = mongodb:getCollection(tablename)
	if type(data) ~= "table" then
		return
	end
	collection:safe_insert(data)
end


skynet.dispatch("lua", function(_, address,  cmd, tablename, data)
	    local f = CMD[cmd]
	    if cmd == "init" then
	    	skynet.retpack(f(tablename))
	    	return
	    end

		if f ~= nil then			
            local status, info = base.pcall(f, tablename, data)
            if not status then
            	filelog.sys_error("mongolog failed ", info)
            	status, info = base.pcall(CMD.init, nil)
            	if status then
            		base.pcall(f, tablename, data)
            	else
            		skynet.sleep(20)
            		status, info = base.pcall(CMD.init, nil)
            		if status then
            			base.pcall(f, tablename, data)            			
            		else
            			filelog.sys_obj("mongolog", tablename, "errorinfo:", info, data)
            		end
            	end
            end
        end
end)

skynet.start(function()
	CMD.start()
    skynet.register(svr_id)
end)

