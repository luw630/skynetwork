create database if not exists #DB#;
use #DB#;
set names utf8;
#创建角色账号表  insert  
create table if not exists role_auth(
                                        uid int(11) NOT NULL DEFAULT '0' comment '账号id',
                                        rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                        create_time int(11) NOT NULL DEFAULT '0' comment '创建时间',
                                        update_time timestamp on update current_timestamp default current_timestamp comment '创建时间',
                                        primary key(uid)
                                    )engine = InnoDB, charset = utf8;
#创建玩家基本信息表 insert update
create table if not exists role_info(
                                          rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                          channelid int(11) NOT NULL DEFAULT '0' comment '渠道id',
                                          rolename varchar(128) not null DEFAULT '' comment '角色名称',
                                          logo varchar(512) not null DEFAULT '' comment 'logo url',
                                          country varchar(128) not null DEFAULT '' comment '国家',
                                          province varchar(128) not null DEFAULT '' comment '省',
                                          phone varchar(24) not null DEFAULT '' comment '手机号',
                                          sex int(11) NOT NULL DEFAULT '0' comment '性别',
                                          name varchar(64) not null DEFAULT '0',
                                          isblock int(11) NOT NULL DEFAULT '0',
                                          update_time timestamp on update current_timestamp default current_timestamp,
                                          primary key(rid) 
                                    )engine = InnoDB, charset = utf8;
#创建玩家玩牌数据表    insert update                                                                                       
create table if not exists role_playcards(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            totalwin int(11) NOT NULL DEFAULT '0' comment '总赢局数',
                                            totallose int(11) NOT NULL DEFAULT '0' comment '总失败局数',
                                            maxformcards varchar(256) not null DEFAULT '' comment '最大牌型',
                                            maxcardform int(11) NOT NULL DEFAULT '0' comment '最大牌型数值',
                                            maxwinchip int(11) NOT NULL DEFAULT '0' comment '最大赢取筹码',
                                            exp_value int(11) NOT NULL DEFAULT '0' comment '经验值',
                                            exp_level int(11) NOT NULL DEFAULT '0' comment '经验等级',
                                            name varchar(64) not null DEFAULT '0',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid) 
                                        )engine = InnoDB, charset = utf8;
#创建玩家金币数据表 insert update
create table if not exists role_money(
                                        rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                        chips bigint unsigned not null DEFAULT '0' comment '金币',
                                        maxchips bigint unsigned not null DEFAULT '0' comment '历史最大金币',
                                        name varchar(64) not null DEFAULT '',
                                        update_time timestamp on update current_timestamp default current_timestamp,
                                        primary key(rid) 
                                    )engine = InnoDB, charset = utf8;
#创建玩家比赛报名信息表   insert delete
create table if not exists role_signupinfo(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            match_instance_id varchar(128) not null DEFAULT '' comment '比赛实例id',
                                            signupinfo varchar(512) not null DEFAULT '' comment '报名信息',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid, match_instance_id) 
                                        )engine = InnoDB, charset = utf8;
#玩家朋友桌战绩记录表    insert delete
create table if not exists role_friendtablerecords(
                                                    id int(11) NOT NULL  auto_increment comment '自增id',
                                                    rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                                    record varchar(4096) not null DEFAULT '' comment '牌桌战绩',
                                                    update_time timestamp on update current_timestamp default current_timestamp,
                                                    primary key(id)                         
                                                )engine = InnoDB, charset = utf8;
#玩家好友记录表   insert delete
create table if not exists role_friendinfo(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            friend_rid int(11) NOT NULL DEFAULT '0' comment '好友id',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid, friend_rid)             
                                        ) engine = InnoDB, charset = utf8;
#玩家群记录表    insert delete                                                                               
create table if not exists role_groupinfo(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            group_id int(11) NOT NULL DEFAULT '0' comment '群id',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid, group_id)
                                        ) engine = InnoDB, charset = utf8;
