local skynet = require "skynet"

local service
local RechargesvrmsgHelper = {}

function RechargesvrmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function RechargesvrmsgHelper.get_conf()
	return service.get_conf()
end

function RechargesvrmsgHelper.set_conf(conf)
	service.set_conf(conf)
end

return	RechargesvrmsgHelper  