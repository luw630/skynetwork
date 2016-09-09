local RoomGameLogic = {}

function RoomGameLogic.init(gameobj, tableobj)
	gameobj.tableobj = tableobj
	return true
end

return RoomGameLogic