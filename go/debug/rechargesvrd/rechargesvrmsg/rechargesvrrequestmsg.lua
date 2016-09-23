local skynet = require "skynet"
local filelog = require "filelog"
local filename = "rechargesvrrequestmsg.lua"
local base = require "base"
local json = require "cjson"
local configdao = require "configdao"
local playerordermysqldao = require "playerordermysqldao"
local playerdatadao = require "playerdatadao"
local msgproxy = require "msgproxy"
local tabletool = require "tabletool"
local timetool = require "timetool"
local dblog = require "dblog"
require "const.enum"

json.encode_sparse_array(true, 1, 1)

local count = 1
local RechargesvrRequestMsg = {}

function RechargesvrRequestMsg.process(session, source, event, ...)
	local f = RechargesvrRequestMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." RechargesvrRequestMsg.process invalid event:"..event)
		base.skynet_retpack(nil)
		return nil
	end
	f(...)	 
end

--[[
#充值
recharge 74 {
	request {
		version 0 : VersionType
		id 1 : integer #商品id（苹果支付渠道）
		pay_type 2 : integer   #支付类型
		option_data 3 : string #附加数据
	}

	response {
	    issucces 0 : boolean	 #true 成功  false 失败
		resultdes 1 : string	 #错误原因
		order_id 2 : string      #订单号
		pay_type 3 : integer	 #支付类型			
	}
}
--支付类型
EPayType = {
	PAY_TYPE_IOS=1, --IOS支付
}
#发货通知
delivergood 75 {
	response {
		order_id 0 : string     #订单号
		awards 1 :  *AwardItem  #物品列表
		option_data 2 : string  #附加数据
	}
}
]]

local function ios_recharge(request, responsemsg)
	local rechargecfg = configdao.get_business_conf(request.version.client_platform, request.version.client_channel, "rechargecfg")
	local result = true
	if rechargecfg == nil or request.option_data == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的请求！"
		return
	end
	local data = msgproxy.sendrpc_reqmsgto_httpsvrd("webclient", request)
	if data == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "系统错误，系统会在你下次登录时给你补单！"
		filelog.sys_error(filename.."msgproxy.sendrpc_reqmsgto_httpsvrd failed")
		return
	end
	if data.status ~= 0 then
		responsemsg.issucces = false
		responsemsg.resultdes = "支付验证错误，"..data.status
	else
		local delivergoodmsg = {}
		local order = {rid = request.rid}
		for id, rechargeitem in pairs(rechargecfg.rechargecfg) do
			if rechargeitem.pid == data.receipt.product_id then
				local awards = {}
				for i, award in pairs(rechargeitem.awards) do
					awards[i]={}
					awards[i].id = award.id
					awards[i].num = award.num
				end
				order.order_id=data.receipt.transaction_id
				order.pid = data.receipt.product_id
				order.good_id = rechargeitem.id
				order.good_awards =  json.encode(awards)
				order.pay_type = request.pay_type
				order.price = rechargeitem.price
				order.create_time = timetool.get_time()
				order.state = 2
				result = playerordermysqldao.save_player_order(request.rid, "sync_insert", order.order_id, order)						
				if result then
					filelog.sys_obj("rechargepay", "ios", "**debit success, save order sucess**", order)
				else
					filelog.sys_obj("rechargepay", "ios", "**debit success, save order failed**", order)
				end

				--记录订单的mongo流水
				dblog.dblog_write("orderinfo", order)

				delivergoodmsg.awards = rechargeitem.awards
				delivergoodmsg.rid = request.rid
				result = msgproxy.sendrpc_reqmsgto_gatesvrd(request.gatesvr_id, request.gatesvr_id, "delivergood", delivergoodmsg, order.order_id)
				if not result then
					responsemsg.issucces = false
					responsemsg.resultdes = "支付发货失败，"..data.status
					filelog.sys_obj("rechargepay", "ios", "**delivergood failed**", order)					
				else
					filelog.sys_obj("rechargepay", "ios", "**delivergood success**", order)					
				end
				break
			end
		end			
	end
end

--[[
#充值
recharge 74 {
	request {
		version 0 : VersionType
		id 1 : integer #商品id（苹果支付渠道）
		pay_type 2 : integer   #支付类型
		option_data 3 : string #附加数据
	}

	response {
	    issucces 0 : boolean	 #true 成功  false 失败
		resultdes 1 : string	 #错误原因
		order_id 2 : string      #订单号
		pay_type 3 : integer	 #支付类型
		id 4 : integer             #商品id				
	}
}
]]

local function generate_order_id()
	local now = skynet.time()*100
	if count >= 1000 then
		count = 1
	end
	local order_id = string.format("%d%03d", now, count)
	count = count + 1

	return order_id
end

local function  create_thirdprepaid_order(request, rechargeconf)
	local result=true
	local params = nil
	rechargeconf = tabletool.deepcopy(rechargeconf)
	if request.pay_type == EPayType.PAY_TYPE_WECHAT then
		request.rechargeconf = json.encode(rechargeconf)
		params = msgproxy.sendrpc_reqmsgto_httpsvrd("webclient", request)

		if params == nil then
			result = false
		else
			params = json.encode(params)
		end
	end

	return result, params
end

