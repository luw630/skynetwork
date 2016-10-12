local filelog = require "filelog"
local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next

local index = {}
local mt_defaultvalue = {__index = function (t)
	return t.__
end}

local mt_monitor = {
	__index = function (t, k)
		filelog.sys_obj("tabletool", "monitor", "*access to element "..tostring(k))
		return t[index][k]
	end,

	__newindex = function (t, k, v)
		filelog.sys_obj("tabletool", "monitor", "*update to element "..tostring(k).." to "..tostring(v))
		t[index][k] = v
	end
}


local TableTool = {}

--设置默认值表
function TableTool.set_default(t, defaultvalue)
	t__ = defaultvalue
	setmetatable(t, mt_defaultvalue)
end

--监控表的访问情况
function TableTool.track(t)
	local proxy = {}
	proxy[index] = t
	setmetatable(proxy, mt_monitor)
	return proxy
end

--创建只读表
function TableTool.create_readonlytable(t)
	local proxy = {}
	local mt = {
		__index = t,
		__newindex = function (t, k, v)
			error("attempt to update a read-only table", 2)
		end
	}

	setmetatable(proxy, mt)
	return proxy
end

--判断一张表是否为空
function TableTool.is_emptytable(t)
	if t == nil or type(t) ~= "table" then
		return false
	end
    return _G.next( t ) == nil
end

--取得hashtable的元素个数
function TableTool.getn(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end

--将table转换为string
function TableTool.tostring(table)
	local cache = {  [table] = "." }
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
			else
				tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return tconcat(temp,"\n"..space)
	end
	return _dump(table, "","")
end

--深度copy table object
function TableTool.deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end  -- if
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end  -- for
        return new_table
        --return setmetatable(new_table, _copy( getmetatable(object) ))
    end  -- function _copy
    return _copy(object)
end  -- function deepcopy

--打印table
function TableTool.print_r(root)
	local cache = {  [root] = "." }
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
			else
				tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return tconcat(temp,"\n"..space)
	end
	print(_dump(root, "",""))
end

return TableTool



