local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agentmsghelper"
local playerdatadao =  require "playerdatadao"
local configdao = require "configdao"
local tabletool = require "tabletool"
local msgproxy = require "msgproxy"
local gmatch = string.gmatch
require "const.enum"

local  Gmcommand = {}



--[[
gmcommand 84 {
	request {
		cmd 0 : string    #命令
		param 1 : string  #参数
		isexit 2 : boolean  
	}

	response {
		issucces 0 : boolean
		resultdes 1 : string
		result 2 : string
	}
}
]]
function  Gmcommand.process(session, source, request)
	local responsemsg = {issucces = true,}
	if request == nil or  request.cmd == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的请求！"
		msghelper.send_resmsgto_client("gmcommand", responsemsg)
		return
	end

	local f = Gmcommand[request.cmd]
	if f == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的命令！"
	else
		f(request.param, responsemsg)
	end	

	msghelper.send_resmsgto_client("gmcommand", responsemsg)

	if request.isexit == nil or request.isexit then
		msghelper.agentfree()
	end
end
--[[
function Gmcommand.addchip(params, responsemsg)
	local rid, chips = string.match(params, "(%w+)%s+(%w+)")

	rid = tonumber(rid)
	chips = tonumber(chips)

	if rid == nil or chips == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的参数！"
		return
	end

	local online = playerdatadao.query_playeronline(rid)
	if online == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的rid参数！"
		return
	end

	if online.gatesvr_id == "" or online.gatesvr_service_address == -1 then
		msghelper.player_add_chip(rid, EPropChangeReason.PROP_CHANGE_GM, chips)
	else
		local result = msgproxy.sendrpc_reqmsgto_gatesvrd(online.gatesvr_id, online.gatesvr_service_address, "gmcommand", "addchip", rid, chips)
		if result == nil then
			responsemsg.issucces = false
			responsemsg.resultdes = "系统错误，可能操作失败！"
			return			
		end

		if not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
			return			
		end
	end	
end

function Gmcommand.addprop(params, responsemsg)
	local rid, prop_id, prop_num = string.match(params, "(%w+)%s+(%w+)%s+(%w+)")
	
	rid = tonumber(rid)
	prop_id = tonumber(prop_id)
	prop_num = tonumber(prop_num)

	if rid == nil or prop_id == nil or prop_num == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的参数！"
		return
	end

	local online = playerdatadao.query_playeronline(rid)
	if online == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的rid参数！"
		return
	end

	if online.gatesvr_id == "" or online.gatesvr_service_address == -1 then
		msghelper.player_add_prop(rid, EPropChangeReason.PROP_CHANGE_GM, prop_id, prop_num)
	else
		local result = msgproxy.sendrpc_reqmsgto_gatesvrd(online.gatesvr_id, online.gatesvr_service_address, "gmcommand", "addprop", rid, prop_id, prop_num)
		if result == nil then
			responsemsg.issucces = false
			responsemsg.resultdes = "系统错误，可能操作失败！"
			return			
		end

		if not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
			return			
		end
	end		
end
]]

function Gmcommand.rechargereload(params, responsemsg)
	local result = msgproxy.sendrpc_reqmsgto_rechargesvrd("gmcommand", "reload")
	if result == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "系统错误，可能操作失败！"
		return			
	end

	if not result then
		responsemsg.issucces = false
		responsemsg.resultdes = "操作失败！"
		return					
	end			
end

function Gmcommand.roomreload(params, responsemsg)
	local roomsvrs = configdao.get_svrs("roomsvrs")
	local svr_id = "gate_1"
	local result

	if params ~= nil and params ~= "" then
		result = msgproxy.sendrpc_reqmsgto_roomsvrd(nil, svr_id, params, "gmcommand", "reload")
		if result == nil or not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
		end
		return
	end

	responsemsg.result = ""
    for roomsvr_id, _ in pairs(roomsvrs) do
		result = msgproxy.sendrpc_reqmsgto_roomsvrd(nil, svr_id, roomsvr_id, "gmcommand", "reload")
		if result == nil or not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
			responsemsg.result = responsemsg.result..roomsvr_id.." "
		end		    	
    end
end

--更新需要10s钟完成
function Gmcommand.matchreload(params, responsemsg)
	local matchsvrs = configdao.get_svrs("matchsvrs")
	local svr_id = "gate_1"
	local result

	if params ~= nil and params ~= "" then
		result = msgproxy.sendrpc_reqmsgto_matchsvrd(svr_id, params, "gmcommand", "reload")
		if result == nil or not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
		end
		return
	end

	responsemsg.result = ""
    for matchsvr_id, _ in pairs(matchsvrs) do
		result = msgproxy.sendrpc_reqmsgto_matchsvrd(svr_id, matchsvr_id, "gmcommand", "reload")
		if result == nil or not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
			responsemsg.result = responsemsg.result..matchsvr_id.." "
		end		    	
    end	
end

function Gmcommand.gatereload(params, responsemsg)

	local gatesvrs = configdao.get_svrs("gatesvrs")
	local result
	if params ~= nil and params ~= "" then
		result = msgproxy.sendrpc_reqmsgto_gatesvrd(params, params, "gmcommand", "reload")
		if result == nil or not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
		end
		return
	end

	responsemsg.result = ""
    for gatesvr_id, _ in pairs(gatesvrs) do
		result = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "reload")
		if result == nil or not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
			responsemsg.result = responsemsg.result..gatesvr_id.." "
		end		    	
    end			
end

function Gmcommand.marquee(params, responsemsg)
	local gatesvrs = configdao.get_svrs("gatesvrs")
	local result
	local marqueemsg = {}
	if params == nil or string.sub(params, 1,1) ~= "{" then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效参数！"
		return
	end

	marqueemsg.content = params
	responsemsg.result = ""	
    for gatesvr_id, _ in pairs(gatesvrs) do
		result = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "marquee", marqueemsg)
		if result == nil or not result then
			responsemsg.issucces = false
			responsemsg.resultdes = "操作失败！"
			responsemsg.result = responsemsg.result..gatesvr_id.." "
		end		    	
    end			
end

return Gmcommand
