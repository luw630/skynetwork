local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
    print("Server start")
    skynet.newservice("systemlog")
    skynet.newservice("confcenter")

    local logindbsvrs = configdao.get_svrs("logindbsvrs")
    if logindbsvrs == nil then
        print("logindbsvrd start failed logindbsvrs == nil")
        skynet.exit()
    end
    local logindbsvr = logindbsvrs[skynet.getenv("svr_id")]
    if logindbsvr == nil then
        print("logindbsvrd start failed logindbsvr == nil", skynet.getenv("svr_id"))
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

    skynet.newservice("debug_console", logindbsvr.debug_console_port)
    
    --[[local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end]]
    
    local params = ",,,,,"..skynet.getenv("svr_id")
    local watchdog = skynet.newservice("logindbsvrd", params)
    skynet.call(watchdog, "lua", "cmd", "start", logindbsvr)
    print("logindbsvrd success")
    skynet.exit()   
end)
