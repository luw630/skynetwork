local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablemsghelper"
local filename = "tablerequestmsg.lua"
local commonconst = require "common_const"
local playerdatadao = require "playerdatadao"
local timer = require "timer"
local timetool = require "timetool"
local configdao = require "configdao"
local base = require "base"
local robotmanager = require "robotmanager"
local json = require "cjson"
local msgproxy = require "msgproxy"

json.encode_sparse_array(true,1,1)

require "const.enum"

local TableRequestMsg = {}

function TableRequestMsg.process(session, source, event, ...)
	local f = TableRequestMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." TableRequestMsg.process invalid event:"..event)
		base.skynet_retpack(nil)
        return nil
	end
	f(...)
end

function TableRequestMsg.disconnect(request)
    local result = false
    local seat = msghelper.get_seat_byindex(request.seat_index)
    local table_data = msghelper.get_tabledata()

    msghelper.write_tableinfo_log("TableRequestMsg.disconnect", request)
    --检查玩家是否已经在座位上
    if seat == nil then
        --如果玩家不在坐位上就将玩家leavetable
        base.skynet_retpack(result)
        --filelog.sys_warning("TableRequestMsg.disconnect seat == nil")
        return
    else
        if request.rid ~= seat.rid or request.sourcesvr_id ~= seat.gatesvr_id then
            base.skynet_retpack(result)
            filelog.sys_warning("TableRequestMsg.disconnect invalid request.rid ~= seat.rid or request.sourcesvr_id ~= seat.gatesvr_id")
            return                  
        end

        if request.table_id ~= table_data.table_id or request.service_address ~= seat.agent_address then
            filelog.sys_warning("TableRequestMsg.disconnect invalid request.table_id ~= table_data.table_id or request.service_address ~= seat.agent_address")
            base.skynet_retpack(result)
            return
        end

        --玩家掉线处理
        result = msghelper.disconnect(seat)
    end
    
    base.skynet_retpack(result)
end

function TableRequestMsg.entertable(request)
    local responsemsg = {issucces = true, }
    msghelper.write_tableinfo_log("TableRequestMsg.entertable", request)

    local seat = msghelper.find_player_seat(request.rid)

    local tableinfo = {table_address = skynet.self(), seat_index = 0}
    local table_data = msghelper.get_tabledata()

    if request.table_address ~= tableinfo.table_address then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的桌子地址！"
        base.skynet_retpack(responsemsg, tableinfo)
    end
    
    if table_data.kicked_list[request.rid] ~= nil then
        responsemsg = {issucces = false, errcode = EErrorReason.ERROR_HAD_KICKED}
        base.skynet_retpack(responsemsg, tableinfo)    
        return
    end
    --检查玩家是否已经在座位上
    if seat == nil then
        --检查玩家是否够SNG条件
        if  table_data.signup_fee ~= nil and #table_data.signup_fee ~= 0 then
            local is_cansignup = false
            for _, value in ipairs(table_data.signup_fee) do
                if value.id == 1 then
                    if table_data.service_charge +value.num < request.playerinfo.chips then
                        is_cansignup = true
                        break
                    end
                else
                    --TO ADD                     
                end
            end
            if not is_cansignup then
                responsemsg.issucces = false
                responsemsg.resultdes = "不够SNG参加条件！"
                base.skynet_retpack(responsemsg, tableinfo)    
                return                                          
            end
        end
        if table_data.isdelete then
            responsemsg.issucces = false
            responsemsg.resultdes = "该局已经结束！"
            base.skynet_retpack(responsemsg, tableinfo)    
            return
        end

        --将玩家加入到旁观队列中
        local wait_player = msghelper.find_wait_player(request.rid)
        if wait_player == nil then
            wait_player = {
                rid = request.rid,
                gatesvr_id = request.sourcesvr_id,
                agent_address = request.service_address,
                rolename = request.playerinfo.rolename,
                logo = request.playerinfo.logo,
                sex = request.playerinfo.sex,
                is_robot = robotmanager.is_robot(request.rid),
            }
            local result = msghelper.add_wait_player(request.rid, wait_player)
            if not result then
                responsemsg.issucces = false
                responsemsg.resultdes = "旁观队列已满！"
                base.skynet_retpack(responsemsg, tableinfo)    
                return   
            end
        else
            wait_player.gatesvr_id = request.sourcesvr_id 
            wait_player.agent_address = request.service_address
            wait_player.is_robot = robotmanager.is_robot(request.rid)
            wait_player.rolename = request.playerinfo.rolename
            wait_player.logo = request.playerinfo.logo
            wait_player.sex = request.playerinfo.sex

        end
    else
        seat.gatesvr_id = request.sourcesvr_id
        seat.agent_address = request.service_address
        tableinfo.seat_index = seat.index
    end

    --先返回进入成功
    responsemsg.gameinfo = {}
    msghelper.copy_tablegameinfo(responsemsg.gameinfo)
    if table_data.fixedchipsplayers[request.rid] == nil or table_data.fixedchipsplayers[request.rid] <= 0 then
        responsemsg.isfixedchips = false
    else
        responsemsg.isfixedchips = true
    end
    base.skynet_retpack(responsemsg, tableinfo)    

    msghelper.entertable(request.rid, request.playerinfo.rolename)

    --当有玩家进入时同步桌子的状态
    if table_data.synctablestate_timer_id == -1 then
        table_data.synctablestate_timer_id=timer.settimer(100, "synctablestate")
        if table_data.synctablestate_timer_id <= 0 then
            table_data.synctablestate_timer_id = -1
        end
    end
end

