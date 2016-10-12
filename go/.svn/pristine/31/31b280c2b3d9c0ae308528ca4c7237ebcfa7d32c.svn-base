local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
    print("Server start")
    skynet.newservice("systemlog")
    skynet.newservice("confcenter")

    local datadbsvrs = configdao.get_svrs("datadbsvrs")
    if datadbsvrs == nil then
        print("datadbsvrd start failed datadbsvrs == nil")
        skynet.exit()
    end
    local datadbsvr = datadbsvrs[skynet.getenv("svr_id")]
    if datadbsvr == nil then
        print("datadbsvrd start failed datadbsvr == nil", skynet.getenv("svr_id"))
        skynet.exit()           
    end


    local proxys = configdao.get_svrs("proxys")
    if proxys ~= nil then
        for id, conf in pairs(proxys) do
            local svr = skynet.uniqueservice("proxy", id)
            conf.svr_id = skynet.getenv("svr_id")
            skynet.call(svr, "lua", "init", conf)            
        end 
    end

    skynet.newservice("debug_console", datadbsvr.debug_console_port)
    
    --[[local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end]]
    
    local params = ",,,,,"..skynet.getenv("svr_id")
    local watchdog = skynet.newservice("datadbsvrd", params)
    skynet.call(watchdog, "lua", "cmd", "start", datadbsvr)
    print("datadbsvrd listen on ")
    skynet.exit()   
end)
