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

创建虚拟环境
virtualenv --no-site-packages upload

启用虚拟环境
cd upload
source bin/activate 或 Scripts\activate

安装所需依赖
pip install -r requirements.txt

其中requirements.txt由命令生成
pip freeze > requirements.txt

退出虚拟环境
deactivate 或 Scripts\deactivate

使用方式，注意这个python是虚拟环境里面的
python upload.py -a "wYxyiNNfatKZJUyjTwOBQJwC_ovx3kag_DOcxIuy" -s "BAlBSj2L9pN4z2MWunlGCWacIbcVp5T1FN8ll5Qa"
    -b "test" -c -p "/root/game/texasgame/shujunjie/msgsvrd/msgpersistent/2016_04_03"

-a 指定access_key
-s 指定secret_key
-b 指定bucket

-f 进行异步上传
-c 使用zlib压缩
-p 需要上传的文件或目录
-n 没有-p时从读取控制台输入数据，指定上传名称
