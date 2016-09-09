import tornado.web
import tornado.ioloop
import api
import sys
sys.path.append("../gm/")
import gmhttp

#错误处理
def write_error(self, status_code, **kwargs):
    self.render("error.html", error_code=status_code, error_reason=self._reason)
tornado.web.RequestHandler.write_error = write_error

@tornado.gen.coroutine
def runsh(shell):
    proc = tornado.process.Subprocess("cd ../../ && " + shell, shell=True,
        stdin=tornado.process.Subprocess.STREAM,
        stdout=tornado.process.Subprocess.STREAM,
        stderr=tornado.process.Subprocess.STREAM)
    output = yield [proc.stdout.read_until_close(), proc.stderr.read_until_close()]
    output = output[0].decode() + output[1].decode()
    
    status = proc.proc.wait()
    if status!=0:
        return api.response(False, message=output)

    data = {"output":output}
    return api.response(True, data)

@tornado.gen.coroutine
def gettime(shell):
    import time
    data = {"now":time.strftime('%Y-%m-%d %X', time.localtime() )}
    return api.response(True, data)

@tornado.gen.coroutine
def settime(nowtime):
    response = yield runsh("date -s " + repr(nowtime))
    return response
	
@tornado.gen.coroutine
def update_chips(arg):
    argstrs = arg.split(',')
    data = None
    if len(argstrs) == 2:
        result = gmhttp.do_gmcommand("send_mail", {"rid":argstrs[0],"content":'{"isattach":true,"des":"尊敬的玩家，现赠送您筹码。请您在邮件后注意查收。对您造成的不便，恳请您的谅解。","awards":[{"id":1,"num":'+ str(argstrs[1]) +'}]}'})
        print(type(result))
        if "success" in str(result):
            data = {"output":"操作完成！"}
        else:
            data = {"output":"操作失败！请检查rid和筹码！"}
    else:
        data = {"output":"参数错误！"}
    return api.response(True, data)

#首页
class Index(tornado.web.RequestHandler):
    def get(self):
        self.render("base.html")

    @tornado.gen.coroutine
    def post(self):
        action = self.get_argument("action", "")
        argument = self.get_argument("argument", "")

        actions = {"runsh":runsh, "gettime":gettime, "settime":settime, "update_chips":update_chips}
        if action in actions:
            response = yield actions[action](argument)
        else:
            response = api.response(False, message="尚未支持的命令")
        return self.write(response)

settings = {
    'debug':True,
    # 'autoreload':True,

    #cookie_secret可通过运行key.py生成
    # 'cookie_secret':"wRNrca9TR9WHnDi9zqT2oGb/lcxTFUD3j5vOVDTtml4=",
    # 'xsrf_cookies':True,

    'gzip': True,

    'static_path':"./static",
    'template_path':'./templates',

    # "login_url": "/login",

    # "ui_modules": uimodules,
}

# 路由
application = tornado.web.Application([
    (r"/", Index),
], **settings)

if __name__ == "__main__":
    application.listen(80)
    tornado.ioloop.IOLoop.current().start()