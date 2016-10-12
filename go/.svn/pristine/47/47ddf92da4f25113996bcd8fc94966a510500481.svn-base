local skynet = require "skynet"
local socket = require "socket"
local filelog = require "filelog"
local msghelper = require "agentmsghelper"
local configdao = require "configdao"
local tabletool = require "tabletool"
local httpd = require "http.httpd"
local httpc = require "http.httpc"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local base = require "base"
local msgproxy = require "msgproxy"
require "const.enum"

local  AgentRequestMsg = {}

function  AgentRequestMsg.process(session, source, subcmd, ...)
	local f = AgentRequestMsg[subcmd] 
	if f == nil then
		filelog.sys_error(filename.."AgentRequestMsg.process invalid subcmd:"..subcmd)
		return nil
	end
	f(...)
	msghelper.agentexit()
end

-- @brief 解析处理http支付通知
-- @param channelinfo    支付回调渠道信息
-- @param body 支付回调参数，字符串或是table
-- @return 返回携带2个值的table:错误码、订单信息
local function process_http_payreq(channelinfo, body)    
    if channelinfo == nil or body == nil then
        return -1, nil
    end

    if channelinfo.payfunc ~= nil then
        return channelinfo.payfunc(body, channelinfo)
    else
        return -1, nil
    end
end

-- @brief 生成http支付回复结果
-- @param channelinf 支付回调渠道信息
-- @param errcode    响应码 -1错误，0成功
-- @return 返回符合渠道要求的回复结果
local function generate_http_payresp(channelinfo, errcode, info)
    if channelinfo == nil or errcode == nil then
        return nil
    end
    msghelper.write_http_info("errcode:"..errcode.." info:", info)
 	
 	if type(channelinfo) ~= "table" then 		
 		return nil
 	end

    if channelinfo.payretfunc ~= nil then
        return channelinfo.payretfunc(errcode, info)
    else
        return nil
    end
end

