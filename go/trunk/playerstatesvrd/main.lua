local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
    print("Server start")
    skynet.newservice("systemlog")
    skynet.newservice("confcenter")

    local playerstatesvrs = configdao.get_svrs("playerstatesvrs")
    if playerstatesvrs == nil then
        print("playerstatesvrd start failed playerstatesvrs == nil")
        skynet.exit()
    end
    local playerstatesvr = playerstatesvrs[skynet.getenv("svr_id")]
    if playerstatesvr == nil then
        print("playerstatesvrd start failed playerstatesvr == nil", skynet.getenv("svr_id"))
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

    skynet.newservice("debug_console", playerstatesvr.debug_console_port)
    
    --[[local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end]]
    
    local params = ",,,,,"..skynet.getenv("svr_id")
    local watchdog = skynet.newservice("playerstatesvrd", params)
    skynet.call(watchdog, "lua", "cmd", "start", playerstatesvr)
    print("playerstatesvrd start success")
    skynet.exit()   
end)
