local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"

skynet.start(function()
	print("Server start")
	skynet.uniqueservice("msgprotoloader")
	skynet.newservice("systemlog")
	skynet.newservice("confcenter")

    local loginsvrs = configdao.get_svrs("loginsvrs")
    if loginsvrs == nil then
        print("loginsvrd start failed loginsvrs == nil")
        skynet.exit()
    end
    local loginsvr = loginsvrs[skynet.getenv("svr_id")]
    if loginsvr == nil then
        print("loginsvrd start failed loginsvr == nil", skynet.getenv("svr_id"))
        skynet.exit()           
    end

    local proxys = configdao.get_svrs("proxys")
    if proxys ~= nil then
        for id, conf in pairs(proxys) do
            local svr = skynet.newservice("proxy", id)
            conf.svr_id = skynet.getenv("svr_id")
            skynet.call(svr, "lua", "init", conf)            
        end 
    end

    local mongologs = configdao.get_svrs("mongologs")
    if mongologs ~= nil then
        for id, conf in pairs(mongologs) do
            local svr = skynet.newservice("mongolog", id)
            skynet.call(svr, "lua", "init", conf)            
        end
    end

    --加载gatecache模块
    local gatecachesvr = skynet.newservice("gatecache", ".gatecache")
    local gatesvrs = configdao.get_svrs("gatesvrs")
    local gatecacheconf = {
        gatesvrs = {},
    }
    for gatesvrid, _ in pairs(gatesvrs) do
        table.insert(gatecacheconf.gatesvrs,  gatesvrid)
    end
    skynet.call(gatecachesvr, "lua", "init", gatecacheconf)

	skynet.newservice("debug_console",loginsvr.debug_console_port)

    local params = loginsvr.svr_ip..","..loginsvr.svr_port..","..loginsvr.svr_gate_type..","..loginsvr.svr_netpack..","..loginsvr.svr_tcpmng..","..skynet.getenv("svr_id")
	local watchdog = skynet.newservice("loginsvrd", params)
	skynet.call(watchdog, "lua", "cmd", "start", {
		port = loginsvr.svr_port,
		maxclient = loginsvr.maxclient,
		nodelay = true,
		agentsize = loginsvr.agentsize,
        agentincr = loginsvr.agentincr,
        svr_netpack = loginsvr.svr_netpack,
	})
	print("loginsvrd success!")
	skynet.exit()	
end)
