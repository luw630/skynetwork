local skynet = require "skynet"

local  FileLog = {}

function FileLog.sys_error(...)
    if not skynet.getenv("error") == "false" then
        return
    end
	skynet.send(".systemlog","lua", "error", "servicename:"..SERVICE_NAME.." service_id:"..skynet.self(), ...)
end

function FileLog.sys_info(...)
    if not skynet.getenv("info") == "false" then
        return
    end
	skynet.send(".systemlog", "lua", "info", "servicename:"..SERVICE_NAME.." service_id:"..skynet.self(), ...)
end

function FileLog.sys_warning(...)

    if skynet.getenv("warning") == "false" then
        return
    end

    skynet.send(".systemlog", "lua", "warning", "servicename:"..SERVICE_NAME.." service_id:"..skynet.self(), ...)
end

function FileLog.sys_protomsg(msgname,...)
    if skynet.getenv("protomsg") == "false" then
        return
    end    
    if msgname == nil or type(msgname) ~= "string" then
        return
    end
    skynet.send(".systemlog", "lua", "protomsg", msgname, "servicename:"..SERVICE_NAME.." service_id:"..skynet.self(), ...)
end

function FileLog.sys_reload()
    skynet.send(".systemlog", "lua", "reload")
end

function FileLog.sys_exit()
    skynet.send(".systemlog", "lua", "exit")
end

function FileLog.sys_obj(objname, objid, ...)
    if not skynet.getenv("obj") then
        return
    end    
 	if objname == nil then
 		objname = "object"
 	end
 	if objid == nil  then
 		objid = "objectid"
 	end
	skynet.send(".systemlog", "lua", "obj", objname, objid, "servicename:"..SERVICE_NAME.." service_id:"..skynet.self(), ...)
end

return FileLog
