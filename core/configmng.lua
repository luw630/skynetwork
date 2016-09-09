local skynet = require "skynet"
local filelog = require "filelog"
local configtool = require "configtool"

local filename = "configmng.lua"

local ConfigMng = {
	conf_cfgcenter = nil,
}

local function load_cfgcenter()
	--加载配置
	local conf_path = skynet.getenv("cfgcenter_config")
	ConfigMng.conf_cfgcenter = configtool.load_config(conf_path)
	if ConfigMng.conf_cfgcenter == nil then
		filelog.sys_error(filename," [BASIC_CONFIGMNG] ConfigMng:new load "..conf_path.." failed")
		return false
	end	
	return true
end

local function load_allbusinesscfg()
	if ConfigMng.conf_cfgcenter ~= nil then
		for _, value in pairs(ConfigMng.conf_cfgcenter) do
			if value ~= nil and type(value) == "table" then
				for _, value1 in pairs(value) do
					if value1 ~= nil and type(value1) == "table" then
						for key2, value2 in pairs(value1) do
							if value2 ~= nil and type(value2) == "table" then
                                for key3, value3 in pairs(value2) do
                                    if key3 ~= nil and key3 == "file" then
                                    	value2.conf = configtool.load_config(value3)
                                    end
                                end
							end
						end
					end
				end 
			end  
		end
	end
end

function ConfigMng.init()
	--加载配置
	if not load_cfgcenter() then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] ConfigMng:new load cfgcenter failed")
		return nil
	end

	--加载所有的业务配置
	load_allbusinesscfg()
end

function ConfigMng.reload()
	--加载配置
	if not load_cfgcenter() then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] ConfigMng:new load cfgcenter failed")
		return false
	end

	--加载所有的业务配置
	load_allbusinesscfg()
	return true	 
end

function ConfigMng.get_business_conf(platform, channel, business)
	if platform == nil or channel == nil or business == nil then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] COnfigMng:get_business_conf invalid param")		
		return nil
	end

    local platformtable = ConfigMng.conf_cfgcenter[platform]
	if platformtable  == nil then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] COnfigMng:get_business_conf invalid platfrom:"..platform)		
		return nil
	end
    local channeltable = platformtable[channel]
	if channeltable == nil then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] COnfigMng:get_business_conf invalid channel:"..channel)		
		return nil		
	end
    local businesstable = channeltable[business]
	if businesstable == nil then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] COnfigMng:get_business_conf invalid business:"..business)		
		return nil		
	end

	return businesstable.conf
end  

function ConfigMng.get_businessconfitem_by_index(platform, channel, business, index)
	local conf = ConfigMng.get_business_conf(platform, channel, business)

	if conf == nil then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] COnfigMng:get_businessconfitem_by_index get platform:"..platform.."channel:"..channel.." business:"..business.."failed")		
		return nil
	end

	return conf[index]
end

function ConfigMng.get_common_conf(conf_itemname)
	local conf = ConfigMng.conf_cfgcenter[conf_itemname]
	if conf == nil then
		filelog.sys_error(filename, " [BASIC_CONFIGMNG] ConfigMng:get_common_conf get conf_itemname:"..conf_itemname)		
		return nil
	end

	return conf
end

function ConfigMng.get_cfgcenter()
	return ConfigMng.conf_cfgcenter
end 

return ConfigMng
