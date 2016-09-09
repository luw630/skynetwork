local TableObj = {
	id = 0,
	seats = nil, --座位信息
	waits = nil, --旁观队列 
	state = 0,
	sitdown_player_num = 0, --坐下的玩家数
	conf = nil,
	gamelogic = nil,
	svr_id = "",
	timer_id = -1,
} 


function TableObj:new(obj)
 	obj = obj or {}
 	obj.id = 0
	obj.seats = {} --座位信息
	obj.waits = {} --旁观队列 
	obj.state = 0
	obj.sitdown_player_num = 0 --坐下的玩家数
	obj.conf = nil
	obj.gamelogic = nil
	obj.svr_id = ""
	obj.timer_id = -1,
 	setmetatable(obj, self)
 	self.__index = self
 	return obj
end
local function tableobj_to_sring ( ... )
	return ("id:"..TableObj.conf.id.." state:"..TableObj.state.." sitdownnum:"..TableObj.sitdown_player_num)
end

TableObj.__tostring = tableobj_to_sring

return TableObj 