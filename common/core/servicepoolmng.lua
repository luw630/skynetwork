--[[
	服务池子管理器, 可回收的资源池
]]
local List = require "list"
local Filelog = require "filelog"
local skynet = require "skynet"

local file_name = "servicepoolmng.lua"

----- 管理器声明---------
local ServicePoolMng = {
					servicepool = {},	--timer {id, } 
					conf = {}, 			--配置: {service_name, service_size}
					servicehash = {},		--{serviceid, index} 	
					curserviceid = 1,
					freelist = nil,
				}
-----------------------------
function ServicePoolMng:new(obj, conf, netpackmodule)
	if conf == nil or conf.service_name == nil then
		return obj
	else
		self.conf.service_name = conf.service_name
	end

	if conf.service_size <= 0 then
		self.conf.service_size = 500
	else
		self.conf.service_size = conf.service_size
	end

	obj = obj or {}

	setmetatable(obj, self)
	self.__index = self
	self.freelist = List:new(nil)
	local i = 1
	while i <= self.conf.service_size do
		if netpackmodule ~= nil then
			self.servicepool[i] = skynet.newservice(conf.service_name, ",,,"..netpackmodule)
		else
			self.servicepool[i] = skynet.newservice(conf.service_name)
		end
		self.freelist:push_right(i)
		i = i + 1
	end

	return obj
end

function ServicePoolMng:write_info_log()
	Filelog.sys_info("ServicePoolMng: totalsize--"..(#self.servicepool).." freesize--"..(self.freelist:get_size()).." usedsize--"..(#self.servicehash))
end

function ServicePoolMng:write_debug_log()
	Filelog.sys_obj("ServicePoolMng", "----servicepool----", self.servicepool, "---freelist---", self.freelist, "---servicehash---", self.servicehash)
end


function ServicePoolMng:is_empty()
	return (self.freelist:get_size() == 0)
end

function ServicePoolMng:create_service()
	if ServicePoolMng:is_empty() then
		Filelog.sys_error(file_name.." [BASIC_ServicePoolMng] ServicePoolMng:create_service not enough service")
		return nil
	end

	local index = self.freelist:pop_left()
	local serviceid = self.curserviceid
	self.servicehash[serviceid] = index
	self.curserviceid = self.curserviceid + 1

	return {id = serviceid, service = self.servicepool[index]}

end

function ServicePoolMng:delete_service(serviceid)
	if self.servicehash[serviceid] == nil then
		Filelog.sys_error(file_name.." [BASIC_ServicePoolMng] ServicePoolMng:delete_service invalid serviceid:"..serviceid)
		return
	end
	local index = self.servicehash[serviceid]
	self.servicehash[serviceid] = nil
	if self.servicepool[index] == nil then
		return
	end

	self.freelist:push_right(index)
end


return ServicePoolMng
