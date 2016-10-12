首先安装python3

yum install python3

如果不行就手动编译

先安装上zlib和openssl

yum install -y zlib-dev openssl-devel

如果不装会表现为pip不能用

wget https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tar.xz
tar xf Python-3.*
cd Python-3.*
./configure
make
make install

然后执行 pip3 install -r requirements.txt 即可安装所需依赖 或 pip3 install --index https://pypi.mirrors.ustc.edu.cn/simple/

运行主程序 python3 application.py