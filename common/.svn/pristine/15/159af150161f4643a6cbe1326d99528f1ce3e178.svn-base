================================================================
安装python3
yum install -y zlib-dev openssl-devel
wget https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tar.xz
tar xf Python-3.*
cd Python-3.*
./configure
make
make install
================================================================
为了隔离项目的第三方依赖，首先安装virtualenv
pip3 install virtualenv

安装所需依赖
pip3 install -r requirements.txt
(其中requirements.txt由命令生成pip3 freeze > requirements.txt)

将flup3-master.zip和spawn-fcgi-1.6.4.gz上传到部署服务器
安装部署
unzip flup3-master.zip
cd flup3-master
python3 ./setup.py build
python3 ./setup.py install

tar -zxvf spawn-fcgi-1.6.4.tar.gz
cd spawn-fcgi-1.6.4
./configure
make && make install

安装nginx（nginx开启fastcgi）
配置nginx.conf
==================================================
user nobody;

keepalive_timeout  600;
fastcgi_connect_timeout 600;
fastcgi_read_timeout 300;
fastcgi_send_timeout 300;

server {
	listen 20000;
	location ~\.cgi$ {
		fastcgi_pass 127.0.0.1:21000;
		fastcgi_index index.cgi;		
		include fastcgi_params;
	}
}
==================================================
说明：
1.recordsvrd/config_cfgcenter下的proxy_port和nginx的fastcgi
端口对应，proxy_ip是nginx的服务器访问ip
2.fastcgi location中的参数可以参看fastcgi配置

在nginx的conf目录下创建cgi-bin目录， 将spawn_python_cgi.py放入
其中, 最后修改spawn_python_cgi.py放入并执行chmod a+x ./spawn_python_cgi.py

启动cgi运行服务器
spawn-fcgi  -d /xxx/cgi-bin -f /xxx/cgi-bin/spawn_python_cgi.py  -a 127.0.0.1 -p 21000 -u nobody -F 5
参数说明： -a 指定服务器ip -p 指定监听端口（和nginx中fastcgi_pass对应） -u 指定访问用户（和nginx中nobody对应） -F 指定启动的进程数


注意：spawn-fcgi在提交目录中文件时， 一定要让spawn-fcgi进程目录有x权限，文件有r权限


