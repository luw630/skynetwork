local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"
local md5 = require "md5" 

local filename = "auth.lua"
local Auth = {}

function Auth.generate_md5token(data)
	if data == nil or type(data) ~= "string" then
		filelog.sys_error(filename, " [BASIC_AUTH] Auth.generate_md5token invalid param")
		return nil
	end
	local authkey = configdao.get_common_conf("authkey")
	if authkey ~= nil then
		data = authkey..data
	end 

	return md5.sumhexa(data) 
end

function Auth.generate_thirdauth_md5token(data)
	if data == nil or type(data) ~= "string" then
		filelog.sys_error(filename, " [BASIC_AUTH] Auth.generate_thirdauth_md5token invalid param")
		return nil
	end
	local thirdauthkey = configdao.get_common_conf("thirdauthkey")
	if thirdauthkey ~= nil then
		data = data..thirdauthkey
	end 

	return string.sub(md5.sumhexa(data), 1, 6)  
end

function Auth.generate_gmqueryauth_md5token(data)
	if data == nil or type(data) ~= "string" then
		filelog.sys_error(filename, " [BASIC_AUTH] Auth.generate_thirdauth_md5token invalid param")
		return nil
	end
	local gmqueykey = configdao.get_common_conf("gmqueykey")
	if gmqueykey ~= nil then
		data = data..gmqueykey
	end 
	return string.sub(md5.sumhexa(data), 1, 6)  
end

return Auth