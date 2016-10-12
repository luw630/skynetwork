--[[
	性能统计辅助工具，会影响一些程序性能
]]
local skynet = require "skynet"
local filelog = require "filelog"
local profile = require "profile"
local timetool = require "timetool"

local stat_mqlen_lasttime = timetool.get_time()
local stat_msg_lasttime = timetool.get_time()
local funcstat = {}
local mqlenstat = {}
local msgstat = {}

local StatisticsMng = {}

--统计函数真正耗时剔除阻塞调用(单位s)
function StatisticsMng.stat_func_start(funcname)
	profile.start()
	if funcstat[funcname] == nil then
		funcstat[funcname] = {
			n = 0,
			time = 0,
		}
	end
end

function StatisticsMng.stat_func_end(funcname)
	if funcstat[funcname] == nil then
		return
	end
	funcstat[funcname].time = funcstat[funcname].time + profile.stop()
	funcstat[funcname].n = funcstat[funcname].n + 1	
end

--统计消息的处理时间包括阻塞调用时间(单位10ms)
function StatisticsMng.stat_msg_start(msgname)
	local msgstatitem = msgstat[msgname]
	if msgstatitem == nil then
		msgstat[msgname] = {
			n = 0,
			time = 0,
			maxtime = 0,
			begintime = timetool.get_10ms_time(),
		}
	else
		msgstatitem.begintime = timetool.get_10ms_time()			
	end
end

function StatisticsMng.stat_msg_end(msgname)
	if msgstat[msgname] == nil then
		return
	end
	local msgstatitem = msgstat[msgname]
	local now_time = timetool.get_time()
	msgstatitem.n = msgstatitem.n + 1
	msgstatitem.time = msgstatitem.time + now_time - msgstatitem.begintime
	msgstatitem.begintime = nil
	if stat_msg_lasttime + 300 >= now_time then
		filelog.sys_obj("statitics", "msgstat", msgstat)
		stat_msg_lasttime = now_time
		msgstat = {}
	end
end

--每20s采样一次当前服务的消息队列长度,当样本超过15时将重置
function StatisticsMng.stat_service_mqlen(servicename)
	if #mqlenstat >= 15 then
		filelog.sys_obj("statitics", servicename, "----funcstat----", funcstat, "----mqlenstat----", mqlenstat)
		mqlenstat = {}
	end

	if timetool.get_time() - stat_mqlen_lasttime >= 20 then
		table.insert(mqlenstat, skynet.mqlen())
		stat_mqlen_lasttime = timetool.get_time()
	end
end

return StatisticsMng