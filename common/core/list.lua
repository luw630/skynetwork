--[[
	双端链表  
	pushleft poprigth  一起使用
	pushright popleft  一起使用
]]

local List={
	first=0,
	last = -1,
	size = 0,
}

function List:new(obj)
	obj = obj or {}
	setmetatable(obj, self)
	self.__index = self

	return obj
end

function List:push_left(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
	self.size = self.size + 1
end

function List:push_right(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
	self.size = self.size + 1
end

function List:pop_left()
	local first = self.first
	if first > self.last then
		return nil
	end
	local value = self[first]
	self[first] = nil
	self.first = first + 1
	self.size = self.size - 1
	return value
end

function List:pop_right()
	local last = self.last
	if self.first > last then
		return nil
	end
	local value = self[last]
	self[last] = nil
	self.last = last - 1
	self.size = self.size - 1
	return value
end

function List:get_size()
	return self.size
end

return List
