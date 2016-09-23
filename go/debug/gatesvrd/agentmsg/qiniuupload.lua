local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local configdao = require "configdao"
local crypt = require "crypt"
local table = table
require "enum"

local  QiniuUpload = {}

--[[
//请求七牛上传token
message QiniuUploadReq {
	optional Version version = 1;
	optional string uploadlogo = 2;	
}

//响应七牛上传token
message QiniuUploadRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
	optional string uploadtoken = 3;	
}

]]

function QiniuUpload.generate_qiniutoken(request)
	if request.uploadlogo == nil or request.uploadlogo == "" then
		return nil
	end
	local accesskey = configdao.get_common_conf("qiniu_access_key")
	local secretkey = configdao.get_common_conf("qiniu_secret_key")

	local sign = crypt.hmac_sha1(secretkey, request.uploadlogo)
	local encode_sign = crypt.base64encode(sign)

	local uploadtoken = accesskey..":"..encode_sign..":"..request.uploadlogo
	return uploadtoken
end

function  QiniuUpload.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}



	if request == nil 
		or request.uploadlogo == nil then
		responsemsg.errcode = EErrCode.ERR_INVALID_REQUEST
		responsemsg.errcodedes = "无效的请求!"
		msghelper:send_resmsgto_client(fd, "QiniuUploadRes", responsemsg)		
		return		
	end

	responsemsg.uploadtoken = QiniuUpload.generate_qiniutoken(request)

	msghelper:send_resmsgto_client(fd, "QiniuUploadRes", responsemsg)
end

return QiniuUpload

