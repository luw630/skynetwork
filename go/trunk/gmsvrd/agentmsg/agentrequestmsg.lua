local skynet = require "skynet"
local socket = require "socket"
local filelog = require "filelog"
local msghelper = require "agentmsghelper"
local gmhttpcmd = require "gmhttpcmd"
local tabletool = require "tabletool"
local auth = require "auth"
local httpd = require "http.httpd"
local httpc = require "http.httpc"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local base = require "base"
local msgproxy = require "msgproxy"
local json = require "cjson"
local timetool = require "timetool"

local filename = "agentrequestmsg.lua"

require "const.enum"

json.encode_sparse_array(true,1,1)

local  AgentRequestMsg = {}

function  AgentRequestMsg.process(session, source, event, ...)
	local f = AgentRequestMsg[event] 
	if f == nil then
		filelog.sys_error(filename.."AgentRequestMsg.process invalid event:"..event)
		return nil
	end
	f(...)
end

local function response(client_fd, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(client_fd), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		filelog.sys_error(string.format("response error: %d, %s", id, err))
	end
end

function AgentRequestMsg.do_webcommand(requestmsg)
	local f = gmhttpcmd[requestmsg.cmd]
	if f then
		local success, result = pcall(f, requestmsg)
		if not success then
			filelog.sys_error(string.format("do_webcommand execute error: %s", result))
			return {status="execute error"}
		end

		return result
	end

	filelog.sys_error(string.format("do_webcommand unsupported command: %s", requestmsg.cmd))
	return {status="unsupported command"}
end

function AgentRequestMsg.callback(client_fd)
	socket.start(client_fd)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local status, code, url, method, header, body = base.pcall(httpd.read_request, sockethelper.readfunc(client_fd), 8192)
	local responsestr, requestmsg
	
	if not status then
		filelog.sys_error("AgentRequestMsg.callback failed", client_fd, code)
		msghelper.agentexit()
		return
	end
	
	result = -1
	if code == nil then
		if url == sockethelper.socket_error then
			filelog.sys_error(string.format("AgentRequestMsg.callback %s socket closed", url))
		else
			filelog.sys_error(string.format("AgentRequestMsg.callback %s", url))
		end
		msghelper.agentexit()
		return
	end

	if code ~= 200 then
		base.pcall(response, client_fd, code)
		msghelper.agentexit()
		return
	end

	if method ~= "POST" then
		filelog.sys_error("AgentRequestMsg.callback failed, method is not post")
		responsestr = [[{"status":"invalid request method"}]]
		base.pcall(response, client_fd, code, responsestr)
		msghelper.agentexit()
		return
	end

	if body == nil or tabletool.is_emptytable(body) then
		filelog.sys_error("AgentRequestMsg.callback failed, body is empty")
		responsestr = [[{"status":"invalid request body"}]]
		base.pcall(response, client_fd, code, responsestr)
		msghelper.agentexit()
		return
	end

	-- for k,v in pairs(header) do
	-- 	print("header",k,v)
	-- end
	-- print("body",#body,body)

	--校验基本参数
	if not header.timestamp or not header.token then
		-- filelog.sys_error("AgentRequestMsg.callback failed, invalid request header", header)
		responsestr = [[{"status":"invalid request header"}]]
		base.pcall(response, client_fd, code, responsestr)
		msghelper.agentexit()
		return
	end

	--校验令牌
	local auth_token = auth.generate_gmqueryauth_md5token(header.timestamp..body)
	-- print(header.token, auth_token)
	if header.token~=auth_token then
		-- filelog.sys_error("AgentRequestMsg.callback failed, invalid token", header.token, body)
		responsestr = [[{"status":"invalid token"}]]
		base.pcall(response, client_fd, code, responsestr)
		msghelper.agentexit()
		return
	end

	--校验时间戳，相差5分钟失效
	local timestamp = tonumber(header.timestamp)
	if not timestamp or math.abs(timetool.get_time() - timestamp) > 5 * 60 then
		-- filelog.sys_error("AgentRequestMsg.callback failed, invalid timestamp", header.timestamp)
		responsestr = [[{"status":"invalid timestamp"}]]
		base.pcall(response, client_fd, code, responsestr)
		msghelper.agentexit()
		return
	end

	--解析json
	status, requestmsg = pcall(json.decode, body)
	if not status then
		-- filelog.sys_error("AgentRequestMsg.callback failed, json decode error", requestmsg)
		responsestr = [[{"status":"invalid request json"}]]
		base.pcall(response, client_fd, code, responsestr)
		msghelper.agentexit()
		return
	end

	--校验基本参数
	if not requestmsg.cmd then
		-- filelog.sys_error("AgentRequestMsg.callback failed, invalid request field", requestmsg)
		responsestr = [[{"status":"invalid request field"}]]
		base.pcall(response, client_fd, code, responsestr)
		msghelper.agentexit()
		return
	end

	--打包回json
	responsestr = json.encode( AgentRequestMsg.do_webcommand(requestmsg) )

	base.pcall(response, client_fd, code, responsestr)
	msghelper.agentexit()
end

return AgentRequestMsg