function TableRequestMsg.reentertable(request)
    local responsemsg = {issucces = true,}

    local seat = msghelper.find_player_seat(request.rid)
    local wait_player = msghelper.find_wait_player(request.rid)
    local table_data = msghelper.get_tabledata()
    local tableinfo = {
        table_address = skynet.self(),
        lock_chips = 0,
        seat_index = 0,
        is_delonline = false,
    }
    msghelper.write_tableinfo_log("TableRequestMsg.reentertable", request)
    
    if request.table_address ~= tableinfo.table_address then
        responsemsg.issucces = false
        responsemsg.resultdes = "进入的玩家无效！"
        base.skynet_retpack(responsemsg, tableinfo)    
        return
    end

    if seat == nil and wait_player == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "玩家已经不再桌子内了！"
        tableinfo.is_delonline = true
        base.skynet_retpack(responsemsg, tableinfo)    
        return      
    end

    --检查玩家是否已经在座位上
    if seat == nil then
        --将玩家从旁观队列中删除
        msghelper.del_wait_player(request.rid)
        responsemsg.issucces = false
        responsemsg.resultdes = "玩家已经不再桌子内了！"
        tableinfo.is_delonline = true
        base.skynet_retpack(responsemsg, tableinfo)    
        return
    else
        seat.gatesvr_id = request.sourcesvr_id
        seat.agent_address = request.service_address
        seat.is_recoverrobot = nil
        tableinfo.seat_index = seat.index
        tableinfo.lock_chips = seat.chips
    end

    --先返回进入成功
    if table_data.fixedchipsplayers[request.rid] == nil or table_data.fixedchipsplayers[request.rid] <= 0 then
        responsemsg.isfixedchips = false
    else
        responsemsg.isfixedchips = true
    end
    
    responsemsg.gameinfo = {}
    msghelper.copy_tablegameinfo(responsemsg.gameinfo)

    base.skynet_retpack(responsemsg, tableinfo)    
    
    msghelper.reentertable(request.rid, tableinfo.seat_index)
end

function TableRequestMsg.leavetable(request)
    local responsemsg = {issucces = true,}
    local seat = msghelper.find_player_seat(request.rid)
    local table_data = msghelper.get_tabledata()
    msghelper.write_tableinfo_log("TableRequestMsg.leavetable", request)
    --检查玩家是否已经在座位上

    if table_data.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE then
        if table_data.signup_list[request.rid] ~= nil 
            and table_data.table_state ~= commonconst.TABLE_STATE_GAME_END then
            responsemsg.is_infriendsnggame = true
            base.skynet_retpack(responsemsg)
            return
        end
    end
    
    if seat == nil then
        --奖玩家从旁观队列中移除
        msghelper.leavetable(request.rid, request.playerinfo.rolename)
    else
        --将玩家从座位上站起
        msghelper.standup(seat.index)

        --奖玩家从旁观队列中移除
        msghelper.leavetable(request.rid, request.playerinfo.rolename)
    end

    base.skynet_retpack(responsemsg)
end

