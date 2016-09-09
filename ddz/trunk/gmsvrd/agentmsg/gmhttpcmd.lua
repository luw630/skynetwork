local msghelper = require "agentmsghelper"
local msgproxy = require "msgproxy"
local configdao = require "configdao"
local json = require "cjson"
local commonconst = require "common_const"
local playerdatadao = require "playerdatadao"
local msgdatadao = require "msgdatadao"
local playerauthdao = require "playerauthdao"
local pushmqdao = require "pushmqdao"
local timetool = require "timetool"
local gamewaterlog = require "gamewaterlog"
local base = require "base"
local filelog = require "filelog"
require "const.enum"

json.encode_sparse_array(true,1,1)

local  CMD = {}

function CMD.ping(responsemsg)
	return {status="success"}
end

function CMD.reload(responsemsg)

	local result = nil

	local gatesvrs = configdao.get_svrs("gatesvrs")
	for gatesvr_id in pairs(gatesvrs) do
		result = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "reload")
		if not result then
			return {status="gatesvr_id "..gatesvr_id.." reload failed"}
		end
	end

	local matchsvrs = configdao.get_svrs("matchsvrs")
	for matchsvr_id in pairs(matchsvrs) do
		result = msgproxy.sendrpc_reqmsgto_matchsvrd("gate_1", matchsvr_id, "gmcommand", "reload")
		if not result then
			return {status="matchsvr_id "..matchsvr_id.." reload failed"}
		end
	end

	local roomsvrs = configdao.get_svrs("roomsvrs")
	for roomsvr_id in pairs(roomsvrs) do
		result = msgproxy.sendrpc_reqmsgto_roomsvrd(nil, "gate_1", roomsvr_id, "gmcommand", "reload")
		if not result then
			return {status="roomsvr_id "..roomsvr_id.." reload failed"}
		end
	end

	result = msgproxy.sendrpc_reqmsgto_rechargesvrd("gmcommand", "reload")
	if not result then
		return {status="rechargesvrd reload failed"}
	end

	return {status="success"}
end

function CMD.marquee(responsemsg)
	local result = nil

	if not responsemsg.content then
		return {status="marquee need content"}
	end

	local marqueemsg = {content=responsemsg.content}

	local gatesvrs = configdao.get_svrs("gatesvrs")
	for gatesvr_id in pairs(gatesvrs) do
		result = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "marquee", marqueemsg)
		if not result then
			return {status="gatesvr_id "..gatesvr_id.." marquee failed"}
		end
	end

	return {status="success"}
end


function CMD.online_count(responsemsg)

	local gatesvrs = configdao.get_svrs("gatesvrs")
	for gatesvr_id in pairs(gatesvrs) do
		local count = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "online_count")
		if not count then
			return {status="online_count failed"}
		end
		return {status="success", count=count}
	end
	
	return {status="online_count failed"}
end

function CMD.game_online_count(responsemsg)

	if not responsemsg.type then
		return {status="game_online_count need type"}
	end

	local gatesvrs = configdao.get_svrs("gatesvrs")
	for gatesvr_id in pairs(gatesvrs) do
		local count = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "game_online_count", responsemsg.type)
		if not count then
			return {status="game_online_count failed"}
		end
		return {status="success", count=count}
	end
	
	return {status="game_online_count failed"}
end

function CMD.table_list(responsemsg)

	if not responsemsg.type then
		return {status="table_list need type"}
	end

	local gatesvrs = configdao.get_svrs("gatesvrs")
	for gatesvr_id in pairs(gatesvrs) do
		local list, room, count = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "table_list", responsemsg.type)
		if not list then
			return {status="table_list failed"}
		end
		return {status="success", list=list, room=room, count=count}
	end
	
	return {status="table_list failed"}
end

function CMD.table_info(responsemsg)

	if not responsemsg.table_id then
		return {status="table_info need table_id"}
	end

	if not responsemsg.room_id then
		return {status="table_info need room_id"}
	end

	local info = msgproxy.sendrpc_reqmsgto_roomsvrd(nil, "gate_1", responsemsg.room_id, "gmcommand", "table_info", responsemsg.table_id)
	if not info then
		return {status="table_info failed"}
	end

	return {status="success", info=info}