#玩家订单表 insert update
create table if not exists role_orderinfo(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            order_id varchar(32) not null DEFAULT '' comment '订单号',
                                            pid varchar(128) not null DEFAULT '' comment '',
                                            pay_type int(11) NOT NULL DEFAULT '0' comment '支付类型',
                                            price int(11) NOT NULL DEFAULT '0' comment '价格',
                                            good_id int(11) NOT NULL DEFAULT '0' comment '充值商品id',
                                            good_awards varchar(256) not null DEFAULT '' comment '充值商品奖励',
                                            create_time int(11) NOT NULL DEFAULT '0' comment '创建时间',
                                            state int(11) NOT NULL DEFAULT '0' comment '1生成订单，2支付成功，3发货成功',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(order_id)                                            
                                        ) engine = InnoDB, charset = utf8;
#玩家系统邮件表 insert delete
create table if not exists role_mailinfo(
                                            id int(4) not null auto_increment comment '自增id',
                                            rid int(11) not null comment '角色id',
                                            create_time int(4) not null DEFAULT '0' comment '创建时间',
                                            content varchar(1024) not null DEFAULT '' comment '邮件内容json格式',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(id)
                                        ) engine = InnoDB, charset = utf8;
#玩家的道具表 insert delete update
create table if not exists role_propinfo(
                                            prop_id int(4) not null comment '道具id',
                                            config_id int(4) not null comment '道具配置id',
                                            prop_num int(4) DEFAULT '0' comment '道具数量',
                                            use_time int(4) DEFAULT '0' comment '道具的使用截止时间',
                                            get_time int(4) DEFAULT '0' comment '获得道具的时间',
                                            last_time int(4) DEFAULT '0' comment '最近一次使用时间', 
                                            rid int(11) not null comment '角色id',
                                            max_id int(4) comment '最大的道具id',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid, prop_id)
                                        ) engine = InnoDB, charset = utf8;
#玩家的联系方式 insert update
create table if not exists role_contactinfo(
                                            id int(4) not null auto_increment comment '自增id', 
                                            rid int(11) not null comment '角色id',
                                            contactinfo varchar(1024) DEFAULT '',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(id, rid)
                                        ) engine = InnoDB, charset = utf8;
#玩家进朋友桌携带锁定的筹码
create table if not exists role_fixedchipsinfo(
                                            rid int(11) not null comment '角色id',
                                            fixed_chips bigint unsigned not null comment '锁定筹码',
                                            table_id  int(4) not null comment '朋友桌id',
                                            table_create_time int(11) not null comment '朋友桌创建时间',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid, table_id, table_create_time)
                                        ) engine = InnoDB, charset = utf8;

#玩家累计生涯数据 insert update select
create table if not exists role_totalcareer(
                                            rid int(11) not null DEFAULT 0 comment '角色id',
                                            hands bigint not null DEFAULT 0 comment '手数',
                                            winhands bigint not null DEFAULT 0 comment '获胜手数',
                                            bet bigint not null DEFAULT 0 comment '下注总数',
                                            raise bigint not null DEFAULT 0 comment '加注总数',
                                            callnum bigint not null DEFAULT 0 comment '跟注总数',
                                            threebet bigint not null DEFAULT 0 comment '再加注总数',
                                            winbb bigint not null DEFAULT 0 comment '每局赢的大盲注数',
                                            maxwinchip bigint not null DEFAULT 0 comment '最大赢取',
                                            maxcardform int(11) not null DEFAULT 0 comment '最大牌型值',
                                            maxformcards varchar(256) not null DEFAULT '' comment '最大牌型',
                                            winchip bigint not null DEFAULT 0 comment '总赢取量',
                                            vp bigint not null DEFAULT 0 comment '入局总数',
                                            round bigint not null DEFAULT 0 comment '总轮数',
                                            steal bigint not null DEFAULT 0 comment '偷盲数',
                                            winsteal bigint not null DEFAULT 0 comment '偷盲成功数',
                                            othersteal bigint not null DEFAULT 0 comment '有人偷盲次数',
                                            flodtosteal bigint not null DEFAULT 0 comment '面对偷盲弃牌', 
                                            flodtocontinebet bigint not null DEFAULT 0 comment '面对他人持续加注数',
                                            flop bigint not null DEFAULT 0 comment '翻牌圈次数',
                                            turn bigint not null DEFAULT 0 comment '转牌圈次数',
                                            river bigint not null DEFAULT 0 comment '河牌圈次数',
                                            preflopraise bigint not null DEFAULT 0 comment '摊牌前加注数',
                                            wenttoshowdown bigint not null DEFAULT 0 comment '摊牌数',
                                            winwenttoshowdown bigint not null DEFAULT 0 comment '摊牌胜利数',
                                            matchnum bigint not null DEFAULT 0 comment '比赛场次数',
                                            maxmatchrank bigint not null DEFAULT 0 comment '比赛最佳名次',
                                            mtt_hands bigint not null DEFAULT 0 comment "mtt手数",
                                            sng_hands bigint not null DEFAULT 0 comment "sng手数", 
                                            score_hands bigint not null DEFAULT 0 comment "积分赛手数",
                                            friend_hands bigint not null DEFAULT 0 comment "朋友桌手数",
                                            continuebet bigint not null DEFAULT 0 comment "持续加注数",
                                            othercontinuebet bigint not null DEFAULT 0 comment "面对他人持续加注数",
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid)
                                        ) engine = InnoDB, charset = utf8;

