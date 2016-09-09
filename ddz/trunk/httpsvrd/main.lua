local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
	print("Server start")
	local console = skynet.newservice("console")
	skynet.newservice("systemlog")
	skynet.newservice("confcenter")

    local httpsvrs = configdao.get_svrs("httpsvrs")
    if httpsvrs == nil then
        print("httpsvrd start failed httpsvrs == nil")
        skynet.exit()
    end
    local httpsvr = httpsvrs[skynet.getenv("svr_id")]
    if httpsvr == nil then
        print("httpsvrd start failed httpsvr == nil", skynet.getenv("svr_id"))
        skynet.exit()           
    end

    local proxys = configdao.get_svrs("proxys")
    if proxys ~= nil then
        for id, conf in pairs(proxys) do
            local svr = skynet.newservice("proxy", id)
            conf.svr_id = httpsvr
            skynet.call(svr, "lua", "init", conf)            
        end 
    end

    skynet.newservice("debug_console", httpsvr.debug_console_port)

    --[[local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end]]
    
    local svr = skynet.newservice("httpsvrd", skynet.getenv("svr_id"))
    skynet.call(svr, "lua", "cmd", "start", httpsvr)

	print("httpsvrd start success")
	skynet.exit()
end)