end



function CMD.mtt_list(responsemsg)

	local gatesvrs = configdao.get_svrs("gatesvrs")
	for gatesvr_id in pairs(gatesvrs) do
		local list = msgproxy.sendrpc_reqmsgto_gatesvrd(gatesvr_id, gatesvr_id, "gmcommand", "mtt_list", responsemsg.type)
		if not list then
			return {status="mtt_list failed"}
		end
		return {status="success", list=list}
	end

	return {status="mtt_list failed"}
end

function CMD.match_list(responsemsg)

	if not responsemsg.matchsvr_id then
		return {status="match_list need matchsvr_id"}
	end

	if not responsemsg.match_instance_id then
		return {status="match_list need match_instance_id"}
	end

	local list, count = msgproxy.sendrpc_reqmsgto_matchsvrd("gate_1", responsemsg.matchsvr_id, "gmcommand", "match_list", responsemsg.match_instance_id)
	if not list then
		return {status="match_list failed"}
	end

	return {status="success", list=list, count=count}
end

function CMD.match_rank(responsemsg)

	if not responsemsg.matchsvr_id then
		return {status="match_rank need matchsvr_id"}
	end

	if not responsemsg.match_instance_id then
		return {status="match_rank need match_instance_id"}
	end

	local rank = msgproxy.sendrpc_reqmsgto_matchsvrd("gate_1", responsemsg.matchsvr_id, "gmcommand", "match_rank", responsemsg.match_instance_id)
	if not rank then
		return {status="match_rank failed"}
	end

	return {status="success", rank=rank}
end


function CMD.send_mail(responsemsg)

	if not responsemsg.rid then
		return {status="send_mail need rid"}
	end

	if not responsemsg.content then
		return {status="send_mail need content"}
	end

	local status, content = pcall(json.decode, responsemsg.content)
	if not status then
		return {status="send_mail content wrong format"}
	end
	local mail = {
		rid = responsemsg.rid,
		create_time = timetool.get_time(),
		content = responsemsg.content,
		mail_key = base.generate_mail_key(responsemsg.rid),
		--content = [[{"notice":true,"isattach":true,"des":"xxxxxx","awards":[{"id":1,"num":100}]}]]
	}
	playerdatadao.save_player_mail(responsemsg.rid, mail)

	if content.notice then
		--mail.id = playerdatadao.query_conn_lastmail_id(mail.rid)
		local online = playerdatadao.query_playeronline(mail.rid)		
		if online.gatesvr_id ~= nil and online.gatesvr_id ~= "" then
			local notifymsg = {mail = mail}
			msgproxy.sendrpc_noticemsgto_gatesvrd(online.gatesvr_id, online.gatesvr_service_address, "noticemail",  notifymsg)
		end
	end 
	return {status="success"}
end


function CMD.push_notice(responsemsg)

	if not responsemsg.message then
		return {status="push_notice need message"}
	end

	if not responsemsg.list then
		return {status="push_notice need list"}
	end

	local message = {
		text = responsemsg.message,
		list = {},
	}

	for i,v in ipairs(responsemsg.list) do
		table.insert(message.list, {1, v[1], v[2]})
	end

	pushmqdao.push(message)

	return {status="success"}
end

function CMD.proplist(responsemsg)
	local propcfg = configdao.get_business_conf(100, 1000, "propcfg")
	local proplist = {}
	for _, cfg in pairs(propcfg.propcfg) do
		-- table.insert(proplist, cfg)
		table.insert(proplist, {
			id=cfg.id,
			name=cfg.name,
			desc=cfg.desc,
		})
	end
	return {status="success", proplist=proplist}
end