--[[#请求在桌子内坐下
sitdowntable 13 {
    request {
        version 0 : VersionType
        rid 1 : integer
        seat_index 2 : integer   # 0 表示随机坐下， other选座位号
        table_id 3 : integer
    }

    response {
        issucces 0 : boolean     #true 成功  false 失败
        resultdes 1 : string     #错误原因
        errcode 2 : integer      #错误码
    }               
}]]
function TableRequestMsg.sitdowntable(request)
    local responsemsg = {issucces = true,}
    local seatinfo = {lock_chips=0}
    local seat = msghelper.find_player_seat(request.rid)
    local playerinfo = request.playerinfo
    local table_data = msghelper.get_tabledata()
    local table_conf = msghelper.get_table_conf()
    msghelper.write_tableinfo_log("TableRequestMsg.sitdowntable", request)
    --检查玩家是否已经在座位上
    if seat ~= nil then
        responsemsg.issucces = true
        --填写座位信息
        seat.outtable_chips = playerinfo.chips
        seat.gatesvr_id = request.sourcesvr_id
        seat.agent_address = request.service_address
        msghelper.canceltuoguan(seat.index)

        --设置回应信息
        seatinfo.lock_chips = seat.chips --被锁住筹码
        seatinfo.seat_index = seat.index        
        seatinfo.cmd = "update"
        
        base.skynet_retpack(responsemsg, seatinfo)
        msghelper.report_tablestate()
        return
    end

    if table_data.out_list[request.rid] then

        responsemsg.issucces = false
        responsemsg.resultdes = "您已经参加过比赛"
        responsemsg.errcode = EErrorReason.ERROR_ATTENDED_SELFSNG        
        seatinfo.table_id = table_data.table_id
        seatinfo.table_create_time = table_conf.table_create_time
        base.skynet_retpack(responsemsg, seatinfo)
        return
    end

    if msghelper.is_full() then
        responsemsg.issucces = false
        responsemsg.resultdes = "桌子已满！"
        responsemsg.errcode = EErrorReason.ERROR_TABLE_FULL
        base.skynet_retpack(responsemsg, seatinfo)
        msghelper.report_tablestate()
        return
    end

    if table_data.isdelete then
        responsemsg.issucces = false
        responsemsg.resultdes = "该局已经结束！"
        responsemsg.errcode = EErrorReason.ERROR_INVALID_REQUEST
        base.skynet_retpack(responsemsg, seatinfo)
        msghelper.report_tablestate()
        return
    end

    local is_fixedchips = false
    local fixed_chips = 0
    seatinfo.cmd = "insert"
    if table_data.table_room_type == commonconst.ROOM_PRIVATE_TYPE then
        local fixedchips_list = playerdatadao.query_fixedchips_list(request.rid)
        if fixedchips_list ~= nil then
            for _, value in pairs(fixedchips_list) do
                if value.table_id == table_data.table_id and value.table_create_time == table_conf.table_create_time then
                    if value.fixed_chips > 0 then
                        is_fixedchips = true
                        fixed_chips = value.fixed_chips
                    else
                        seatinfo.cmd = "update"
                    end
                    break
                end 
            end
        end
    end
    --检查玩家的筹码是否能够坐下
    local game_draw = math.ceil(table_data.big_blinds * table_data.game_draw_rate  / 100)
    if not is_fixedchips and playerinfo.chips < game_draw then
        responsemsg.issucces = false
        responsemsg.resultdes = "你的筹码不够台费，不能坐下！"
        responsemsg.errcode = EErrorReason.ERROR_NOTENOUGH_CHIPS
        base.skynet_retpack(responsemsg, seatinfo)
        msghelper.report_tablestate()
        return                              
    end

    if not is_fixedchips and playerinfo.chips < table_data.ante and table_data.signup_fee == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "你的筹码不够前注，不能坐下！"
        responsemsg.errcode = EErrorReason.ERROR_NOTENOUGH_CHIPS
        base.skynet_retpack(responsemsg, seatinfo)
        msghelper.report_tablestate()
        return                              
    end

    if not is_fixedchips and playerinfo.chips < table_data.min_carry then
        responsemsg.issucces = false
        responsemsg.resultdes = "你的筹码不足，不能坐下！"
        responsemsg.errcode = EErrorReason.ERROR_NOTENOUGH_CHIPS
        base.skynet_retpack(responsemsg, seatinfo)
        msghelper.report_tablestate()
        return                              
    end

    local lock_chips
    if request.carry_chips == nil or request.carry_chips < table_data.min_carry then
        lock_chips = table_data.min_carry
    elseif request.carry_chips > playerinfo.chips then
        lock_chips = playerinfo.chips
    else
        lock_chips = request.carry_chips
    end 

    --检查玩家是否够SNG条件
    if  table_data.signup_fee ~= nil and #table_data.signup_fee ~= 0 then
        local is_cansignup = false
        for _, value in ipairs(table_data.signup_fee) do
            if value.id == 1 then
                if table_data.service_charge +value.num < playerinfo.chips then
                    is_cansignup = true
                    lock_chips = table_data.service_charge +value.num
                    break
                end
            else
                --TO ADD                     
            end
        end
        if not is_cansignup then
            responsemsg.issucces = false
            responsemsg.resultdes = "不够SNG参加条件！"
            responsemsg.errcode = EErrorReason.ERROR_NOTENOUGH_SIGNUP_CONDITIONS
            base.skynet_retpack(responsemsg, seatinfo)
            msghelper.report_tablestate()
            return                                          
        end
    end

    if request.seat_index > 0 then
        --在指定座位上坐下
        seat = msghelper.get_seat_byindex(request.seat_index)        
        if seat == nil then
            responsemsg.issucces = false
            responsemsg.resultdes = "无效的桌位号！"
            responsemsg.errcode = EErrorReason.ERROR_INVALID_TABLESEAT
            base.skynet_retpack(responsemsg, seatinfo)
            msghelper.report_tablestate()
            return              
        end

        if seat.rid ~= 0 and seat.rid ~= request.rid then
            responsemsg.issucces = false
            responsemsg.resultdes = "当前桌位已经有人！"
            responsemsg.errcode = EErrorReason.ERROR_INVALID_TABLESEAT
            base.skynet_retpack(responsemsg, seatinfo)
            msghelper.report_tablestate()
            return                          
        end 
    else
        --随机选择一个空座位
        seat = msghelper.get_seat_byindex(0)            
        if seat == nil then
            responsemsg.issucces = false
            responsemsg.resultdes = "桌子已满！"
            responsemsg.errcode = EErrorReason.ERROR_TABLE_FULL
            base.skynet_retpack(responsemsg, seatinfo)
            msghelper.report_tablestate()
            return
        end
    end

    --玩家在旁观中，将玩家从旁观队列中删除
    msghelper.del_wait_player(request.rid)

    --判断控制状态
    if not is_fixedchips and table_conf.is_control then
        local refusesitdown = table_data.refusesitdownrecords[request.rid]
        if refusesitdown then
            --判断次数
            local refuse_sitdown_count = configdao.get_common_conf("friendtable_refuse_sitdown_count")
            if refusesitdown.count >= refuse_sitdown_count then
                responsemsg.issucces = false
                responsemsg.resultdes = string.format("拒绝%s次后不能申请带入！", refuse_sitdown_count)
                responsemsg.errcode = EErrorReason.ERROR_REFUSE_SITDOWN
                base.skynet_retpack(responsemsg, seatinfo)
                msghelper.report_tablestate()
                return
            end
            --判断时间
            local refuse_sitdown_time = configdao.get_common_conf("friendtable_refuse_sitdown_time")
            if timetool.get_time() < refusesitdown.time + refuse_sitdown_time*60 then
                responsemsg.issucces = false
                responsemsg.resultdes = string.format("拒绝%d分钟内不能申请带入！", refuse_sitdown_time)
                responsemsg.errcode = EErrorReason.ERROR_APPLY_TOO_FAST
                base.skynet_retpack(responsemsg, seatinfo)
                msghelper.report_tablestate()
                return
            end
        end
    end

    --检查是否报名
    if table_data.table_room_type==commonconst.ROOM_FRIEND_SNG_TYPE then
        if table_data.signup_list[request.rid]==nil then
            responsemsg.issucces = false
            responsemsg.resultdes = "您尚未报名"
            base.skynet_retpack(responsemsg, seatinfo)
            return
        end
    end

    --填写座位信息
    if not is_fixedchips then
        fixed_chips = lock_chips
    else
        lock_chips = 0
    end

    seat.rid = request.rid
    seat.is_robot = robotmanager.is_robot(request.rid)
    seat.outtable_chips = playerinfo.chips
    seat.chips = fixed_chips
    if is_fixedchips then
        seat.carry_chips = 0
    else
        seat.carry_chips = fixed_chips
    end
    seat.state = commonconst.PLAYER_STATE_WAIT_FOR_NEXT_ONE_GAME
    seat.gatesvr_id = request.sourcesvr_id
    seat.agent_address = request.service_address
    seat.playerinfo.rolename = playerinfo.rolename
    seat.playerinfo.logo = playerinfo.logo
    seat.playerinfo.sex = playerinfo.sex
    seat.is_tuoguan = false
    seat.sng_rank = 0

    --设置回应信息
    seatinfo.lock_chips = lock_chips --被锁住筹码
    seatinfo.seat_index = seat.index
    seatinfo.table_id = table_data.table_id
    seatinfo.table_create_time = table_conf.table_create_time
    base.skynet_retpack(responsemsg, seatinfo)

    --玩家坐下处理（下发玩家坐下信息、驱动游戏开始等）
    msghelper.sitdown(request.rid, seat.index, seat.chips, playerinfo.rolename)
end

function TableRequestMsg.standuptable(request)
    local responsemsg = {issucces = true,}
    local seat = msghelper.get_seat_byindex(request.seat_index)
    msghelper.write_tableinfo_log("TableRequestMsg.standuptable", request)
    --检查玩家是否已经在座位上
    if seat == nil then
            responsemsg.issucces = false
            responsemsg.resultdes = "无效的桌位号！"
            base.skynet_retpack(responsemsg)
            return
    else
        --校验发起请求的agent是否和座位上的信息一致
        if seat.gatesvr_id ~= request.sourcesvr_id or seat.agent_address ~= request.service_address then
            responsemsg.issucces = false
            responsemsg.resultdes = "无效操作"
            base.skynet_retpack(responsemsg)
            return          
        end
    end

    base.skynet_retpack(responsemsg)

    msghelper.standup(request.seat_index)       
