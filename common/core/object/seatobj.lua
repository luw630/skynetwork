local SeatObj = {
	index = 0,
	rid = 0,
	state = 0,  --改坐位玩家状态
	gatesvr_id="",
	agent_address = -1,
	playerinfo = nil, --[[{
		rolename="",
		logo="",
		sex=0,
	}]]
	is_tuoguan = 0, --是否托管
	is_robot = false,  --是否机器人
	is_delete = false, --是否删除桌子
}

function SeatObj:new(obj)
	obj = obj or {}

	obj.index = 0
	obj.rid = 0
	obj.state = 0  --改坐位玩家状态
	obj.gatesvr_id=""
	obj.agent_address = -1
	obj.playerinfo = {
		rolename="",
		logo="",
		sex=0,
	}
	obj.is_tuoguan = 0
	obj.is_robot = false
	obj.is_delete = false
 	setmetatable(obj, self)
 	self.__index = self
 	return obj
end

local function seatobj_to_sring ( ... )
	return ("index:"..SeatObj.index.." state:"..SeatObj.state.." gatesvr_id:"..SeatObj.gatesvr_id.." address:"..SeatObj.agent_address.." rid:"..SeatObj.rid)
end

SeatObj.__tostring = seatobj_to_sring

return SeatObj