#玩家每日生涯数据 insert update select
create table if not exists role_career(
                                            rid int(11) not null DEFAULT 0 comment '角色id',
                                            create_time int(11) not null DEFAULT 0 comment '创建时间',
                                            hands bigint not null DEFAULT 0 comment '手数',
                                            winhands bigint not null DEFAULT 0 comment '获胜手数',
                                            bet bigint not null DEFAULT 0 comment '下注总数',
                                            raise bigint not null DEFAULT 0 comment '加注总数',
                                            callnum bigint not null DEFAULT 0 comment '跟注总数',
                                            threebet bigint not null DEFAULT 0 comment '再加注总数',
                                            winbb bigint not null DEFAULT 0 comment '每局赢的大盲注数',
                                            flashtime varchar(2048) not null DEFAULT '' comment '最大赢取牌局回放id', 
                                            maxwinchip bigint not null DEFAULT 0 comment '最大赢取',
                                            maxcardform int(11) not null DEFAULT 0 comment '最大牌型值',
                                            maxformcards varchar(256) not null DEFAULT '' comment '最大牌型',
                                            winchip bigint not null DEFAULT 0 comment '总赢取量',
                                            vp bigint not null DEFAULT 0 comment '入局总数',
                                            round bigint not null DEFAULT 0 comment '总轮数',
                                            steal bigint not null DEFAULT 0 comment '偷盲数',
                                            winsteal bigint not null DEFAULT 0 comment '偷盲成功数',
                                            othersteal bigint not null DEFAULT 0 comment '有人偷盲次数',
                                            flodtosteal bigint not null DEFAULT 0 comment '面对偷盲弃牌', 
                                            flodtocontinebet bigint not null DEFAULT 0 comment '面对他人持续加注数',
                                            flop bigint not null DEFAULT 0 comment '翻牌圈次数',
                                            turn bigint not null DEFAULT 0 comment '转牌圈次数',
                                            river bigint not null DEFAULT 0 comment '河牌圈次数',
                                            preflopraise bigint not null DEFAULT 0 comment '摊牌前加注数',
                                            wenttoshowdown bigint not null DEFAULT 0 comment '摊牌数',
                                            winwenttoshowdown bigint not null DEFAULT 0 comment '摊牌胜利数',
                                            matchnum bigint not null DEFAULT 0 comment '比赛场次数',
                                            maxmatchrank bigint not null DEFAULT 0 comment '比赛最佳名次',
                                            mtt_hands bigint not null DEFAULT 0 comment "mtt手数",
                                            sng_hands bigint not null DEFAULT 0 comment "sng手数", 
                                            score_hands bigint not null DEFAULT 0 comment "积分赛手数",
                                            friend_hands bigint not null DEFAULT 0 comment "朋友桌手数",
                                            continuebet bigint not null DEFAULT 0 comment "持续加注数",
                                            othercontinuebet bigint not null DEFAULT 0 comment "面对他人持续加注数",
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid, create_time)
                                        ) engine = InnoDB, charset = utf8;

