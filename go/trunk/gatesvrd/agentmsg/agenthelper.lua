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

--用于copy玩家的基本信息
function AgentHelper:copy_base_info(baseinfo, info, playgame, money)
	baseinfo.rid = info.rid
	baseinfo.rolename = info.rolename
    baseinfo.logo = info.logo
    baseinfo.phone = info.phone
    baseinfo.level = playgame.level
    baseinfo.dan = playgame.dan
    baseinfo.winnum = playgame.winnum 
    baseinfo.losenum = playgame.losenum
    baseinfo.drawnum = playgame.drawnum
    baseinfo.sex = info.sex
end

--判断玩家是否登陆成功
function AgentHelper:is_login_success()
	return  (self.server.state == EGateAgentState.GATE_AGENTSTATE_LOGINED) 
end

--判断玩家是否退出成功
function AgentHelper:is_logout_success()
	return  (self.server.state == EGateAgentState.GATE_AGENTSTATE_LOGOUTED) 
end

return AgentHelper