EErrCode = {
	ERR_SUCCESS            = 1,   --重复报名
	ERR_ACCESSDATA_FAILED  = 2,   --访问数据失败
	ERR_INVALID_REQUEST    = 3,   --无效的请求
	ERR_VERIFYTOKEN_FAILED = 4,   --验证token失败
	ERR_NOGATESVR = 5, --当前无可用的服务器
	ERR_INVALID_PARAMS = 6, --无效的参数
	ERR_NET_EXCEPTION = 7,  --错误的网络异常
	ERR_SYSTEM_ERROR = 8,   --系统错误
	ERR_SERVER_EXPIRED = 9, --服务器过期
	ERR_DEADING_LASTREQ = 10, --正在处理上一次请求
}

--agent的状态
EGateAgentState = {
	GATE_AGENTSTATE_UNKNOW = 0,    --初始状态
	GATE_AGENTSTATE_LOGINING = 1,  --正在登陆
	GATE_AGENTSTATE_LOGINED = 2,   --登陆成功
	GATE_AGENTSTATE_LOGOUTING = 3, --正在登出
	GATE_AGENTSTATE_LOGOUTED = 4,  --退出成功
}

--桌子的状态
ETableState = {
	TABLE_STATE_WAIT_MIN_PLAYER = 0, --等待最小玩家数
	TABLE_STATE_WAIT_START_GAME = 1, --等待桌主开始游戏
}

--座位状态
ESeatState = {
	SEAT_STATE_NO_PLAYER = 0,  --没有玩家
	SEAT_STATE_WAIT_START = 1, --等待开局
	SEAT_STATE_PLAYING  = 2,   --正在游戏中
}

--房间类型
ERoomType = {
	ROOM_TYPE_UNKNOW = 0,
	ROOM_TYPE_FRIEND_QUICK = 1,
	ROOM_TYPE_FRIEND_SLOW = 2,
	ROOM_TYPE_FRIEND_FREE = 3,
}

--游戏类型
EGameType = {
	GAME_TYPE_UNKNOW = 0,
	GAME_TYPE_COMMON = 1, --普通游戏
}

--发行平台
EPublishPlatform = {
	PUBLISH_PLATFORM_JUZONG = 1, --聚众
	PUBLISH_PLATFORM_COMMON = 100, --通用平台
}
--发行渠道
EPublishChannel = {
	PUBLISH_CHANNEL_JUZONG_IOS = 1, --聚众ios官方渠道
	PUBLISH_CHANNEL_JUZONG_ANDROID = 2, --聚众android官方渠道
	PUBLISH_CHANNEL_COMMON = 1000,  --通用渠道
}

