local skynet = require "skynet"
local filelog = require "filelog"
local base = require "base"

local filename = "gatecachedao.lua"

local  GatecacheDao = {}
local svr_id = ".gatecache"

function GatecacheDao.update(gatesvrid, gatesvrinfo)
    if gatesvrid == nil 
        or gatesvrinfo == nil
        or type(gatesvrinfo) ~= "table" then
        filelog.sys_error(filename.." [BASIC_GatecacheDao] GatecacheDao.update invalid params")        
        return
    end
    base.pcall(skynet.send, svr_id, "lua", "update", gatesvrid, gatesvrinfo)
end

function GatecacheDao.delete(gatesvrid)
    if gatesvrid == nil then
        filelog.sys_error(filename.." [BASIC_GatecacheDao] GatecacheDao.delete invalid params")        
        return
    end
    
    base.pcall(skynet.send, svr_id, "lua", "delete", gatesvrid)
end

function GatecacheDao.query()
    return skynet.call(svr_id, "lua", "query")
end

return GatecacheDao