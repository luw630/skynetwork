create database if not exists #DB#;
use #DB#;
set names utf8;
#创建群信息表 insert update
create table if not exists group_info(
                                        id int(11) NOT NULL DEFAULT '0' comment '群id',
                                        name varchar(128) not null DEFAULT '' comment '群名称',
                                        logo varchar(256) not null DEFAULT '' comment '群logo',
                                        province varchar(128) not null DEFAULT '' comment '省份',
                                        city varchar(128) not null DEFAULT '' comment '城市',
                                        des varchar(1024) not null DEFAULT '' comment '群描述',
                                        create_rid int(11) NOT NULL DEFAULT '0' comment '群创建者',
                                        create_time int(11) NOT NULL DEFAULT '0' comment '创建时间',
                                        create_rolename varchar(128) not null DEFAULT '' comment '创建者昵称',
                                        create_logo varchar(256) not null DEFAULT '' comment '创建者头像',                                        
                                        max_player_num int(11) NOT NULL DEFAULT '0' comment '最大成员数',
                                        server_id varchar(32) not null DEFAULT '' comment '服务器id',
                                        onlinenum int(11) NOT NULL DEFAULT '0' comment '填充字段无具体意义',
                                        totalnum int(11) NOT NULL DEFAULT '0' comment '填充字段无具体意义',
                                        update_time timestamp on update current_timestamp default current_timestamp comment '创建时间',                                        
                                        primary key(id)
                                    )engine = InnoDB, charset = utf8;
#创建群成员表 insert delete
create table if not exists  group_players(
                                        id int(11) NOT NULL DEFAULT '0' comment '群id',
                                        rid int(11) NOT NULL DEFAULT '0' comment '玩家id',
                                        update_time timestamp on update current_timestamp default current_timestamp comment '创建时间',                                        
                                        primary key(id, rid)
                                    )engine = InnoDB, charset = utf8;