#玩家当日生涯数据insert update select
create table if not exists role_samedaycareer(
                                            rid int(11) not null DEFAULT 0 comment '角色id',
                                            create_time int(11) not null DEFAULT 0 comment '创建时间',
                                            hands bigint not null DEFAULT 0 comment '手数',
                                            winhands bigint not null DEFAULT 0 comment '获胜手数',
                                            bet bigint not null DEFAULT 0 comment '下注总数',
                                            raise bigint not null DEFAULT 0 comment '加注总数',
                                            callnum bigint not null DEFAULT 0 comment '跟注总数',
                                            threebet bigint not null DEFAULT 0 comment '再加注总数',
                                            winbb bigint not null DEFAULT 0 comment '每局赢的大盲注数',
                                            flashtime varchar(2048) not null DEFAULT '' comment '最大赢取牌局回放id', 
                                            maxwinchip bigint not null DEFAULT 0 comment '最大赢取',
                                            maxcardform int(11) not null DEFAULT 0 comment '最大牌型值',
                                            maxformcards varchar(256) not null DEFAULT '' comment '最大牌型',
                                            winchip bigint not null DEFAULT 0 comment '总赢取量',
                                            vp bigint not null DEFAULT 0 comment '入局总数',
                                            round bigint not null DEFAULT 0 comment '总轮数',
                                            steal bigint not null DEFAULT 0 comment '偷盲数',
                                            winsteal bigint not null DEFAULT 0 comment '偷盲成功数',
                                            othersteal bigint not null DEFAULT 0 comment '有人偷盲次数',
                                            flodtosteal bigint not null DEFAULT 0 comment '面对偷盲弃牌', 
                                            flodtocontinebet bigint not null DEFAULT 0 comment '面对他人持续加注数',
                                            flop bigint not null DEFAULT 0 comment '翻牌圈次数',
                                            turn bigint not null DEFAULT 0 comment '转牌圈次数',
                                            river bigint not null DEFAULT 0 comment '河牌圈次数',
                                            preflopraise bigint not null DEFAULT 0 comment '摊牌前加注数',
                                            wenttoshowdown bigint not null DEFAULT 0 comment '摊牌数',
                                            winwenttoshowdown bigint not null DEFAULT 0 comment '摊牌胜利数',
                                            matchnum bigint not null DEFAULT 0 comment '比赛场次数',
                                            maxmatchrank bigint not null DEFAULT 0 comment '比赛最佳名次',
                                            mtt_hands bigint not null DEFAULT 0 comment "mtt手数",
                                            sng_hands bigint not null DEFAULT 0 comment "sng手数", 
                                            score_hands bigint not null DEFAULT 0 comment "积分赛手数",
                                            friend_hands bigint not null DEFAULT 0 comment "朋友桌手数",
                                            continuebet bigint not null DEFAULT 0 comment "持续加注数",
                                            othercontinuebet bigint not null DEFAULT 0 comment "面对他人持续加注数",
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid)
                                        ) engine = InnoDB, charset = utf8;

#玩家的里程碑数据 insert update select
create table if not exists role_milepostinfo(
                                            id int(4) not null auto_increment comment '自增id', 
                                            rid int(11) not null comment '角色id',
                                            type int(4) not null comment '数据类型',
                                            content varchar(256) DEFAULT '',
                                            create_time int(11) not null comment '记录创建时间',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(id, rid)
                                        ) engine = InnoDB, charset = utf8;

#玩家的累计数据 insert update select
create table if not exists role_cumulativeinfo(
                                            rid int(11) not null comment '角色id',
                                            content varchar(1024) DEFAULT '',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid)
                                        ) engine = InnoDB, charset = utf8;

