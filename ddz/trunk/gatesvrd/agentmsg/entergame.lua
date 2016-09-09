local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "agenthelper"
local configdao = require "configdao"
local tabletool = require "tabletool"
local timetool = require "timetool"
local gamelog = require "gamelog"
local table = table
require "enum"

local  EnterGame = {}

--[[
#玩家的基础信息
.PlayerBaseinfo {
	 rid 0 : integer
	 rolename 1 : string
	 country 2 : string
	 province 3 : string
	 logo 4 : string
	 sex 5 : integer
}

#登录游戏请求
entergame 3 {
	request {
		version 0 : VersionType
		device_info 1 : string  #设备信息
		uid 2 : string
		rid 3 : integer
		expiretime 4 : integer
		logintoken 5 : string 
	}
	response {
	    errcode 0 : integer	   		#错误原因 0表示成功
		errcodedes 1 : string  		#错误描述
		isreauth 2 : boolean     	#是否需要重新认证， 断线重连时根据token是否过期告诉client是否需要重新登录认证
		servertime 4 : integer  	#同步服务器时间
		baseinfo 3 : PlayerBaseinfo
		#下面数据用于判断玩家是否需要牌桌断线重连
	}	
}
]]

function  EnterGame.process(session, source, fd, request)
	local responsemsg = {
		errcode = EErrCode.ERR_SUCCESS,
	}
	local server = msghelper:get_server()



	msghelper:send_resmsgto_client(fd, "EnterGame", responsemsg)
end

return EnterGame

