package.cpath = "../../skynet/luaclib/?.so"
package.path = "../../skynet/lualib/?.lua;../../core/?.lua;../../ddz/trunk/common/?.lua"

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local socket = require "clientwebsocket"
local sproto = require "mesproto"
local msgproto = require "msgproto"

local servers = {
	["out"] = {
		ip = "120.132.94.79",
		port = 8890,
	},
	["yfb"] = {
		ip = "",
		port = "",
	},
	["local"] = {
		ip = "127.0.0.1",
		port = 8890,
	}
}

--[[
	request {
		cmd 0 : string    #命令
		param 1 : string  #参数
		isexit 2 : boolean  
	}
]]
local requestmsg = {
	cmd = "",
	param = "",
	isexit = false,
}

local fd
local host
-------------------------------------------------------
local function recv_package()
	local r , istimeout= socket.recv(fd, 100)
	if not r then
		return nil
	end
	if r == ""  and istimeout == 0 then
		error "Server closed"
	end
	return r
end

local function send_request(args)
	local str = host:encode_requestmsg("gmcommand", args)
	socket.send(fd, str)
	print("send_request")
end

local function print_request(datas)
	print("REQUEST", datas)
end

local function print_response(_, args)
	local datas = ""
	for k,v in pairs(args) do
		datas=datas.." "..k.."="..tostring(v)
	end
	print("RESPONSE:", datas)
end

local function dispatch_package(is_end)
	while true do
		local v
		v = recv_package()
		if not v  or v == "" then
			break
		end
		print_response(host:decode_responsemsg(v))
		if is_end ~= nil and is_end then
			break
		end
	end
end

local function string_trim(s)
	return s:match "^%s*(.-)%s*$"
end

local function parse_cmd(params)
	local cmd, param
	if params == nil or params == "" then
		return cmd, param
	end	
	params = string_trim(params)
	local index = string.find(params, " ")
	if index == nil then
		cmd = params		
		return cmd, param
	end
	cmd = string.sub(params, 1, index-1)
	param = string.sub(params, index+1, -1)
	param = string_trim(param)	
    return cmd, param	
end


local function main()
	local server
	local is_cmdline = false
	local start_index = 1
	if arg[1] == nil or arg[1] == "" then
		server = servers["local"]
	elseif arg[1] ~= "out" or arg[1] ~= "yfb" or arg[1] ~= "local" then
		server = servers["local"]
	else
		server = servers[arg[1]]
	end 
	fd = assert(socket.connect(server.ip, server.port))
	host = sproto.new(msgproto):host "package"

	if arg[1] ~= nil and (arg[1] ~= "out" or arg[1] ~= "yfb" or arg[1] ~= "local") then
		is_cmdline = true
	elseif arg[1] ~= nil then
		is_cmdline = true		
		start_index = 2
	end
	if is_cmdline then
		requestmsg.cmd = arg[start_index]
		requestmsg.isexit = true
		requestmsg.param = table.concat(arg, " ", start_index + 1)
		requestmsg.param = string_trim(requestmsg.param)
		send_request(requestmsg)
		socket.usleep(50000)
		dispatch_package(true)
	else
		print("websocket client ok:")
		while true do
		    dispatch_package(false)
		    local params = socket.readstdin()
		    if params then
		        print_request(params)
		        requestmsg.cmd , requestmsg.param = parse_cmd(params)

		        if requestmsg.cmd == nil then
		        	print("invalid input")
		        elseif requestmsg.cmd == "quit" or requestmsg.cmd == "exit" then
		        	break
		        else
		            send_request(requestmsg)      
		        end
		    end
		end
	end
	socket.close(fd)	
end

main()