end

function TableRequestMsg.reqdoaction(request)
    local responsemsg = {issucces = true,}
    local table_data = msghelper.get_tabledata()
    local seat = msghelper.get_seat_byindex(request.seat_index)

    msghelper.write_tableinfo_log("TableRequestMsg.reqdoaction", request)

    --检查玩家是否已经在座位上
    if seat == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不再座位上"
        base.skynet_retpack(responsemsg)
        filelog.sys_error("TableRequestMsg.reqdoaction1", request)
        return
    else
        --校验发起请求的agent是否和座位上的信息一致
        if seat.gatesvr_id ~= request.sourcesvr_id or seat.agent_address ~= request.service_address then
            responsemsg.issucces = false
            responsemsg.resultdes = "无效操作"
            base.skynet_retpack(responsemsg)
            filelog.sys_error("TableRequestMsg.reqdoaction2", seat, request)
            return          
        end
    end

    --检查桌子状态
    if msghelper.get_tablestate() ~= commonconst.TABLE_STATE_WAIT_CLIENT_ACTION then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作"
        base.skynet_retpack(responsemsg)
        filelog.sys_error("TableRequestMsg.reqdoaction3", msghelper.get_tablestate())
        return                  
    end

    if table_data.action_index ~= request.seat_index then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作"
        base.skynet_retpack(responsemsg)
        filelog.sys_error("TableRequestMsg.reqdoaction4", table_data.action_index, request.seat_index)                
        return
    end

    --成功
    base.skynet_retpack(responsemsg)

    --如果玩家主动进行了操作，取消超时次数
    seat.timeout_times = nil

    --处理玩家玩牌
    msghelper.doaction(request.seat_index, request.action_type, request.action_num)
end

function TableRequestMsg.canceltuoguan(request)
    local responsemsg = {issucces = true,}
    local seat = msghelper.get_seat_byindex(request.seat_index)

    msghelper.write_tableinfo_log("TableRequestMsg.canceltuoguan", request)

    --检查玩家是否已经在座位上
    if seat == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不再座位上"
        base.skynet_retpack(responsemsg)
        return
    else
        --校验发起请求的agent是否和座位上的信息一致
        if seat.gatesvr_id ~= request.sourcesvr_id or seat.agent_address ~= request.service_address then
            responsemsg.issucces = false
            responsemsg.resultdes = "无效操作"
            base.skynet_retpack(responsemsg)
            return
        end
    end

    --处理玩家玩牌
    if not msghelper.canceltuoguan(request.seat_index) then
        responsemsg.issucces = false
        responsemsg.resultdes = "不能取消托管！"
        base.skynet_retpack(responsemsg)
        return
    end
    
    --成功
    base.skynet_retpack(responsemsg)
end

--[[
#将玩家从朋友桌踢掉
kickfromtable 79 {
    request {
        version 0 : VersionType
        kicked_rid 1 : integer  #被踢掉玩家
        table_id 2 : integer    #桌子id
    }

    response {
        issucces 0 : boolean
        resultdes 1 : string
    }
}
]]
function TableRequestMsg.kickfromtable(request)
    local responsemsg = {issucces = true,}
    local conf = msghelper.get_table_conf()
    msghelper.write_tableinfo_log("TableRequestMsg.kickfromtable", request)
    
    if conf.table_create_user ~= nil and request.fromrid ~= conf.table_create_user then
        responsemsg.issucces = false
        responsemsg.resultdes = "只有桌主能踢人！"
        base.skynet_retpack(responsemsg)
        return
    end 

    local success = msghelper.kickfromtable(request.kicked_rid)
    if not success then
        responsemsg.issucces = false
        responsemsg.resultdes = "被踢玩家不在桌上！"
        base.skynet_retpack(responsemsg)
        return
    end

    base.skynet_retpack(responsemsg) 
end

--[[
#朋友桌开始游戏
friendtablestart 81 {
    request {
        version 0 : VersionType     
    }

    response {
        issucces 0 : boolean
        resultdes 1 : string
    }
}
]]
function TableRequestMsg.friendtablestart(request)
    local conf = msghelper.get_table_conf()
    local responsemsg = {issucces = true,}

    if conf.table_create_user ~= nil and request.rid ~= conf.table_create_user then
        responsemsg.issucces = false
        responsemsg.resultdes = "只有房主能够开始朋友桌游戏！"
        base.skynet_retpack(responsemsg)
        return
    end

    base.skynet_retpack(responsemsg)    
    msghelper.startgame()
end

--[[
#回复进入朋友桌
replyenterfriendtable 103 {
    request {
        version 0 : VersionType
        requestrid 1 : integer           #发起申请玩家id
        is_agree 2 : boolean      #true 表示同意  false 表示拒绝
        table_id 3 : integer      #桌子id号
        table_address 4 : integer
    }

    response {
        issucces 0 : boolean       #true 成功  false 失败
        resultdes 1 : string       #错误原因
        requestrid 2 : integer     #发起申请玩家id
        table_id 3 : integer       #桌子id号
    }
}
]]
function TableRequestMsg.replyenterfriendtable(request)
    local table_data = msghelper.get_tabledata()
    local conf = msghelper.get_table_conf()
    local responsemsg = {issucces = true,}

    if request.table_address ~= skynet.self() then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return        
    end

    if conf.table_create_user ~= nil and request.rid ~= conf.table_create_user then
        responsemsg.issucces = false
        responsemsg.resultdes = "只有房主能够回应申请！"
        base.skynet_retpack(responsemsg)
        return
    end

    local seat = msghelper.find_player_seat(request.requestrid)
    if not seat or seat.state ~= commonconst.PLAYER_STATE_WAIT_CONFIRM then
        responsemsg.issucces = false
        if table_data.sitdown_player_num >= conf.max_player_num then
            responsemsg.resultdes = "比赛已经开始"            
        else
            responsemsg.resultdes = "比赛已经开始"
        end
        base.skynet_retpack(responsemsg)
        return
    end

    --回复玩家
    local notifymsg = {is_agree=request.is_agree, table_id=table_data.table_id}
    msghelper.sendmsg_totableplayer(seat, "replyenterfriendtablenotify", notifymsg)

    responsemsg.requestrid = request.requestrid
    responsemsg.table_id = request.table_id

    if request.is_agree then
        --同意，修改座位状态
        table_data.refusesitdownrecords[seat.rid] = nil
        seat.state = commonconst.PLAYER_STATE_WAIT_FOR_NEXT_ONE_GAME

        msghelper.add_tablestateinfo(ETableStateinfoType.TABLE_STATEINFO_SITDOWN, seat.rid, seat.chips, timetool.get_time(), seat.playerinfo.rolename)

        local record = {}
        record.rid = seat.rid
        record.buy_in_chips = seat.carry_chips
        record.win_chips = 0
        record.rolename = seat.playerinfo.rolename
        record.logo = seat.playerinfo.logo
        msghelper.add_onetablerecord(seat.rid, record)

        --检查开始游戏
        msghelper.checkgamerun()
    else
        --拒绝

        --增加拒绝次数
        if not table_data.refusesitdownrecords[seat.rid] then
            table_data.refusesitdownrecords[seat.rid] = {count=0}
        end
        table_data.refusesitdownrecords[seat.rid].count = table_data.refusesitdownrecords[seat.rid].count + 1
        table_data.refusesitdownrecords[seat.rid].time = timetool.get_time()

        --强行让玩家站起来
        msghelper.standup(seat.index, "dont_notify_cancel")
    end
    
    --清除timer
    if seat.applyenter_timerid then
        timer.cleartimer(seat.applyenter_timerid)
        seat.applyenter_timerid = nil
    end

    base.skynet_retpack(responsemsg)
