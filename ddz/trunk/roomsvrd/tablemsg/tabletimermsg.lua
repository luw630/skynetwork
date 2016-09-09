local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablemsghelper"
local filename = "tabletimermsg.lua"
local commonconst = require "common_const"
local timetool = require "timetool"
local configdao = require "configdao"
local playerdatadao = require "playerdatadao"
local json = require "cjson"
local timer = require "timer"
require "const.enum"

json.encode_sparse_array(true,1,1)

local TableTimerMsg = {}

function TableTimerMsg.process(session, source, event, ...)
	local f = TableTimerMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." TableTimerMsg.process invalid event:"..event)
		return nil
	end
	f(...)	 
end

function TableTimerMsg.gameroundstart(timerid, request)
	local table_data = msghelper.get_tabledata()

    if msghelper.get_tablestate() ~= commonconst.TABLE_STATE_WAIT_ROUND_START then
     	return
    end

    if table_data.timer_id ~= timerid then
    	return
    end
    table_data.timer_id = -1
    msghelper.set_tablestate(commonconst.TABLE_STATE_ROUND_START)
    msghelper.gamerun()
end

function TableTimerMsg.gameonerealend(timerid, request)
	local table_data = msghelper.get_tabledata()

    if msghelper.get_tablestate() ~= commonconst.TABLE_STATE_WAIT_GAME_END then
     	return
    end

    if table_data.timer_id ~= timerid then
    	return
    end
    table_data.timer_id = -1
    msghelper.set_tablestate(commonconst.TABLE_STATE_GAME_ONE_REAL_END)
    msghelper.gamerun()
end

function TableTimerMsg.doaction(timerid, request)
	local table_data = msghelper.get_tabledata()

    msghelper.write_tableinfo_log("Timeout Doaction.process", skynet.time(), table_data)

    if msghelper.get_tablestate() ~= commonconst.TABLE_STATE_WAIT_CLIENT_ACTION then
        filelog.sys_error("TableTimerMsg.doaction msghelper.get_tablestate() ~= commonconst.TABLE_STATE_WAIT_CLIENT_ACTION")
     	return
    end

    if table_data.timer_id ~= timerid then
        filelog.sys_error("TableTimerMsg.doaction table_data.timer_id ~= timerid")
    	return
    end

    -- 设置定时器
    table_data.timer_id = -1

    -- 超时
    msghelper.game_timeout()

    -- 让或弃处理
    msghelper.gamedefaultaction()

    msghelper.game_continuous_timeout(request.seat_index)    
end

function TableTimerMsg.updateblind(timerid, request)
    local game = msghelper.get_game()
	game.onupdateblind(timerid)
end

function TableTimerMsg.syncsngtablestate(timerid, request)
    local game = msghelper.get_game()
    if game then
        game.onsync_sngtablestate(timerid)
    end
end

function TableTimerMsg.deletetable(timerid, request)
    local table_data = msghelper.get_tabledata()
    if table_data.deletetable_timer_id == timerid then
        table_data.deletetable_timer_id = -1
        msghelper.event_process("cmd", "delete")
    end 
end

function TableTimerMsg.cancelmatch(timerid, request)
    local table_data = msghelper.get_tabledata()
    if table_data.cancelmatch_timer_id == timerid then
        table_data.cancelmatch_timer_id = -1

        local game = msghelper.get_game()
        game.cancelmatch()
    end 
end

function TableTimerMsg.applyenterfriendtable(timerid, rid)
    local table_data = msghelper.get_tabledata()
    local seat = msghelper.find_player_seat(rid)
    if not seat or seat.state ~= commonconst.PLAYER_STATE_WAIT_CONFIRM then
        filelog.sys_error("TableTimerMsg.applyenterfriendtable not seat or seat.state ~= commonconst.PLAYER_STATE_WAIT_CONFIRM")
        return
    end

    if seat.applyenter_timerid ~= timerid then
        filelog.sys_error("TableTimerMsg.applyenterfriendtable seat.applyenter_timerid ~= timerid")
        return
    end

    seat.applyenter_timerid = nil

    --回复玩家
    local responsemsg = {is_agree=false, table_id=table_data.table_id}
    msghelper.sendmsg_totableplayer(seat, "replyenterfriendtablenotify", responsemsg)

    --增加拒绝次数
    if not table_data.refusesitdownrecords[seat.rid] then
        table_data.refusesitdownrecords[seat.rid] = {count=0}
    end
    table_data.refusesitdownrecords[seat.rid].count = table_data.refusesitdownrecords[seat.rid].count + 1
    table_data.refusesitdownrecords[seat.rid].time = timetool.get_time()

    --超时默认桌主拒绝，强行让玩家站起来
    msghelper.standup(seat.index, "dont_notify_cancel")
