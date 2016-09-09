local skynet = require "skynet"
local filelog = require "filelog"
local sharedata = require "sharedata"
require "enum"

local filename = "configdao.lua"
local ConfigDAO = {}
local cfgcentermng = nil
local platforms = nil
local cfgsvrs = nil
local cfgdbhash = nil
local cfgclusters = nil
local keys = {} 

local function get_business_conf(platform, channel, business)
	if platform == nil or channel == nil or business == nil then
		filelog.sys_error(filename," [BASIC_CONFIGDAO] get_business_conf invalid param")		
		return nil
	end
	
	if cfgcentermng == nil then
		 cfgcentermng = sharedata.query("cfgmng")
		 platforms = cfgcentermng.platforms
	end	
	
    local platformtable = cfgcentermng[platform]
	if platformtable  == nil then
		--filelog.sys_error(filename.." [BASIC_CONFIGMNG] get_business_conf invalid platfrom:"..platform, cfgcentermng)		
		return nil
	end
    local channeltable = platformtable[channel]
	if channeltable == nil then
		--filelog.sys_error(filename.." [BASIC_CONFIGMNG] get_business_conf invalid channel:"..channel, cfgcentermng)		
		return nil		
	end
    local businesstable = channeltable[business]
	if businesstable == nil then
		--filelog.sys_error(filename.." [BASIC_CONFIGMNG] get_business_conf invalid business:"..business)		
		return nil		
	end
	return businesstable.conf
end

function ConfigDAO.get_business_conf(platform, channel, business)
	if cfgcentermng == nil then
		 cfgcentermng = sharedata.query("cfgmng")
		 platforms = cfgcentermng.platforms
	end

	if cfgcentermng == nil then
		return nil
	end
	local conf
	platform = platforms[platform]
	if platform ~= nil then
		conf = get_business_conf(platform, channel, business)
		if conf == nil and platform ~= nil then
			conf = get_business_conf(platform, EPublishChannel.PUBLISH_CHANNEL_COMMON, business)
			if conf == nil then
				conf = get_business_conf("common", EPublishChannel.PUBLISH_CHANNEL_COMMON, business)
			end
		end 
	end

	if conf == nil then
		filelog.sys_error("ConfigDAO.get_business_conf can not find:", platform, channel, business)
	end

	return conf
end

function ConfigDAO.get_businessconfitem_by_index(platform, channel, business, index)
	local conf = ConfigDAO.get_business_conf(platform, channel, business)
	if conf == nil then
		return nil
	end 
	return conf[index]
end

function ConfigDAO.get_common_conf(conf_itemname)
	if cfgcentermng == nil then
		 cfgcentermng = sharedata.query("cfgmng")
		 platforms = cfgcentermng.platforms
	end

	if cfgcentermng == nil then
		return
	end
	
	local conf = cfgcentermng[conf_itemname]
	if conf == nil then
		return nil
	end
	return conf
end

function ConfigDAO.get_svrs(name)
	if cfgsvrs == nil then
		cfgsvrs = sharedata.query("cfgsvrs")
	end

	if cfgsvrs == nil then
		return
	end

	return cfgsvrs[name]
end

function ConfigDAO.get_cfgsvrs()
	if cfgsvrs == nil then
		cfgsvrs = sharedata.query("cfgsvrs")
	end

	if cfgsvrs == nil then
		return nil
	end

	return cfgsvrs	
end

function ConfigDAO.get_cfgdbhash()
	if cfgdbhash == nil then
		cfgdbhash = sharedata.query("cfgdbhash")
	end
	return cfgdbhash	
end

function ConfigDAO.get_cfgclusters()
	if cfgclusters == nil then
		cfgclusters = sharedata.query("cfgclusters")
	end
	return cfgclusters		
end

function ConfigDAO.reload()
	skynet.send(".confcenter", "lua", "reload")
end

function ConfigDAO.set_data(key, value)
	if key == nil or value == nil then
		return
	end
	skynet.send(".confcenter", "lua", "set", key, value)		
end

function ConfigDAO.get_data(key)
	if key == nil then
		return nil
	end
	local status = false
	local result = nil
	if keys[key] == nil then
		--keys[key] = sharedata.query(key)
		status, result = pcall(sharedata.query, key)
		if not status then
			return nil
		end
		keys[key] = result 
	end
	return keys[key]
end

return ConfigDAO
