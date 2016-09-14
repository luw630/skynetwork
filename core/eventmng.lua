local skynet = require "skynet"
local filelog = require "filelog"
local base = require "base"
local eventpool = {}
local EventMng = {}
local service

local filename = "eventmng.lua"

local function add_event(name, event)
	eventpool[name] = require(event)
end

--type : client  lua等
function EventMng.process(session, source, type, msgname,  ...)
	if msgname == nil then
		filelog.sys_error(filename.." [BASIC_EVENTMNG] invalid msgname")
		return
	end
	
	filelog.sys_protomsg(skynet.self().."__"..type.."_"..msgname.."_request", ...)
	
	local f = eventpool[msgname]
	if f == nil then
		filelog.sys_error(filename.." [BASIC_EVENTMNG] invalid msgname:"..msgname)		
		return
	end
			
	local result, errorinfo = base.pcall(f.process, session, source, ...)
	if not result then
		filelog.sys_error(filename.." [BASIC_EVENTMNG] pcall failed", errorinfo, ...)
	end
end

function  EventMng.add_event(event)
	add_event(event, event)	
end

function  EventMng.add_eventbyname(name, event)
	add_event(name, event)	
end

function EventMng.reload()
	-- TO ADD
	-- 添加热更新机制
end


function EventMng.init(server)
	if server == nil or type(server) ~= "table" then
		skynet.exit()
	end
	service = server
end

return EventMng
