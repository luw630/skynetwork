local filelog = require "filelog"
local msghelper = require "tablemsghelper"
local filename = "tablenoticemsg.lua"
local TableNoticeMsg = {}

function TableNoticeMsg.process(session, source, event, ...)
	local f = TableNoticeMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." TableNoticeMsg.process invalid event:"..event)
		return nil
	end
	f(...)
end

function TableNoticeMsg.updatebaseinfo(request)
    local seat = msghelper.get_seat_byindex(request.seat_index)
    msghelper.write_tableinfo_log("TableNoticeMsg.updatebaseinfo", request)
    --检查玩家是否已经在座位上
    if seat ~= nil and seat.rid == request.rid then
        if seat.gatesvr_id == request.sourcesvr_id and seat.agent_address == request.service_address then
            seat.playerinfo.rolename = request.rolename
            seat.playerinfo.logo = request.logo
            seat.playerinfo.sex = request.sex
            seat.outtable_chips = request.chips
        end
    end
end

function TableNoticeMsg.tablechat(request)
    msghelper.sendmsg_toalltableplayer("tablechat", request)
end

function TableNoticeMsg.leavesngtable(rid)
    local seat = msghelper.find_player_seat(rid)
    if seat ~= nil then
        seat.gatesvr_id = ""
        seat.agent_address = -1
        return
    end

    msghelper.del_wait_player(rid)
end

return TableNoticeMsg