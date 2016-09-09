local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
	print("Server start")
	skynet.newservice("systemlog")
	skynet.newservice("confcenter")

    local rechargesvrs = configdao.get_svrs("rechargesvrs")
    if rechargesvrs == nil then
        print("rechargesvrd start failed rechargesvrs == nil")
        skynet.exit()
    end
    local rechargesvr = rechargesvrs[skynet.getenv("svr_id")]
    if rechargesvr == nil then
        print("rechargesvrd start failed rechargesvr == nil", skynet.getenv("svr_id"))
        skynet.exit()           
    end

    local proxys = configdao.get_svrs("proxys")
    if proxys ~= nil then
        for id, conf in pairs(proxys) do
            local svr = skynet.newservice("proxy", id)
            conf.svr_id = rechargesvr
            skynet.call(svr, "lua", "init", conf)            
        end 
    end

    skynet.newservice("debug_console", rechargesvr.debug_console_port)

    local mysqldatadbs = configdao.get_svrs("mysqldatadbs")
    if mysqldatadbs ~= nil then
        for id, conf in pairs(mysqldatadbs) do
            local dbsvr = skynet.newservice("mysqldb", id)
            skynet.call(dbsvr, "lua", "init", conf)
        end                        
    end

    local mysqlorderdbs = configdao.get_svrs("mysqlorderdbs")
    if mysqlorderdbs ~= nil then
        for id, conf in pairs(mysqlorderdbs) do
            local dbsvr = skynet.newservice("mysqldb", id)
            skynet.call(dbsvr, "lua", "init", conf)
        end                        
    end

    
    local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end

    local datadbs = configdao.get_svrs("datadbs")
    if datadbs ~= nil then
        for id, conf in pairs(datadbs) do
            local dbsvr = skynet.newservice("redisdb", id)
            skynet.call(dbsvr, "lua", "init", conf)            
        end
    end

    local svr = skynet.newservice("rechargesvrd", skynet.getenv("svr_id"))
    skynet.call(svr, "lua", "cmd", "start", rechargesvr)
    
	print("rechargesvrd start success")
	skynet.exit()
end)
