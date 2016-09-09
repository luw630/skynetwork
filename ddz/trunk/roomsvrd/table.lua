local skynet = require "skynet"
local filelog = require "filelog"
local eventmng = require "eventmng"
local msghelper = require "tablemsghelper"
local commonconst = require "common_const"
local timer = require "timer"
local roomsvr
local table_conf
local TABLE_DATA = {
	--记录选择自动购买玩家信息
	autobuyinplayers = {
		--[[
			[rid] = {
				auto_type = 0, 1 表示自动补到月设置值 2 表示低于下设线自动补到预设值
				default_value = 0, 带入预设值
				bottom_value = 0,  自动买入下设线
			}
		]]
	},

	fixedchipsplayers = {
		--[[
			[rid]=chips
		]]
	},

	--申请带入拒绝记录
	refusesitdownrecords = {
		--[[
			[rid]=
			{
				count=,--拒绝次数
				time=,--上次拒绝时间
			}
		]]
	},

	--申请重构拒绝记录
	refuserebuyrecords = {
		--[[
			[rid]=
			{
				count=,--拒绝次数
				time=,--上次拒绝时间
			}
		]]
	},

	--桌主不在线时申请入桌的申请记录
	applyenterrecords = {
		--[[
			[rid]=
			{
				msg=,--消息
				time=,--申请时间
			}
		]]
	},

	tableseats = {
		--[[
			1= {
				index = 0,
				rid = 0,
				state = 0, 		--改坐位玩家状态
				gatesvr_id,
				agent_address,
				outtable_chips = 0, --记录桌外筹码
				carry_chips,    --坐下时携带进桌的筹码
				chips,          --玩家在牌桌内的筹码
				bet_chips,      --玩家已下筹码
				is_tuoguan,     --玩家是否托管
				sng_rank,       --玩家SNG的排名
				playerinfo = {
					rolename,
					logo,
					sex,
				}
				cards = {},      --玩家的底牌
				card_form = 0,   --牌型
				form_cards = {}, --牌型对应的牌
				bunko = 0,
				onegame_winchips = 0, --一局游戏赢的筹码
				is_robot = false,
				next_addtime_index = 1,				
			}
		]]
	},

	tablesrecord = {
		--[[
			[rid]={
				rid = 0,          --玩家rid
    			buy_in_chips = 0, --买入筹码
    			win_chips = 0,    --单局赢得筹码
    			rolename = "",
    			logo = "",
			}
		]]
	},

	--记录朋友桌实时动态信息
	tablestateinfos = {
		--[[
			{
				msgtype = 0,
				rid = 0,
				chips = 0,
				timestamp = 0,
			}
		]]
	},

	wait_list = {
		--[[
		rid = {gatesvr_id, agent_addres},
		]]
	}, --旁观队列

	kicked_list = {
		--[[
			rid=true, 被踢的玩家
		]]
	},

	--记录每局玩游戏使用的座位从button开始记录
	gameseat_list = {
		--[[
			[1] = {
				seat_index = 0,
				rid = 0,
			}
		]]
	},

	--记录已经报名的玩家
	signup_list = {
		--[[
			rid={
	            gatesvr_id = seat.gatesvr_id,
	            agent_address = seat.agent_address,
	            rolename = seat.playerinfo.rolename,
	            logo = seat.playerinfo.logo,
	            sex = seat.playerinfo.sex,
	        }
		]]
	},

	add_time_player_list = {
		--[[
			rid=next_addtime_index,				
		]]
	},

	--拒绝报名记录
	refusesignuprecords = {
		--[[
			[rid]=
			{
				count=,--拒绝次数
				time=,--上次拒绝时间
			}
		]]
	},

	--桌主不在线时申请报名的申请记录
	applysignuprecords = {
		--[[
			[rid]=
			{
				msg=,--消息
				time=,--申请时间
			}
		]]
	},

	out_list = {
		--[[
			rid=true, 被淘汰的玩家
		]]
	},

	--桌子状态数据
	sitdown_player_num = 0, --坐下的玩家数
	isdelete = false,		--是否删除桌子
	iskick = false,         --是否单局结束踢出玩家
	table_state = 0, 
	button_index = 0, 	    --庄家位置
	small_blinds_index = 0, --小盲注位置
	small_blinds_num = 0,   --小盲注筹码
	big_blinds_index = 0,   --大盲注位置
 	big_blinds_num = 0,     --大盲注筹码
 	action_index = 0,       --当前操作玩家的座位号
 	action_timeout = 0,     --当前操作玩家到期时间
 	round_count = 0,        --记录桌子当前游戏轮数
 	community_cards = {},   --公共牌

 	action_type = 0,        --玩家操作类型
 	action_num = 0,         --玩家操作数量
 	timer_id = -1, 			--记录桌子的定时器id
 	round_end_index = 0,    --回合结束位置
 	highest_bet = 0,        --本轮最高下注
 	last_raise_diff = 0,    --上一次下注差额
 	deck_cards = {},		--牌堆
 	pots = {				--记录奖池
 		--[[
 		{
		total_bet            = 0, --总下注额
  		player_indexes       = 0, --参与奖池玩家座位号索引
  		win_player_indexes   = 0, --赢得奖池玩家座位号索引
  		sub_chips_curround   = 0, --本轮每人扣除的最大注额
  		curround = 0,	
 		},
 		]]
 	},
 	is_bet = false, 		   --记录每轮玩家是否bet
	--桌子的配置信息
	isneed_updateconf = false, --是否需要更新配置
	table_id = 0,
	table_room_type = 0,     --桌子的房间类型
	small_blinds = 0,
	min_player_num = 0,      --最少开始游戏人数
	max_player_num = 0,      --桌子座位数
	big_blinds = 0,
	min_carry = 0,
	max_carry =	0,
	game_draw_rate = 0,      --房费占大盲的百分比
	prop_price = 0,
	table_name = "",
	calculate_win_expbase = 0,
	calculate_win_expratio = 0,
	calculate_lose_exp = 0,       
	everyday_max_exp = 0,  --每天玩家能获得的最大经验值
	max_wait_num = 0,      --最大旁观人数
	action_time_interval = 0,   --玩家操作超时时间单位10ms
	ante = 0,
	continuous_timeout = 2,
	robot_type = 3,
   	robot_level = 0,
   	robot_min_num = 0,
    robot_max_num = 0,
   	robot_continue_time = 0,    --单位s
    robot_enter_maxtime = 0,    --单位s
    robot_enter_mintime = 0,    --单位s
	--SNG相关配置
	sng_initcarry = 0,
	service_charge = 0,   --服务费
	signup_fee = {},
	blind_template_index = 0,
	award_template_index = 0,
	table_game_type = 0,


	deletetable_timer_id = -1,
	applyrobot_timer_id = -1,
	checkrobot_timer_id = -1,
	synctablestate_timer_id = -1,
	is_passive_lightcards = false,
	table_record_id = "",
}

