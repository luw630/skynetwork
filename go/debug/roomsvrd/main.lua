local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
    print("Server start")
    skynet.newservice("systemlog")
    skynet.newservice("confcenter")

    local roomsvrs = configdao.get_svrs("roomsvrs")
    if roomsvrs == nil then
        print("roomsvrd start failed roomsvrs == nil")
        skynet.exit()
    end
    local roomsvr = roomsvrs[skynet.getenv("svr_id")]
    if roomsvr == nil then
        print("roomsvrd start failed roomsvr == nil", skynet.getenv("svr_id"))
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

    local timersvr = skynet.newservice("timercenter")
    skynet.call(timersvr, "lua", "init", roomsvr.timersize)

    skynet.newservice("debug_console", roomsvr.debug_console_port)
    
    --[[local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end]]
    
    local params = ",,,,,"..skynet.getenv("svr_id")
    local watchdog = skynet.newservice("roomsvrd", params)
    skynet.call(watchdog, "lua", "cmd", "start", roomsvr)
    print("roomsvrd start success ")
    skynet.exit()   
end)
