local skynet = require "skynet"
local filelog = require "filelog"
local configdao = require "configdao"
local base = require "base"
require "skynet.manager"
local filename = "marqueemsg"
local msgarry = {}
local msgsize = 0
local count = 0
local Marqueemsg = {}

local function generate_id()
	local now = skynet.time()*100
	if count < 1000 then
		count = count + 1
	else
		count = 0
	end

	return (skynet.getenv("svr_id")..tostring(now)..count)
end

--[[
	msg = {
		id="",
		content="",		
	}
]]
function Marqueemsg.add(msg)
	msg.id = generate_id()
	msgsize = msgsize + 1
	local index = 0
	index = msgsize % configdao.get_common_conf("marquee_size")
	if index == 0 then
		index = configdao.get_common_conf("marquee_size")
	end
	msgarry[index] = msg
end

function Marqueemsg.queryindex(...)
 	return msgsize+1
end 

function Marqueemsg.querymsg(index)
	local noticemsg = {msglist={}}
	if index > msgsize then
		return index, noticemsg
	else
		local tmp_index = 0
		local count = 0
		for i = index, msgsize do
			tmp_index = i % configdao.get_common_conf("marquee_size")
			if tmp_index == 0 then
				tmp_index = configdao.get_common_conf("marquee_size")
			end
			table.insert(noticemsg.msglist, msgarry[tmp_index])
			count = count + 1
			index = i
			if count >= configdao.get_common_conf("marqueenum") then
				break
			end
		end
		return (index+1), noticemsg
	end 
end

skynet.dispatch("lua", function(_, address,  cmd, isresponse, ...)
	    local f = Marqueemsg[cmd]
		if f ~= nil then
			if isresponse then
				base.skynet_retpack(f(...))
			else
            	f(...)
			end
        else
            filelog.sys_error(filename.." [BASIC_MARQUEE] skynet.dispatch invalid func "..cmd)
        end
end)

skynet.start(function()
    skynet.register ".marqueemsg"
end)