end


--[[
#管理控制带入
controlfriendtable 105 {
    request {
        version 0 : VersionType
        is_control 1 : boolean  #是否控制带入
    }

    response {
        issucces 0 : boolean       #true 成功  false 失败
        resultdes 1 : string       #错误原因
        is_control 2 : boolean  #是否控制带入
    }
}
]]
function TableRequestMsg.controlfriendtable(request)
    local conf = msghelper.get_table_conf()
    local responsemsg = {issucces = true,}

    if conf.table_create_user ~= nil and request.rid ~= conf.table_create_user then
        responsemsg.issucces = false
        responsemsg.resultdes = "只有房主能够控制带入！"
        base.skynet_retpack(responsemsg)
        return
    end

    conf.is_control = request.is_control
    responsemsg.is_control = conf.is_control

    base.skynet_retpack(responsemsg)
end

--[[
#请求亮牌
reqlightcards 86 {
    request {
        version 0 : VersionType
        cards 1 : *integer
        is_auto 2 : boolean   #是否自动亮牌
    }

    response {
        issucces 0 : boolean
        resultdes 1 : string
    }   
}
]]
function TableRequestMsg.reqlightcards(request)
    local responsemsg = {issucces = true,}
    local seat = msghelper.get_seat_byindex(request.seat_index)

    msghelper.write_tableinfo_log("TableRequestMsg.reqlightcards", request)

    --检查玩家是否已经在座位上
    if seat == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不再座位上"
        base.skynet_retpack(responsemsg)
        return
    else
        --校验发起请求的agent是否和座位上的信息一致
        if seat.gatesvr_id ~= request.sourcesvr_id or seat.agent_address ~= request.service_address then
            responsemsg.issucces = false
            responsemsg.resultdes = "无效操作"
            base.skynet_retpack(responsemsg)
            return          
        end
    end
    
    --成功
    base.skynet_retpack(responsemsg)

    --处理玩家亮牌
    msghelper.dolightcards(request.seat_index, request.cards, request.is_auto)    
end

--[[
#重买进入筹码
rebuychips 88 {
    request {
        version 0 : VersionType
        auto_type 1 : integer     #1 表示自动补到月设置值 2 表示低于下设线自动补到预设值
        default_value 2 : integer #带入预设值
        bottom_value 3 : integer  #自动买入下设线
    }

    response {
        issucces 0 : boolean
        resultdes 1 : string
    }
}
]]
function TableRequestMsg.rebuychips(request)
    local responsemsg = {issucces = true,}

    msghelper.write_tableinfo_log("TableRequestMsg.rebuychips", request)

    if not msghelper.is_intable(request.rid) then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不在桌子里！"
        base.skynet_retpack(responsemsg)
        return        
    end
    
    --成功
    base.skynet_retpack(responsemsg)

    --处理重买筹码
    msghelper.rebuychips(request.rid, request.auto_type, request.default_value, request.bottom_value)            
end

--[[
#通知牌桌实时动态信息
gettablestateinfo 97 {
    request {
        version 0 : VersionType                     
    }
    response {
        issucces 0 : boolean
        resultdes 1 : string
        states 2 : *TableStateinfoItem
    }
}
]]
function TableRequestMsg.gettablestateinfo(request)
    local responsemsg = {issucces = true,}
    local table_data = msghelper.get_tabledata()

    msghelper.write_tableinfo_log("TableRequestMsg.gettablestateinfo", request)
    
    responsemsg.states = table_data.tablestateinfos
    --成功
    base.skynet_retpack(responsemsg)    
end


--[[
#朋友桌重购
friendtablerebuy 110 {
    request {
        version 0 : VersionType
        chips 1 : integer     #1 带入筹码
    }

    response {
        issucces 0 : boolean
        resultdes 1 : string
    }
}
]]
function TableRequestMsg.friendtablerebuy(request)
    local responsemsg = {issucces = true,}

    msghelper.write_tableinfo_log("TableRequestMsg.friendtablerebuy", request)

    if not msghelper.is_intable(request.rid) then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不在桌子里！"
        base.skynet_retpack(responsemsg)
        return
    end

    local seat = msghelper.find_player_seat(request.rid)
    if not seat then
        responsemsg.issucces = false
        responsemsg.resultdes = "玩家不在座位上"
        base.skynet_retpack(responsemsg)
        return
    end
    if seat.state==commonconst.PLAYER_STATE_WAIT_CONFIRM then
        responsemsg.issucces = false
        responsemsg.resultdes = "带入申请尚未通过"
        base.skynet_retpack(responsemsg)
        return
    end

    --处理重买筹码
    responsemsg.issucces, responsemsg.resultdes = msghelper.friendtablerebuy(seat, request.chips)
    
    --返回
    base.skynet_retpack(responsemsg)
end

