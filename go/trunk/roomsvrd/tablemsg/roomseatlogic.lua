require "enum"

local RoomSeatLogic = {}

function RoomSeatLogic.init(seatobj, index)
	seatobj.index = index
	seatobj.state = ESeatState.SEAT_STATE_NO_PLAYER
	return true
end

function RoomSeatLogic.clear(seatobj)
	seatobj.rid = 0
	seatobj.state = 0  --改坐位玩家状态
	seatobj.gatesvr_id=""
	seatobj.agent_address = -1
	seatobj.playerinfo = {}
end

return RoomSeatLogic