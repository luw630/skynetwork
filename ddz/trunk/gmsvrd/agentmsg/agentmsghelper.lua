local skynet = require "skynet"
local filelog = require "filelog"
local dblog = require "dblog"
local playerdatadao =  require "playerdatadao"
local configdao = require "configdao"
local timetool = require "timetool"
local tabletool = require "tabletool"

local filename = "agentmsghelper.lua"
local service
local propcfg
local AgentmsgHelper = {}

function AgentmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function AgentmsgHelper.send_resmsgto_client(msgname, msg)
	if service ~= nil then
		service.send_resmsgto_client(msgname, msg)
	else
		filelog.sys_error(filename.."AgentmsgHelper service == nil")
	end
end

function AgentmsgHelper.send_noticemsgto_client(msgname, msg)
	if service ~= nil then
		service.send_noticemsgto_client(msgname, msg)
	else
		filelog.sys_error(filename.."AgentmsgHelper service == nil")
	end
end

function AgentmsgHelper.agentfree()
	return service.agentfree()
end

function AgentmsgHelper.agentexit()
	service.agentexit()
end

function AgentmsgHelper.get_agentdata()
	return service.get_agentdata()
end

function AgentmsgHelper.create_clientsession(session_id, conf)
	return service.create_clientsession(session_id, conf)
end

--给玩家加筹码(增量修改可正可负)
function AgentmsgHelper.player_transferaccount_add_chip(money, rid, reasion, num)
	if num == nil then
		return		
	end

	local data = {rid=money.rid, reasion=reasion, num=num, beforetotal=money.chips}
	money.chips = money.chips + num
	if money.chips < 0 then
		money.chips = 0
	end
	if money.chips > money.maxchips then
		money.maxchips = money.chips
	end

	data.aftertotal= money.chips
	playerdatadao.save_player_money(rid, money)
	dblog.dblog_write("money", data)
end


--给玩家加筹码(增量修改可正可负)
function AgentmsgHelper.player_add_chip(rid, reasion, num)
	local money = playerdatadao.query_playermoney(rid)
	if money == nil or num == nil then
		return false		
	end

	local data = {rid=money.rid, reasion=reasion, num=num, beforetotal=money.chips}
	money.chips = money.chips + num
	if money.chips < 0 then
		money.chips = 0
	end
	if money.chips > money.maxchips then
		money.maxchips = money.chips
	end

	data.aftertotal= money.chips
	playerdatadao.save_player_money(rid, money)
	dblog.dblog_write("money", data)
	return true
end

--给玩家添加道具, 返回发生变化的道具
function AgentmsgHelper.player_add_prop(rid, reasion, config_id, num)
	if propcfg == nil then
		propcfg = configdao.get_business_conf(100, 1000, "propcfg")
		propcfg = propcfg.propcfg
	end
	local propconf = propcfg[config_id]
	local prop = nil

	if config_id == 1 then
		AgentmsgHelper.player_add_chip(rid, reasion, num)
	else
		local propinfo = playerdatadao.query_props(rid)
		for i = 1, #(propinfo.props) do
			prop = propinfo.props[i]
			if prop.config_id == config_id then
				break
			end			
		end
		if propconf.is_entity then
			prop = nil
		end
		local cmd = "update"
		if prop == nil then
			prop = {
				rid = rid,
				prop_id = propinfo.id + 1,
				prop_num = 0,
				config_id = propconf.id,
				use_time = 0,
				get_time = timetool.get_time(),
				last_time = 0,
			}
			cmd = "insert"
		end
		if propconf.is_immediatedel then
			if propconf.use_sec_lmt > 0 then
				if prop.use_time == 0 then
					prop.use_time = prop.get_time + propconf.use_sec_lmt
				else
					prop.use_time = prop.use_time + propconf.use_sec_lmt
				end 
			elseif propconf.use_day_lmt > 0 then
				timetool.get_day_time(prop.use_time, propconf.use_day_lmt)
			end
		else
			prop.prop_num = prop.prop_num + num
		end

		playerdatadao.save_player_prop(cmd, rid, prop)
	end
end

return	AgentmsgHelper  
