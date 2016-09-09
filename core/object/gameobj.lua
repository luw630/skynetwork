local GameObj = {
	tableobj = nil,
}

function GameObj:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

return GameObj