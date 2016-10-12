local skynet = require "skynet"
local filelog = require "filelog"
--local statisticsmng = require "statisticsmng"
local base = require "base"
local cluster = require "cluster"
local filename = "proxy.lua"  
require "skynet.manager"

local svr_id=...
local Proxy = {}

function  Proxy.init(conf)
  if conf.svr_id == nil then
    conf.svr_id = skynet.getenv("svr_id")
  end
  if conf.svr_id ~= nil then
    local status, err = base.pcall(cluster.open, conf.svr_id)
    if not status then
      filelog.sys_error("MsgProxy.init "..conf.svr_id, err)
      base.skynet_retpack(false)
    end
  else
      base.skynet_retpack(false)
  end
  base.skynet_retpack(true)
end


function Proxy.reload(...)
  cluster.reload()
  base.skynet_retpack(true)
end 

function Proxy.exit(...)
	skynet.exit()
end 

function Proxy.request(node, address, ...)
    base.skynet_retpack(base.pcall(cluster.call, node, ".proxy", "local_request", nil, address, ...)) 
end

function Proxy.notice(node, address, ...)
  base.pcall(cluster.call, node, ".proxy", "local_notice", nil, address, ...)
end

function Proxy.local_request(_, address, ...)
  local status, result1, result2, result3, result4, result5
  status, result1, result2, result3, result4, result5 = base.pcall(skynet.call, address, "lua", ...)
  if status then
    base.skynet_retpack(result1, result2, result3, result4, result5)
  else
    base.skynet_retpack(nil)    
  end
end

function Proxy.local_notice(_, address, ...)
  base.skynet_retpack(nil)
  base.pcall(skynet.send, address, "lua", ...) 
end

function Proxy.start()
end

skynet.dispatch("lua", function(_, _, cmd, node, address, ...)
		--statisticsmng.stat_service_mqlen(svr_id)
	  local f = Proxy[cmd]
		if f ~= nil then
        base.pcall(f, node, address, ...)
    else
        filelog.sys_error(filename.." [BASIC_PROXY] skynet.dispatch invalid func "..cmd)
    end
end)

skynet.start(function()
    skynet.register(svr_id)
end)
