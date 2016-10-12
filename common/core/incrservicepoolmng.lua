--[[
	服务池子管理器, 当服务数量小于incr时自动增加incr
]]
local List = require "list"
local Filelog = require "filelog"
local skynet = require "skynet"

local file_name = "incrservicepoolmng.lua"

----- 管理器声明---------
local INCRServicePoolMng = {
					servicepool = {},	--{id, } 
					conf = {}, 			--配置: {service_name, service_size, incr}
					tail = 1,
					head = -1,
					size = 0,
				}
-----------------------------
function INCRServicePoolMng:new(obj, conf, netpackmodule)
	if conf == nil or conf.service_name == nil then
		return nil
	else
		self.conf.service_name = conf.service_name
	end

	if conf.service_size == nil or conf.service_size <= 0 then
		self.conf.service_size = 1000
	else
		self.conf.service_size = conf.service_size
	end

	if conf.incr == nil or conf.incr <= 0 then
		self.conf.incr = 100
	else
		self.conf.incr = conf.incr
	end

	self.conf.netpackmodule = netpackmodule

	obj = obj or {}

	setmetatable(obj, self)
	self.__index = self
	self.tail = 1
	self.head = 1
	self.size = self.conf.service_size
	while self.tail <= self.conf.service_size do
		if netpackmodule ~= nil then
			self.servicepool[self.tail] = skynet.newservice(conf.service_name, ",,,"..netpackmodule)
		else			
			self.servicepool[self.tail] = skynet.newservice(conf.service_name)
		end
		self.tail = self.tail + 1
	end

	return obj
end

function INCRServicePoolMng:is_empty()
	if self.head >= self.tail then
		return true
	end
	return false
end

function INCRServicePoolMng:create_service()
	if INCRServicePoolMng:is_empty() then
		Filelog.sys_error(file_name.." [BASIC_INCRServicePoolMng] INCRServicePoolMng:create_service not enough service")
		return nil
	end

	local index = self.head
	self.head = self.head + 1
	self.size = self.size - 1

	skynet.fork(function()
		--检查是否要生成一批service
		if self.size <= self.conf.incr then
			local count = self.conf.incr
			while count >= 1 do
				if self.conf.netpackmodule ~= nil then
					self.servicepool[self.tail] = skynet.newservice(self.conf.service_name, ",,,"..self.conf.netpackmodule)
				else			
					self.servicepool[self.tail] = skynet.newservice(self.conf.service_name)
				end
				self.tail = self.tail + 1
				count = count - 1
				self.size = self.size + 1
			end
		end 
	end)

	local ret = {id = index, service = self.servicepool[index]}
	self.servicepool[index] = nil
	return ret
end

function INCRServicePoolMng:delete_service(serviceid)
end

--迭代访问空闲服务
function INCRServicePoolMng:idle_service_iter()
	local i = self.head
	return function ()
		i = i + 1
		if i < self.tail then 
			return self.servicepool[i]
		else
			return nil
		end
	end
end

return INCRServicePoolMng