--[[
#回复朋友桌重购
replyfriendtablerebuy 112 {
    request {
        version 0 : VersionType
        requestrid 1 : integer           #发起申请玩家id
        is_agree 2 : boolean      #true 表示同意  false 表示拒绝
        table_id 3 : integer #桌子id号
        roomsvr_id 4 : string
        table_address 5 : integer
    }

    response {
        issucces 0 : boolean       #true 成功  false 失败
        resultdes 1 : string       #错误原因
        requestrid 2 : integer           #发起申请玩家id
        table_id 3 : integer #桌子id号
    }
}
]]
function TableRequestMsg.replyfriendtablerebuy(request)
    local responsemsg = {issucces = true,}
    local table_data = msghelper.get_tabledata()
    local conf = msghelper.get_table_conf()

    msghelper.write_tableinfo_log("TableRequestMsg.replyfriendtablerebuy", request)

    if request.table_address ~= skynet.self() then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效请求！"
        base.skynet_retpack(responsemsg)
        return        
    end

    if conf.table_create_user ~= nil and request.rid ~= conf.table_create_user then
        responsemsg.issucces = false
        responsemsg.resultdes = "只有房主能够回应！"
        base.skynet_retpack(responsemsg)
        return
    end

    local seat = msghelper.find_player_seat(request.requestrid)
    if not seat then
        responsemsg.issucces = false
        responsemsg.resultdes = "玩家无效"
        base.skynet_retpack(responsemsg)
        return
    end

    if not seat.rebuying then
        responsemsg.issucces = false
        responsemsg.resultdes = "操作无效"
        base.skynet_retpack(responsemsg)
        return
    end
    
    --回复玩家
    local notifymsg = {is_agree=request.is_agree, ia_auto=false}
    msghelper.sendmsg_totableplayer(seat, "friendtablerebuyresult", notifymsg)

    responsemsg.requestrid = request.requestrid
    responsemsg.table_id = request.table_id

    if request.is_agree then
        --同意
        table_data.refuserebuyrecords[seat.rid] = nil
        table_data.autobuyinplayers[seat.rid] = seat.rebuying
    else
        --拒绝

        --增加拒绝次数
        if not table_data.refuserebuyrecords[seat.rid] then
            table_data.refuserebuyrecords[seat.rid] = {count=0}
        end
        table_data.refuserebuyrecords[seat.rid].count = table_data.refuserebuyrecords[seat.rid].count + 1
        table_data.refuserebuyrecords[seat.rid].time = timetool.get_time()
    end
    
    seat.rebuying = nil
    if seat.rebuy_timerid then
        timer.cleartimer(seat.rebuy_timerid)
        seat.rebuy_timerid = nil
    end

    base.skynet_retpack(responsemsg)
end


--[[
#取消朋友桌重购
friendtablerebuycancel 115 {
    request {
        version 0 : VersionType
    }

    response {
        issucces 0 : boolean
        resultdes 1 : string
    }
}
]]
function TableRequestMsg.friendtablerebuycancel(request)
    local responsemsg = {issucces = true,}
    local table_data = msghelper.get_tabledata()

    msghelper.write_tableinfo_log("TableRequestMsg.friendtablerebuy", request)

    if not msghelper.is_intable(request.rid) then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不在桌子里！"
        base.skynet_retpack(responsemsg)
        return
    end

    local seat = msghelper.find_player_seat(request.rid)
    if not seat then
        responsemsg.issucces = false
        responsemsg.resultdes = "玩家不在座位上"
        base.skynet_retpack(responsemsg)
        return
    end
    if not seat.rebuying then
        responsemsg.issucces = false
        responsemsg.resultdes = "操作无效"
        base.skynet_retpack(responsemsg)
        return
    end

    --清理
    seat.rebuying = nil
    if seat.rebuy_timerid then
        timer.cleartimer(seat.rebuy_timerid)
        seat.rebuy_timerid = nil
    end

    local notify = {
        rid = seat.rid,
        rolename = seat.playerinfo.rolename,
        table_id = table_data.table_id,
    }

    local table_conf = msghelper.get_table_conf()
    msghelper.sendmsg_totableplayer_rid(table_conf.table_create_user, "friendtablerebuycancelnotify", notify)
    
    --返回
    base.skynet_retpack(responsemsg)
end

--[[
#取得朋友桌旁观列表
getfriendtablewaits 117 {
    request {
        version 0 : VersionType
        table_id 1 : integer
        roomsvr_id 2 : string
    }

    response {
        issucces 0 : boolean
        resultdes 1 : string
        waitplayers 2 : *TablePlayerInfo #旁观玩家列表
    }
}
]]
function TableRequestMsg.getfriendtablewaits(request)
    local responsemsg = {issucces = true, waitplayers={},}
    local table_data = msghelper.get_tabledata()

    for _, wait_player in pairs(table_data.wait_list) do
        table.insert(responsemsg.waitplayers, wait_player)
    end
    base.skynet_retpack(responsemsg)    
end

--[[
#朋友桌SNG赛报名
friendsngsign 122 { 
    request {
        version 0 : VersionType
    }

    response {
        issucces 0 : boolean     #true 成功  false 失败
        resultdes 1 : string     #错误原因
        need_agree 2 : boolean #是否需要桌主同意
        timeout 3 : integer #超时时间
        table_id 4 : integer #桌子id号
    }
}
]]
function TableRequestMsg.friendsngsign(request)
    local responsemsg = {issucces = true,}
    local game = msghelper.get_game()
    local table_data = msghelper.get_tabledata()
    local table_conf = msghelper.get_table_conf()

    msghelper.write_tableinfo_log("TableRequestMsg.friendsngsign", request)

    if not msghelper.is_intable(request.rid) then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作，玩家不在桌子里！"
        base.skynet_retpack(responsemsg)
        return
    end

    if request.chips < (table_conf.signup_cost + table_conf.service_fee) then
        responsemsg.issucces = false
        responsemsg.resultdes = "您的聚众币不足，请充值后重试。"
        base.skynet_retpack(responsemsg)
        return
    end

    if game.is_signup(request.rid) then
        responsemsg.issucces = false
        responsemsg.resultdes = "您已经报名"
        base.skynet_retpack(responsemsg)
        return
    end
    if table_data.table_state ~= commonconst.TABLE_STATE_WAIT_GAME_START then
        responsemsg.issucces = false
        responsemsg.resultdes = "比赛已经开始，您已不能报名。"
        base.skynet_retpack(responsemsg)
        return
    end
    if game.get_signup_num() >= table_conf.player_num then
        responsemsg.issucces = false
        responsemsg.resultdes = "报名人数已满"
        base.skynet_retpack(responsemsg)
        return
    end

    local wait_player = msghelper.find_wait_player(request.rid)
    if wait_player.signuping then
        responsemsg.issucces = false
        responsemsg.resultdes = "正在等待桌主操作"
        base.skynet_retpack(responsemsg)
        return
    end

    --返回
    responsemsg = msghelper.friendsngsign(request.rid)
    base.skynet_retpack(responsemsg)
    if responsemsg.issucces 
        and (not table_conf.is_control or request.rid == table_conf.table_create_user) then
        game.onsignup(request.rid)        
    end
