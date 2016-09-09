local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
	print("Server start")
	skynet.newservice("systemlog")
	skynet.newservice("confcenter")

    local proxys = configdao.get_svrs("proxys")
    if proxys ~= nil then
        for id, conf in pairs(proxys) do
            local svr = skynet.uniqueservice("proxy", id)
            conf.svr_id = skynet.getenv("svr_id")
            skynet.call(svr, "lua", "init", conf)            
        end 
    end
    
    local recordsvrs = configdao.get_svrs("recordsvrs")
    if recordsvrs == nil then
        print("recordsvrd start failed recordsvrs == nil")
        skynet.exit()
    end
    local recordsvr = recordsvrs[skynet.getenv("svr_id")]
    if recordsvr == nil then
        print("recordsvrd start failed recordsvr == nil", skynet.getenv("svr_id"))
        skynet.exit()           
    end

    skynet.newservice("debug_console", recordsvr.debug_console_port)
    
    --加载mq服务
    local mqsvrs = configdao.get_svrs("mqsvrs")
    if mqsvrs ~= nil then
        for id, conf in pairs(mqsvrs) do
            local dbsvr = skynet.newservice("redisdb", id)
            skynet.call(dbsvr, "lua", "init", conf)
        end
    end
    
    local datadbs = configdao.get_svrs("datadbs")
    if datadbs ~= nil then
        for id, conf in pairs(datadbs) do
            local dbsvr = skynet.newservice("redisdb", id)
            skynet.call(dbsvr, "lua", "init", conf)
        end
    end
    
    local svr = skynet.newservice("recordsvrd", skynet.getenv("svr_id"))
    skynet.call(svr, "lua", "cmd", "start", recordsvr)

	print("recordsvrd start success")
	skynet.exit()
end)
