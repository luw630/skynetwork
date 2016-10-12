#!/bin/env python3
#-*- coding: utf-8 -*-
import flup.server.fcgi as flups
from qiniu import Auth, put_data
from qiniu import set_default
import urllib.parse
import zlib
import logging
import os
import sys

# 获取文件内容
def get_filedata(path):
    with open(path, "rb") as f:
        return f.read()

# 上传文件
def upload_file(name, path, accesskey, secretkey, bucket):
    data = get_filedata(path)
    auth = Auth(accesskey, secretkey)
    token = auth.upload_token(bucket)
    # 压缩文件
    ret, info = put_data(token, name, data)
    if ret is None:
        return (False, info)
    return (True, "success")
# 上传文件夹
def upload_directory(directory, accesskey, secretkey, bucket):
    basename = os.path.basename(directory)
    for parent,dirnames,filenames in os.walk(directory):
        for filename in filenames:
            path = os.path.join(directory, filename)
            name = os.path.join(basename, filename)
            upload_file(name, path, accesskey, secretkey, bucket)
            # 上传一个文件后进行内存回收
            import gc
            gc.collect()
    return (True, "success")
# 上传文件夹或文件
def path_upload(logpath, accesskey, secretkey, bucket):
    logpath = os.path.normpath(logpath)
    if os.path.isdir(logpath):
        return upload_directory(logpath, accesskey, secretkey, bucket)
    elif os.path.isfile(logpath):
        return upload_file(logpath, os.path.basename(logpath), accesskey, secretkey, bucket)
    else:
        return (True, "success")    
# 上传数据到云存储
def data_upload(data, name, accesskey, secretkey, bucket):
    auth = Auth(accesskey, secretkey)
    token = auth.upload_token(bucket)
    # 压缩文件
    if 'compress' in params:
        data = zlib.compress(data)
    ret, info = put_data(token, name, data)
    if ret is None:
        return (False, info)
    return (True, "success")

# 上传到七牛，
def upload_qiniu(params):
    #logging.debug("upload_qiniu-----------", params)
    data = params["data"][0]
    name = params["name"][0]
    accesskey = params["accesskey"][0]
    secretkey = params["secretkey"][0]
    bucket = params["bucket"][0]
    logpath = params["logpath"][0]

    if data is None or name is None or accesskey is None or logpath is None:
        return (False, "invalid request")
    if secretkey is None or bucket is None:
        return (False, "invalid request")
    if logpath == "no":
        return data_upload(data, name, accesskey, secretkey, bucket)
    else:
        return path_upload(logpath, accesskey, secretkey, bucket)

def get_params(environ):
    #query_string = environ["QUERY_STRING"]
    #logging.debug("get_params------------", query_string)
    content_length = int(environ["CONTENT_LENGTH"])
    query_string = environ["wsgi.input"].read(content_length).decode()  
    if query_string is None or query_string == "" :
        return (False, "invalid request")
    #query_string = urllib.parse.unquote(query_string)    
    return (True, urllib.parse.parse_qs(query_string))

def get_environ(environ):
    request_method = environ["REQUEST_METHOD"]
    str = "request_method:"+request_method+"\r\n"
    query_string = environ["QUERY_STRING"]
    str += ", query_string:"+query_string+"\r\n"
    #script_filename = environ["SCRIPT_FILENAME"]
    #str += "script_filename:"+script_filename + "\r\n"
    script_name = environ["SCRIPT_NAME"]
    str += ",script_name:" + script_name + "\r\n"  
    rquest_uri = environ["REQUEST_URI"]  
    str += ", rquest_uri:" + rquest_uri + "\r\n"  
    remote_addr = environ["REMOTE_ADDR"]  
    str += ",remote_addr:" + remote_addr + "\r\n"  
    remote_port = environ["REMOTE_PORT"]  
    str += ",remote_port:" + remote_port + "\r\n"  
    data = environ["wsgi.input"].read()  
    str += ", data:" + data + "\r\n"  
    return str      
    


def application(environ, start_response):    
    #logging.basicConfig(level=logging.DEBUG,  
    #                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',  
    #                datefmt='%a, %d %b %Y %H:%M:%S',  
    #                filename='/tmp/test.log',  
    #                filemode='w')
    start_response('200 OK', [('Content-Type', 'text/plain')])
    (ret, params) = get_params(environ)
    #logging.debug("application------------", params)
    if not ret:
        return ["failed"]
    (ret, status) = upload_qiniu(params)
    #content = get_environ(environ)
    return [status]

if __name__ == "__main__":
    set_default(connection_pool=30)
    #flups.WSGIServer(application, multithreaded=True, multiprocess=False, bindAddress=('127.0.0.1, 21000')).run()
    flups.WSGIServer(application).run()