local function other_recharge(request, responsemsg)
	local rechargecfg = configdao.get_business_conf(request.version.client_platform, request.version.client_channel, "rechargecfg")
	if rechargecfg == nil or request.id == nil or request.pay_type == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的请求！"
		return
	end

	rechargecfg = rechargecfg.rechargecfg

	local rechargeitem = rechargecfg[request.id]
	if rechargeitem == nil or request.id ~= rechargeitem.id then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效的商品ID"
		return
	end

	request.order_id = generate_order_id()
	local result, params = create_thirdprepaid_order(request, rechargeitem)
	if not result then
		responsemsg.issucces = false
		responsemsg.resultdes = "生成预付订单失败！"
		return		
	end

	responsemsg.option_data = params

	--生成订单
	local order = {rid = request.rid}
	local awards = {}
	for i, award in pairs(rechargeitem.awards) do
		awards[i]={}
		awards[i].id = award.id
		awards[i].num = award.num
	end
	order.order_id=request.order_id
	order.pid = rechargeitem.pid
	order.good_id = rechargeitem.id
	order.good_awards =  json.encode(awards)
	order.pay_type = request.pay_type
	order.price = rechargeitem.price
	order.create_time = timetool.get_time()
	order.state = 1

	result = playerordermysqldao.save_player_order(request.rid, "sync_insert", order.order_id, order)

	dblog.dblog_write("orderinfo", order)
	if result then
		filelog.sys_obj("rechargepay", "other", "**generate order success**", order)		
		responsemsg.order_id = order.order_id	
	else
		filelog.sys_obj("rechargepay", "other", "**generate order failed**", order)
		responsemsg.issucces = false
		responsemsg.resultdes = "生成订单后保存失败！"
	end
end
function RechargesvrRequestMsg.recharge(request)
	local responsemsg = {issucces = true, pay_type=request.pay_type, id = request.id}

	if request.pay_type == EPayType.PAY_TYPE_IOS then
		ios_recharge(request, responsemsg)
		base.skynet_retpack(responsemsg)
	else
		other_recharge(request, responsemsg)
		base.skynet_retpack(responsemsg)
	end
end

--[[
orderinfo={
	pay_type=0,
	order_id = "",
	price = ,
}
]]
function RechargesvrRequestMsg.delivergood(orderinfo)
	--[[
		errcode,  0表示成功，非0表示失败
		info={},
	]]
	local reshttpsvrdmsg = {errcode = 0, info={}}
	if orderinfo == nil or orderinfo.order_id == nil or orderinfo.pay_type == nil then
		filelog.sys_error("RechargesvrRequestMsg.delivergood invalid orderinfo", orderinfo)
		reshttpsvrdmsg.errcode = -1
		base.skynet_retpack(reshttpsvrdmsg)
		return
	end

	local order = playerdatadao.query_player_order(nil, orderinfo.order_id)
	if order == nil then
		filelog.sys_error("RechargesvrRequestMsg.delivergood invalid orderinfo.order_id", orderinfo)
		reshttpsvrdmsg.errcode = -1
		base.skynet_retpack(reshttpsvrdmsg)
		return		
	end

	if orderinfo.pay_type ~= order.pay_type then
		filelog.sys_error("RechargesvrRequestMsg.delivergood invalid orderinfo.pay_type", orderinfo, order)
		reshttpsvrdmsg.errcode = -1
		base.skynet_retpack(reshttpsvrdmsg)
		return
	end

	if orderinfo.price ~= nil and order.price ~= orderinfo.price then
		filelog.sys_error("RechargesvrRequestMsg.delivergood invalid orderinfo.price", orderinfo, order)
		reshttpsvrdmsg.errcode = -1
		base.skynet_retpack(reshttpsvrdmsg)
		return		
	end

	if order.state == 3 then
		filelog.sys_error("RechargesvrRequestMsg.delivergood order.state == 3", orderinfo, order)
		reshttpsvrdmsg.errcode = 0
		base.skynet_retpack(reshttpsvrdmsg)
		return		
	end
	local result
	order.state = 2
	result = playerordermysqldao.save_player_order(order.rid, "sync_update", order.order_id, order)
	if not result then
		filelog.sys_obj("rechargepay", "other", "**delivergood failed, save order faled, debit success**", order)		
		reshttpsvrdmsg.errcode = -1
		base.skynet_retpack(reshttpsvrdmsg)
	end

	dblog.dblog_write("orderinfo", order)

	base.skynet_retpack(reshttpsvrdmsg)

	--通知agent发货
	local delivergoodmsg = {}
	local online = playerdatadao.query_playeronline(order.rid)
	if online and online.gatesvr_id ~= "" then
		delivergoodmsg.awards = json.decode(order.good_awards)
		delivergoodmsg.rid = order.rid
		result = msgproxy.sendrpc_reqmsgto_gatesvrd(online.gatesvr_id, online.gatesvr_id, "delivergood", delivergoodmsg, order.order_id)
		if not result then
			filelog.sys_obj("rechargepay", "other", "**delivergood failed**", order)					
		else
			filelog.sys_obj("rechargepay", "other", "**delivergood success**", order)					
		end
	else
		filelog.sys_obj("rechargepay", "other", "**delivergood failed**", order)					
	end
end

function RechargesvrRequestMsg.gmcommand(cmd, ...)
	if cmd == nil then
		base.skynet_retpack(false)
		return
	end

	if cmd == "reload" then
		configdao.reload()
		base.skynet_retpack(true)
		return
	end
end


return RechargesvrRequestMsg