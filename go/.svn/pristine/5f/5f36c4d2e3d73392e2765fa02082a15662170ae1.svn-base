local skynet = require "skynet"
local configdao = require "configdao"
local tabletool = require "tabletool"
local base = require "base"
local filelog = require "filelog"
--[[
	注意:请求响应返回的参数最多5个
]]
local proxy = ".proxy"
local cfgclusters = nil
local cfgdbhash = nil
local svrs_indexs={}
local MsgProxy = {}


local function init_svrs_indexs()
	if tabletool.is_emptytable(svrs_indexs) then
		local cfgsvrs = configdao.get_cfgsvrs()
		for key, value in pairs(cfgsvrs) do
			svrs_indexs[key]={}
			for svr_id, _ in pairs(value) do
				table.insert(svrs_indexs[key], svr_id)
			end
		end 
	end

	if cfgclusters == nil then
		cfgclusters = configdao.get_cfgclusters()
	end
end

local function get_datadbsvr_id(rid)
	if cfgdbhash == nil then
		cfgdbhash = configdao.get_cfgdbhash()
		if cfgdbhash ~= nil then
			cfgdbhash = cfgdbhash.datadbsvrs
		end
	end 
	return cfgdbhash[rid % 128 + 1]
end

local function get_globaldbsvr_id(key)
	if cfgdbhash == nil then
		cfgdbhash = configdao.get_cfgdbhash()
		if cfgdbhash ~= nil then
			cfgdbhash = cfgdbhash.globaldbsvrs
		end
	end
	local num
	if type(key) == "string" then
		num = base.strtohash(key)
	else
		num = key
	end  
	return cfgdbhash[num % 128 + 1]
end

function MsgProxy.init(svr_id)
	if svr_id == nil then
		svr_id = skynet.getenv("svr_id")
	end

	init_svrs_indexs()
	--return skynet.call(".proxy", "lua", "init", {svr_id = svr_id})
end

function MsgProxy.reload()
	svrs_indexs = {}
	init_svrs_indexs()
	return skynet.call(".proxy", "lua", "reload")	
end