end


function TableTimerMsg.friendtablerebuy(timerid, rid)
    local table_data = msghelper.get_tabledata()
    local seat = msghelper.find_player_seat(rid)
    if not seat then
        filelog.sys_error("TableTimerMsg.friendtablerebuy not seat")
        return
    end

    if seat.rebuy_timerid ~= timerid then
        filelog.sys_error("TableTimerMsg.friendtablerebuy seat.rebuy_timerid ~= timerid")
        return
    end

    seat.rebuy_timerid = nil

    if seat.rebuying then
        seat.rebuying = nil

        --回复玩家
        local responsemsg = {is_agree=false, ia_auto=false}
        msghelper.sendmsg_totableplayer(seat, "friendtablerebuyresult", responsemsg)

        --增加拒绝次数
        if not table_data.refuserebuyrecords[seat.rid] then
            table_data.refuserebuyrecords[seat.rid] = {count=0}
        end
        table_data.refuserebuyrecords[seat.rid].count = table_data.refuserebuyrecords[seat.rid].count + 1
        table_data.refuserebuyrecords[seat.rid].time = timetool.get_time()
    end
end


function TableTimerMsg.friendsngsign(timerid, rid)
    local table_data = msghelper.get_tabledata()
    local table_conf = msghelper.get_table_conf()
    local wait_player = msghelper.find_wait_player(rid)
    if not wait_player then
        filelog.sys_error("TableTimerMsg.friendsngsign not wait_player")
        return
    end

    if wait_player.signup_timerid ~= timerid then
        filelog.sys_error("TableTimerMsg.friendsngsign wait_player.signup_timerid ~= timerid")
        return
    end
    wait_player.signup_timerid = nil
    if wait_player.signuping then
        wait_player.signuping = nil
        --桌主拒绝给玩家退报名费
        local mail = configdao.get_common_conf("friendsng_signfees_mail")
        local signup_cost = {
            {id = 1, num = wait_player.deduct_signup_cost}
        }        
        mail = {
            rid = rid,
            create_time=timetool.get_time(),
            content=string.format(mail,
                table_conf.table_create_user_rolename,
                wait_player.deduct_signup_cost,
                json.encode(signup_cost)),
        }
        playerdatadao.save_player_mail(rid, mail)
        wait_player.deduct_signup_cost = nil
        --回复玩家
        local responsemsg = {
            is_agree=false,
            ia_auto=false
        }
        msghelper.sendmsg_totableplayer_rid(rid, "friendsngsignresult", responsemsg)
        --增加拒绝次数
        if not table_data.refusesignuprecords[rid] then
            table_data.refusesignuprecords[rid] = {count=0}
        end
        table_data.refusesignuprecords[rid].count = table_data.refusesignuprecords[rid].count + 1
        table_data.refusesignuprecords[rid].time = timetool.get_time()
    end
end

function TableTimerMsg.checkrobot(timerid, request)
    local table_data = msghelper.get_tabledata()
    if table_data.checkrobot_timer_id ~= timerid then
        return
    end  

    if table_data.table_id ~= request.table_id then
        return
    end
    
    table_data.checkrobot_timer_id = -1

    if msghelper.is_canapplyrobot() then
        msghelper.apply_robot(1)
    end
end

function TableTimerMsg.applyrobot(timerid, request)
    local table_data = msghelper.get_tabledata()
    if table_data.applyrobot_timer_id ~= timerid then
        return
    end  

    if table_data.table_id ~= request.table_id then
        return
    end
    
    table_data.applyrobot_timer_id = -1

    if msghelper.is_canapplyrobot() then
        msghelper.apply_robot(request.robot_num)
    end

    if table_data.checkrobot_timer_id == -1 and msghelper.get_robot_num() == 0 then
        local checkrobottimermsg = {table_id=table_data.table_id}
        table_data.checkrobot_timer_id = timer.settimer(80 * 100, "checkrobot", checkrobottimermsg)        
    end
end

function TableTimerMsg.synctablestate(timerid, request)
    local table_data = msghelper.get_tabledata()
    if table_data.synctablestate_timer_id ~= timerid then
        return
    end

    table_data.synctablestate_timer_id = -1

    msghelper.report_tablestate()
end

return TableTimerMsg