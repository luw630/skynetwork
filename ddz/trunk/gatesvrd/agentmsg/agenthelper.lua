local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"
--local msgproxy = require "msgproxy"
local timetool = require "timetool"
local helperbase = require "helperbase"
require "enum"

local trace_rids = nil
local AgentHelper = helperbase:new({}) 

--用于输出指定rid玩家的信息，方便定位问题
function AgentHelper:write_agentinfo_log(...)
	if trace_rids == nil then
		trace_rids = configdao.get_common_conf("rids")
	end

	if trace_rids == nil then
		return
	end

	local rid = self.server.rid
	if (trace_rids.isall ~= nil and trace_rids.isall) or trace_rids[rid] ~= nil then
		filelog.sys_obj("agent", rid, ...)	
	end	
end

return AgentHelper