--------------tablesvrd交互相关--------------------
function MsgProxy.sendrpc_reqmsgto_tablesvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["tablestatesvrs"]
	local index = rid % (#svrs)	+ 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...) 		
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgto_tablesvrd failed", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_broadcastmsgto_tablesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["tablestatesvrs"]
	for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
	end
	return true
end

function MsgProxy.sendrpc_reqmsgto_tablesvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["tablestatesvrs"]
	local index = rid % (#svrs)	+ 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_tablesvrd error server exception:", result1)
		return nil
	end
	return result1, result2, result3, result4
end
------------------roomsvrd交互相关----------------------
function MsgProxy.sendrpc_reqmsgto_roomsvrd(rid, roomsvr_id, service_id, ...)
	local status, result1, result2, result3, result4
	init_svrs_indexs()
	if roomsvr_id == nil then
		roomsvr_id = service_id
	end

	if rid ~= nil then
		local svrs = svrs_indexs["roomsvrs"]
		local index = rid % (#svrs)	+ 1
		roomsvr_id = svrs[index]
		if service_id == nil then
			service_id = roomsvr_id
		end
	end
	
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", roomsvr_id, service_id, "request", ...)
	if not status then
		filelog.sys_error("MsgProxy.sendrpc_reqmsgto_roomsvrd error server exception", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_roomsvrd(roomsvr_id, service_id, ...)
	init_svrs_indexs()
	if skynet.getenv("svr_id") ~= roomsvr_id 
		and cfgclusters[roomsvr_id] then
		skynet.send(proxy, "lua", "notice", roomsvr_id, service_id, "notice", ...)
	else
		skynet.send(service_id, "lua", "notice", ...)		
	end
	return true
end

function MsgProxy.sendrpc_broadcastmsgto_roomsvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["roomsvrs"]
	if svrs == nil then
		return false
	end
    for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
    end
    return true		
end
---------------------gatesvrd交互相关接口-------------------------
function MsgProxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id,service_id, ...)
	local status, result1, result2, result3, result4
	init_svrs_indexs()
	status, result1, result2, result3, result4 = base.pcall(skynet.call, proxy, "lua", "request", gatesvr_id, service_id, "request", ...)		
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_gatesvrd error server exception", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_gatesvrd(gatesvr_id, service_id, ...)
	skynet.send(proxy, "lua", "notice", gatesvr_id, service_id, "notice", ...)
	return true
end

function MsgProxy.sendrpc_broadcastmsgto_gatesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["gatesvrs"]
	for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
	end
	return true
end

------------------matchstatesvrd交互接口--------------------------
function MsgProxy.send_reqmsgto_matchstatesvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["matchstatesvrs"]
	local index = rid % (#svrs)	+ 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	if skynet.getenv("svr_id") ~= svr_id 
		and cfgclusters[svr_id] then
		status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
	else
		status, result1, result2, result3, result4 = base.pcall(skynet.call, svr_id, "lua", "request", ...)
	end
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgto_matchstatesvrd failed", result1)
		return nil
	end	
	return result1, result2, result3, result4
end

function MsgProxy.send_broadcastmsgto_matchstatesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["matchstatesvrs"]
	for _, svr_id in pairs(svrs) do
		if skynet.getenv("svr_id") ~= svr_id 
			and cfgclusters[svr_id] then
			skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
		else
			skynet.send(svr_id, "lua", "notice", ...)
		end
	end
	return true
end

function MsgProxy.sendrpc_reqmsgto_matchstatesvrd(svr_id, service_id, ...)
	local status, result1, result2, result3, result4
	if svr_id == nil then
		svr_id = "matchstatesvr_1"
	end
	if service_id == nil then
		service_id = svr_id
	end

	status, result1, result2, result3, result4 = base.pcall(cluster.call, svr_id, service_id, "request", ...)
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_matchstatesvrd error server:"..svr_id.." exception", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_broadcastmsgto_matchstatesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["matchstatesvrs"]
	for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
	end
	return true
end

----------------------matchsvrd交互接口--------------------
function MsgProxy.send_reqmsgto_matchsvrd(matchsvr_id, service_id, ...)
	local status, result1, result2, result3, result4
	init_svrs_indexs()
	if skynet.getenv("svr_id") ~= matchsvr_id 
		and cfgclusters[matchsvr_id] then
		status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", matchsvr_id, service_id, "request", ...)		
	else
		status, result1, result2, result3, result4 = base.pcall(skynet.call, service_id, "lua", "request", ...)
	end
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgto_matchsvrd", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.send_noticemsgto_matchsvrd(matchsvr_id, service_id, ...)
	init_svrs_indexs()
	if skynet.getenv("svr_id") ~= matchsvr_id 
		and cfgclusters[matchsvr_id] then
		skynet.send(proxy, "lua", "notice", matchsvr_id, service_id, "notice", ...)				
	else
		skynet.send(service_id, "lua", "notice", ...)		
	end
	return true
end

function MsgProxy.send_reqmsgbyridto_matchsvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["matchsvrs"]
	local index = rid % (#svrs)	+ 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	if skynet.getenv("svr_id") ~= svr_id 
		and cfgclusters[svr_id] then
		status, result1, result2, result3, result4 = skynet.call(proxy, "lua", svrs[index], "lua", "request", ...)
	else
		status, result1, result2, result3, result4 = base.pcall(skynet.call, svr_id, "lua", "request", ...)
	end
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgbyridto_matchsvrd failed", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_reqmsgto_matchsvrd(matchsvr_id, service_id, ...)
	local status, result1, result2, result3, result4	
	if matchsvr_id == nil then
		matchsvr_id = service_id
	end
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", matchsvr_id, service_id, "request", ...)
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_matchsvrd error server:"..svr_id.." exception", result1)
		return nil
	end
	return result1, result2, result3, result4	
end

function MsgProxy.sendrpc_noticemsgto_matchsvrd(matchsvr_id, service_id, ...)
	if service_id == nil then
		service_id = matchsvr_id
	end
	skynet.send(proxy, "lua", "notice", matchsvr_id, service_id, "notice", ...)
	return true	
end

function MsgProxy.sendrpc_reqmsgbyridto_matchsvrd(rid, ...)
	local status, result1, result2, result3, result4
	init_svrs_indexs()
	local svrs = svrs_indexs["matchsvrs"]
	local index = rid % (#svrs)	+ 1
	local svr_id = svrs[index]
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgbyridto_matchsvrd error server:"..svrs[index].." exception", result1)
		return nil
	end
	return result1, result2, result3, result4	
end
----------------------onlinestatesvrd交互接口----------------
function MsgProxy.send_reqmsgto_onlinestatesvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["onlinestatesvrs"]
	local index = rid % (#svrs)	+ 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	if skynet.getenv("svr_id") ~= svr_id 
		and cfgclusters[svr_id] then
		status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
	else
		status, result1, result2, result3, result4 = base.pcall(skynet.call, svr_id, "lua", "request", ...)
	end
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgto_onlinestatesvrd failed", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.send_broadcastmsgto_onlinestatesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["onlinestatesvrs"]
	for _, svr_id in pairs(svrs) do
		if skynet.getenv("svr_id") ~= svr_id 
			and cfgclusters[svr_id] then
			skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
		else
			skynet.send(svr_id, "lua", "notice", ...)
		end
	end
	return true
end

function MsgProxy.sendrpc_reqmsgto_onlinestatesvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["onlinestatesvrs"]
	local index = rid % (#svrs)	+ 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgto_onlinestatesvrd error server exception", result1)
		return nil
	end
	return result1, result2, result3, result4	
end

function MsgProxy.sendrpc_broadcastmsgto_onlinestatesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["onlinestatesvrs"]
	for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
	end
	return true
end

-------------------------imsvrd相关的交互接口-----------------------
function MsgProxy.send_noticemsgto_imsvrd(imsvr_id, service_id, ...)
	if imsvr_id == nil then
		imsvr_id = service_id
	end
	init_svrs_indexs()
	if skynet.getenv("svr_id") ~= imsvr_id 
		and cfgclusters[imsvr_id] then
		skynet.send(proxy, "lua", "notice", imsvr_id, service_id, "notice", ...)
	else
		skynet.send(service_id, "lua", "notice", ...)
	end
	return true	
end

function MsgProxy.send_broadcastmsgto_imsvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["imsvrs"]
	for _, svr_id in pairs(svrs) do
		if skynet.getenv("svr_id") ~= svr_id 
			and cfgclusters[svr_id] then
			skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
		else
			skynet.send(svr_id, "lua", "notice", ...)
		end
	end
	return true
end
--根据玩家rid散列
function MsgProxy.send_reqmsgbyridhashto_imsvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["imsvrs"]
	local index = rid % (#svrs) + 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	if skynet.getenv("svr_id") ~= svr_id 
		and cfgclusters[svr_id] then
		status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)		
	else
		status, result1, result2, result3, result4 = base.pcall(skynet.call, svr_id, "lua", "request", ...)
	end
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgbyridhashto_imsvrd failed", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.send_reqmsgto_imsvrd(imsvr_id, ...)
	if imsvr_id == nil then
		imsvr_id = "imsvr_1"
	end
	init_svrs_indexs()
	local status, result1, result2, result3, result4
	if skynet.getenv("svr_id") ~= imsvr_id 
		and cfgclusters[imsvr_id] then
		status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", imsvr_id, imsvr_id, "request", ...)
	else
		status, result1, result2, result3, result4 = base.pcall(skynet.call, imsvr_id, "lua", "request", ...)
	end
	if not status then
		--filelog.sys_error("MsgProxy.send_reqmsgto_imsvrd failed", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_imsvrd(imsvr_id, service_id, ...)
	if service_id == nil then
		service_id = imsvr_id 
	end
	skynet.send(proxy, "lua", "notice", imsvr_id, service_id, "notice", ...)
	return true		
end

function MsgProxy.sendrpc_reqmsgto_imsvrd(imsvr_id, service_id, ...)
	local status, result1, result2, result3, result4
	if service_id == nil then
		service_id = imsvr_id
	end
	status, result1, result2, result3, result4 =  skynet.call(proxy, "lua", "request", imsvr_id, service_id, "request", ...)
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_imsvrd error server:"..imsvr_id.." exception", result1)
		return nil
	end
	return result1, result2, result3, result4	
end

function MsgProxy.sendrpc_broadcastmsgto_imsvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["imsvrs"]
	for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
	end
	return true
end

--根据玩家rid散列
function MsgProxy.sendrpc_reqmsgbyridhashto_imsvrd(rid, ...)
	init_svrs_indexs()	
	local svrs = svrs_indexs["imsvrs"]
	local index = rid % (#svrs) + 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4

	status, result1, result2, result3, result4 =  skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)	
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgbyridhashto_imsvrd error server exception", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_reqmsgto_imsvrd(imsvr_id, ...)
	local status, result1, result2, result3, result4
	if imsvr_id == nil then
		imsvr_id = "imsvr_1"
	end

	status, result1, result2, result3, result4 =  skynet.call(proxy, "lua", "request", imsvr_id, imsvr_id, "request", ...)	
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgbygroupidhashto_imsvrd error server exception", result1)
		return nil
	end

	return result1, result2, result3, result4
end
----------------------groupstatesvrd相关的交互接口------------------
function MsgProxy.send_reqmsgbyridhashto_groupstatesvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["groupstatesvrs"]
	local index = rid % (#svrs) + 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4
	if skynet.getenv("svr_id") ~= svr_id 
			and cfgclusters[svr_id] then
		status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
		if not status then
			--filelog.sys_error("MsgProxy.send_reqmsgbyridhashto_groupstatesvrd", result1)
			return nil
		end
	else
		status, result1, result2, result3, result4 = base.pcall(skynet.call, svr_id, "lua", "request", ...)		
	end

	return result1, result2, result3, result4
end

function MsgProxy.send_noticemsgto_groupstatesvrd(svr_id, ...)
	init_svrs_indexs()
	if skynet.getenv("svr_id") ~= svr_id 
			and cfgclusters[svr_id] then
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)			
	else
		skynet.send(svr_id, "lua", "notice", ...)
	end
	return true
end

function MsgProxy.send_broadcastmsgto_groupstatesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["groupstatesvrs"]
	for _, svr_id in pairs(svrs) do
		if skynet.getenv("svr_id") ~= svr_id 
			and cfgclusters[svr_id] then
			skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
		else
			skynet.send(svr_id, "lua", "notice", ...)		
		end
	end	
	return true
end

function MsgProxy.sendrpc_reqmsgbyridhashto_groupstatesvrd(rid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["groupstatesvrs"]
	local index = rid % (#svrs) + 1
	local svr_id = svrs[index]
	local status, result1, result2, result3, result4

	status, result1, result2, result3, result4 =  skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)	
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgbyridhashto_groupstatesvrd error server exception", result1)
		return nil
	end

	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_groupstatesvrd(svr_id, ...)
	skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)	
	return true
end

function MsgProxy.sendrpc_broadcastmsgto_groupstatesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["groupstatesvrs"]
	for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)	
	end	
	return true
end

----------------------shopsvrd相关的交互接口------------------
function MsgProxy.sendrpc_reqmsgto_rechargesvrd(...)
	local status, result1, result2, result3, result4
	init_svrs_indexs()
	local svrs = svrs_indexs["rechargesvrs"]
	for _, svr_id in pairs(svrs) do
		status, result1, result2, result3, result4 =  skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
		if not status then
			--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_rechargesvrd error server:"..svr_id.." exception", result1)
			return nil
		end
		break
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_rechargesvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["rechargesvrs"]
	for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
		break
	end

	return true		
end

---------------msgsvrd相关的交互接口---------------

-------------msgpersistent相关的接口交互-----------
function MsgProxy.send_msgto_msgpersistentsvrd(...)
	init_svrs_indexs()
    local svrs = svrs_indexs["msgpersistentsvrs"]
    for _, svr_id in pairs(svrs) do
    	skynet.send(svr_id, "lua", "record", ...)
    	break
    end
    return true	
end
-------------httpsvrd相关的接口交互----------------
function MsgProxy.sendrpc_reqmsgto_httpsvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["httpsvrs"]
	if svrs == nil then
		filelog.sys_error("MsgProxy.sendrpc_msgto_httpsvrd httpsvrs is nil")
		return nil
	end
    local status, result1, result2, result3, result4
    for _, svr_id in pairs(svrs) do
		status, result1, result2, result3, result4 =  skynet.call(proxy, "lua", "request", svr_id, svr_id, "request", ...)
		if not status then
			--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_httpsvrd error server:"..svr_id.." exception", result1)
			return nil
		end
		break
    end
    return result1, result2, result3, result4
end

----------和robotsvrd相关的交互接口--------------
function MsgProxy.send_noticemsgto_robotsvrd(robotsvr_id, service_id, ... )
	init_svrs_indexs()
	local svrs = svrs_indexs["robotsvrs"]
	if svrs == nil then
		--filelog.sys_error("MsgProxy.send_noticemsgto_robotsvrd robotsvrs is nil")
		return false
	end
	if service_id == nil then
		for _, svr_id in pairs(svrs) do
			if skynet.getenv("svr_id") ~= svr_id 
				and cfgclusters[svr_id] then
				skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
			else
				skynet.send(svr_id, "lua", "notice", ...)
			end
			break
		end 
	else
		if robotsvr_id == nil then
			robotsvr_id = service_id
		end
		if skynet.getenv("svr_id") ~= robotsvr_id 
			and cfgclusters[robotsvr_id] then
			skynet.send(proxy, "lua", "notice", robotsvr_id, service_id, "notice", ...)		
		else
			skynet.send(service_id, "lua", "notice", ...)		
		end
	end
	return true
end

function MsgProxy.sendrpc_noticemsgto_robotsvrd(robotsvr_id, service_id, ... )
	init_svrs_indexs()
	local svrs = svrs_indexs["robotsvrs"]
	if svrs == nil then
		--filelog.sys_error("MsgProxy.send_noticemsgto_robotsvrd robotsvrs is nil")
		return false
	end
	if robotsvr_id == nil or service_id == nil then
		for _, svr_id in pairs(svrs) do
			skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
			break
		end
	else
		skynet.send(proxy, "lua", "notice", robotsvr_id, service_id, "notice", ...)
	end
	return true 
end

--------------loginsvrd相关的交互接口-----------------
function MsgProxy.sendrpc_broadcastmsgto_loginsvrd(...)
	init_svrs_indexs()
	local svrs = svrs_indexs["loginsvrs"]
	if svrs == nil then
		--filelog.sys_error("MsgProxy.sendrpc_broadcastmsgto_loginsvrd loginsvrs is nil")
		return false
	end
    for _, svr_id in pairs(svrs) do
		skynet.send(proxy, "lua", "notice", svr_id, svr_id, "notice", ...)
    end
    return true	
end

-------------和ranklistsvrd相关的交互接口---------------
function MsgProxy.sendrpc_reqmsgto_ranklistsvrd(rank_key, ...)
    local status, result1, result2, result3, result4
	status, result1, result2, result3, result4 =  skynet.call(proxy, "lua", "request", "ranklistsvr_1", "ranklistsvr_1", "request", ...)
	if not status then
		--filelog.sys_error("MsgProxy.sendrpc_reqmsgto_ranklistsvrd error server:ranklistsvr_1 exception", result1)
		return nil
	end
    return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_ranklistsvrd( ... )
	skynet.send(proxy, "lua", "notice", "ranklistsvr_1", "ranklistsvr_1", "notice", ...)
	return true 
end

-------------------和datadbsvrd相关的交互接口-----------------------
function MsgProxy.sendrpc_reqmsgto_datadbsvrd(rid, ...)
	local status, result1, result2, result3, result4
	local svr_id = get_datadbsvr_id(rid)
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, ...)		
	if not status then
		filelog.sys_error("MsgProxy.sendrpc_reqmsgto_datadbsvrd error server exception", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_datadbsvrd(rid, ...)
	local svr_id = get_datadbsvr_id(rid)
	skynet.send(proxy, "lua", "notice", svr_id, svr_id, ...)
	return true
end
-----------------------和logindbsvrd交互接口----------------
function MsgProxy.sendrpc_reqmsgto_logindbsvrd(uid, ...)
	init_svrs_indexs()
	local status, result1, result2, result3, result4
	local svrs = svrs_indexs["logindbsvrs"]
	local index = uid % (#svrs) + 1
	local svr_id = svrs[index]
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, ...)		
	if not status then
		filelog.sys_error("MsgProxy.sendrpc_reqmsgto_logindbsvrd error server exception", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_logindbsvrd(uid, ...)
	init_svrs_indexs()
	local svrs = svrs_indexs["logindbsvrs"]
	local index = uid % (#svrs) + 1
	local svr_id = svrs[index]
	skynet.send(proxy, "lua", "notice", svr_id, svr_id, ...)
	return true
end

-------------------和globaldbsvrd相关的交互接口-----------------------
function MsgProxy.sendrpc_reqmsgto_globaldbsvrd(key, ...)
	local status, result1, result2, result3, result4
	local svr_id = get_globaldbsvr_id(key)
	status, result1, result2, result3, result4 = skynet.call(proxy, "lua", "request", svr_id, svr_id, ...)		
	if not status then
		filelog.sys_error("MsgProxy.sendrpc_reqmsgto_datadbsvrd error server exception", result1)
		return nil
	end
	return result1, result2, result3, result4
end

function MsgProxy.sendrpc_noticemsgto_globaldbsvrd(key, ...)
	local svr_id = get_globaldbsvr_id(key)
	skynet.send(proxy, "lua", "notice", svr_id, svr_id, ...)
	return true
end

return MsgProxy



