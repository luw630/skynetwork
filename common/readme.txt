-----------------工程介绍--------------------------------
这里是是基于skynet框架的服务端程序,目录说明如下:
1. skynetpatch,   对skynet的websocket的扩展。
2. tools, gm工具、简单web操作后台、mongo业务流水日志导出工具、upload上传python的脚本、uploadcgi上传数据到七牛云存储的数据的python fast-cgi
3. service, 一些公共的skynet工具服务
4. core,  一些公用的工具接口
5. ddz,  项目
-----------------工程构建部署-----------------------------
1.需要linux os, 并安装gcc/g++相关库、make工具、git
2.需要数据库redis(版本2.8以上)、mongo(版本3.0以上)、mysql（root账号不设置密码）
3.配置完系统环境后执行 build.sh 即可完成构建skynet运行环境
 



			