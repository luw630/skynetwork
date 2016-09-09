local skynet = require "skynet"
local filelog = require "filelog"
local base = require "base"
local timetool = require "timetool"
local msgproxy = require "msgproxy"
local filename = "gatecache.lua"  
require "skynet.manager"

local svr_id=...
local gatecachedata = {
  --[[
     [gatesvrid] = {
        ip = "",
        port = 0,
        updatetime = 0, --最近一次更新时间
        onlinenum = 0,  --在线人数
     }
  ]]
}
local GateCache = {}
function  GateCache.init(conf)
  if conf == nil or conf.gatesvrs == nil then
    return
  end
  msgproxy.sendrpc_broadcastmsgto_gatesvrd("get_gatesvr_state")
  base.skynet_retpack(true)
end

function GateCache.reload(...)
end 

function GateCache.exit(...)
	skynet.exit()
end 

function GateCache.update(gatesvrid, gatesvrinfo)
    if gatesvrid == nil or gatesvrinfo == nil then
        return
    end
    if gatecachedata[gatesvrid]  == nil then
        gatesvrinfo.updatetime = timetool.get_time()
        gatecachedata[gatesvrid] = gatesvrinfo
    else
        gatecachedata[gatesvrid].ip = gatesvrinfo.ip
        gatecachedata[gatesvrid].port = gatesvrinfo.port
        gatecachedata[gatesvrid].onlinenum = gatesvrinfo.onlinenum
        gatecachedata[gatesvrid].updatetime = timetool.get_time()
    end
end

function GateCache.delete(gatesvrid)
    if gatesvrid == nil then
        return
    end
    gatecachedata[gatesvrid] = nil
end

function GateCache.query(...)    
    base.skynet_retpack(gatecachedata)
end

function GateCache.start(...)
end

skynet.dispatch("lua", function(_, _, cmd, ...)
	  local f = GateCache[cmd]
		if f ~= nil then
        base.pcall(f, ...)
    else
        filelog.sys_error(filename.." [BASIC_GateCache] skynet.dispatch invalid func "..cmd)
    end
end)

skynet.start(function()
    skynet.fork(function()
      local nowtime
      local i
      local deletearray = {}
      while true do
        skynet.sleep(3000)
        nowtime = timetool.get_time()
        for gatesvrid, gatesvrinfo in pairs(gatecachedata) do
          if gatesvrinfo.updatetime + 120 <= nowtime then
            filelog.sys_warning("delete zombie gatesvr", gatesvrid, gatesvrinfo)
            table.insert(deletearray, gatesvrid)
          end
        end
        i = 1
        while deletearray[i] do
          gatecachedata[deletearray[i]] = nil 
          table.remove(deletearray,i) 
          i = i+1 
        end 
      end
    end)    

    skynet.register(svr_id)
end)
