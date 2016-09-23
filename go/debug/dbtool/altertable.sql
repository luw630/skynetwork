use #DB#;

alter table role_mailinfo add mail_key varchar(30) not null default "" comment '邮件key';
