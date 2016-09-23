local sprotoparser = require "sprotoparser"

local msgproto = sprotoparser.parse  [[
.package {
	type 0 : integer
	session 1 : integer # 0表示请求 1表示响应 3表示通知
}

#版本信息
.VersionType {
	platform 0 : integer #client 平台id(属于哪家公司发行)
	channel 1 : integer	 #client 渠道id(发行公司的发行渠道)
	version 2 : string	 #client 版本号
	authtype 3: integer  #client 账号类型
	regfrom 4 : integer  #描述从哪里注册过来的
}

#gate服务的ip和端口项
.GateSvrItem {
	ip 0 : string
	port 1 : integer
}

#奖励项
.AwardItem {
	id 0 : integer	#物品id  id = 1表示筹码
	num 1 : integer #物品个数
}

heartbeat 1 {
	request {
		rid 0: string 
	}

	response {
		issucces 0: boolean
		system_time 1 : integer
	}
}

######################logsvrd######################
loginsvrlogin 2 {
	request {
		version 0 : VersionType
		deviceinfo 1 : string  #设备信息
		uid 2 : string
		uidtype 3 : string		#登录账号类型 如: 游客: guest 手机: phone 微信: weixin等
		thirdtoken 4 : string 
		username 5 : string	
	}

	response {
	    errcode 0 : integer	   #错误原因 0表示成功
		errcodedes 1 : string  #错误描述
		uid 2 : string
		rid 3 : integer
		logintoken 4 : string     #登录服务器返回的登录token
		expiretime 5 : integer     #过期时间（绝对时间）单位s
		gatesvrs 6 : *GateSvrItem  #gate服务器地址列表 
	}
}
######################gatesvrd######################
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

return msgproto
