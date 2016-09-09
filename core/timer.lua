local skynet = require "skynet" 
local Timer = {}

function Timer.settimer(ms10_time, msgname, msg)
	return skynet.call(".timercenter", "lua", "settimer", ms10_time, msgname, msg)	
end

function Timer.cleartimer(timerid)
	skynet.send(".timercenter", "lua", "cleartimer", timerid)
end

return Timer