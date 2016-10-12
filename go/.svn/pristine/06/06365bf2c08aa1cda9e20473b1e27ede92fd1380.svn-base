local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "logindbsvrhelper"
local base = require "base"
local msgproxy = require "msgproxy"
local configdao = require "configdao"
local filename = "logindbsvrcmd.lua"
local LogindbsvrCMD = {}

function LogindbsvrCMD.process(session, source, event, ...)
	local f = LogindbsvrCMD[event] 
	if f == nil then
		filelog.sys_error(filename.."Loginsvrd LogindbsvrCMD.process invalid event:"..event)
		return nil
	end
	f(...)
end

function LogindbsvrCMD.start(conf)
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

function LogindbsvrCMD.close(...)
	local server = msghelper:get_server()
	server:exit_service()	
end

function LogindbsvrCMD.reload(...)
	base.skynet_retpack(1)
	filelog.sys_error("LogindbsvrCMD.reload start")

	configdao.reload()

	skynet.sleep(200)

	msgproxy.reload()
	
	filelog.sys_error("LogindbsvrCMD.reload end")
end

return LogindbsvrCMD