local TABLE = {}


function  TABLE.init()

	msghelper.init(TABLE)

	eventmng.init(TABLE)
	eventmng.add_eventbyname("cmd", "tablecmdmsg")
	eventmng.add_eventbyname("timer", "tabletimermsg")
  eventmng.add_eventbyname("notice", "tablenoticemsg")  
  eventmng.add_eventbyname("request", "tablerequestmsg")  
end

function TABLE.send_msgto_client(msg,...)
end

function TABLE.send_resmsgto_client(msgname, msg, ...)
end

function TABLE.send_noticemsgto_client(msgname, msg, ...)
end

function TABLE.process_client_message(session, source, ...)
end

function TABLE.process_other_message(session, source, ...)
	eventmng.process(session, source, "lua", ...)
end

function TABLE.decode_client_message(...)
end
----------------------------------------------------------------------------------------------------

--清除桌子的所有状态和数据
function TABLE.clear()
	roomsvr = nil
	table_conf = nil
	TABLE_DATA.tableseats = nil
	TABLE_DATA.tableseats = {}
	TABLE_DATA.wait_list = nil
	TABLE_DATA.wait_list = {}
	TABLE_DATA.kicked_list = nil
	TABLE_DATA.kicked_list = {}
	TABLE_DATA.table_state = 0
	TABLE_DATA.sitdown_player_num = 0
	TABLE_DATA.isdelete = false
	TABLE_DATA.button_index = 0 	    --庄家位置
    TABLE_DATA.small_blinds_index = 0 --小盲注位置
    TABLE_DATA.small_blinds_num = 0   --小盲注筹码
    TABLE_DATA.big_blinds_index = 0   --大盲注位置
   	TABLE_DATA.big_blinds_num = 0     --大盲注筹码
   	TABLE_DATA.community_cards = nil
   	TABLE_DATA.community_cards = {}   --公共牌
   	TABLE_DATA.action_index = 0       --当前操作玩家的座位号
   	TABLE_DATA.action_timeout = 0     --当前操作玩家到期时间
   	TABLE_DATA.round_count = 0
   	TABLE_DATA.tablesrecord = nil
   	TABLE_DATA.tablesrecord = {}
   	TABLE_DATA.action_type = 0        --玩家操作类型
   	TABLE_DATA.action_num = 0         --玩家操作数量
   	TABLE_DATA.timer_id = -1 			--记录桌子的定时器id
   	TABLE_DATA.round_end_index = 0    --回合结束位置
   	TABLE_DATA.highest_bet = 0        --本轮最高下注
   	TABLE_DATA.last_raise_diff = 0    --上一次下注差额
   	TABLE_DATA.deck_cards = nil
   	TABLE_DATA.deck_cards = {}		  --牌堆
   	TABLE_DATA.pots = nil
   	TABLE_DATA.pots = {}			  --记录奖池
	TABLE_DATA.is_bet = false
	TABLE_DATA.is_passive_lightcards = false
	--桌子的配置信息
	TABLE_DATA.isneed_updateconf = false
	TABLE_DATA.table_id = 0
    TABLE_DATA.table_room_type = 0
    TABLE_DATA.small_blinds = 0
    TABLE_DATA.min_player_num = 0
    TABLE_DATA.max_player_num = 0
    TABLE_DATA.big_blinds = 0
    TABLE_DATA.min_carry = 0
    TABLE_DATA.max_carry = 0
    TABLE_DATA.game_draw_rate = 0
    TABLE_DATA.prop_price = 0
    TABLE_DATA.table_name = ""
    TABLE_DATA.calculate_win_expbase = 0
    TABLE_DATA.calculate_win_expratio = 0
    TABLE_DATA.calculate_lose_exp = 0      
    TABLE_DATA.everyday_max_exp = 0
    TABLE_DATA.max_wait_num = 0
    TABLE_DATA.action_time_interval = 0
    TABLE_DATA.ante = 0
    TABLE_DATA.continuous_timeout = 2
   	TABLE_DATA.robot_type = 0
   	TABLE_DATA.robot_level = 0
   	TABLE_DATA.robot_min_num = 0
    TABLE_DATA.robot_max_num = 0
   	TABLE_DATA.robot_continue_time = 0
    TABLE_DATA.robot_enter_maxtime = 0
    TABLE_DATA.robot_enter_mintime = 0
    --SNG相关配置
    TABLE_DATA.service_charge = 0
    TABLE_DATA.signup_fee = nil
    TABLE_DATA.signup_fee = {}
    TABLE_DATA.blind_template_index = 0
    TABLE_DATA.award_template_index = 0
    TABLE_DATA.table_game_type = 0
    TABLE_DATA.table_record_id = ""
    TABLE_DATA.sng_initcarry = 0
    if TABLE_DATA.deletetable_timer_id ~= -1 then
    	timer.cleartimer(TABLE_DATA.deletetable_timer_id)
    	TABLE_DATA.deletetable_timer_id = -1
    end

    if TABLE_DATA.applyrobot_timer_id ~= -1 then
    	timer.cleartimer(TABLE_DATA.applyrobot_timer_id)
    	TABLE_DATA.applyrobot_timer_id = -1	
    end

    if TABLE_DATA.synctablestate_timer_id ~= -1 then
    	timer.cleartimer(TABLE_DATA.synctablestate_timer_id)
    	TABLE_DATA.synctablestate_timer_id = -1	
    end

    if TABLE_DATA.checkrobot_timer_id ~= -1 then
    	timer.cleartimer(TABLE_DATA.checkrobot_timer_id)
    	TABLE_DATA.checkrobot_timer_id = -1	    	
    end
        
    --记录每局玩游戏使用的座位从button开始记录
	TABLE_DATA.gameseat_list = nil
	TABLE_DATA.gameseat_list = {}
	TABLE_DATA.autobuyinplayers = nil
	TABLE_DATA.autobuyinplayers = {}
	TABLE_DATA.tablestateinfos = nil
	TABLE_DATA.tablestateinfos = {}
	TABLE_DATA.fixedchipsplayers = nil
	TABLE_DATA.fixedchipsplayers = {}
	
	TABLE_DATA.applyenterrecords = nil
	TABLE_DATA.applyenterrecords = {}
	TABLE_DATA.refusesitdownrecords = nil
	TABLE_DATA.refusesitdownrecords = {}
	TABLE_DATA.refuserebuyrecords = nil
	TABLE_DATA.refuserebuyrecords = {}

	TABLE_DATA.signup_list = nil
	TABLE_DATA.signup_list = {}
	TABLE_DATA.applysignuprecords = nil
	TABLE_DATA.applysignuprecords = {}
	TABLE_DATA.refusesignuprecords = nil
	TABLE_DATA.refusesignuprecords = {}
	TABLE_DATA.out_list = nil
	TABLE_DATA.out_list = {}
	TABLE_DATA.add_time_player_list = {}
end

function TABLE.set_table_conf(conf)
	table_conf = conf
end

function TABLE.get_table_conf()
	return table_conf
end

function TABLE.get_tabledata()
	return TABLE_DATA
end

function TABLE.set_roomsvr(address)
	roomsvr = address
end

function TABLE.get_roomsvr()
	return roomsvr
end

function TABLE.get_tablestate()
	return TABLE_DATA.table_state
end

function TABLE.set_tablestate(tablestate)
	TABLE_DATA.table_state = tablestate
end

function TABLE.start()

	--[[skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = TABLE.decode_client_message,
		dispatch = TABLE.process_client_message, 
	}]]


	skynet.dispatch("lua", TABLE.process_other_message)

	--gate = skynet.newservice("wsgate")
	
end

skynet.start(function()
	TABLE.init()
	TABLE.start()
end)
