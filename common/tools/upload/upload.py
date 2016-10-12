import os
import sys
import getopt
import zlib

from qiniu import Auth, put_data

# 命令行参数
options = {}

# 上传到七牛，
def upload_qiniu(name, data):
    auth = Auth(options["-a"], options["-s"])
    token = auth.upload_token(options["-b"])

    # 压缩文件
    if "-c" in options:
        data = zlib.compress(data)

    ret, info = put_data(token, name, data)
    if ret is None:
        raise Exception(info)

# 获取文件内容
def get_filedata(path):
    with open(path, "rb") as f:
        return f.read()

# 上传文件
def upload_file(name, path):
    data = get_filedata(path)
    upload_qiniu(name, data)

# 上传文件夹
def upload_directory(directory):
    basename = os.path.basename(directory)
    for parent,dirnames,filenames in os.walk(directory):
        for filename in filenames:
            path = os.path.join(parent, filename)
            name = os.path.join(basename, filename)
            upload_file(path, name)

            # 上传一个文件后进行内存回收
            import gc
            gc.collect()

# 上传文件夹或文件
def path_upload(path):
    path = os.path.normpath(path)
    if os.path.isdir(path):
        upload_directory(path)
    elif os.path.isfile(path):
        upload_file(path, os.path.basename(path))

# 判断上传
def upload():
    if "-p" in options:
        # 上传路径
        path_upload(options["-p"])
    else:
        data = ""
        try:
            data = raw_input()
        except Exception as e:
            data = input()
        upload_qiniu(options["-n"], data)


if __name__ == '__main__':
    # 解析命令行参数
    optlist, args = getopt.getopt(sys.argv[1:], "fca:s:b:p:n:")
    for name, value in optlist:
        options.update({name:value})
    
    if "-f" in options:
        pid = os.fork()
        if pid==0:
            upload()
    else:
        try:
            upload()
            sys.exit(0)
        except Exception as e:
            sys.exit(1)
