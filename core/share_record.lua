local json = require "cjson"
local timetool = require "timetool"
local skynet = require "skynet"
local filelog = require "filelog"

json.encode_sparse_array(true,1,1)

local mqsvr_id = "recordmq_1"

local function share_record(table_id, svr_id, service_id, obj)
	obj = obj or {}
	obj.record_id = timetool.get_time() .. table_id .. svr_id .. service_id
	obj.record = {}

	local function clone(t)
		local target = {}
		for k, v in pairs(t) do
			if type(v) == "table" then
				target[k] = clone(v)
			else
				target[k] = v
			end
		end
		return target
	end

	function obj.insert(cmd, msg, is_notsave)
		--暂时关闭牌局分享记录
		--if cmd=="gamestart" then
			--开始，自动清除数据
			--obj.reset()
		--end

		local record_ = {
			time = timetool.get_time(),
			cmd = cmd,
			msg = clone(msg),
		}
		table.insert(obj.record, record_)

		if cmd=="gameresult" and not is_notsave then
			--结束，开始上传，发送到MQ
			filelog.sys_info("save one record")			
			local record_str = obj.serialize()
			--发送到MQ
			skynet.send(mqsvr_id, "lua", "lpush", false, "record", record_str)
		end
	end

	function obj.getid()
		return obj.record_id
	end

	function obj.serialize()
		return json.encode({record_id=obj.record_id, record=obj.record})
	end

	function obj.reset()
		obj.record = {}
		obj.record_id = timetool.get_time() .. table_id .. svr_id .. service_id
	end

	function obj.query_status(record_id)
		--查询是否上传成功
		local result, status = pcall(skynet.call, mqsvr_id, "lua", "get", "record:"..obj.record_id)
		if result and status=="1" then
			return true
		end
		return false
	end

	return obj
end

local function new(...)
	return share_record(...)
end

return {new=new}

