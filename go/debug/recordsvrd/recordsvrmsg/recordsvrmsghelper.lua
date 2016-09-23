local skynet = require "skynet"
local configdao = require "configdao"
local json = require "cjson"
local filelog = require "filelog"
local httpd = require "http.httpd"
local httpc = require "http.httpc"
local base = require "base"

json.encode_sparse_array(true,1,1)

local filename = "recordsvrmsghelper.lua"

local service
local RecordsvrmsgHelper = {}

local mqsvr_id = "recordmq_1"

function RecordsvrmsgHelper.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

function RecordsvrmsgHelper.get_serverid()
	return service.get_serverid()
end

function RecordsvrmsgHelper.get_conf()
	return service.get_conf()
end

function RecordsvrmsgHelper.set_conf(conf)
	service.set_conf(conf)
end

function RecordsvrmsgHelper.bpop()
	local result, msg = skynet.call(mqsvr_id, "lua", "brpop", true, "record", 300)
	if msg ~= nil and #msg >= 2 then
		return json.decode(msg[2])
	end	
	return nil
end

local function escape(s)
	return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

function RecordsvrmsgHelper.upload_qiniu(name, data)
	--local url_format = "/record.cgi?data=%s&name=%s&bucket=%s&accesskey=%s&secretkey=%s"
	local host = configdao.get_common_conf("proxy_ip")..":"..configdao.get_common_conf("proxy_port")	
	local recvheader = {}
	local header = {
		["content-type"] = "application/x-www-form-urlencoded"
	}
	local url = "/record.cgi"
	local form = {
		data = data,
		name = name,
		bucket = configdao.get_common_conf("bucket"),
		accesskey = configdao.get_common_conf("accesskey"),
		secretkey = configdao.get_common_conf("secretkey"),
		logpath = "no"
	}

	--[[local url = string.format(url_format,
								escape(data), name,
								configdao.get_common_conf("bucket"),
								configdao.get_common_conf("accesskey"),
								configdao.get_common_conf("secretkey"))]]
	local method = "GET"
	local status, code, body
	--status, code, body = base.pcall(httpc.request, method, host, url, recvheader, header)	
	status, code, body = base.pcall(httpc.post, host, url, form, recvheader)
	if not status then
		return false
	end
	if code ~= 200 then
		return false
	end

	if body == "success" then
		return true
	end

	return false
end

--[[function RecordsvrmsgHelper.upload_qiniu(name, data)
	local recordsvrs = configdao.get_svrs("recordsvrs")
	local recordsvr = recordsvrs[skynet.getenv("svr_id")]
	local success = false

	local command = string.format("%q %q -a %q -s %q -b %q -n %q", 
		recordsvr.python_path, recordsvr.upload_script, 
		recordsvr.access_key, recordsvr.secret_key, recordsvr.bucket, name)

	local handle = io.popen(command, "w")
	if handle then
		handle:write(data)
		handle:write("\n")
		local _, _, exitcode = handle:close()
		if exitcode==0 then
			success = true
		end
	end

	return success
end]]

function RecordsvrmsgHelper.upload(msg)

	local name = msg.record_id
	local data = json.encode(msg.record)
	-- 尝试3次上传
	for i=1,3 do
		if RecordsvrmsgHelper.upload_qiniu(name, data) then
			break
		end
	end

end

function RecordsvrmsgHelper.readmq()
	while true do
		local msgitem = RecordsvrmsgHelper.bpop()
		if msgitem ~= nil then
			skynet.fork(function()
				RecordsvrmsgHelper.upload(msgitem)
			end)
		end
	end
end

return	RecordsvrmsgHelper  