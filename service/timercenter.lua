local skynet = require "skynet"
require "skynet.manager"

local timermng = require "timermng"
local base = require "base"
local timerpool
local CMD = {}
local last_writelog_time = 0
local is_time_ticking = false

function CMD.init(timersize)
	local conf = {}
	conf.timer_size = timersize 
	timerpool = timermng:new({}, conf)	
	last_writelog_time = skynet.time()
	skynet.retpack(true)
end

function CMD.reload(...)
end

function CMD.exit(...)
	skynet.exit()
end

function CMD.timeout(source_address, msgname, timerid, msg, ...)
	skynet.send(source_address, "lua", "timer", msgname, timerid, msg, ...)
end

function CMD.settimer(source_address,ms10_time, msgname, msg, ...)
	base.pcall(skynet.retpack, timerpool:set_timer(source_address, ms10_time, msgname, msg))
	CMD.timetick()
	--skynet.ret(skynet.pack(timerpool:set_timer(source_address, ms10_time, msgname, msg)))
end

function CMD.cleartimer(_, timerid)
	timerpool:clear_timer(timerid)
end

function CMD.timetick()
	if is_time_ticking then
		return
	end

	if timerpool:is_empty_usedlist() then
		return
	end

	skynet.fork(function()
		is_time_ticking = true
		while true do
			--检查定时器是否超时
			timerpool:time_tick(CMD.timeout)

			if timerpool:is_empty_usedlist() then
				break
			end
			--检查是否输出错误日志
			local now_time = skynet.time()
			if  last_writelog_time + 120 < now_time then
				timerpool:write_info_log()
				timerpool:write_debug_log()
				last_writelog_time = now_time
			end 
			skynet.sleep(5)
		end
		is_time_ticking = false		
	end)	
end

function CMD.start(...)
	--CMD.init(...)
end


skynet.dispatch("lua", function(_, address,  cmd, ...)
	    local f = CMD[cmd]
	    if cmd == "init" then
	    	f(...)
	    	return
	    end
		if f ~= nil then
            f(address, ...)
        end
end)

skynet.start(function()
	CMD.start()
    skynet.register ".timercenter"
end)