local function response(client_fd, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(client_fd), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		msghelper.write_http_info(string.format("response error: %d, %s", id, err))
	end
end

function AgentRequestMsg.callback(client_fd)
	msghelper.write_http_info("AgentRequestMsg.callback: one connect "..client_fd)
	msghelper.check_timeout()
	socket.start(client_fd)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local status, code, url, method, header, body = base.pcall(httpd.read_request, sockethelper.readfunc(client_fd), 8192)
	local query, result, orderinfo, info
	local responsestr
	
	if not status then
		filelog.sys_error("AgentRequestMsg.callback failed", client_fd, code)
		return
	end
	
	result = -1
	msghelper.write_http_info("AgentRequestMsg.callback:", code, url, method, header, body)
	if code then
		if code ~= 200 then
			base.pcall(response, client_fd, code)
		else
			if method == "GET" then
				url, query = urllib.parse(url)
				if query then
					body = urllib.parse_query(query)
				else
					body = nil
				end
			end			
			local channelinfo = msghelper.get_channel_byurl(url)
		    if channelinfo == nil then
		    	msghelper.write_http_info("AgentRequestMsg.callback channelinfo == nil")
		    else
		    	if body == nil or tabletool.is_emptytable(body) then
		    		responsestr = generate_http_payresp(channelinfo, -1, "")
					base.pcall(response, client_fd, code, responsestr)
		    	end
		    	--[[
					orderinfo={
						pay_type=0,
						order_id = "",
						price = ,
					}
		    	]]
		    	result, orderinfo = process_http_payreq(channelinfo, body)
		    	if result == 0 then
		    		--支付回调校验成功通知发货
		    		--[[
		    			errcode,  0表示成功，非0表示失败
		    			info={},
		    		]]
		    		local rechargeresponse 
		    		rechargeresponse = msgproxy.sendrpc_reqmsgto_rechargesvrd("delivergood", orderinfo)
		    		
		    		if rechargeresponse==nil then
		    			result = -1
		    		elseif rechargeresponse.errcode == nil or rechargeresponse.errcode ~= 0 then
		    			result = -1
		    			info = rechargeresponse.info
		    		else
						result = 0
						info = rechargeresponse.info		    			
		    		end
		    		msghelper.write_http_info("AgentRequestMsg.callback rechargeresponse:", rechargeresponse)
		    	elseif result == 1000 then
		    		--TO ADD
		    	end
		    end
		    responsestr = generate_http_payresp(channelinfo, result, info)
			base.pcall(response, client_fd, code, responsestr)
		end
	else
		if url == sockethelper.socket_error then
			msghelper.write_http_info(string.format("AgentRequestMsg.callback %s socket closed", url))
		else
			msghelper.write_http_info(string.format("AgentRequestMsg.callback %s", url))
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
	}
}
]]
function AgentRequestMsg.webclient(request)
	local channelinfo = msghelper.get_channel_byid(request.pay_type)

	if channelinfo == nil then
		filelog.sys_error(filename.." AgentRequestMsg.webclient invalid pay_type", request)
		base.skynet_retpack(nil)
		return
	end

	msghelper.write_httpclient_info("info", request)

	local host
	if channelinfo.proxy_ip == nil then
		host = "127.0.0.1"
	else
		host = channelinfo.proxy_ip
	end
	if channelinfo.proxy_port ~= nil then
		host = host..":"..channelinfo.proxy_port		
	end 	

	local recvheader = {}
	local header = {
		["content-type"] = "application/x-www-form-urlencoded"
	}

	local method = (channelinfo.ispost and "POST") or "GET"
	local httpdata = channelinfo.prepayfunc(request, channelinfo)
	local status, code, body
	status, code, body = base.pcall(httpc.request, method, host, channelinfo.preurl, recvheader, header, httpdata)
	if not status then
		msghelper.write_httpclient_info("failed status == false", channelinfo.preurl, request, code)		
		base.skynet_retpack(nil)
		return
	end
	if code ~= 200 then
		msghelper.write_httpclient_info("failed code ~= 200", channelinfo.preurl, request, code, recvheader, body)
		base.skynet_retpack(nil)
		return
	end
	local result, resdata = channelinfo.prepayretfunc(body, channelinfo)	
	msghelper.write_httpclient_info("success http", code, recvheader, httpdata, body, resdata)
	
	if not result then
		msghelper.write_httpclient_info("channelinfo.prepayretfunc failed", resdata, channelinfo.preurl, request, code, recvheader, body)
		base.skynet_retpack(nil)
		return		
	end
	if request.pay_type == EPayType.PAY_TYPE_IOS then
		if resdata.status == 21007 then
			recvheader = {}
			status, code, body = base.pcall(httpc.request, method, host, channelinfo.preurltest, recvheader, header, httpdata)
			if not status then
				msghelper.write_httpclient_info("resdata.status == 21007 failed status == false", channelinfo.preurltest, request, code)		
				base.skynet_retpack(nil)
				return
			end			
			if code ~= 200 then
				msghelper.write_httpclient_info("failed  iostest code ~= 200", channelinfo.preurltest, request, code, recvheader, body)
				base.skynet_retpack(nil)
				return
			end

			if body == nil or (type(body) == "table" and tabletool.is_emptytable(body)) then
				msghelper.write_httpclient_info("failed  iostest body exception", channelinfo.preurltest, request, code, recvheader, body)
				base.skynet_retpack(nil)				
			else
				result, resdata = channelinfo.prepayretfunc(body, channelinfo)
				if not result then
					msghelper.write_httpclient_info("channelinfo.prepayretfunc failed", resdata, channelinfo.preurltest, request, code, recvheader, body)
					base.skynet_retpack(nil)
					return					
				end				
			end
		end
		msghelper.write_httpclient_info("success request.pay_type", code, recvheader, resdata)
		base.skynet_retpack(resdata)
	elseif request.pay_type == EPayType.PAY_TYPE_WECHAT then
		msghelper.write_httpclient_info("success request.pay_type", code, recvheader, resdata)
		base.skynet_retpack(resdata)
	else
		msghelper.write_httpclient_info("failed invalid request.pay_type", channelinfo.preurl, request, code, recvheader, body)
		base.skynet_retpack(nil)		
	end
end

function AgentRequestMsg.versioninfo()
	local recvheader = {}
	local header = {
		["content-type"] = "application/x-www-form-urlencoded"
	}

	local method = "GET"
	local status, code, body
	status, code, body = base.pcall(httpc.request, method, "texasversvrlist.juzhongjoy.com:4321", "/gsverlimit.php", recvheader, header)
	if not status then
		msghelper.write_httpclient_info("get versioninfo failed status == false", code)		
		base.skynet_retpack(nil)
		return
	end
	if code ~= 200 then
		msghelper.write_httpclient_info("get versioninfo failed code ~= 200", code, recvheader, body)
		base.skynet_retpack(nil)
		return
	end
	base.skynet_retpack(body)
	--msghelper.write_httpclient_info("success http", code, recvheader, body)	
end

function AgentRequestMsg.generate_params(request, rechargeconf)
	local channelinfo = msghelper.get_channel_byid(request.pay_type)

	if channelinfo == nil then
		filelog.sys_error(filename.." AgentRequestMsg.generate_params invalid pay_type", request, rechargeconf)
		base.skynet_retpack(nil)
		return
	end

	local f = channelinfo.paramsfunc
	local params = f(request, rechargeconf, channelinfo)
	filelog.sys_info("AgentRequestMsg.generate_params", params)
	base.skynet_retpack(params)
end

return AgentRequestMsg
