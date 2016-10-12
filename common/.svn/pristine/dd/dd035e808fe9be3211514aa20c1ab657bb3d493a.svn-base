local timetool = require "timetool"
local ProcessState = {}

function ProcessState:new(obj)
	obj = obj or {}
	setmetatable(obj, self)
    self.__index = self
    obj.is_process = false
    obj.process_time = 0
    return obj
end

function ProcessState:is_processing()
	local nowtime = timetool.get_time()
	if self.timeout == nil then
		self.timeout = 20
	end

	if nowtime >= self.process_time + self.timeout then
		self.is_process = false
	end

	return self.is_process
end

function ProcessState:set_process_state(is_process)
	if is_process then
		self.process_time = timetool.get_time()
	end
	self.is_process = is_process
end

return ProcessState