end

--[[
#桌主回复朋友桌SNG赛报名
replyfriendsngsign 124 {
    request {
        version 0 : VersionType
        requestrid 1 : integer    #发起申请玩家id
        is_agree 2 : boolean      #true 表示同意  false 表示拒绝
        table_id 3 : integer      #桌子id号
        roomsvr_id 4 : string
        table_address 5 : integer
    }

    response {
        issucces 0 : boolean       #true 成功  false 失败
        resultdes 1 : string       #错误原因
        requestrid 2 : integer     #发起申请玩家id
        table_id 3 : integer #桌子id号
    }
}
]]
function TableRequestMsg.replyfriendsngsign(request)
    local responsemsg = {issucces = true,}
    local table_data = msghelper.get_tabledata()
    local conf = msghelper.get_table_conf()

    msghelper.write_tableinfo_log("TableRequestMsg.replyfriendsngsign", request)

    if request.table_address ~= skynet.self() then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return
    end

    if conf.table_create_user ~= nil 
        and request.rid ~= conf.table_create_user then
        responsemsg.issucces = false
        responsemsg.resultdes = "只有房主能够回应！"
        base.skynet_retpack(responsemsg)
        return
    end

    local rid = request.requestrid
    local wait_player = msghelper.find_wait_player(rid)
    if not wait_player then
        responsemsg.issucces = false
        responsemsg.resultdes = "玩家无效"
        base.skynet_retpack(responsemsg)
        return
    end

    if not wait_player.signuping then
        responsemsg.issucces = false
        responsemsg.resultdes = "操作无效"
        base.skynet_retpack(responsemsg)
        return
    end

    if table_data.sitdown_player_num >= conf.max_player_num then
        responsemsg.issucces = false
        responsemsg.resultdes = "当前玩家已满，不能同意该玩家的请求！"
        base.skynet_retpack(responsemsg)
        return        
    end
    
    responsemsg.requestrid = request.requestrid
    responsemsg.table_id = request.table_id

    local game = msghelper.get_game() 
    if request.is_agree then
        --同意
        wait_player.signuping = nil
        wait_player.deduct_signup_cost = nil
        table_data.refusesignuprecords[rid] = nil
        msghelper.signup(rid)
    else

        game.restore_signupfee(rid)

        --增加拒绝次数
        if not table_data.refusesignuprecords[rid] then
            table_data.refusesignuprecords[rid] = {count=0}
        end
        table_data.refusesignuprecords[rid].count = table_data.refusesignuprecords[rid].count + 1
        table_data.refusesignuprecords[rid].time = timetool.get_time()
    end
    
    --回复玩家
    local notifymsg = {
        is_agree=request.is_agree,
        ia_auto=false, refuse_time=game.get_refuse_time(rid)
    }
    msghelper.sendmsg_totableplayer_rid(request.requestrid, "friendsngsignresult", notifymsg)
    
    --清理
    if wait_player.signup_timerid then
        timer.cleartimer(wait_player.signup_timerid)
        wait_player.signup_timerid = nil
    end

    base.skynet_retpack(responsemsg)
end

--[[
#取消朋友桌SNG赛报名
cancelfriendsngsign 126 {
    request {
        version 0 : VersionType
    }

    response {
        issucces 0 : boolean     #true 成功  false 失败
        resultdes 1 : string     #错误原因
    }
}
]]
function TableRequestMsg.cancelfriendsngsign(request)
    local responsemsg = {issucces = true,}
    local table_data = msghelper.get_tabledata()
    local conf = msghelper.get_table_conf()

    --msghelper.write_tableinfo_log("TableRequestMsg.friendtablerebuy", request)

    if not msghelper.is_intable(request.rid) then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不在桌子里！"
        base.skynet_retpack(responsemsg)
        return
    end

    local wait_player = msghelper.find_wait_player(request.rid)
    if wait_player ~= nil and wait_player.signuping and wait_player.deduct_signup_cost then
        responsemsg.deduct_signup_cost = wait_player.deduct_signup_cost
        wait_player.signuping = nil
        wait_player.deduct_signup_cost = nil        
        if wait_player.signup_timerid then            
            timer.cleartimer(wait_player.signup_timerid)
            wait_player.signup_timerid = nil
        end
    elseif table_data.signup_list and table_data.signup_list[request.rid] then
        responsemsg.deduct_signup_cost = table_data.signup_list[request.rid].deduct_signup_cost        
        table_data.signup_list[request.rid] = nil
        local rids = {}
        table.insert(rids, request.rid)
        --玩家桌上时将玩家弹出
        local seat = msghelper.find_player_seat(request.rid)
        if seat ~= nil then
            msghelper.standup(seat.index)
        end
        msghelper.report_signup_clear(rids)
    else
        responsemsg.issucces = false
        responsemsg.resultdes = "操作无效"
        base.skynet_retpack(responsemsg)
        return 
    end

    --返回
    base.skynet_retpack(responsemsg)

    local notify = {
        rid = request.rid,
        rolename = request.rolename,
        table_id = table_data.table_id,
    }
    msghelper.sendmsg_toalltableplayer("cancelfriendsngsignnotice", notify)
    
    local game = msghelper.get_game()
    local noticemsg = {
        signup_cost = conf.signup_cost,
        service_fee = conf.service_fee,
        promotion_blinds_time = conf.promotion_blinds_time,
        initial_chips = conf.initial_chips,
        small_blinds = table_data.small_blinds,
        big_blinds = table_data.big_blinds,
        signup_num = game.get_signup_num(),
        signup_max_num = conf.player_num,
        signup_list = {},
    }
    for _, info in pairs(table_data.signup_list) do
        table.insert(noticemsg.signup_list, info.rolename)
    end


    for _, seat in ipairs(table_data.tableseats) do
        if not game.is_noplayer(seat) then
            noticemsg.is_signup = game.is_signup(seat.rid)
            noticemsg.is_signuping = game.is_signuping(seat.rid)
            noticemsg.refuse_time = game.get_refuse_time(seat.rid)
            msghelper.sendmsg_totableplayer_rid(seat.rid, "friendsngsignupinfo", noticemsg)
        end
    end

    for rid, wait in pairs(table_data.wait_list) do
        noticemsg.is_signup = game.is_signup(rid)
        noticemsg.is_signuping = game.is_signuping(rid)
        noticemsg.refuse_time = game.get_refuse_time(rid)
        msgproxy.send_noticemsgto_gatesvrd(wait.gatesvr_id, wait.agent_address, "friendsngsignupinfo", noticemsg)
    end    
