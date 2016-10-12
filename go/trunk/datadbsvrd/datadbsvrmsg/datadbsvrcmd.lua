local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "datadbsvrhelper"
local base = require "base"
local msgproxy = require "msgproxy"
local configdao = require "configdao"
local filename = "datadbsvrcmd.lua"
local DatadbsvrCMD = {}

function DatadbsvrCMD.process(session, source, event, ...)
	local f = DatadbsvrCMD[event] 
	if f == nil then
		filelog.sys_error(filename.."Loginsvrd DatadbsvrCMD.process invalid event:"..event)
		return nil
	end
	f(...)
end

function DatadbsvrCMD.start(conf)
	local server = msghelper:get_server()
	local redisdb
	local mysqldb	
    for i = 1, conf.redisnum do
        redisdb = skynet.newservice("redisdb", nil)
        skynet.call(redisdb, "lua", "init", conf.redisconn)
        table.insert(server.redisdb_service, redisdb)            
    end

    for i = 1, conf.mysqlnum do
    	mysqldb = skynet.newservice("mysqldb", nil)
        skynet.call(mysqldb, "lua", "init", conf.mysqlconn)
   		table.insert(server.mysqldb_service, mysqldb)
   	end
	base.skynet_retpack(true)
end

function DatadbsvrCMD.close(...)
	local server = msghelper:get_server()
	server:exit_service()	
end

function DatadbsvrCMD.reload(...)
	base.skynet_retpack(1)
	filelog.sys_error("DatadbsvrCMD.reload start")

	configdao.reload()

	skynet.sleep(200)

	msgproxy.reload()
	
	filelog.sys_error("DatadbsvrCMD.reload end")
end

return DatadbsvrCMD