function CMD.send_chat(responsemsg)

	if not responsemsg.rid then
		return {status="send_chat need rid"}
	end

	if not responsemsg.content then
		return {status="send_chat need content"}
	end

	if string.len(responsemsg.content) > 256 then
		return {status="send_chat content too long"}
	end

	local send_rid = 1000000
	local to_id = responsemsg.rid

	local msg_item = {
		msg_id = msgdatadao.query_msgid(send_rid, to_id),
		send_rid = send_rid,
		to_id = to_id,
		time = timetool.get_time(),
		msg_type = MsgType.MSG_TYPE_P2P_TEXT,
		msg = responsemsg.content,
	}

	--通知好友
	local online = playerdatadao.query_playeronline(to_id)
	if online.gatesvr_id ~= nil and online.gatesvr_id ~= "" then
		local notifymsg = {msg_list={msg_item}}
		msgproxy.sendrpc_reqmsgto_gatesvrd(online.gatesvr_id, online.gatesvr_id, "gmcommand", "notifyimmsg", online.gatesvr_id, online.gatesvr_service_address, notifymsg)
	end

	--保存消息记录
	msgdatadao.save_msg(send_rid, to_id, msg_item)

	return {status="success"}
end

function CMD.transfer_account(responsemsg)
	if responsemsg.token == nil or responsemsg.token == "" then
		return {status="failed", resultdes="无效的token！"}
	end

	if responsemsg.uid == nil or responsemsg.rid == nil then
		return {status="failed", resultdes="无效的参数！"}
	end

	local from_rid = playerauthdao.query_player_rid(responsemsg.uid)
	if from_rid == nil then
		return {status="failed", resultdes="你的账号无效！"}
	end

	local from_playerbaseinfo = playerdatadao.query_player_baseinfo2(from_rid)
	local to_playerbaseinfo = playerdatadao.query_player_baseinfo2(responsemsg.rid)
	if from_playerbaseinfo == nil then
		return {status="failed", resultdes="你的账号无效，该账号未在游戏注册！"}
	end

	if to_playerbaseinfo == nil then
		return {status="failed", resultdes="你的赠送账号无效，赠送账号未在游戏注册！"}		
	end

	local online = from_playerbaseinfo.online
	local money = from_playerbaseinfo.money
	local info = from_playerbaseinfo.info
	local to_info = to_playerbaseinfo.info
	if money.chips < responsemsg.money then
		return {status="failed", resultdes="你当前余额不足，请充值！"}
	end

	local result_data
	responsemsg.from_rid = from_rid
	if online.gatesvr_id ~= nil and online.gatesvr_id ~= "" then
		result_data = msgproxy.sendrpc_reqmsgto_gatesvrd(online.gatesvr_id, online.gatesvr_id, "gmcommand", "transfer_account", online.gatesvr_id, online.gatesvr_service_address, responsemsg)		
	end
	if not result_data then
		msghelper.player_transferaccount_add_chip(money, responsemsg.from_rid, EPropChangeReason.PROP_CHANGE_TRANSFER_ACCOUNT, -responsemsg.money)
		gamewaterlog.write_transfer_account(responsemsg.uid, responsemsg.from_rid, responsemsg.rid, responsemsg.money, 1)		
	elseif not result_data.issuccess then
		return {status="failed", resultdes = result_data.resultdes}
	end

	local mailcontent = configdao.get_common_conf("from_give_awards_mail")
	local mail = {
		rid = responsemsg.from_rid,
		create_time=timetool.get_time(),
		content=string.format(mailcontent,
		to_info.rolename,
		responsemsg.money)}
	playerdatadao.save_player_mail(mail.rid, mail)

	--给赠送玩家发货
	mailcontent = configdao.get_common_conf("give_awards_mail")
	mail = {
		rid = responsemsg.rid,
		create_time=timetool.get_time(),
		content=string.format(mailcontent,
		info.rolename,
		responsemsg.money,
		json.encode({{id = 1, num=responsemsg.money}}))}
	playerdatadao.save_player_mail(mail.rid, mail)
	gamewaterlog.write_transfer_account(responsemsg.uid, responsemsg.from_rid, responsemsg.rid, responsemsg.money, 2)		
	
	return {status="success"}
end


return CMD