end

--[[
#获取朋友桌SNG赛规则，包括奖励和升盲
getfriendsngrules 129 {
    request {
        version 0 : VersionType
    }

    response {
        issucces 0 : boolean    #true 成功  false 失败
        resultdes 1 : string    #错误
        rank_award 2 : *RankAward #奖励
        blinds_list 2 : *BlindsList #盲注表
    }
}
]]
function TableRequestMsg.getfriendsngrules(request)
    local responsemsg = {issucces = true,}

    msghelper.write_tableinfo_log("TableRequestMsg.friendtablerebuy", request)

    if not msghelper.is_intable(request.rid) then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不在桌子里！"
        base.skynet_retpack(responsemsg)
        return
    end
    
    responsemsg = msghelper.getfriendsngrules()
    
    --返回
    base.skynet_retpack(responsemsg)
end

function TableRequestMsg.sharematchrecord(request)
    local responsemsg = {issucces = true,}
    local seat = msghelper.get_seat_byindex(request.seat_index)

    msghelper.write_tableinfo_log("TableRequestMsg.sharematchrecord", request)

    --检查玩家是否已经在座位上
    if seat == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效操作玩家不再座位上"
        skynet.ret(skynet.pack(responsemsg))
        return
    else
        --校验发起请求的agent是否和座位上的信息一致
        if seat.gatesvr_id ~= request.sourcesvr_id or seat.agent_address ~= request.service_address then
            responsemsg.issucces = false
            responsemsg.resultdes = "无效操作"
            skynet.ret(skynet.pack(responsemsg))
            return          
        end
    end

    local success, record_id = msghelper.sharerecord()
    if not success then
        responsemsg.issucces = false
        responsemsg.resultdes = "分享失败"
    else
        responsemsg.record_id = record_id
    end
    
    --返回
    skynet.ret(skynet.pack(responsemsg))
end

--GM请求桌子详细信息
function TableRequestMsg.get_table_info()
    local table_data = msghelper.get_tabledata()
    local game = msghelper.get_game()
    local info = {}

    for _, seat in ipairs(table_data.tableseats) do
        if game.is_ingameseat(seat) then
            table.insert(info, {
                rid = seat.rid,
                rolename = seat.playerinfo.rolename,
                chips = seat.chips,
            })
        end
    end
    --返回
    base.skynet_retpack(info)
end

function TableRequestMsg.leavefriendsng(request)
    local responsemsg = {issucces = true,}
    local seat = msghelper.find_player_seat(request.rid)    
    if seat ~= nil then
        --将玩家从座位上站起
        msghelper.standup(seat.index)

        --奖玩家从旁观队列中移除
        --msghelper.leavetable(request.rid, request.playerinfo.rolename)
    end

    base.skynet_retpack(responsemsg)
end


--[[
#请求增购时间
addtimecost 170 {
    request {
        version 0 : VersionType     
    }

    response {
        issucces 0 : boolean      #true 成功  false 失败
        resultdes 1 : string      #错误原因
        add_time 2 : integer      #增购时间
        add_time_cost 3 : integer #增购花费
        chips_balance 4 : integer #金币余额
        next_add_time_cost 5 : integer #下一次增购花费
    }                   
}
]]
function TableRequestMsg.addtimecost(request)
    local responsemsg = {issucces = true,}
    local seat = msghelper.find_player_seat(request.rid)
    local table_data = msghelper.get_tabledata()
    if seat == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "你不在坐位上！"
        base.skynet_retpack(responsemsg)
        return
    end

    if table_data.table_state ~= commonconst.TABLE_STATE_WAIT_CLIENT_ACTION then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return
    end 

    if table_data.tableseats[table_data.action_index].rid ~= seat.rid then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return
    end

    if table_data.action_timeout <= timetool.get_time()+1 then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return
    end

    local add_time_cost = msghelper.get_add_time_cost()
    if add_time_cost == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return
    end

    local next_addtime_index = table_data.add_time_player_list[seat.rid]
    if next_addtime_index == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return
    end
    --filelog.sys_info("addtimecost", request, add_time_cost, next_addtime_index)
    if (request.player_chips - request.player_lock_chips) < add_time_cost[next_addtime_index] then
        responsemsg.issucces = false
        responsemsg.resultdes = "您账户的聚众币不足，请充值后再使用该功能。"
        base.skynet_retpack(responsemsg)
        return        
    end

    local game = msghelper.get_game()
    if game.add_time == nil then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return                    
    end
 
    responsemsg.add_time = 20
    responsemsg.add_time_cost = add_time_cost[next_addtime_index]
    next_addtime_index = next_addtime_index + 1
    if next_addtime_index > #add_time_cost then
        next_addtime_index = #add_time_cost    
    end    
    table_data.add_time_player_list[seat.rid] = next_addtime_index
    if not game.add_time(seat, 20) then
        responsemsg.issucces = false
        responsemsg.resultdes = "无效的请求！"
        base.skynet_retpack(responsemsg)
        return                     
    end    
    base.skynet_retpack(responsemsg)

    --[[
        #通知玩家操作
        doactionaddtime 171 {
            response {
                rid 0 : integer        #玩家ID
                seat_index 1 : integer #玩家位置
                timeout 2 : integer    #操作到期时间
            }
        }
    ]]
    local doactionaddtimemsg = {
        rid = seat.rid,
        seat_index = seat.index,
        timeout = table_data.action_timeout,
        next_add_time_cost = add_time_cost[next_addtime_index]
    }
    msghelper.sendmsg_toalltableplayer("doactionaddtime", doactionaddtimemsg)
end

return TableRequestMsg