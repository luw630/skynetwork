local base = require "base"
local skynet = require "skynet"
local os = os
local math =math
--[[
	时间相关操作的函数
]]  

local time_zone = 8*3600
local TimeTool = {}

--计算time2 比 time1 晚个自然日 
function TimeTool.get_diff_day(time1, time2)
	return math.floor((time2-time1)/(3600*24))
end
--计算两个时间相差的日期天数（time2 比 time1 晚几个非自然日天）
function TimeTool.get_diffdate_day(time1, time2, iszone)
	--if iszone ~= nil and not iszone then
		time1 = (time1)//(3600*24)
		time2 = (time2)//(3600*24)
	--else
	--	time1 = (time1+time_zone)//(3600*24)
	--	time2 = (time2+time_zone)//(3600*24)
	--end
	return (time2 - time1)	
end
--计算自然日时间
function TimeTool.get_day_time(begintime, interval)
	if begintime == 0 then
		begintime = TimeTool.get_time()
	end
	local temp = os.date("*t", begintime)
	if temp.hour > 20 then
		interval = interval + 1
	end
	temp.hour = 0
	temp.min = 0
	temp.sec = 0

	return (os.time(temp) + 3600 * 24 * interval)
end

--[[
	参数说明：
	strdatetime 原始字符串，要求格式2015-01-11 00:01:40
	interval 对时间进行加或减具体指， > 0 表示加 < 0 表示减
	dateunit 时间单位 支持DAY,HOUR,SECOND,MINUTE 4时间操作单位操作，根据具体值对原始时间按指定
	单位进行加或减
	返回：
	-1 表示srcdatetime字符串格式无效
]]
function TimeTool.datestr_to_time (srcdatetime, interval, dateunit)
	
	if srcdatetime == nil then
		return -1
	end

	local Y, M, D, H, MM, SS = string.match(srcdatetime, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")

	if Y == nil or M == nil or D == nil or H == nil or MM == nil or SS == nil then
		return -1
	end

	local time = os.time({year=Y, month=M, day=D, hour=H, min=MM, sec=SS})

	--更加时间单位和偏移量得到具体的偏移数据
	if interval == nil or dateunit == nil then
		return time
	end

	local ofset
	if dateunit == 'DAY' then
		ofset = 3600 * 24 * interval
	elseif dateunit == 'HOUR' then
		ofset = 3600 * interval 
	elseif dateunit == 'MINUTE' then
		ofset = 60 * interval
	elseif dateunit == 'SECOND' then
		ofset = interval
	end

	return (time + ofset)
 end

function TimeTool.get_10ms_time()
	if base.isdebug() then
		return (os.time()*100)
	end
	return skynet.time()*100
end

function TimeTool.get_time()
	if base.isdebug() then
		return os.time()
	end
	return math.floor(skynet.time())
end

--从wday获得实际的星期几
function TimeTool.get_wday(wday)
	return (wday + 5) % 7 + 1
end

--转换字符串为时间戳，格式 "12:34:56"
function TimeTool.get_str_timestamp(time_str)
    local today = os.date('*t', os.time())

    local hour, min, sec = time_str:match("(%d+):(%d+):(%d+)")
    return os.time({year = today.year, month = today.month, day = today.day, 
        hour = hour, min = min, sec=sec})
end

return TimeTool