EErrCode = {
	ERR_SUCCESS            = 0,   --重复报名
	ERR_ACCESSDATA_FAILED  = 1,   --访问数据失败
	ERR_INVALID_REQUEST    = 2,   --无效的请求
	ERR_VERIFYTOKEN_FAILED = 3,   --验证token失败
	ERR_NOGATESVR = 4, --当前无可用的服务器
	ERR_INVALID_PARAMS = 5, --无效的参数
	ERR_NET_EXCEPTION = 6,  --错误的网络异常
}

--agent的状态
EGateAgentState = {
	GATE_AGENTSTATE_UNKNOW = 0,    --初始状态
	GATE_AGENTSTATE_LOGINING = 1,  --正在登陆
	GATE_AGENTSTATE_LOGINED = 2,   --登陆成功
	GATE_AGENTSTATE_LOGOUTING = 3, --正在登出
}

