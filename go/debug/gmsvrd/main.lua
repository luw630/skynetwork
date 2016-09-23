local skynet = require "skynet"
local configdao = require "configdao"

local max_client = 100000

skynet.start(function()
	print("Server start")
	skynet.uniqueservice("msgprotoloader")
	skynet.newservice("systemlog")
	skynet.newservice("confcenter")

    local gmsvrs = configdao.get_svrs("gmsvrs")
    if gmsvrs == nil then
        print("gmsvrd start failed gmsvrs == nil")
        skynet.exit()
    end
    local gmsvr = gmsvrs[skynet.getenv("svr_id")]
    if gmsvr == nil then
        print("gmsvrd start failed gmsvr == nil", skynet.getenv("svr_id"))
        skynet.exit()           
    end

    local proxys = configdao.get_svrs("proxys")
    if proxys ~= nil then
        for id, conf in pairs(proxys) do
            local svr = skynet.newservice("proxy", id)
            conf.svr_id = gmsvr
            skynet.call(svr, "lua", "init", conf)            
        end 
    end

	skynet.newservice("debug_console",gmsvr.debug_console_port)

    local datadbs = configdao.get_svrs("datadbs")
    if datadbs ~= nil then
        for id, conf in pairs(datadbs) do
            local dbsvr = skynet.newservice("redisdb", id)
            skynet.call(dbsvr, "lua", "init", conf)            
        end
    end

    local mysqldatadbs = configdao.get_svrs("mysqldatadbs")
    if mysqldatadbs ~= nil then
        for id, conf in pairs(mysqldatadbs) do
            local dbsvr=skynet.newservice("mysqldb", id)
            skynet.call(dbsvr, "lua", "init", conf)
        end                        
    end

    local authdbsvrs = configdao.get_svrs("authdbsvrs")
    if authdbsvrs ~= nil then
        for id, conf in pairs(authdbsvrs) do
            local dbsvr = skynet.newservice("redisdb", id)
            skynet.call(dbsvr, "lua", "init", conf)            
        end
    end

    local mysqlauthdbs = configdao.get_svrs("mysqlauthdbs")
    if mysqlauthdbs ~= nil then
        for id, conf in pairs(mysqlauthdbs) do
            local dbsvr=skynet.newservice("mysqldb", id)
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
    
    --加载mq服务
    local mqsvrs = configdao.get_svrs("mqsvrs")
    if mqsvrs ~= nil then
        for id, conf in pairs(mqsvrs) do
            local dbsvr = skynet.newservice("redisdb", id)
            skynet.call(dbsvr, "lua", "init", conf)
        end
    end

	local watchdog = skynet.newservice("gmsvrd", skynet.getenv("svr_id"))
	skynet.call(watchdog, "lua", "cmd", "start", {
		port = gmsvr.gmsvr_port,
		maxclient = max_client,
		nodelay = true,
        address = gmsvr.gmsvr_ip,
		agentsize = gmsvr.agentsize,
        agentincr = gmsvr.agentincr,
        gmhttpsvr_ip = gmsvr.gmhttpsvr_ip,
        gmhttpsvr_port = gmsvr.gmhttpsvr_port,
	})
	print("gmsvrd listen on ")
	skynet.exit()	
end)
