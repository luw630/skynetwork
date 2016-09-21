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
                                          rolename varchar(128) not null DEFAULT '' comment '角色名称',
                                          logo varchar(512) not null DEFAULT '' comment 'logo url',
                                          country varchar(128) not null DEFAULT '' comment '国家',
                                          province varchar(128) not null DEFAULT '' comment '省',
                                          phone varchar(24) not null DEFAULT '' comment '手机号',
                                          sex int(11) NOT NULL DEFAULT '0' comment '性别',
                                          update_time timestamp on update current_timestamp default current_timestamp,
                                          primary key(rid) 
                                    )engine = InnoDB, charset = utf8;
#创建玩家玩棋数据表    insert update                                                                                       
create table if not exists role_playgame(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            level int(11) NOT NULL DEFAULT '0' comment '级位',   
                                            dan int(11) NOT NULL DEFAULT '0' comment '段位',     
                                            winnum int(11) NOT NULL DEFAULT '0' comment '胜局', 
                                            losenum int(11) NOT NULL DEFAULT '0' comment '败局', 
                                            drawnum int(11) NOT NULL DEFAULT '0' comment '和局', 
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid) 
                                        )engine = InnoDB, charset = utf8;
#创建玩家金币数据表 insert update
create table if not exists role_money(
                                        rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                        chips bigint unsigned not null DEFAULT '0' comment '金币',
                                        maxchips bigint unsigned not null DEFAULT '0' comment '历史最大金币',
                                        update_time timestamp on update current_timestamp default current_timestamp,
                                        primary key(rid) 
                                    )engine = InnoDB, charset = utf8;

#创建玩家在线数据表    insert update                                                                                       
create table if not exists role_online(
                                            rid int(11) NOT NULL DEFAULT '0' comment '角色id',
                                            activetime int(11) NOT NULL DEFAULT '0', 
                                            onlinetime int(11) NOT NULL DEFAULT '0' comment '上线时间',
                                            roomsvr_id varchar(126) NOT NULL DEFAULT '',
                                            roomsvr_table_id int(11) NOT NULL DEFAULT '0',
                                            roomsvr_table_address int(11) NOT NULL DEFAULT '0',
                                            gatesvr_ip varchar(64) NOT NULL DEFAULT '',
                                            gatesvr_port int(11) NOT NULL DEFAULT '0',
                                            gatesvr_id varchar(126) NOT NULL DEFAULT '',
                                            gatesvr_service_address int(11) NOT NULL DEFAULT '0',
                                            update_time timestamp on update current_timestamp default current_timestamp,
                                            primary key(rid) 
                                        )engine = InnoDB, charset = utf8;
