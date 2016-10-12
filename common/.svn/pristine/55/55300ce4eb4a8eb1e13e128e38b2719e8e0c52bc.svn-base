local GameObj = {
	tableobj = nil,
	stateevent = nil,
}

function GameObj:new(obj)
    obj = obj or {}
    obj.stateevent = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

return GameObj