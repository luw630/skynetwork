EErrCode = {
	ERR_SUCCESS            = 0,   --成功
	ERR_ACCESSDATA_FAILED  = 2,   --访问数据失败
	ERR_INVALID_REQUEST    = 3,   --无效的请求
	ERR_VERIFYTOKEN_FAILED = 4,   --验证token失败
	ERR_NOGATESVR = 5, --当前无可用的服务器
	ERR_INVALID_PARAMS = 6, --无效的参数
	ERR_NET_EXCEPTION = 7,  --错误的网络异常
	ERR_SYSTEM_ERROR = 8,   --系统错误
	ERR_SERVER_EXPIRED = 9, --服务器过期
	ERR_DEADING_LASTREQ = 10, --正在处理上一次请求
	ERR_CREATE_TABLE_FAILED = 11, --创建朋友桌失败
	ERR_HAD_IN_TABLE = 12, --已经在桌在内
	ERR_HAD_IN_SEAT = 13, --已经在座位上
	ERR_TABLE_FULL = 14, --桌子已经满了
	ERR_NO_EMPTY_SEAT = 15, --桌子已经没有空座位
	ERR_HAD_STANDUP = 16, --已经站起来了
	ERR_NOT_INTABLE = 17, --玩家不在座位上
	ERR_CANNOT_MOVE = 18, --此位置不能落子
}

--agent的状态
EGateAgentState = {
	GATE_AGENTSTATE_UNKNOW = 0,    --初始状态
	GATE_AGENTSTATE_LOGINING = 1,  --正在登陆
	GATE_AGENTSTATE_LOGINED = 2,   --登陆成功
	GATE_AGENTSTATE_LOGOUTING = 3, --正在登出
	GATE_AGENTSTATE_LOGOUTED = 4,  --退出成功
}
--bool的枚举值定义
EBOOL = {
	FALSE = 0,
	TRUE = 1,
} 
--桌子的状态
ETableState = {
	TABLE_STATE_UNKNOW = 0,
	TABLE_STATE_WAIT_MIN_PLAYER = 1,        --等待最小玩家数
	TABLE_STATE_WAIT_GAME_START = 2,        --等待桌主开始游戏
	TABLE_STATE_WAIT_CLIENT_ACTION = 3,     --等待client操作
	TABLE_STATE_WAIT_ONE_GAME_REAL_END = 4, --等待一局游戏真正结束
	TABLE_STATE_WAIT_GAME_END = 5,     --等待游戏结束
	TABLE_STATE_GAME_START = 6,        --游戏开始状态
	TABLE_STATE_ONE_GAME_START = 7,    --一局游戏开始
	TABLE_STATE_CONTINUE = 8,
	TABLE_STATE_CONTINUE_AND_STANDUP = 9,
	TABLE_STATE_CONTINUE_AND_LEAVE = 10,
	TABLE_STATE_ONE_GAME_END = 11,      --一局游戏结束
	TABLE_STATE_ONE_GAME_REAL_END = 12, --一局游戏真正结束 
	TABLE_STATE_GAME_END = 13,  	   --游戏结束
}

--座位状态
ESeatState = {
	SEAT_STATE_UNKNOW = 0,
	SEAT_STATE_NO_PLAYER = 1,  --没有玩家
	SEAT_STATE_WAIT_START = 2, --等待开局
	SEAT_STATE_PLAYING  = 3,   --正在游戏中
}

--玩家操作类型
EActionType = {
	ACTION_TYPE_UNKNOW = 0,
	ACTION_TYPE_STANDUP = 1,
	ACTION_TYPE_LAOZI = 2,
	ACTION_TYPE_TIMEOUT = 3,
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

--玩家站起原因
EStandupReason = {
	STANDUP_REASON_UNKNOW = 0,
	STANDUP_REASON_ONSTANDUP = 1, --玩家主动站起
}

--棋子类型
EPAWNTYPE = {
	PAWN_TYPE_UNKNOW = 0,
	PAWN_TYPE_BLACK = 1,
	PAWN_TYPE_WHITE = 2,
}

