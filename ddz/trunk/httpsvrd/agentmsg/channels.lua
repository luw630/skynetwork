-- 定义所有第三方渠道信息及帐号认证、支付回调处理接口

module(..., package.seeall)

local HTTP_RESP_FORMAT =
"HTTP/1.1 200 OK\r\n".."Content-Length: %d\r\n"..
"Content-Type: application/json\r\n".."Connection: keep-alive\r\n".."\r\n%s"

local HTTP_CALLBACK_URL = "http://3rdapi.ximigame.net"
----小米渠道-------------------------------------------------
function DoXiaoMiAccAuth(self, gametype, uid, token)
    local util = require("util")

    if self == nil or self.appid == nil or self.key == nil then
        return nil
    end

    local sigstr = "appId="..self.appid.."&session="..token.."&uid="..uid
    local digest = util.HMAC(sigstr, self.key)
    if digest == nil then
        util.LogErr("calc digest for xiaomi acc auth failed: "..sigstr)
        return nil
    end

    local res = self.acc.."?"..sigstr.."&signature="..digest
    return res
end

function ReplyXiaoMiAccAuth(self, retcode)
    local util = require("util")
    local json = require("json")
    local ret = json.decode(retcode)

    if ret == nil or ret.errcode == nil then
        util.LogErr("Invalid xiaomi acc auth response: "..retcode)
        return -1
    end

    if tonumber(ret.errcode) == 200 then
        return 0
    else
        return -1
    end
end

function DoXiaoMiPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    local value = util.FindValueOfKey(params, "cpUserInfo")
    if value == nil then
        util.LogErr("*** xiaomi: can't find cpUserInfo")
        return errret
    end

    local payinfo = util.ParseUserInfo(value)
    if payinfo == nil then
        util.LogErr("*** xiaomi: can't parse json, "..value)
        return errret
    end

	payinfo.id = self.id

    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** xiaomi: can't find appinfo")
        return errret
    end

    value = util.FindValueOfKey(params, "appId")
    if value == nil or value ~= self.appid then
        util.LogErr("*** xiaomi: can't find appId")
        return errret
    end

    value = util.FindValueOfKey(params, "cpOrderId")
    if value == nil or value ~= payinfo.orderid then
        util.LogErr("*** xiaomi: can't find cpOrderId")
        return errret
    end

    value = util.FindValueOfKey(params, "orderStatus")
    if value == nil or value ~= "TRADE_SUCCESS" then
        util.LogErr("*** xiaomi: can't find orderStatus")
        return errret
    end

    value = util.FindValueOfKey(params, "signature")
    if value == nil then
        util.LogErr("*** xiaomi: can't find signature")
        return errret
    end

    local _, _, sigstr = string.find(params, "(.-)&signature=")
    if sigstr == nil then
        return errret
    end
    local digest = util.HMAC(sigstr, self.key)
    if digest ~= value then
        util.LogErr("unmatched signature, given:"..value.." calculated:"..digest)
        return errret
    end

    return util.PayRet(0, payinfo)
end

--小米手机
function DoXiaoMiPhonePay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    local orderid = util.FindValueOfKey(params, "cpUserInfo")
    if orderid == nil then
        util.LogErr("*** xiaomi: can't find cpUserInfo")
        return errret
    end

    local payinfo = {}
    payinfo.id = self.id
    payinfo.orderid = orderid
    payinfo.price = 0

    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** xiaomi: can't find appinfo")
        return errret
    end

    local value = util.FindValueOfKey(params, "appId")
    if value == nil or value ~= self.appid then
        util.LogErr("*** xiaomiPhone: can't find appId")
        return errret
    end

    value = util.FindValueOfKey(params, "cpOrderId")
    if value == nil or value ~= payinfo.orderid then
        util.LogErr("*** xiaomi: can't find cpOrderId")
        return errret
    end

    value = util.FindValueOfKey(params, "orderStatus")
    if value == nil or value ~= "TRADE_SUCCESS" then
        util.LogErr("*** xiaomi: can't find orderStatus")
        return errret
    end

    value = util.FindValueOfKey(params, "signature")
    if value == nil then
        util.LogErr("*** xiaomi: can't find signature")
        return errret
    end

    local _, _, sigstr = string.find(params, "(.-)&signature=")
    if sigstr == nil then
        return errret
    end
    local digest = util.HMAC(sigstr, self.key)
    if digest ~= value then
        util.LogErr("unmatched signature, given:"..value.." calculated:"..digest)
        return errret
    end

	util.LogInfo(" ===>xiaomiPhone RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    return util.PayRet(0, payinfo)
end

function ReplyXiaoMiPay(self, errcode, channelinfo)
    local util = require("util")
    local respfmt = "{\"errcode\":%d}"
    local res = nil

    if errcode == 0 then
        res = string.format(respfmt, 200)
    else
        res = string.format(respfmt, 1506)
    end
    return string.format(HTTP_RESP_FORMAT, string.len(res), res)
end

--------------------------------------------------------------

----手机短信网关----------------------------------------------
function DoPhoneTextGWAuth(self, gametype, uid, token)
    local util = require("util")
    local curl = require("curl")
    local verifyCodeMsg =
            "您的验证码是："..token.."，有效时间为三十分钟，如果您未曾申请过本服务请忽略该短信，谢谢。"
    local signature = "西米科技"

    local sigstr = "content="..curl.escape(verifyCodeMsg).."&key="..self.key..
                "&mobile="..uid.."&sig="..curl.escape(signature)
    local digest = util.MD5(sigstr)
    if digest == nil then
        util.LogErr("calc digest for phone gw failed. "..sigstr)
        return nil
    end

    local res = self.acc.."mobile="..uid.."&content="..verifyCodeMsg..
            "&sig="..signature.."&sec="..digest

    return res
end

function ReplyPhoneTextGWAuth(self, retcode)
    local util = require("util")
    local json = require("json")
    local ret = json.decode(retcode)

    if ret == nil or ret.code == nil then
        util.LogErr("Invalid phone gw response: "..retcode)
        return -1
    end

    if tonumber(ret.code) == 0 then
        return 0
    else
        return -1
    end
end

function DoLeTVPay(self, params)
    local util = require("util")
    local curl = require("curl")
    local errret = util.PayRet(-1, nil)

    local currencyCode = util.FindValueOfKey(params, "currencyCode")
    if currencyCode == nil then
        util.LogErr("*** letv: can't find currencycode")
        return errret
    end

    local price = util.FindValueOfKey(params, "price")
    if price == nil then
        util.LogErr("*** letv: can't find price")
        return errret
    end

    local products = util.FindValueOfKey(params, "products")
    if products == nil then
        util.LogErr("*** letv: can't find products")
        return errret
    end

    local pxNumber = util.FindValueOfKey(params, "pxNumber")
    if pxNumber == nil then
        util.LogErr("*** letv: can't find pxNumber")
        return errret
    end

    local appKey = util.FindValueOfKey(params, "appKey")
    if appKey == nil then
        util.LogErr("*** letv: can't find appKey")
        return errret
    end

    local userName = util.FindValueOfKey(params, "userName")
    if userName == nil then
        util.LogErr("*** letv: can't find userName")
        return errret
    end

    local userInfo = util.FindValueOfKey(params, "params")
    if userInfo == nil then
        util.LogErr("*** letv: can't find params")
        return errret
    end

    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** letv: can't find appinfo")
        return errret
    end

    local payinfo = {}
    payinfo.id = self.id
    payinfo.orderid = userInfo
    payinfo.price = price *100
    
	util.LogInfo(" ===>LeTV RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** letv: can't find sign")
        return errret
    end

    local sigstr = HTTP_CALLBACK_URL..self.url.."appKey="..appKey..
            "currencyCode="..currencyCode.."params="..userInfo.."price="..price..
            "products="..products.."pxNumber="..pxNumber.."userName="..userName..self.key
    local encoded = curl.escape(sigstr)
    local digest = util.MD5(encoded)
    if digest ~= sign then
        util.LogErr("unmatched signature, given:"..sign.." calculated:"..digest)
        return errret
    end

    return util.PayRet(0, payinfo)
end

function ReplyLeTVPay(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "SUCCESS"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end

-------------------------------------------------------------

---支付宝统一预下单接口-------------------------------------
function DoZhiFuBaoPay_Uniform(self, params)

    local errret = util.PayRet(-1, nil)
    util.LogInfo("ZhiFuBaoUniform params: "..self.url.."  "..params)

    require('LuaXml')
    local util = require("util")
	-------------------------------------------------------------------------
	----------------------------------- 基本参数 ----------------------------
    --解析notify_time 通知时间
    local notify_time = util.FindValueOfKey(params, "notify_time")
    if notify_time == nil then
        return errret
    end

    --解析notify_type 通知类型 
    local notify_type = util.FindValueOfKey(params, "notify_type")
    if notify_type == nil then
        return errret
    end

    --notify_id解析通知校验ID 
    local notify_id = util.FindValueOfKey(params, "notify_id")
    if notify_id == nil then
        return errret
    end

    --解析sign_type签名方式
    local sign_type = util.FindValueOfKey(params, "sign_type")
    if sign_type == nil then
        return errret
    end

    --解析sign_type签名方式
    local paytools_pay_amount = util.FindValueOfKey(params, "paytools_pay_amount")
    if paytools_pay_amount == nil then
        return errret
    end

    --解析sign 签名 
    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        return errret
    end
	
	----------------------------------------------------------------------
	--------------------------------业务参数------------------------------
    --解析out_trade_no 商户网站唯一订单号
    local out_trade_no = util.FindValueOfKey(params, "out_trade_no")
    if out_trade_no == nil then
        return errret
    end

	 --解析subject 商品名称 
    local subject = util.FindValueOfKey(params, "subject")
    if subject == nil then
        return errret
    end

    --解析trade_no 支付宝交易号
    local trade_no = util.FindValueOfKey(params, "trade_no")
    if trade_no == nil then
        return errret
    end

    --解析trade_status 交易状态 
    local trade_status = util.FindValueOfKey(params, "trade_status")
    if trade_status == nil then--or trade_status ~= "TRADE_SUCCESS" then
        return errret
    end

    --解析gmt_create 交易创建时间
    local gmt_create = util.FindValueOfKey(params, "gmt_create")
    if gmt_create == nil then
        return errret
    end

	--解析gmt_payment交易付款时间 
    local gmt_payment = util.FindValueOfKey(params, "gmt_payment")
    if gmt_payment == nil then
        return errret
    end

	--解析seller_email卖家支付宝账号
    local seller_email = util.FindValueOfKey(params, "seller_email")
    if seller_email == nil then
        return errret
    end

	--解析buyer_email买家支付宝账号
    local buyer_email = util.FindValueOfKey(params, "buyer_email")
    if buyer_email == nil then
        return errret
    end

	--解析seller_id卖家支付宝用户号 
    local seller_id = util.FindValueOfKey(params, "seller_id")
    if seller_id == nil then
        return errret
    end

	--解析buyer_id买家支付宝账号
    local buyer_id = util.FindValueOfKey(params, "buyer_id")
    if buyer_id == nil then
        return errret
    end

	--解析price商品单价
    local price = util.FindValueOfKey(params, "price")
    if price == nil then
        return errret
    end

	--解析quantity购买数量 
    local quantity = util.FindValueOfKey(params, "quantity")
    if quantity == nil then
        return errret
    end

	--解析total_fee交易金额 
    local total_fee = util.FindValueOfKey(params, "total_fee")
    if total_fee == nil then
        return errret
    end

	--根据gametype取得key
    if self == nil or self.key == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find appinfo")
        return errret
    end

    -- 参数按照KEY=VALUE的方式排序如下：
    --1		body --客户端没传
    --2		buyer_email
    --3		buyer_id
    --4		gmt_create
    --5		gmt_payment
    --6		notify_id
    --7		notify_time
    --8		notify_type
    --9		out_trade_no
    --10	price
    --11	quantity
    --12	seller_email
    --13	seller_id
    --14	sign
    --15	sign_type
    --16	subject
    --17	total_fee
    --18	trade_no
    --19	trade_status

    --验证签名 签名字符串按照key0=value0&key1=value1&key2=value2MD5KEY然后用MD5加密
    local sigstr = "buyer_email="..buyer_email.."&buyer_id="..buyer_id.."&gmt_create="..gmt_create.."&gmt_payment="
        ..gmt_payment.."&notify_id="..notify_id.."&notify_time="..notify_time.."&notify_type="..notify_type
        .."&out_trade_no="..out_trade_no.."&paytools_pay_amount="..paytools_pay_amount.."&price="..price
        .."&quantity="..quantity.."&seller_email="..seller_email
        .."&seller_id="..seller_id.."&subject="..subject.."&total_fee="..total_fee
        .."&trade_no="..trade_no.."&trade_status="..trade_status..self.key

    util.LogInfo("@@@@@@@@@@@@@@@@@@@@@@@@ZhiFuBaoUniform sigstr = > "..sigstr.." sign => "..sign)
    local sigvalue = util.MD5(sigstr)
    if sigvalue ~= sign then
        util.LogErr("*** ZhiFuBaoUniform: unmatched signature, given:"..sign.." calculated:"..sigvalue)
        return errret
    end

    util.LogInfo("*** Congratulations ZhiFuBaoUniform Check Passed ***")

    if trade_status == "WAIT_BUYER_PAY"  or trade_status == "TRADE_FINISHED" then
        local res = string.format(HTTP_RESP_FORMAT, string.len("success"), "success")
        local payinfo = {}
        payinfo.res = res
        return util.PayRet(1000, payinfo)
    end

    if trade_status == "TRADE_SUCCESS" then
        --解析透传信息
        local payinfo = {}
        payinfo.orderid = out_trade_no
        payinfo.price = price * 100
        payinfo.id = self.id

        util.LogInfo(" ===>ZhiFuBaoUniform RetPayInfo: payinfo.orderid:"..payinfo.orderid)

        return util.PayRet (0, payinfo)
    end

    return errret
end

function ReplyZhiFuBaoPay_Uniform(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "success"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end

-------------------------------------------------------------

---支付宝统一预下单接口-------------------------------------
function DoZhiFuBaoPay_Ph(self, params)

    local errret = util.PayRet(-1, nil)
    local util = require("util")
    -------------------------------------------------------------------------
    ----------------------------------- 基本参数 -------------------------- --
    --解析notify_time 通知时间
    local notify_time = util.FindValueOfKey(params, "notify_time")
    if notify_time == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find notify_time")
        return errret
    end

    --解析notify_type 通知类型 
    local notify_type = util.FindValueOfKey(params, "notify_type")
    if notify_type == nil then      
        util.LogErr("*** ZhiFuBaoUniform: can't find notify_type")
        return errret
    end

    --notify_id解析通知校验ID 
    local notify_id = util.FindValueOfKey(params, "notify_id")
    if notify_id == nil then      
        util.LogErr("*** ZhiFuBaoUniform: can't find notify_id")
        return errret
    end

    --解析sign_type签名方式
    local sign_type = util.FindValueOfKey(params, "sign_type")
    if sign_type == nil then     
        util.LogErr("*** ZhiFuBaoUniform: can't find sign_type")
        return errret
    end

    --解析sign 签名 
    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then        
        util.LogErr("*** ZhiFuBaoUniform: can't find sign")
        return errret
    end

    ----------------------------------------------------------------------
    --------------------------------业务参数------------------------------
    --解析out_trade_no 商户网站唯一订单号
    local out_trade_no = util.FindValueOfKey(params, "out_trade_no")
    if out_trade_no == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find out_trade_no")
        return errret
    end
    local discount = util.FindValueOfKey(params, "discount")
    if discount == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find discount")
        return errret
    end
    local payment_type = util.FindValueOfKey(params, "payment_type")
    if payment_type == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find payment_type")
        return errret
    end
    local body = util.FindValueOfKey(params, "body")
    if body == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find body")
        return errret
    end
    local is_total_fee_adjust = util.FindValueOfKey(params, "is_total_fee_adjust")
    if is_total_fee_adjust == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find is_total_fee_adjust")
        return errret
    end
    local use_coupon = util.FindValueOfKey(params, "use_coupon")
    if use_coupon == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find use_coupon")
        return errret
    end

     --解析subject 商品名称 
    local subject = util.FindValueOfKey(params, "subject")
    if subject == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find subject")
        return errret
    end

    --解析trade_no 支付宝交易号
    local trade_no = util.FindValueOfKey(params, "trade_no")
    if trade_no == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find trade_no")
        return errret
    end

    --解析trade_status 交易状态 
    local trade_status = util.FindValueOfKey(params, "trade_status")
    if trade_status == nil then--or trade_status ~= "TRADE_SUCCESS" then
        util.LogErr("*** ZhiFuBaoUniform: can't find trade_status")
        return errret
    end

    if trade_status == "WAIT_BUYER_PAY"  or trade_status == "TRADE_FINISHED" then
        local res = string.format(HTTP_RESP_FORMAT, string.len("success"), "success")
        local payinfo = {}
        payinfo.res = res
        return util.PayRet(1000, payinfo)
    end

    --解析gmt_create 交易创建时间
    local gmt_create = util.FindValueOfKey(params, "gmt_create")
    if gmt_create == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find gmt_create")
        return errret
    end

    --解析gmt_payment 交易创建时间
    local gmt_payment = util.FindValueOfKey(params, "gmt_payment")
    if gmt_payment == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find gmt_payment")
        return errret
    end

    --解析seller_email卖家支付宝账号
    local seller_email = util.FindValueOfKey(params, "seller_email")
    if seller_email == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find seller_email")
        return errret
    end

    --解析buyer_email买家支付宝账号
    local buyer_email = util.FindValueOfKey(params, "buyer_email")
    if buyer_email == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find buyer_email")
        return errret
    end

    --解析seller_id卖家支付宝用户号 
    local seller_id = util.FindValueOfKey(params, "seller_id")
    if seller_id == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find seller_id")
        return errret
    end

    --解析buyer_id买家支付宝账号
    local buyer_id = util.FindValueOfKey(params, "buyer_id")
    if buyer_id == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find buyer_id")
        return errret
    end

    --解析price商品单价
    local price = util.FindValueOfKey(params, "price")
    if price == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find price")
        return errret
    end

    --解析quantity购买数量 
    local quantity = util.FindValueOfKey(params, "quantity")
    if quantity == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find quantity")
        return errret
    end

    --解析total_fee交易金额 
    local total_fee = util.FindValueOfKey(params, "total_fee")
    if total_fee == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find total_fee")
        return errret
    end

    --根据gametype取得key
    if self == nil or self.publickey == nil then
        util.LogErr("*** ZhiFuBaoUniform: can't find appinfo")
        return errret
    end

    -- 参数按照KEY=VALUE的方式排序如下：
    --&body=Cocktail * 1
    --&buyer_email=wct511@126.com
    --&buyer_id=2088102650142454
    --&discount=0.00
    --&gmt_create=2015-07-27 19:12:20
    --&gmt_payment=2015-07-27 19:12:21
    --&is_total_fee_adjust=N
    --&notify_id=3b461a65c9cc9973a4b4f0e78e946eb84i
    --&notify_time=2015-07-27 19:26:59
    --&notify_type=trade_status_sync
    --&out_trade_no=072719120917694
    --&payment_type=8
    --&price=0.01
    --&quantity=1
    --&seller_email=ximipay1@ximigame.com
    --&seller_id=2088511815999910
    --&subject=Cocktail
    --&total_fee=0.01
    --&trade_no=2015072700001000450060986061
    --&trade_status=TRADE_SUCCESS
    --&use_coupon=N

    --验证签名 签名字符串按照key0=value0&key1=value1&key2=value2MD5KEY然后用MD5加密
    local sigstr = "body="..body.."&buyer_email="..buyer_email.."&buyer_id="..buyer_id.."&discount="..discount..
        "&gmt_create="..gmt_create.."&gmt_payment="..gmt_payment.."&is_total_fee_adjust="..is_total_fee_adjust..
        "&notify_id="..notify_id.."&notify_time="..notify_time.."&notify_type="..notify_type..
        "&out_trade_no="..out_trade_no.."&payment_type="..payment_type.."&price="..price.."&quantity="..quantity..
        "&seller_email="..seller_email.."&seller_id="..seller_id.."&subject="..subject..
        "&total_fee="..total_fee.."&trade_no="..trade_no.."&trade_status="..trade_status..
        "&use_coupon="..use_coupon

    util.LogInfo("@@@@@@@@@@@@@@@@@@@@@@@@ZhiFuBaoUniform sigstr = > "..sigstr.." sign => "..sign)

    ---验证签名

    sign = string.gsub(sign, ' ', '+')
    local sign_result = util.RSASignVerify(self.publickey, sigstr, sign)
    if sign_result ~= true then 
        util.LogErr("zhifubao ph sign failed...")
        return errret
    end

    util.LogInfo("*** Congratulations ZhiFuBaoUniform Check Passed ***")

    if trade_status == "TRADE_SUCCESS" then
        --解析透传信息
        local payinfo = {}
        payinfo.orderid = out_trade_no
        payinfo.price = price * 100
        payinfo.id = self.id

        util.LogInfo(" ===>ZhiFuBaoUniform RetPayInfo: payinfo.orderid:"..payinfo.orderid)

        return util.PayRet (0, payinfo)
    end

    return errret
end

function ReplyZhiFuBaoPay_Ph(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "success"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end

-------------------------------------------------------------
------------------------ 网讯渠道 ---------------------------
function DoWangXunTVPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo("WangXun ===> params: "..params)

    --POST方式返回, 详情参考官方SDK文档
    --参数如下：
    -- localOrderNo 开发者本地记录的订单号码
    -- merchantNo 商户记录的订单号
    -- payStatus 支付是否成功的状态（2 表示成功，1表示失败）
    -- payMoney 支付的金额
    -- md5Str 加密验证 （localOrderNo|merchantNo|payStatus）需要将这几个参数以 '|'连接加密，如果为空则用""字符串表示    
    -- commodity 购买商品的名称 --这个不是必要的
    -- comcount 购买商品的数量
    -- comprice 购买商品的单价

	--解析回传参数信息, 商户记录的订单号，利用这个字段来透传
    local merchantNo = util.FindValueOfKey(params, "merchantNo")
    if merchantNo == nil then
        util.LogErr("*** WangXun: can't find merchantNo")
        return errret
    end

	--解析开发者本地记录的订单号码
	local localOrderNo = util.FindValueOfKey(params, "localOrderNo")
    if localOrderNo == nil then
        util.LogErr("*** WangXun: can't find localOrderNo")
        return errret
    end

	--解析支付状态，2表示成功， 1表示失败
	local payStatus = util.FindValueOfKey(params, "payStatus")
    if payStatus == nil or payStatus ~= "2" then
        util.LogErr("*** WangXun: can't find payStatus or pay failed !!!")
        return errret
    end

	--解析支付的金额
	local payMoney = util.FindValueOfKey(params, "payMoney")
    if payMoney == nil then
        util.LogErr("*** WangXun: can't find payMoney !!!")
        return errret
    end

	--解析md5Str
	local md5Str = util.FindValueOfKey(params, "md5Str")
    if md5Str == nil then
        util.LogErr("*** WangXun: can't find md5Str !!!")
        return errret
    end

    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** WangXun: can't find appinfo")
        return errret
    end

	--解析透传信息
    local payinfo = {}
    payinfo.orderid = merchantNo
    payinfo.id = self.id
    payinfo.price = payMoney

	util.LogInfo(" ===>WangXun RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    --验证签名
    local sigstr = ""..localOrderNo.."|"..merchantNo.."|"..payStatus
    util.LogInfo("WangXun [ NOT MD5 KEY ]sigstr => "..sigstr.." md5Str=> "..md5Str)
    local sigvalue = util.MD5(sigstr)
    if sigvalue ~= md5Str then
        util.LogErr("*** WangXun: unmatched signature, given:"..md5Str.." calculated:"..sigvalue)
        --return errret
    end

    util.LogInfo("*** Congratulations Wang Xun Check Passed ***")
	-- 还剩下商品名称，商品数量，商品单价可以不用验证...

    --返回订单结果
    return util.PayRet (0, payinfo)
end

function ReplyWangXunTVPay(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "true"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end
-------------------------------------------------------------

------------------------ 欢付宝 -----------------------------
function DoHuanFuBaoTVPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

	util.LogInfo("HuanFuBao ===> params: "..params)

     --POST方式返回, 详情参考官方SDK文档
    --参数如下：
    -- respCode 返回码 => 00:交易成功；01:失败 
    -- respInfo 返回信息 => 返回码为00以外的情况，返回错误信息
    -- orderNum 订单号 => 本系统生成的订单号码 
    -- productName 产品名称 => 产品名称，多个产品以"|"（半角）分割。
    -- productCount 产品数量 => 产品数量，多个产品以"|"（半角）分割，与产品名称对应。 
    -- productPrice 产品价格 => 以分为单位，多个产品以"|"  （半角）分割，与产品名称对应。例：1000代表10元 
    -- appSerialNo 商户订单号 => 调用支付接口时传入的商户订单号
    -- createOrderTime 订单创建时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。 
	-- transDate 支付订单付款完成时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。
	-- extension 扩展域
	-- sign 签名字符串 => 

	--解析回传参数信息, 扩展域，利用这个字段来透传
    local extension = util.FindValueOfKey(params, "extension")
    if extension == nil then
        util.LogErr("*** HuanFuBao: can't find extension")
        return errret
    end

	--解析返回码 => 00:交易成功；01:失败
	local respCode = util.FindValueOfKey(params, "respCode")
    if respCode == nil or respCode ~= "00" then
        util.LogErr("*** HuanFuBao: can't find respCode or pay failed !!!")
        return errret
    end

	--解析返回信息 => 返回码为00以外的情况，返回错误信息
	local respInfo = util.FindValueOfKey(params, "respInfo")
    if respInfo == nil then
        util.LogErr("*** HuanFuBao: can't find respInfo !!!")
        return errret
    end

	--解析orderNum 订单号 => 本系统生成的订单号码 
	local orderNum = util.FindValueOfKey(params, "orderNum")
    if orderNum == nil then
        util.LogErr("*** HuanFuBao: can't find orderNum !!!")
        return errret
    end

    -- productName 产品名称 => 产品名称，多个产品以"|"（半角）分割。
	local productName = util.FindValueOfKey(params, "productName")
    if productName == nil then
        util.LogErr("*** HuanFuBao: can't find productName !!!")
        return errret
    end

    -- productCount 产品数量 => 产品数量，多个产品以"|"（半角）分割，与产品名称对应。
	local productCount = util.FindValueOfKey(params, "productCount")
    if productCount == nil then
        util.LogErr("*** HuanFuBao: can't find productCount !!!")
        return errret
    end

	-- productPrice 产品价格 => 以分为单位，多个产品以"|"  （半角）分割，与产品名称对应。例：1000代表10元 
	local productPrice = util.FindValueOfKey(params, "productPrice")
    if productPrice == nil then
        util.LogErr("*** HuanFuBao: can't find productPrice !!!")
        return errret
    end

    -- appSerialNo 商户订单号 => 调用支付接口时传入的商户订单号
	local appSerialNo = util.FindValueOfKey(params, "appSerialNo")
    if appSerialNo == nil then
        util.LogErr("*** HuanFuBao: can't find appSerialNo !!!")
        return errret
    end

    -- createOrderTime 订单创建时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。 
	local createOrderTime = util.FindValueOfKey(params, "createOrderTime")
    if createOrderTime == nil then
        util.LogErr("*** HuanFuBao: can't find createOrderTime !!!")
        return errret
    end

	-- transDate 支付订单付款完成时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。
	local transDate = util.FindValueOfKey(params, "transDate")
    if transDate == nil then
        util.LogErr("*** HuanFuBao: can't find transDate !!!")
        return errret
    end

	-- sign 签名字符串
	local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** HuanFuBao: can't find sign !!!")
        return errret
    end

    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** HuanFuBao: can't find appinfo")
        return errret
    end

	--解析透传信息
    local payinfo = {}
    payinfo.orderid = extension
    payinfo.id = self.id
    payinfo.price = productPrice

	util.LogInfo(" ===>HuanFuBao RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

	--验证签名
    local sigstr = "respCode="..respCode.."&respInfo="..respInfo.."&orderNum="..orderNum.."&productName="..productName
                   .."&productCount="..productCount.."&productPrice="..productPrice.."&appSerialNo="..appSerialNo
                   .."&createOrderTime="..createOrderTime.."&transDate="..transDate.."&extension="..extension..self.key

    util.LogInfo("HuanFuBao sign = "..sign.."   sigstr = "..sigstr)
    local sigvalue = util.MD5(sigstr)
    if sigvalue ~= sign then
        util.LogErr("*** HuanFuBao: unmatched signature, given:"..sign.." calculated:"..sigvalue)
        return errret
    end

	util.LogInfo("*** Congratulations HuanFuBao Check Passed ***")

    --返回订单结果
    return util.PayRet (0, payinfo)
end

function ReplyHuanFuBaoTVPay(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "success"
        --return string.format(HTTP_RESP_FORMAT, string.len(res), res)
        return res 
    else
        return "failed"
    end
end

----------------------------------------------------------------
------------------------ 欢付宝 _2 -----------------------------
function DoHuanFuBaoTVPay_2(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)
	
	util.LogInfo("HuanFuBao ===> params: "..params)

     --POST方式返回, 详情参考官方SDK文档
    --参数如下：
    -- respCode 返回码 => 00:交易成功；01:失败 
    -- respInfo 返回信息 => 返回码为00以外的情况，返回错误信息
    -- orderNum 订单号 => 本系统生成的订单号码 
    -- productName 产品名称 => 产品名称，多个产品以"|"（半角）分割。
    -- productCount 产品数量 => 产品数量，多个产品以"|"（半角）分割，与产品名称对应。 
    -- productPrice 产品价格 => 以分为单位，多个产品以"|"  （半角）分割，与产品名称对应。例：1000代表10元 
    -- appSerialNo 商户订单号 => 调用支付接口时传入的商户订单号
    -- createOrderTime 订单创建时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。 
	-- transDate 支付订单付款完成时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。
	-- extension 扩展域
	-- sign 签名字符串 => 
	
	--解析回传参数信息, 扩展域，利用这个字段来透传
    --local extension = util.FindValueOfKey(params, "extension")
    --if extension == nil then
    --    util.LogErr("*** HuanFuBao: can't find extension")
    --    return errret
    --end

	--解析返回码 => 00:交易成功；01:失败
	local respCode = util.FindValueOfKey(params, "respCode")
    if respCode == nil or respCode ~= "00" then
        util.LogErr("*** HuanFuBao: can't find respCode or pay failed !!!")
        return errret
    end

	--解析返回信息 => 返回码为00以外的情况，返回错误信息
	local respInfo = util.FindValueOfKey(params, "respInfo")
    if respInfo == nil then
        util.LogErr("*** HuanFuBao: can't find respInfo !!!")
        return errret
    end

	--解析orderNum 订单号 => 本系统生成的订单号码 
	local orderNum = util.FindValueOfKey(params, "orderNum")
    if orderNum == nil then
        util.LogErr("*** HuanFuBao: can't find orderNum !!!")
        return errret
    end

    -- productName 产品名称 => 产品名称，多个产品以"|"（半角）分割。
	local productName = util.FindValueOfKey(params, "productName")
    if productName == nil then
        util.LogErr("*** HuanFuBao: can't find productName !!!")
        return errret
    end

    -- productCount 产品数量 => 产品数量，多个产品以"|"（半角）分割，与产品名称对应。
	local productCount = util.FindValueOfKey(params, "productCount")
    if productCount == nil then
        util.LogErr("*** HuanFuBao: can't find productCount !!!")
        return errret
    end

	-- productPrice 产品价格 => 以分为单位，多个产品以"|"  （半角）分割，与产品名称对应。例：1000代表10元 
	local productPrice = util.FindValueOfKey(params, "productPrice")
    if productPrice == nil then
        util.LogErr("*** HuanFuBao: can't find productPrice !!!")
        return errret
    end

    -- appSerialNo 商户订单号 => 调用支付接口时传入的商户订单号
	local appSerialNo = util.FindValueOfKey(params, "appSerialNo")
    if appSerialNo == nil then
        util.LogErr("*** HuanFuBao: can't find appSerialNo !!!")
        return errret
    end

    -- createOrderTime 订单创建时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。 
	local createOrderTime = util.FindValueOfKey(params, "createOrderTime")
    if createOrderTime == nil then
        util.LogErr("*** HuanFuBao: can't find createOrderTime !!!")
        return errret
    end

	-- transDate 支付订单付款完成时间 => 14 位定长数字字符 格式：yyyyMMddHHmmss，其中yyyy=年份，MM=月份，dd=日，HH=小时，mm=分钟，ss=秒。
	local transDate = util.FindValueOfKey(params, "transDate")
    if transDate == nil then
        util.LogErr("*** HuanFuBao: can't find transDate !!!")
        return errret
    end

	-- sign 签名字符串
	local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** HuanFuBao: can't find sign !!!")
        return errret
    end

    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** HuanFuBao: can't find appinfo")
        return errret
    end

	--解析透传信息
    local payinfo = {}
    payinfo.orderid = appSerialNo --extension
    payinfo.id = self.id
    payinfo.price = productPrice

	util.LogInfo(" ===>HuanFuBao RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)    

	--验证签名
    local sigstr = "respCode="..respCode.."&respInfo="..respInfo.."&orderNum="..orderNum.."&productName="..productName
                   .."&productCount="..productCount.."&productPrice="..productPrice.."&appSerialNo="..appSerialNo
                   .."&createOrderTime="..createOrderTime.."&transDate="..transDate..self.key--.."&extension="..extension..self.key

    util.LogInfo("HuanFuBao sign = "..sign.."   sigstr = "..sigstr)
    local sigvalue = util.MD5(sigstr)
    if sigvalue ~= sign then
        util.LogErr("*** HuanFuBao: unmatched signature, given:"..sign.." calculated:"..sigvalue)
        return errret
    end

	util.LogInfo("*** Congratulations HuanFuBao Check Passed ***")

    --返回订单结果
    return util.PayRet (0, payinfo)
end

function ReplyHuanFuBaoTVPay_2(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "success"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
        --return res 
    else
        return "failed"
    end
end

-----------------------------------------------------------
---天猫盒子------------------------------------------------
function DoAliPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

	util.LogInfo(" ===>TianMaoBox Decrypt Before AliPay params: "..params)

	--notify_url?data=encryptString
	--POST参数格式为：data=encryptString
	local encryptstr = util.FindValueOfKey(params, "data")
    if encryptstr == nil then
        util.LogErr("*** TianMaoBox: can't find data !!!")
        return errret
    end
	local decrypt_result = util.RSADecrypt(util.Base64Decode(encryptstr), self.privatekey)

	if decrypt_result == nil then 
		util.LogInfo("===> TianMaoBox RSA Decrypt Failed...")
		return errret
	end

	--加密参数为：
	-- order_status: TRAD_SUCCESS
	-- partner_order_no: 合作伙伴的订单号
	-- alipay_trade_no: 支付宝的订单号
	-- buyer_logon_id: 买家支付宝账号

	util.LogInfo("====>TianMaoBox Decrypt Later AliPay Later: "..decrypt_result)

    local json = require("json")
    local retcode, retval = pcall(json.decode, decrypt_result)
    if retcode == false then
        util.LogErr("TianMaoBox decode json failed: "..retval)
        return errret 
    end

    if type(retval) == "table" then
    	if retval.partner_order_no == nil or retval.alipay_trade_no == nil or retval.buyer_logon_id == nil or retval.order_status == nil or retval.order_status ~= "TRADE_SUCCESS" then
    		return errret
		end
   	else
		util.LogErr("TianMaoBox Ret Not JSON")
		return errret
	end

	util.LogInfo("====>TianMaoBox: "..retval.partner_order_no.."@"..retval.alipay_trade_no.."@"..retval.buyer_logon_id.."@"..retval.order_status)

	--解析透传信息
    local payinfo = {}
    payinfo.orderid = retval.partner_order_no
    payinfo.id = self.id
    payinfo.price = 0

	util.LogInfo(" ===>TianMaoBox RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    util.LogInfo("*** Congratulations TianMaoBox Check Passed ***")

    return util.PayRet(0, payinfo)
end

function ReplyAliPay(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "success"
        --return res
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end

-----------------------------------------------------------
------------------------ 爱游戏 ---------------------------
function DoLoveGameTVPay(self, params)

    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo("LOVEGAME ===> params: "..params)

     --POST方式返回, 详情参考官方SDK文档
    --参数如下：
    -- serial_no CP业务流水号 (32Bytes) 
    -- result_code 返回码：120 计费成功
    -- result_msg 返回消息
    -- validate_code_s 验证码 MD5(DES(serial_no+result_code+fromer+fee))
    -- request_time 请求时间
    -- response_time 响应时间
    -- transaction_id 爱游戏平台流水号
    -- fee 道具价格

	------------------------------------------- 获取重要参数-------------------------
    --解析回传参数信息, 扩展域，利用这个字段来透传
    local serial_no = util.FindValueOfKey(params, "serial_no")
    if serial_no == nil then
        util.LogErr("*** LOVEGAME: can't find serial_no")
        return errret
    end

	--解析result_code 返回码：120 计费成功
    local result_code = util.FindValueOfKey(params, "result_code")
    if result_code == nil or result_code ~= "120" then
        util.LogErr("*** LOVEGAME: can't find result_code or result_code == nil")
        return errret
    end

	--解析 fee道具价格
    local fee = util.FindValueOfKey(params, "fee")
    if fee == nil then
        util.LogErr("*** LOVEGAME: can't find fee")
        return errret
    end

	--解析 validate_code_s 验证码 MD5(DES(serial_no+result_code+fromer+fee))
    local validate_code_s = util.FindValueOfKey(params, "validate_code_s")
    if validate_code_s == nil then
        util.LogErr("*** LOVEGAME: can't find validate_code_s")
        return errret
    end

    if self == nil or self.appid == nil or self.key == nil or self.fromer == nil then
        util.LogErr("*** LOVEGAME: can't find self")
        return errret
    end

    local payinfo = {}
    payinfo.id = self.id
    payinfo.orderid = serial_no
    payinfo.price = fee *100

	util.LogInfo(" ===>LoveGame RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    --验证签名MD5(DES(secretString, desKey))
    local sigstr = ""..serial_no..result_code..self.fromer..fee
    util.LogInfo("LOVEGAME validate_code_s = "..validate_code_s.." sigstr = "..sigstr)

    local sigvalue = util.MD5(util.Base64Encode(util.DESEncrypt(sigstr, self.key)))
    if sigvalue ~= validate_code_s then
        util.LogErr("*** LOVEGAME unmatched signature, given:"..validate_code_s.." calculated:"..sigvalue)
        return errret
    end

	util.LogInfo("*** Congratulations LOVEGAME Check Passed ***")

    --返回订单结果
    return util.PayRet (0, payinfo)

end

function ReplyLoveGameTVPay(self, errcode, channelinfo)
    local util = require("util")

    --测试爱游戏返回订单号是否正确
    util.LogInfo("Love Game Response ChannelInfo => "..channelinfo)

    if errcode == 0 then
        local res = ""..channelinfo
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end

-----------------------------------------------------------
------------------------ 大麦盒子 ---------------------------
function DoDaMaiTVPay(self, params)

    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo("DAMAI ===> params: "..params)

----------------------- 获取重要参数-----------------------------
	--解析sign
    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** DAMAI: can't find sign or sign == nil")
        return errret
    end

    -- 订单状态 0-下单成功，1-支付中，2-支付成功，3-支付失败，4-已退款，5-支付关闭
    local orderStatus = util.FindValueOfKey(params, "orderStatus")
    if orderStatus == nil or orderStatus ~= "2" then
        util.LogErr("*** DAMAI: can't find orderStatus or orderStatus ~= 2")
        return errret
    end

    --找到透传参数JSON格式
    local touchuan = util.FindValueOfKey(params, "orderAppend")
    if touchuan == nil then
        util.LogErr("*** DAMAI: can't find orderAppend == nil")
        return errret
    end

    local json = require("json")
    local retcode, retval = pcall(json.decode, touchuan)
    if retcode == false then
        util.LogErr("DAMAI decode json failed: "..retval)
        return errret 
    end

    if type(retval) == "table" then 
	if retval.a == nil then 
		return errret
	end 
   	else
		util.LogErr("DAMAI Ret Not JSON")
		return errret
    end 

	------------------ 获取appinfo---------------------------------------------------------
    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** DAMAI: can't find appinfo")
        return errret
    end
	
    local payinfo = {}
    payinfo.orderid = retval.a
    payinfo.id = self.id
    payinfo.price = 0

	util.LogInfo(" ===>DAMAI RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

     local sigstr = ""
     local items = util.SplitString(params, "&")
     table.sort(items)
		
     for key, value in pairs(items) do
    	if key == 1 then
		if string.sub(value, 1, 5) ~= "sign=" then
        		sigstr = ""..value 
		end
    	else
		if string.sub(value, 1, 5) ~= "sign=" then
        		sigstr = sigstr.."&"..value 
		end
    	end 
    end  

    sigstr = sigstr.."&partnerKey="..self.key
    util.LogInfo("DAMAI sigstr = "..sigstr.." sign = "..sign)
    local sigvalue = util.MD5(sigstr)

    if sigvalue ~= sign then
        util.LogErr("*** DAMAI unmatched signature, given:"..sign.." calculated:"..sigvalue)
        return errret
    end
	
	util.LogInfo("*** Congratulations DAMAI Check Passed ***")
    --返回订单结果
    return util.PayRet (0, payinfo)
	
end

function ReplyDaMaiTVPay(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "success"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end

----------------------------------------------------------
------------------------ 移动基地 ------------------------
function DoChinaMobilePay(self, params)

    local errret = util.PayRet(-1, nil)
    util.LogInfo("ChainMobile params: "..params)

	if params == nil  then 
		util.LogErr("ChainMobile params is nil")
		return errret
	end
	
	if string.sub(params, 1, 5) ~= "<?xml" then
		util.LogErr("!!!!!ChinaMobile params is not xml format")
		return errret
	end
	
    require('LuaXml')
    require('BigNum')
    local util = require("util")
    local rettable = xml.eval(params)

	if rettable == nil then
		util.LogErr("ChinaMobile rettable is nil")
		return errret
	end
    
    --解析hRet 返回0表示成功
    local hRet = rettable:find('hRet')
    if hRet == nil or hRet[1] == nil or hRet[1] ~= "0" then
        return errret
    end

    --解析道具计费代码
    local consumeCode = rettable:find('consumeCode')
    if consumeCode == nil or consumeCode[1] == nil then
	    util.LogErr("*** ChinaBank: parse consumeCode is nil failed")
        return errret
    end

    --解析cpparam
    local cpparam = rettable:find('cpparam')
    if cpparam == nil or cpparam[1] == nil or cpparam[1] == "" then
        return errret
    end

	--解析透传信息
    local payinfo = {}
    
	payinfo.orderid = cpparam[1]

    util.LogInfo("hRet = "..hRet[1].." consumeCode = "..consumeCode[1].." cpparam = "..cpparam[1]);
    --从道具计费代码中取得支付金额

    local propFeeTable = { ["001"] = 1, ["002"] = 10, ["003"] = 100, ["004"] = 200 
	, ["005"] = 500 , ["006"] = 600 , ["007"] = 1000 ,["008"] = 2000 ,["009"] = 5000 ,["010"] = 10000}

	local  consumeCodeLast = string.sub(consumeCode[1], -3, -1)
	util.LogInfo("consumeCodeLast params: "..consumeCodeLast)

	payinfo.price = propFeeTable[""..consumeCodeLast]

    if payinfo.price == nil then
        util.LogErr("ChinaMobile payinfo.price")
        return errret
    end

 	payinfo.channelid = self.id
	payinfo.id = self.id
	payinfo.channelinfo = ""

	if payinfo.channelinfo == nil then
	   util.LogErr("channelinfo is nil")
	   return errret;
	end

	util.LogInfo(" ===>ChainMobile RetPayInfo: payinfo.orderid: "
                    ..payinfo.orderid.." payinfo.channelid: ".. payinfo.channelid.." payinfo.price: "..payinfo.price
					.."payinfo.channelinfo: "..payinfo.channelinfo)

    util.LogInfo("*** Congratulations ChinaMobile[ NO CHECK ] Check Passed ***")

	if payinfo.orderid == nil or payinfo.channelid == nil or payinfo.price == nil  then
		return errret;
	end


    return util.PayRet (0, payinfo)
end

function ReplyChinaMobilePay(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><hRet>0</hRet><message>Successful</message></request>"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end
--------------------------创维酷开---------------------------------
function DoKuKaiTVPay(self, params)

    local util = require("util")
    local errret = util.PayRet(-1, nil)
    
    util.LogInfo("KuKai ===> params: "..params)

	--该请求是HTTP协议请求，酷开以POST方式，向第三方URL请求，请求报文的内容为JSON格式字符串
	local json = require("json")
    local retcode, retval = pcall(json.decode, params)
    if retcode == false then
        LogErr("KuKai decode json failed: "..retval)
        return errret
    end
	
	--取出JSON里面的每一个参数
    if type(retval) == "table" then
	if retval.resp_code == nil or retval.resp_code ~= "0000" then 
		util.LogErr("KuKai resp_code is nil")
		return errret
	end
	
	if retval.order_id == nil then 
		util.LogErr("KuKai order_id is nil")
		return errret
	end
		
	if retval.pay_time == nil then 
		util.LogErr("KuKai pay_time is nil")
		return errret
	end
		
	if retval.sign_code == nil then 
		util.LogErr("KuKai sign_code is nil")
		return errret
	end
		
	if retval.mac  == nil then 
		util.LogErr("KuKai mac is nil")
		return errret
	end
		
	if retval.tel == nil then 
		util.LogErr("KuKai tel is nil")
		return errret
	end
		
	if retval.appCode == nil then 
		util.LogErr("KuKai appcode is nil")
		return errret
	end
    end 

	--获取KEY
    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** KUKAI: can't find appinfo")
        return errret
    end

    --解析透传信息
    local payinfo = {}
    payinfo.orderid = retval.order_id
    payinfo.id = self.id
    payinfo.price = 0

	util.LogInfo(" ===>Kukai RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

	local sigstr = ""..retval.appCode..retval.mac..retval.order_id..retval.pay_time..retval.resp_code..retval.tel..self.key

	--------MD5校验
	local sigvalue = util.MD5(sigstr)
    if string.lower(sigvalue) ~= retval.sign_code then
        util.LogErr("*** KuKai unmatched signature, given:"..retval.sign_code.." calculated:"..sigvalue)
        return errret
    end		
    	
	util.LogInfo("*** Congratulations KuKai MD5 Check Passed ***")
    --返回订单结果
    return util.PayRet (0, payinfo)

end

function ReplyKuKaiTVPay(self, errcode, channelinfo)
    local util = require("util")
	
    if errcode == 0 then
        local res = "success"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end


-------------------------------------- 沙发管家---------------------------------
function DoShaFaTVPay(self, params)

    local util = require("util")
    local errret = util.PayRet(-1, nil)
    
    util.LogInfo("ShaFa ===> params: "..params)

	--解析参数
    local data = util.FindValueOfKey(params, "data")
    if data == nil then
        util.LogErr("*** ShaFa: can't find data or data == nil")
        return errret
    end

    local json = require("json")


	--解析整个参数JSON
    local retcode, retval = pcall(json.decode, data)
    if retcode == false then
        util.LogErr("ShaFa decode json failed: "..retval)
        return errret 
    end

    if type(retval) ~= "table" then 
	    util.LogErr("ShaFa not json")
		return errret
    end

	--判断sign是否为空
    if retval.sign == nil then
	util.LogInfo("ShaFa sign")
	return errret
    end

    local sign = retval.sign

    --解析自定义参数JSON
    if retval.custom_data == nil then 
	util.LogInfo("ShaFa Custom_data is nil...")
	return errret
    end

    local retcode1, retval1 = pcall(json.decode, retval.custom_data)
    if retcode1 == false then
        util.LogErr("ShaFa decode json failed: "..retval1)
        return errret 
    end

    util.LogInfo("..retval.custom_data = "..retval.custom_data)
    if type(retval1) ~= "table" then 
	return errret
    end

	------------------ 获取appinfo---------------------
    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** ShaFa: can't find appinfo")
        return errret
    end

	--解析透传信息
    local payinfo = {}
    payinfo.orderid = retval.partner_order_no
    payinfo.id = self.id
    payinfo.price = 0

	util.LogInfo(" ===>ShaFa RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

	local temp = string.gsub(data, "[\"]", "")
	local temp1 = string.sub(temp, 2, string.len(temp) - 1)
	local temp2 = ""..string.gsub(temp1, ":", "=")
	local items = util.SplitString(temp2, ",")

     	table.sort(items)

	local flag = ""

	--预处理Items
     	for key, value in pairs(items) do

		-- 处理是否 支付成功
		if items[key] == "is_success=true" then
			flag = flag.."AAAAA"
			items[key] = "is_success=1"
		end

		--处理自定义数据
		if string.sub(items[key], 1, string.len("custom_data=")) == "custom_data=" then
			items[key] = string.gsub(items[key], "\\", "\"")
			items[key] = string.gsub(items[key], "custom_data={\"a\"=", "custom_data={\"a\":")
		end

		--处理中文编码
		if string.sub(items[key], 1, string.len("name=")) == "name=" then
			if string.sub(items[key], 1, string.find(items[key], '\\') - 1) == nil then
				util.LogInfo("ShaFa paraser total number failed")
				return errret
			end
			items[key]=string.sub(items[key], 1, string.find(items[key], '\\') - 1).."个西米币"
		end
    	end  
	
     if flag ~= "AAAAA" then
	util.LogInfo("ShaFa is_success != true")
	return errret
     end

     --生成签名字符串
     local sigstr =  ""
     for key, value in pairs(items) do
    	if key == 1 then
		if string.sub(value, 1, 5) ~= "sign=" then
        		sigstr = ""..value 
		end
    	else
		if string.sub(value, 1, 5) ~= "sign=" then
        		sigstr = sigstr.."&"..value 
		end
    	end 
    end  
		
    sigstr = sigstr..self.key
    util.LogInfo("sigstr = "..sigstr)
	--------MD5校验
    local sigvalue = util.MD5(sigstr)
    if sigvalue ~= sign then
        util.LogErr("*** ShaFa unmatched signature, given:"..sign.." calculated:"..sigvalue)
        return errret
    end
	
    util.LogInfo("*** Congratulations ShaFa(MD5) Check Passed ***")
    --返回订单结果
    return util.PayRet (0, payinfo)
	
end

function ReplyShaFaTVPay(self, errcode, channelinfo)
    local util = require("util")
	
    if errcode == 0 then
       return "success"
    else
        return nil
    end
end


--------------------------------------------------------------------
----------------------- 葡萄接入------------------------------------
function DoPuTaoPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>PuTao params: "..params)

    -------------------------------------------------------
    --------------------------------------------------------
    local amount = util.FindValueOfKey(params, "amount")
    if amount == nil then
        util.LogErr("*** PuTao: can't find amount or amount == nil")
        return errret
    end

    local currency = util.FindValueOfKey(params, "currency")
    if currency == nil then
        util.LogErr("*** puTao : can't find currency or currency == nil")
        return errret
    end

    local extra = util.FindValueOfKey(params, "extra")
    if extra == nil then
        util.LogErr("*** PuTao: can't find extra or extra == nil")
        return errret
    end

    local notify_id = util.FindValueOfKey(params, "notify_id")
    if notify_id == nil then
        util.LogErr("*** PuTao: can't find notify_id or notify_id == nil")
        return errret
    end

    local product = util.FindValueOfKey(params, "product")
    if product == nil then
        util.LogErr("*** PuTao: can't find product or product == nil")
        return errret
    end

    local result = util.FindValueOfKey(params, "result")
    if result == nil then
        util.LogErr("*** PuTao: can't find result or result == nil")
        return errret
    end

    local trans_no = util.FindValueOfKey(params, "trans_no")
    if trans_no == nil then
        util.LogErr("*** PuTao: can't find trans_no or trans_no == nil")
        return errret
    end

    local trade_time = util.FindValueOfKey(params, "trade_time")
    if trade_time == nil then
        util.LogErr("*** PuTao: can't find trade_time or trade_time == nil")
        return errret
    end

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** PuTao: can't find sign or sign = nil")
        return errret
    end

    local sign_type = util.FindValueOfKey(params, "sign_type")
    if sign_type == nil then
        util.LogErr("*** PuTao: can't find sign_type or sign_type = nil")
        return errret
    end

    local sign_str = "amount="..amount.."&currency="..currency.."&extra="..extra.."&notify_id="
    ..notify_id.."&product="..product.."&result="..result.."&trade_time="..trade_time.."&trans_no="..trans_no

    util.LogInfo("sign_str = "..sign_str)

    if self == nil or self.appid == nil or self.key == nil then
        util.LogErr("*** ShaFa: can't find appinfo")
        return errret
    end

    local sign_result = util.RSASign(self.privatekey, sign_str)
    if sign_result ~= sign then 
        util.LogErr("PuTao sign failed...")
        return errret
    end

    util.LogInfo("sign_result = "..sign_result)

    local payinfo = {}
    payinfo.orderid = extra
    payinfo.id = self.id
    payinfo.price = amount

	util.LogInfo(" ===>PuTao RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    util.LogInfo("*** Congratulations PuTao Check Passed ***")

    return util.PayRet(0, payinfo)
end

function ReplyPuTaoPay(self, errcode, channelinfo)
    local util = require("util")

    if errcode == 0 then
        local res = "success"
        return res
    else
        return nil
    end
end

--TCL渠道
function DoTclPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>TCL SubChannel  params: "..params)

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** tcl: can't find sign")
        return errret
    end

    sign = string.gsub(sign, ' ', '+')
    util.LogInfo("replace later : "..sign)

    local transdata = util.FindValueOfKey(params, "transdata")
    if transdata == nil then
        util.LogErr("*** tcl: can't find transdata")
        return errret
    end

    ---验证签名
    local sign_result = util.RSASignVerify(self.privatekey, transdata, sign)
    if sign_result ~= true then 
        util.LogErr("SubChannel TCL sign failed...")
        return errret
    end

    --解析JSON参数
    local json = require("json")
    local retcode, retval = pcall(json.decode, transdata)
    if retcode == false then
        LogErr("subchannel TCL decode transdata json failed: "..retval)
        return nil
    end

    util.LogInfo("retval.result = "..retval.result.." retval.cpPrivateInfo: "..retval.cpPrivateInfo)
    if type(retval) == "table" then

        --判断是否支付成功
        if retval.result ~= 0 then
            util.LogErr("*** tcl: pay result return not 0")
            return errret
        end

        --判断透传参数是否正常
        if retval.cpPrivateInfo == nil then
            util.LogErr("*** tcl: can't find cpPrivateInfo")
            return errret
        end
        
        --判断金额是否正常
        if retval.amount == nil then
            util.LogErr("*** tcl: can't find amount")
            return errret
        end

    else
        util.LogErr("*** tcl: can't find transdata")
        return errret
    end

    local payinfo = {}
    payinfo.orderid = retval.cpPrivateInfo
    payinfo.id = self.id
    payinfo.price = retval.amount

	util.LogInfo(" ===>TCL RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    util.LogInfo("*** Congratulations SubChannel TCL  Check Passed ***")

    return util.PayRet(0, payinfo)
end

function ReplyTclPay(self, errcode, channelinfo)
    if errcode == 0 then
        return "success"
    else
        return nil
    end
end

--------------------------------------------------------------------
----------------------- 联想支付------------------------------------
function DoLenovoPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>Lenovo  params: "..params)

    local data = util.FindValueOfKey(params, "data")
    if data == nil then
        util.LogErr("*** Lenovo: can't find data")
        return errret
    end

    local encryptkey = util.FindValueOfKey(params, "encryptkey")
    if encryptkey == nil then
        util.LogErr("*** Lenovo: can't find encryptkey")
        return errret
    end

    --encryptkey被RSA加密，data被AES加密
    --RSA解密encryptkey
	local decrypt_result = util.RSADecrypt(util.Base64Decode(encryptkey), self.privatekey)
	if decrypt_result == nil then 
        util.LogInfo("===> lenovo RSA Decrypt Failed...")
        return errret
	end
    --AES解密data
    local real_data = util.AESDecrypt(util.Base64Decode(data), decrypt_result)
    if real_data == nil then
		util.LogInfo("===> lenovo AES Decrypt Failed...")
		return errret
	end

    util.LogInfo("real_data"..real_data)

    --解析JSON参数
    local json = require("json")
    local retcode, retval = pcall(json.decode, real_data)
    if retcode == false then
        util.LogErr("Lenovo decode data json failed: "..retval)
        return nil
    end

    if type(retval) == "table" then
        --判断是否支付成功
        if retval.status ~= 1 then
            util.LogErr("*** lenovo: pay result return not 1")
            return errret
        end
        if retval.merchantaccount == nil then
            util.LogErr("*** lenovo: can't find merchantaccount")
            return errret
        end
        if retval.yborderid == nil then
            util.LogErr("*** lenovo: can't find yborderid")
            return errret
        end
        if retval.orderid == nil then
            util.LogErr("*** lenovo: can't find orderid")
            return errret
        end
        if retval.amount == nil then
            util.LogErr("*** lenovo: can't find amount")
            return errret
        end
        if retval.bankcode == nil then
            util.LogErr("*** lenovo: can't find bankcode")
            return errret
        end
        if retval.bank == nil then
            util.LogErr("*** lenovo: can't find bank")
            return errret
        end
        if retval.cardtype == nil then
            util.LogErr("*** lenovo: can't find cardtype")
            return errret
        end
        if retval.lastno == nil then
            util.LogErr("*** lenovo: can't find lastno")
            return errret
        end
        if retval.sign == nil then
            util.LogErr("*** lenovo: can't find sign")
            return errret
        end
    else
        util.LogErr("*** Lenovo: retval not table")
        return errret
    end
    
    --拼接数据
    sign_str = retval.amount..retval.bank..retval.bankcode
        ..retval.cardtype..retval.lastno..retval.merchantaccount..retval.orderid
        ..retval.status..retval.yborderid

    util.LogInfo("sing_srt:"..sign_str)

    --sign = string.gsub(retval.sign, ' ', '+')
    ---验证签名
    local sign_result = util.RSASignVerify(self.publickey, sign_str, retval.sign)
    if sign_result ~= true then 
        util.LogErr("lenovo sign failed...")
        return errret
    end

    local payinfo = {}
    payinfo.orderid = retval.orderid
    payinfo.id = self.id
    payinfo.price = retval.amount

	util.LogInfo(" ===>Lenovo RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price)

    return util.PayRet(0, payinfo)
end

function ReplyLenovoPay(self, errcode, channelinfo)
    if errcode == 0 then
        return "success"
    else
        return nil
    end
end

--------------------------------------------------------------------
----------------------- 世博云------------------------------------
function DoShiBoYunPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>ShiBoYun  params: "..params)

    local apporderno = util.FindValueOfKey(params, "apporderno")
    if apporderno == nil then
        util.LogErr("*** ShiBoYun: can't find apporderno or apporderno == nil")
        return errret
    end
    local cbmporderno = util.FindValueOfKey(params, "cbmporderno")
    if cbmporderno == nil then
        util.LogErr("*** ShiBoYun : can't find cbmporderno or cbmporderno == nil")
        return errret
    end
    local globalusercode = util.FindValueOfKey(params, "globalusercode")
    if globalusercode == nil then
        util.LogErr("*** ShiBoYun: can't find globalusercode or globalusercode == nil")
        return errret
    end
    local orderstatus = util.FindValueOfKey(params, "orderstatus")
    if orderstatus == nil then
        util.LogErr("*** ShiBoYun: can't find orderstatus")
        return errret
    end
    --订单状态为2才发货，通知客户端进行订单确认
    if orderstatus ~= "2" then
        util.LogErr("*** ShiBoYun: order status not 2")
        return errret
    end
    local productcode = util.FindValueOfKey(params, "productcode")
    if productcode == nil then
        util.LogErr("*** ShiBoYun: can't find productcode or productcode == nil")
        return errret
    end
    local amount = util.FindValueOfKey(params, "amount")
    if amount == nil then
        util.LogErr("*** ShiBoYun: can't find amount or amount == nil")
        return errret
    end
    local extrainfo = util.FindValueOfKey(params, "extrainfo")
    if extrainfo == nil then
        util.LogErr("*** ShiBoYun: can't find extrainfo or extrainfo == nil")
        return errret
    end
    local encryptdata = util.FindValueOfKey(params, "encryptdata")
    if encryptdata == nil then
        util.LogErr("*** ShiBoYun: can't find encryptdata or encryptdata = nil")
        return errret
    end
	local cryptdata = apporderno..globalusercode..orderstatus..productcode..amount..extrainfo
	local crypt_result = util.SHA1(cryptdata..self.key)
	crypt_result = string.upper(crypt_result)
	crypt_result1 = string.upper(encryptdata)
	if crypt_result ~= crypt_result1 then 
		util.LogErr("ShiBoYun checksh1 failed...")
		return errret
	end
    util.LogInfo("*** Congratulations ShiBoYun Check Passed ***")

    local payinfo = {}
    payinfo.orderid = apporderno
    payinfo.id = self.id
    payinfo.price = 0
    payinfo.cbmporderno = cbmporderno

	util.LogInfo(" ===>ShiBoYun RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "
                    ..payinfo.id.." payinfo.price: "..payinfo.price.." payinfo.cbmporderno"..payinfo.cbmporderno)

    return util.PayRet(0, payinfo)
end

function ReplyShiBoYunPay(self, errcode, channelinfo)
	local retstr = nil
	if errcode == 0 then     --发送订单确认消息
		retstr = '{"result_code":0,"result_description":"订单确认"}'
	else 
		retstr = '{"result_code":-1,"result_description":"订单确认"}'
	end
    return retstr
end

----------------------------------------------------------------------
---------------------------海信支付-------------------------------------------
function DoHaiXinPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    local items = util.SplitString(params, "&")
    local itemCount = #items

    local tl= {}

    for i=1,itemCount,1
    do
        table.insert(tl,items[i])
    end

    table.sort(tl)

    local str=""
    for key,value in pairs(tl) do
        if string.find(value,"sign")==nil then
            str=str.."&"..value
        end
    end

    str=string.sub(str,2,-1)

	util.LogInfo(" ==>HaiXin  params: "..params)

    local out_trade_no = util.FindValueOfKey(params, "out_trade_no")
    if out_trade_no == nil then
        util.LogErr("*** HaiXin: can't find out_trade_no or out_trade_no == nil")
        return errret
    end

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** HaiXin: can't find sign or sign = nil")
        return errret
    end

	local total_fee = util.FindValueOfKey(params, "total_fee")
    if total_fee == nil then
        util.LogErr("*** HaiXin: can't find total_fee or total_fee = nil")
        return errret
    end

    local cryptdata = str..self.key
    local crypt_result = util.MD5(cryptdata)
    if crypt_result ~= sign then 
		util.LogErr("HaiXin check MD5 failed...")
		return errret
    end

    util.LogInfo("*** Congratulations HaiXin Check Passed ***")

	local payinfo = {}
    payinfo.id = self.id
    payinfo.orderid = out_trade_no
    payinfo.price = total_fee*100
	payinfo.channelinfo = ""
    return util.PayRet(0, payinfo)
end

function ReplyHaiXinPay(self, errcode, channelinfo)
    local util = require("util")
    local retstr = nil

    if errcode == 0 then
        retstr = "success"
    else
        retstr = ""
    end
    return string.format(HTTP_RESP_FORMAT, string.len(retstr), retstr)
end
--------------------------------------------------------------------
----------------------- 天猫盒子新sdk-------------------------------
function DoAliPayNew(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>TianMaoBoxNew  params: "..params)

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** TianMaoBoxNew: can't find sign")
        return errret
    end
    local is_success = util.FindValueOfKey(params, "is_success")
    if is_success == nil then
        util.LogErr("*** TianMaoBoxNew : can't find is_success")
        return errret
    end
    if is_success ~= "T" then
        util.LogErr("*** TianMaoBoxNew: is_success not T")
        return errret
    end
    local ts = util.FindValueOfKey(params, "ts")
    if ts == nil then
        util.LogErr("*** TianMaoBoxNew : can't find ts")
        return errret
    end
    local coin_order_id = util.FindValueOfKey(params, "coin_order_id")
    if coin_order_id == nil then
        util.LogErr("*** TianMaoBoxNew: can't find coin_order_id")
        return errret
    end
    local consume_amount = util.FindValueOfKey(params, "consume_amount")
    if consume_amount == nil then
        util.LogErr("*** TianMaoBoxNew: can't find orderstatus")
        return errret
    end
    local app_order_id = util.FindValueOfKey(params, "app_order_id")
    if app_order_id == nil then
        util.LogErr("*** TianMaoBoxNew: can't find app_order_id")
        return errret
    end
    if self.key == nil then
        util.LogErr("*** TianMaoBoxNew: can't find self.key")
        return errret
    end

    --非必传参数
    local has_arg = false
    local credit_amount = util.FindValueOfKey(params, "credit_amount")
    if credit_amount ~= nil then
        has_arg = true
    end

    --md5 字母升序拼接参数,添加key
    if has_arg == true then
        sign_str = "app_order_id"..app_order_id.."coin_order_id"..coin_order_id.."consume_amount"..consume_amount.."credit_amount"..credit_amount
                .."is_success"..is_success.."ts"..ts..self.key
    else
        sign_str = "app_order_id"..app_order_id.."coin_order_id"..coin_order_id.."consume_amount"..consume_amount
                .."is_success"..is_success.."ts"..ts..self.key
    end

    local sign_val = util.MD5(sign_str)
    if sign_val ~= sign then
        util.LogErr("*** TianMaoBoxNew: sign failed")
        return errret
    end

    util.LogInfo("*** TianMaoBoxNew Check Passed ***")

    local payinfo = {}
    payinfo.orderid = app_order_id
    payinfo.id = self.id
    payinfo.price = consume_amount
    payinfo.coin_order_id = coin_order_id

	util.LogInfo(" ===>TianMaoBoxNew RetPayInfo: payinfo.orderid: "..payinfo.orderid.." payinfo.id: "..payinfo.id
        .." payinfo.price: "..payinfo.price.." payinfo.coin_order_id: "..payinfo.coin_order_id)

    return util.PayRet(0, payinfo)
end

function ReplyAliPayNew(self, errcode, channelinfo)
    if channelinfo == nil then
        util.LogErr("TianMaoBoxNew: rsp channelinfo nil")
        return nil
    end
    local app_order_id = util.FindValueOfKey(channelinfo, "app_order_id")
    if app_order_id == nil then
        util.LogErr("*** TianMaoBoxNew: rsp can't find app_order_id")
        return nil
    end
    local coin_order_id = util.FindValueOfKey(channelinfo, "coin_order_id")
    if coin_order_id == nil then
        util.LogErr("*** TianMaoBoxNew: rsp can't find coin_order_id")
        return nil
    end
	local retstr = nil
	if errcode == 0 then     --发送订单确认消息
		retstr = '{"is_success":"T","app_order_id":"'..app_order_id..'","coin_order_id":'..coin_order_id..'}'
	else 
		retstr = '{"is_success":"F","app_order_id":"'..app_order_id..'","coin_order_id":'..coin_order_id..',"error_code":"'..errcode..'","msg":"sys error"}'
	end
    return retstr
end

--------------------------------------------------------------------
-------------------------电信爱游戏短代接入-------------------------
function DianxinDuanVerifyPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)
    local order_id = util.FindValueOfKey(params, "cp_order_id")
    if order_id == nil then
        util.LogErr("DianxinDuanVerifyPay: can't find order_id!")
        return errret
    end
    local correlator = util.FindValueOfKey(params, "correlator")
    if correlator == nil then
        util.LogErr("DianxinDuanVerifyPay: can't find correlator!")
        return errret       
    end
    local order_time = util.FindValueOfKey(params, "order_time")
    if order_time == nil then
        util.LogErr("DianxinDuanVerifyPay: can't find order_time!")
        return errret         
    end
    local method = util.FindValueOfKey(params, "method")
    if method == nil then
        util.LogErr("==> Can't find method in  DianxinDuanVerifyPay! Params:"..params)
        return errret
    end
    local sig = util.FindValueOfKey(params, "sign")
    if sig == nil then
        util.LogErr("*** DianxinDuanVerifyPay: can't find sig")
        return errret
    end
    local sign_str = order_id..correlator..order_time..method..self.key
    local digest = util.MD5(sign_str)
    if digest ~= sig then
        util.LogErr("*** DianxinDuanVerifyPay: sig doesn't match! given "..sig.." calculated "..digest)
        return errret
    end 

    local payinfo = {}
    payinfo.orderid = order_id
    payinfo.id = self.id
    payinfo.price = 0
    payinfo.verify = true
    payinfo.correlator = correlator

    return util.PayRet(0, payinfo)  
end
function DoDianxinDuanPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)
    local method = util.FindValueOfKey(params, "method")
    if method == nil then
        util.LogErr("==> Can't find method in  DianxinDuanPay! Params:"..params)
        return errret
    end
    --订单确认消息
    if method == "check" then
        local verifyret = DianxinDuanVerifyPay(self, params)
        if verifyret.errcode == 0 then
            util.LogInfo("DianxinDuanPay: Verify telecom egame pay suceeded!");
        end
        return verifyret
    end
    --订单支付消息
    local order_id = util.FindValueOfKey(params, "cp_order_id")
    if order_id == nil then
        util.LogErr("DianxinDuanPay: can't find order_id!")
        return errret
    end
    local correlator = util.FindValueOfKey(params, "correlator")
    if correlator == nil then
        util.LogErr("DianxinDuanPay: can't find correlator!")
        return errret
    end
    local result_code = util.FindValueOfKey(params, "result_code")
    if result_code == nil or result_code ~= "00" then
        util.LogErr("DianxinDuanPay: can't find result_code! or code err")
        return errret
    end
    local fee = util.FindValueOfKey(params, "fee")
    if fee == nil then
       util.LogErr("DianxinDuanPay: can't find fee!") 
        return errret
    end
    local pay_type = util.FindValueOfKey(params, "pay_type")
    if pay_type == nil then
        util.LogErr("DianxinDuanPay: can't find pay_type!") 
        return errret
    end 
    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** DianxinDuanPay: can't find sign")
        return errret
    end
    sign_str = order_id..correlator..result_code..fee..pay_type..method..self.key
    local digest = util.MD5(sign_str)
    if digest ~= sign then
        util.LogErr("*** DianxinDuanPay: sign doesn't match! given "..sign.." calculated "..digest)
        return errret
    end

    local payinfo = {}
    payinfo.orderid = order_id
    payinfo.id = self.id
    payinfo.price = fee *100
    payinfo.verify = false

    return util.PayRet(0, payinfo)
end
function ReplyDianxinDuanPay(self, errcode, channelinfo)
    local util = require("util")
    local retstr = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    util.LogInfo("DianxinDuanPay: channelinfo "..channelinfo);

    if channelinfo == nil then
        util.LogErr("DianxinDuanPay: rsp channelinfo nil")
        return nil
    end
    local verify = util.FindValueOfKey(channelinfo, "verify")
    --订单确认
    if verify == "1" then
        local correlator = util.FindValueOfKey(channelinfo, "correlator")
        if correlator == nil then
            util.LogErr("DianxinDuanPay: can't find correlator!")
            return nil
        end
        local cp_order_id = util.FindValueOfKey(channelinfo, "order_id")
        if cp_order_id == nil then
            util.LogErr("DianxinDuanPay: can't find order_id!")
            return nil
        end
        local game_account = util.FindValueOfKey(channelinfo, "uid")
        if game_account == nil then
            util.LogErr("DianxinDuanPay: can't find uid!")
            return nil
        end
        local fee = util.FindValueOfKey(channelinfo, "fee")
        if fee == nil then
            util.LogErr("DianxinDuanPay: can't find fee!")
            return nil
        end
        local CurrentTime = os.date("%Y%m%d%H%M%S", os.time())
        local ret = 0
        retstr = retstr.."<sms_pay_check_resp>"..
                "<cp_order_id>"..cp_order_id.."</cp_order_id>"..
                "<correlator>"..correlator.."</correlator>"..
                "<game_account>"..game_account.."</game_account>"..
                "<fee>"..fee.."</fee>"..
                "<if_pay>"..ret.."</if_pay>"..
                "<order_time>"..CurrentTime.."</order_time></sms_pay_check_resp>"
    --发货确认
    elseif verify == "0" then
        local orderid = util.FindValueOfKey(channelinfo, "orderid")
        if orderid == nil then
            util.LogErr("DianxinDuanPay: can't find orderid!")
            return nil
        end
        retstr = retstr.."<cp_notify_resp>"..
        "<h_ret>"..errcode.."</h_ret>"..
        "<cp_order_id>"..orderid.."</cp_order_id></cp_notify_resp>"
    else
        util.LogErr("DianxinDuanPay: can't find verify or verify invalid")
        return nil
    end

    util.LogInfo("ReplyChinaTelecomEgamePay Msg: "..retstr);
    return string.format(HTTP_RESP_FORMAT, string.len(retstr), retstr)  
end

--------------------------------------------------------------------
----------------------------联通短代渠道接入------------------------
function LiantongDuanVerifyPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)
    local sigstr = ""

    require('LuaXml')
    local retcode, rettable = pcall(xml.eval, params)
    if retcode == false then
        util.LogErr("==> Invalid xmlstring "..params)
        return errret
    end

    if rettable == nil then
        util.LogErr("LiantongDuanVerifyPay: invalid params "..params)
        return errret
    end

    local signMsg = rettable:find('signMsg')
    if signMsg == nil or signMsg[1] == nil then
        return errret
    end
    signMsg = signMsg[1]

    local order_id = rettable:find('orderid')
    if order_id == nil or order_id[1] == nil then
        return errret
    end
    sigstr = sigstr.."orderid="..order_id[1]

    sigstr = sigstr.."&Key="..self.key
    util.LogInfo("==> LianTong Duan: VerifyPay sigstr "..sigstr)
    util.LogInfo("==> LianTong Duan: VerifyPay given sig "..signMsg)
    local sig = util.MD5(sigstr)
    util.LogInfo("==> LianTong Duan: VerifyPay calculated sig "..sig)
    if sig ~= signMsg then
        return errret
    end

    local payinfo = {}
    payinfo.id = self.id
    payinfo.orderid = string.sub(order_id[1],9)
    payinfo.price = 0
    payinfo.verify = true

    return util.PayRet(0, payinfo)
end
function DoLiantongDuanPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    require('LuaXml')
    local retcode, rettable = pcall(xml.eval, params)
    if retcode == false then
        util.LogErr("==> Invalid xmlstring "..params)
        return errret
    end
    if rettable == nil then
        util.LogErr("*** DoLiantongDuanPay: invalid params "..params)
        return errret
    end

    -- 订单验证
    local method = rettable:find('checkOrderIdReq')
    if method ~= nil then
        local verifyret = LiantongDuanVerifyPay(self, params)
        if verifyret.errcode == 0 then
            util.LogInfo("DoLiantongDuanPay: Verify liantong pay suceeded!");
        end
        return verifyret
    end

    -- 订单发货
    -- 获取参数
    local order_id = rettable:find('orderid')
    if order_id == nil or order_id[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find orderid")
        return errret
    end
    local ordertime = rettable:find('ordertime')
    if ordertime == nil or ordertime[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find ordertime")
        return errret
    end
    local cpid = rettable:find('cpid')
    if cpid == nil or cpid[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find cpid")
        return errret
    end
    local appid = rettable:find('appid')
    --if appid == nil or appid[1] == nil then
    if appid == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find appid")
        return errret
    end
    local fuck = true
    if appid[1] == nil then
        fuck = false
    end
    local fid = rettable:find('fid')
    if fid == nil or fid[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find fid")
        return errret
    end
    local consumeCode = rettable:find('consumeCode')
    if consumeCode == nil or consumeCode[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find consumeCode")
        return errret
    end
    local payfee = rettable:find('payfee')
    if payfee == nil or payfee[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find payfee")
        return errret
    end
    local payType = rettable:find('payType')
    if payType == nil or payType[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find payType")
        return errret
    end
    local hRet = rettable:find('hRet')
    if hRet == nil or hRet[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find hRet")
        return errret
    end
    local status = rettable:find('status')
    if status == nil or status[1] ~= "00000" then
        if status == nil then
            util.LogErr("*** DoLiantongDuanPay: can't find status")
        else
            util.LogErr("*** DoLiantongDuanPay: invalid purchase status "..status[1])
        end
        return errret
    end
    -- MD5签名
    local signMsg = rettable:find('signMsg')
    if signMsg == nil or signMsg[1] == nil then
        util.LogErr("*** DoLiantongDuanPay: can't find signMsg")
        return errret
    end
    signMsg = signMsg[1]

    -- 拼接参数
    local sigstr
    if fuck == false then
        sigstr = "orderid="..order_id[1].."&ordertime="..ordertime[1].."&cpid="..cpid[1].."&appid=".."&fid="..fid[1]
            .."&consumeCode="..consumeCode[1].."&payfee="..payfee[1].."&payType="..payType[1].."&hRet="..hRet[1]
            .."&status="..status[1].."&Key="..self.key
    else
        sigstr = "orderid="..order_id[1].."&ordertime="..ordertime[1].."&cpid="..cpid[1].."&appid="..appid[1].."&fid="..fid[1]
            .."&consumeCode="..consumeCode[1].."&payfee="..payfee[1].."&payType="..payType[1].."&hRet="..hRet[1]
            .."&status="..status[1].."&Key="..self.key
    end
    util.LogInfo(sigstr)

    -- 检查签名
    local sig = util.MD5(sigstr)
    if sig ~= signMsg then
        util.LogErr("*** DoLiantongDuanPay: sig doesn't match! ")
        util.LogErr("*** DoLiantongDuanPay: given "..signMsg.." calculated "..sig)
        return errret
    end

    util.LogInfo("==> LianTong Duan: purchase succeeded!")

    local payinfo = {}
    payinfo.id = self.id
    payinfo.orderid = string.sub(order_id[1], 9)
    payinfo.price = payfee[1]
    payinfo.verify = false

    return util.PayRet(0, payinfo)
end
function ReplyLiantongDuanPay(self, errcode, channelinfo)
    local util = require("util")
    local retstr = nil
    util.LogInfo("ReplyLiantongDuanPay: channelinfo "..channelinfo)

    if channelinfo == nil then
        util.LogErr("ReplyLiantongDuanPay: rsp channelinfo nil")
        return nil
    end
    local verify = util.FindValueOfKey(channelinfo, "verify")
    --订单确认
    if verify == "1" then
        local extra_info = util.FindValueOfKey(channelinfo, "extra_info")
        if extra_info == nil then
            util.LogErr("ReplyLiantongDuanPay: can't find extra_info!")
            return nil
        end
        local consume_code = util.FindValueOfKey(channelinfo, "consume_code")
        if consume_code == nil then
            util.LogErr("ReplyLiantongDuanPay: can't find consume_code!")
            return nil
        end

        local json = require("json")
        local retcode, retval = pcall(json.decode, extra_info)
        if retcode == false then
            LogErr("ReplyLiantongDuanPay decode extra_info json failed")
            return nil
        end
        if errcode == 0 then
            retstr = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><paymessages><checkOrderIdRsp>0</checkOrderIdRsp>"
        else
            retstr = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><paymessages><checkOrderIdRsp>-1</checkOrderIdRsp>"
        end
        retstr = retstr.."<gameaccount>"..retval.gameaccount.."</gameaccount>"..
                "<macaddress>"..retval.macaddress.."</macaddress>"..
                "<ipaddress>"..retval.ipaddress.."</ipaddress>"..
                "<serviceid>"..consume_code.."</serviceid>"..
                "<channelid>"..retval.channelid.."</channelid>"..
                "<cpid>"..retval.cpid.."</cpid>"..
                "<ordertime>"..retval.ordertime.."</ordertime>"..
                "<imei>"..retval.imei.."</imei>"..
                "<appversion>"..retval.appversion.."</appversion></paymessages>"
    -- 发货确认
    elseif verify == "0" then
        if errcode == 0 then
            retstr = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><callbackRsp>1</callbackRsp>"
        else
            retstr = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><callbackRsp>-1</callbackRsp>"
        end
    else
        util.LogErr("ReplyLiantongDuanPay: can't find verify or verify invalid")
        return nil
    end

    util.LogInfo("ReplyLiantongDuanPay: retstr "..retstr)

    return string.format(HTTP_RESP_FORMAT, string.len(retstr), retstr)
end
----------------------------------------------------------
------------------------ 移动短代 ------------------------
function DoYidongDuanPay(self, params)
    local errret = util.PayRet(-1, nil)

    if params == nil  then 
        util.LogErr("ChainMobile params is nil")
        return errret
    end

    util.LogInfo("ChainMobile params: "..params)

    if string.sub(params, 1, 5) ~= "<?xml" then
        util.LogErr("!!!!!ChinaMobile params is not xml format")
        return errret
    end

    require('LuaXml')
    require('BigNum')
    local util = require("util")
    local rettable = xml.eval(params)

    if rettable == nil then
        util.LogErr("ChinaMobile rettable is nil")
        return errret
    end

    --解析hRet 返回0表示成功
    local hRet = rettable:find('hRet')
    if hRet == nil or hRet[1] == nil or hRet[1] ~= "0" then
        return errret
    end

    --解析道具计费代码
    local consumeCode = rettable:find('consumeCode')
    if consumeCode == nil or consumeCode[1] == nil then
        util.LogErr("*** ChinaBank: parse consumeCode is nil failed")
        return errret
    end

    --解析cpparam
    local cpparam = rettable:find('cpparam')
    if cpparam == nil or cpparam[1] == nil or cpparam[1] == "" then
        return errret
    end

    util.LogInfo("hRet = "..hRet[1].." consumeCode = "..consumeCode[1].." cpparam = "..cpparam[1]);

    local payinfo = {}
    payinfo.orderid = cpparam[1]
    payinfo.price = 0
    payinfo.id = self.id

    util.LogInfo(" ===>ChainMobile RetPayInfo: payinfo.orderid: "
                    ..payinfo.orderid.." payinfo.id: ".. payinfo.id.." payinfo.price: "..payinfo.price)

    util.LogInfo("*** Congratulations ChinaMobile[ NO CHECK ] Check Passed ***")

    return util.PayRet (0, payinfo)
end

function DoYidongDuanRes(self, params)

    local payinfo = {}
    payinfo.res = "0"
    return util.PayRet(1000, payinfo)
end

function ReplyYidongDuanPay(self, errcode, channelinfo)
    if errcode == 0 then
        local res = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><response><hRet>0</hRet><message>Successful</message></response>"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        return nil
    end
end

----------------------------------------------------------
------------------------ 爱贝支付 ------------------------
function DoAiBeiPay(self, params)
    util.LogInfo(" ==>AiBei  params: "..params)

    local util = require("util")
    local errret = util.PayRet(-1, nil)

    local transdata = util.FindValueOfKey(params, "transdata")
    if transdata == nil then
        util.LogErr("*** AiBei : can't find param transdata")
        return errret
    end

    util.LogInfo("AiBei transdata: "..transdata)

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        util.LogErr("*** AiBei : can't find param sign")
        return errret
    end

    local signtype = util.FindValueOfKey(params, "signtype")
    if signtype == nil then
        util.LogErr("*** AiBei : can't find param signtype")
        return errret
    end

    if signtype == "RSA" then
        sign = string.gsub(sign, ' ', '+')
        --data_md5 = util.MD5(transdata)
        local sign_result = util.RSASignVerifyMD5(self.publickey, transdata, sign)
        if sign_result ~= true then 
            util.LogErr("AiBei RSA sign failed...")
            return errret
        end
    else
        util.LogErr("AiBei unknow sign type")
        return errret
    end

    local json = require("json")
    local retcode, retval = pcall(json.decode, transdata)
    if retcode == false then
        LogErr("AiBei decode json failed: "..retval)
        return errret
    end

    if retval.transtype == nil or retval.transtype ~= 0 then
        LogErr("AiBei transtype err")
        return errret
    end
    if retval.result == nil or retval.result ~= 0 then
        LogErr("AiBei result err")
        return errret
    end
    if retval.cporderid == nil then
        LogErr("AiBei can't find cporderid")
        return errret
    end
    if retval.money == nil then
        LogErr("AiBei can't find money")
        return errret
    end

    local payinfo = {}
    payinfo.orderid = retval.cporderid
    payinfo.price = retval.money *100
    payinfo.id = self.id

    util.LogInfo(" ===>AiBei RetPayInfo: payinfo.orderid: "
                    ..payinfo.orderid.." payinfo.id: ".. payinfo.id.." payinfo.price: "..payinfo.price)

    return util.PayRet (0, payinfo)
end

function ReplyAiBeiPay(self, errcode, channelinfo)
    if errcode == 0 then
        local res = "SUCCESS"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    else
        local res = "FAILURE"
        return string.format(HTTP_RESP_FORMAT, string.len(res), res)
    end
end
----海马渠道-------------------------------------------------
function DoHaiMaAccAuth(self, gametype, uid, token)
    local util = require("util")

    if self == nil or self.appid == nil or self.key == nil then
        return nil
    end


    --local sigstr = "appId="..self.appid.."&session="..token.."&uid="..uid
    --local digest = util.HMAC(sigstr, self.key)
    --if digest == nil then
    --    util.LogErr("calc digest for xiaomi acc auth failed: "..sigstr)
    --    return nil
    --end

    local res = "appid="..self.appid.."&t="..token
    util.LogInfo("haima postdata: "..res)
    
    return res
end

function ReplyHaiMaAccAuth(self, retcode)
    local util = require("util")
    local json = require("json")
    --local ret = json.decode(retcode)

    if retcode == nil then
        util.LogErr("Invalid haima acc auth response: nil")
        return -1
    end

    if retcode == "success" then
        return 0
    else 
        util.LogErr("Invalid haima acc auth response: "..retcode)
        return -1
    end
end

function DoHaiMaPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>HaiMa  params: "..params)

    local value = util.FindValueOfKey(params, "notify_time")
    if value == nil then
        util.LogErr("*** haima: can't find notify_time")
        return errret
    end

    local  notify_time = util.encodeURI(value)

    value = util.FindValueOfKey(params, "appid")
    if value == nil then
        util.LogErr("*** haima: can't find appid")
        return errret
    end
    if value ~= self.appid then
        util.LogErr("*** haima: appid:"..value.." ~= self.appid:"..self.appid)
    end
    local appid = util.encodeURI(value)

    value = util.FindValueOfKey(params, "out_trade_no")
    if value == nil then
        util.LogErr("*** haima: can't find order_id")
        return errret
    end
    local out_trade_no = util.encodeURI(value)

    value = util.FindValueOfKey(params, "total_fee")
    if value == nil then
        util.LogErr("*** haima: can't find total_fee")
        return errret
    end
    local total_fee = util.encodeURI(value)

    value = util.FindValueOfKey(params, "subject")
    if value == nil then
        util.LogErr("*** haima: can't find subject")
        return errret
    end
    local subject = util.encodeURI(value)

    value = util.FindValueOfKey(params, "body")
    if value == nil then
        util.LogErr("*** haima: can't find body")
        return errret
    end
    local body = util.encodeURI(value)

    value = util.FindValueOfKey(params, "trade_status")
    if value == nil then
        util.LogErr("*** haima: can't find trade_status")
        return errret
    end
    local trade_status = util.encodeURI(value)

    if trade_status ~= "1" then
        util.LogErr("*** haima: trade_status:"..trade_status.." ~= 1")
        return errret
    end

    value = util.FindValueOfKey(params, "user_param")
    if value == nil then
        util.LogErr("*** haima: can't find user_param")
        return errret
    end
    local user_param = util.encodeURI(value)

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        return errret
    end

    local to_md5_str = "notify_time="..notify_time.."&appid="..appid.."&out_trade_no="..out_trade_no.."&total_fee="..total_fee.."&subject="..subject.."&body="..body.."&trade_status="..trade_status..self.key
    util.LogInfo(" ==>HaiMa  decodeurl params: "..to_md5_str)

    local digest = util.MD5(to_md5_str)
    if digest ~= sign then
        util.LogErr("unmatched sign, given:"..sign.." calculated:"..digest)
        return errret
    end

    local payinfo = {}
    payinfo.orderid = out_trade_no
    payinfo.price = total_fee *100
    payinfo.id = self.id

    return util.PayRet(0, payinfo)
end

function ReplyHaiMaPay(self, errcode, channelinfo)
    local util = require("util")
    local respfmt = "{\"errcode\":%d}"
    local res = nil

    if errcode == 0 then
        res = "success"
    else
        res = "failed"
    end
    return string.format(HTTP_RESP_FORMAT, string.len(res), res)
end
----17waa渠道-------------------------------------------------
function Do17WaaAccAuth(self, gametype, uid, token)
    local util = require("util")

    if self == nil or self.appid == nil or self.key == nil then
        return nil
    end

    local jtime = os.time()

    local game_id = self.appid

    local srv_secret_key = self.key

    local sigstr = srv_secret_key.."/"..game_id.."/"..jtime
    local sign = util.MD5(sigstr)
    if sign == nil then
        util.LogErr("calc digest for 17waa acc auth failed: "..sigstr)
        return nil
    end

    local res = "game_id="..game_id.."&jtime="..jtime.."&sign="..sign.."&juid="..uid.."&jutoken="..token
    util.LogInfo("17waa postdata: "..res)
    
    return res
end

function Reply17WaaAccAuth(self, retcode)
    local util = require("util")
    local json = require("json")
    local ret = json.decode(retcode)

    if ret == nil or ret.code ~= 0 then
        util.LogErr("Invalid 17waa acc auth response:"..retcode)
        return -1
    end

    return 0
end

function Do17WaaPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)
    local json = require("json")

    util.LogInfo(" ==>17waa  params: "..params)

    local transdata = util.FindValueOfKey(params, "transdata")
    if transdata == nil then
        util.LogErr("*** 17waa: can't find transdata")
        return errret
    end

    local transdatajson = json.decode(transdata)

    if transdatajson.game_id == nil or transdatajson.game_id ~= self.appid then
        util.LogErr("*** 17waa: can't find game_id or game_id:"..transdatajson.game_id.."~= self.appid:"..self.appid)
        return errret
    end

    if transdatajson.game_order_id == nil then
        util.LogErr("*** 17waa: can't find game_order_id")
        return errret
    end

    if transdatajson.pay_price == nil then
        util.LogErr("*** 17waa: can't find pay_price")
        return errret
    end
    
    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then
        return errret
    end

    local to_md5_str = transdata.."/"..self.key
    local digest = util.MD5(to_md5_str)
    if digest ~= sign then
        util.LogErr("17waa unmatched sign, given:"..sign.." calculated:"..digest)
        return errret
    end

    local payinfo = {}
    payinfo.orderid = transdatajson.game_order_id
    payinfo.price = transdatajson.pay_price*100
    payinfo.id = self.id

    return util.PayRet(0, payinfo)
end

function Reply17WaaPay(self, errcode, channelinfo)
    local util = require("util")
    local res = nil

    if errcode == 0 then
        res = '{"result":success","message":""}'
    else
        res = '{"result":fail","message":""}'
    end
    return string.format(HTTP_RESP_FORMAT, string.len(res), res)
end
--------------------------------------------------------------------
--**********************************************************--
--                  金三七电信--
--**********************************************************--
function DoJin37DianXinPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>Jin37 dianxin  params: "..params)

    local orderNo = util.FindValueOfKey(params, "orderNo")
    if orderNo == nil then
        util.LogErr("*** Jin37 dainxin: can't find orderNo")
        return errret
    end

    local opId = util.FindValueOfKey(params, "opId")
    if opId == nil then 
        util.LogErr("*** Jin37 dainxin: can't find opId") 
        return errret
    end

    if opId ~= "3" then
        util.LogErr("*** Jin37 dainxin:  invalid opId;"..opId) 
        return errret
    end

    local appId = util.FindValueOfKey(params, "appId")
    if appId == nil then
        util.LogErr("*** Jin37 dainxin: can't find appId")
        return errret
    end

    if appId ~= self.appid then
        util.LogErr("*** Jin37 dainxin: invalid appId:"..appId.."~="..self.appid)
        return errret
    end

    local imsi = util.FindValueOfKey(params, "imsi")
    if imsi == nil then
        util.LogErr("*** Jin37 dainxin: can't find imsi")
        return errret
    end

    local fee = util.FindValueOfKey(params, "fee")
    if fee == nil then
        util.LogErr("*** Jin37 dainxin: can't find fee")
        return errret
    end

    local channelId = util.FindValueOfKey(params, "channelId")
    if channelId == nil then
        util.LogErr("*** Jin37 dainxin: can't find channelId")
        return errret
    end

    if channelId ~= "9014" then
        util.LogErr("*** Jin37 dainxin: invalid channelId:"..channelId)
        return errret
    end

    local exData = util.FindValueOfKey(params, "exData")
    if exData == nil then
        util.LogErr("*** Jin37 dainxin: can't find exData")
        return errret
    end

    local region = util.FindValueOfKey(params, "region")
    if region == nil then
        util.LogErr("*** Jin37 dainxin: can't find region")
        return errret
    end

    local resultCode = util.FindValueOfKey(params, "resultCode")
    if resultCode == nil then
        util.LogErr("*** Jin37 dainxin: can't find resultCode")
        return errret
    end
    if resultCode ~= "000000" then
        util.LogErr("*** Jin37 dainxin:  zhifu failed resultCode:"..resultCode)
        return errret
    end


    local payinfo = {}
    payinfo.orderid = exData
    payinfo.price = fee
    payinfo.id = self.id

    return util.PayRet(0, payinfo)
end

function ReplyJin37DianXinPay(self, errcode, channelinfo)
    local util = require("util")
    local res = nil

    if errcode == 0 then
        res = "-1"
    else
        res = "0"
    end
    return string.format(HTTP_RESP_FORMAT, string.len(res), res)
end
--------------------------------------------------------------------
--**********************************************************--
--                  金三七掌支付--
--**********************************************************--
function DoJin37ZhangzhifuPay(self, params)
    local util = require("util")
    local errret = util.PayRet(-1, nil)

    util.LogInfo(" ==>Jin37 zhangzhifu  params: "..params)

    local orderid = util.FindValueOfKey(params, "orderid")
    if orderid == nil then
        util.LogErr("*** Jin37 zhangzhifu: can't find orderid")
        return errret
    end

    local transeid = util.FindValueOfKey(params, "transeid")
    if transeid == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find transeid") 
        return errret
    end

    local cporderid = util.FindValueOfKey(params, "cporderid")
    if cporderid == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find cporderid") 
        return errret
    end

    local feemode = util.FindValueOfKey(params, "feemode")
    if feemode == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find feemode") 
        return errret
    end

    local appfeeid = util.FindValueOfKey(params, "appfeeid")
    if appfeeid == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find appfeeid") 
        return errret
    end
    local appfeetables = { ["8536"] = 500, ["8537"] = 1000, ["8538"] = 2000, ["8539"] = 5000, ["8540"] = 10000, ["8541"] = 50000, ["8542"]  = 3000, ["8543"] = 9800, ["8544"] = 6800, ["8545"] = 1200, ["8546"] = 600}

    if appfeetables[appfeeid] == nil then
        util.LogErr("*** Jin37 zhangzhifu: invalid appfeeid:" ..appfeeid) 
        return errret
    end

    local appfee = util.FindValueOfKey(params, "appfee")
    if appfee == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find appfee") 
        return errret
    end

    local paidfee = util.FindValueOfKey(params, "paidfee")
    if paidfee == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find paidfee") 
        return errret
    end

    local pushtype = util.FindValueOfKey(params, "pushtype")
    if pushtype == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find pushtype") 
        return errret
    end

    local imsi = util.FindValueOfKey(params, "imsi")
    if imsi == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find imsi") 
        return errret
    end
    
    local appId = util.FindValueOfKey(params, "appId")
    if appId == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find appId") 
        return errret
    end

    if appId ~= self.appid then
        util.LogErr("*** Jin37 zhangzhifu: invalid appid:"..appId.."~=self.appid:"..self.appid) 
        return errret
    end

    local appname = util.FindValueOfKey(params, "appname")
    if appname == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find appname") 
        return errret
    end

    local qd = util.FindValueOfKey(params, "qd")
    if qd == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find qd") 
        return errret
    end

    local qdname = util.FindValueOfKey(params, "qdname")
    if qdname == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find qdname") 
        return errret
    end

    local op = util.FindValueOfKey(params, "op")
    if op == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find op") 
        return errret
    end

    local sign = util.FindValueOfKey(params, "sign")
    if sign == nil then 
        util.LogErr("*** Jin37 zhangzhifu: can't find sign") 
        return errret
    end

    local sigstr = "cp="..self.cpid.."&orderid="..orderid.."&transeid="..transeid.."&cporderid="..cporderid.."&feemode="..feemode.."&appfeeid="..appfeeid.."&paidfee="..paidfee
    local signkey = util.MD5(sigstr)
    if signkey == nil then
        util.LogErr("calc digest for jin37 acc auth failed: "..sigkey)
        return errret
    end

    if signkey ~= string.lower(sign) then
        util.LogErr("calc digest for jin37 invalid sign: "..sign.."~=signkey:"..signkey)
        return errret
    end

    local payinfo = {}
    payinfo.orderid = cporderid
    payinfo.price = appfee
    payinfo.id = self.id

    return util.PayRet(0, payinfo)
end

function ReplyJin37ZhangzhifuPay(self, errcode, channelinfo)
    local util = require("util")
    local res = nil

    if errcode == 0 then
        res = "0"
    else
        res = "1"
    end
    return string.format(HTTP_RESP_FORMAT, string.len(res), res)
end
------------快发支付验证--------------
function DoKuaiFaPay(self,params)
    local util = require("util")
    local curl = require("curl")

    local errret = util.PayRet(-1, nil)

    util.LogInfo("KuaiFa ===> params: "..params)

    --解析参数
    local ptable={
        {key="serial_number",value=nil},
        {key="cp",value=nil},
        {key="timestamp",value=nil},
        {key="result",value=nil},
        {key="extend",value=nil},
        {key="server",value=nil},
        {key="product_id",value=nil},
        {key="product_num",value=nil},
        {key="game_orderno",value=nil},
        {key="amount",value=nil},
    }

    for k,v in pairs(ptable) do
        v.value = util.FindValueOfKey(params,v.key)
        if v.value == nil then
            util.LogErr("*** KuaiFa pay: can't find "..v.key)
            return errret
        end
    end

    --单独解析sign
    local sign = util.FindValueOfKey(params,"sign")
    if sign == nil then
        util.LogErr("*** KuaiFa pay: can't find sign")
        return errret
    end

    --对参数(除sign外)按参数名字母生序排序
    table.sort(ptable,function(a,b) return a.key < b.key end)

    --连接各个参数，并对参数值进行urlencode
    local isFirst = true
    local raw = ""
    for k,v in pairs(ptable) do
        if isFirst then
            raw = v.key.."="..curl.escape(v.value)
            isFirst = false
        else
            raw = raw .. "&" .. v.key .."="..curl.escape(v.value)
        end
    end

    util.LogInfo("*** KuaiFa pay: raw is "..raw)

    --计算md5
    local sign_cal = util.MD5(util.MD5(raw)..self.key)
    util.LogInfo("*** KuaiFa pay: sign cal is "..sign_cal)
    
    --与sign对比
    if sign_cal ~= sign then
        util.LogErr("*** KuaiFa pay: sign_cal "..sign_cal.." ~= sign "..sign)
        return errret
    end

    --解析出订单号等信息,返回订单信息给调用者
    function getParam(table,key)
        for k,v in pairs(table) do
            if v.key == key then
                return v.value
            end
        end
        return nil
    end

    --判断支付结果
    local result = getParam(ptable,"result")
    if result ~= "0" then
        util.LogErr("*** KuaiFa pay: result is "..result)
        return errret
    end

    local payinfo = {}
    payinfo.orderid = getParam(ptable,"game_orderno")
    payinfo.price = getParam(ptable,"amount")*100 --转换为分
    payinfo.id = self.id

    util.LogInfo("*** KuaiFa pay: check pass orderid = "..payinfo.orderid)

    return util.PayRet(0, payinfo)
end
------------快发支付回复--------------
function ReplyKuaiFaPay(self, errcode, channelinfo)
    local res_format = "{\"result\":\"%d\",\"result_desc\":\"%s\"}"
    local res=""
    if errcode == 0 then
        res = string.format(res_format,0,"ok")
    else
        res = string.format(res_format,1,string.format("发货失败:err %d",errcode))
    end
    return string.format(HTTP_RESP_FORMAT, string.len(res), res)
end

--------------------------------------------------------------------
--**********************************************************--
--                  渠道信息配置表                          --
--**********************************************************--
-- id, url, game id/key
channels = {
    {
        id = 1,
        authid = 1,
        acc = "http://mis.migc.xiaomi.com/api/biz/service/verifySession.do",
        url = "/texas/payauth/xiaomi",
        accauthfunc = DoXiaoMiAccAuth,
        accauthretfunc = ReplyXiaoMiAccAuth,
        payauthfunc = DoXiaoMiPay,
        payauthretfunc = ReplyXiaoMiPay,
        appid = "2882303761517295757",
        key = "OfnXJj6WxqPX/YPVbb+x7Q==",
    },
    
    {
        -- 手机短信网关，需特殊处理
        authid = 2,
        acc = "http://sms.kserv.cn/mobilesrv/public/index.php?r=smsproxy/send&",
        accauthfunc = DoPhoneTextGWAuth,
        accauthretfunc = ReplyPhoneTextGWAuth,
        key = "ximi9527",
    },

    {
        id = 2,
        url = "/texas/payauth/zhifubaopay",
        payauthfunc = DoZhiFuBaoPay_Uniform,
        payauthretfunc = ReplyZhiFuBaoPay_Uniform,
        appid = "1602d863b3034ad50bce12394ddbba1c",
        key = "jup0b428jl83ibi5mjby400455wka7mz",
    },

    {
        id = 3,
        url = "/texas/payauth/yidong",
        payauthfunc = DoChinaMobilePay,
        payauthretfunc = ReplyChinaMobilePay,
        appid = "23004388",
        key = "f770aa7c7190c5500b9bb3c10306f000",
    },

    {
        id = 4,
        url = "/texas/payauth/tmallbox",
        payauthfunc = DoAliPay,
        payauthretfunc = ReplyAliPay,
        privatekey = [[-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBALpqLqth+7RAFDaf
8w3GE4eIIFo6m1PWi5aO7gJeXIAutKZoXYBNjmlDGfF/nR7K9rEzM2ppNcQ4uL4n
wL76YVXqCQqgB+j0vZN0Oo8jiPCgzBR9YaYAKzicL64H9IZdbxSsj9twf1uJVk6W
g6YRln2wtsOyoPQMq4IO50Kb7dQPAgMBAAECgYAwx2ow5HHVx9LCPHaASy1/EIrO
sXlFpeVe30W+juyLii0xQiv9T84NE0btn6QAk8GburcgiClOkD0fXQ2dq6zeOLpL
QonQ3ziQz6mWU1+9lzRxOipWa/RcqDQaOfrpBWIGW9y1VLR6raoZ2/S/nDRvg1V9
pSTDw6j36+kP2fWggQJBAOt4oSBfH5eoRJm/Y2Op3jDSWURReSlrmOYv4CehvniG
h9irsU39jgMoQqfhXeqZxF4Y9PjORkkeyOxBo+w6aMECQQDKqq9/nQg5jFA9A8q/
f0eYxfCRAqvmyM91BXSbDjOgA9t0gB1Gj5sBdV1dDBFpfZ3Iti9rfV3gvObr2LjP
WyDPAkA+kjyGxKA5hZ5NGL2Jc082u/66l8fRiOUFbf1rqqBZmK4qll00M0d0cVNd
FxcEyz2SH6GhJ/cnYQXVOhAcKt1BAkB1rNfMDDzrVUp9swb1XA0RatU9DcUMcsrq
kqlbIsrc/YBeS8kz4ExLc38reMdfbj3AffBYxGlPBcA7bxIX7DzHAkEAhO/9JjnE
XlTPgtDLxSotAQ2S68D3z2Vi90hHfUkfxel+R4p9BqcEn9mQakXGcKqth7+yQhcC
SXTiS94ZKJ6nOw==
-----END PRIVATE KEY-----]],
    },

    {
        id = 5,
        url = "/texas/payauth/damaitv",
        payauthfunc = DoDaMaiTVPay,
        payauthretfunc = ReplyDaMaiTVPay,
        appid = "p150121110013224",
        key = "b0b7ef5df442ddd26b443b967d91d2c7"

    },

    {
        id = 6,
        url = "/texas/payauth/kukaipay",
        payauthfunc = DoKuKaiTVPay,
        payauthretfunc = ReplyKuKaiTVPay,
        appid = "2024",
        key = "0e4a8ff0969e6effde1d83befc9ff587"
    },

    {
        id = 7,
        url = "/texas/payauth/putaotv",
        payauthfunc = DoPuTaoPay,
        payauthretfunc = ReplyPuTaoPay,
        privatekey = [[-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA02DSY1HkGN+UWIaobm+R0L2RZYf9BDTosSdy5S7ub7jR8oHp
z4IZgQ2whC145fX2cnjU7zYJoSVlfiuJ9JJLZ48Zxcsfss/Skivvn17rRMxjToNH
/f1tv8+o0AvKv7TxR/G6h4P//H389CaaEciPhuCaghc9bDtQydQ3dNNTFm6vubLm
oGt1l51YcysEexvqeahBLG+Eh5TJyOtCMmL9iNi/ytF95UoX4/oZwiitggyGZnfC
IrMaeqP4xe0k+A8xQRR2y0IfMnUzQsKvI7Pl5IDKVC4OicF2dfpAQDBthg3PBvxM
CLf6jaUbjYPGaLOaeOE/385lvFQ3o8Ffv4hmIwIBEQKCAQEAuoKbhM/JQx+hAtEr
NERTe/KPWZYbfC6vMuaSjfw7y/1t9BhGxid/6ldfg6+m6QYzzmqdxAKA95l3q4/U
FAic4uetVCuyjrdfceqIIzWiaeGEzM4wdrJv5Xr+XTeUx0VNXZkN/xoeGwXBE6mX
AKHoDZkAzSOQjKzO0DO4diPf5pxLbjizivFYzloYlkGsZPej+SomWE7EIJG3Nwih
/P556J+ANlte0MEilsX3bigJs9Kzo8m9q8sLkN5DUILrOOF4tkWIVuSBw3+4IbnD
aHTiqeFNJhm2oGiK1c0uTahjpHEiLWqLSPUv8bSgtocS0AsUg2jo3hjE+IS6ADlQ
MEpcaQKBgQDzNVis2TqxiFapsSjLGsSPmT+xvHnWZ7BDNE+y/SVG2VQwV9yDG2jZ
1PtOQCsxJOTyNKl4MBNMDycqFPXJJUAsF+pjSbanv/Cvfionq/Vwq6pnpgF+T64j
nOt5mQ5W9PILbPXgrceVFhREDhH4MyFhC5bK9DQ41MpbpbflIDE7/QKBgQDefubD
oTBOWJxOoEBT3NhLtPSGHPG+x8fqIwk+BXKj/TYxV3xcIY7jqGKzFjaCbzjImlAM
llNJ2F7Gqw2mklgE4x+KDf/1ctGiBMX/VrF0VixglA9r6q3os4yjPg3p586/ACdE
9y/ZzAhln4Njjg4zPsJ+EgajARWRuYRB4BP0nwKBgGQlBmVKY3ZHMr5YAb0LBaSK
ZYVrubKjKnYGeyuVabPC5m5CS72DwcMbdomh86rS9NwzzU+bUz1vprb5kmHiKXuR
YIM8eGMw6qKdXKbsdB9VvqMmPNmoVsNeu1Av9tiC+kDwoXqh6MTq+Uky+FckHM2b
XDVznQhXnp41LZqUyPqVAoGBAILhPHMThdO7pz1PNOYJcCyIj9ZrYQbP3wIyuiR7
rNjvTQ33OhgTvXbbhVpJTT2q1humEPhYbTp/Rs83cXEKyl06Tsmt4dus88i3g4cj
7+oUkpMp6vQvsZfxJY0zj7bEl7ulvL8n/gelMh2pIBxxrgAGzMKhMRSXOd0/83IL
VwhdAoGBAOrwbiYWVpsxA6tiG1djK82cSIf0n057DKJu4aJoFWw9Kwhnqtu99iNL
JYwJ3LkJNrFGazS6HF/k4TsWl5t97SRyAJz6psBmll9OBhoMStbhZ7BpiR8XMHM9
/C4A/k7VN2oLAMb/AmXPwrPNNYwxc3aiFPyntZaWgf5LP1J6ei8b
-----END RSA PRIVATE KEY-----]],  
    },

    {
        id = 8,
        url = "/texas/payauth/shafapay",
        payauthfunc = DoShaFaTVPay,
        payauthretfunc = ReplyShaFaTVPay,
        appid = "p140822110757922",
        key = "a121c36569a78f4b43e99fa1482704f2"
    },

    {
        id = 9,
        url = "/texas/payauth/wangxun",
        payauthfunc = DoWangXunTVPay,
        payauthretfunc = ReplyWangXunTVPay,
        appid = "0908050905050002040d0f08030e0801",
        key = "BAsKAgQdC5Gy8CzJZ1wF4vVno"
    },

    {
        id = 10,
        url = "/texas/payauth/huanwang",
        payauthfunc = DoHuanFuBaoTVPay,
        payauthretfunc = ReplyHuanFuBaoTVPay,
        appid = "123456",
        key = "e2d2d0c260694f495cb424cc62a083b3"
    },

    {
        id = 11,
        url = "/texas/payauth/letv",
        payauthfunc = DoLeTVPay,
        payauthretfunc = ReplyLeTVPay,
        appid = "d24ce57aede2d44f98752692332a1974",
        key = "e64a5df5bc8647b1a371690c4c8c0b13",
    },

    {
        id = 12, 
        url = "/texas/payauth/tcltv",
        payauthfunc = DoTclPay,
        payauthretfunc = ReplyTclPay,
        privatekey = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCcd4UcY1KRWwy5POoF4
+GTqKCkTE6dU9W8z+lOmfn4zRkS1/mioXsKN1Qj9sAoUNZGD8VPgCR9KD
E9LV3G8TFwgUX50nb/8TfZ3ypqGMm7k/m2OzrTUzHNtbh1ytKx/i6TedI
kf7Qs0iuTwDkVuMqc6UTQPyFi6reyDsGd8I4H6QIDAQAB
-----END PUBLIC KEY-----]],
    },

    {
        id = 13,
        url = "/texas/payauth/haixinpay",
        payauthfunc = DoHaiXinPay,
        payauthretfunc = ReplyHaiXinPay,
        appid = "",
        key = "8ADC73C4766C43B453A24638B2C70177",
    },

    {
        id = 13,
        url = "/texas/payauth/haixintv",
        payauthfunc = DoZhiFuBaoPay_Uniform,
        payauthretfunc = ReplyZhiFuBaoPay_Uniform,
        appid = "1602d863b3034ad50bce12394ddbba1c",
        key = "jup0b428jl83ibi5mjby400455wka7mz",
    },

    {
        id = 14,
        url = "/texas/payauth/egametv",
        payauthfunc = DoLoveGameTVPay,
        payauthretfunc = ReplyLoveGameTVPay,
        appid = "23004388",
        key = "ef56b106ea38a8db54c27381e9f224ad",
        fromer = "90731527"
    },

    {
        id = 15,
        url = "/texas/payauth/lenovo",
        payauthfunc = DoLenovoPay,
        payauthretfunc = ReplyLenovoPay,
        privatekey = [[-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAN77o0XGUrhJr+4ZD
gPFERkBZNxYstqP6wqvBoLJO0fqJnB6G7qgMotdTtxjop8YTba9XMKU2NDAKVTeXj
xJ9YEePVVoQdclh1e5sid69ak/JI3hIGFuRGkrrhUVVIll3OVHMXk7y6iuE52t/nl
s+rh7Njlwi/dMPgfCsQeFljOHAgMBAAECgYEAvubZBeeg8j3D7ShuIzQYSzwySaN2
nEASjncCL/5wTkVc23bvPnvgSgh8d5qlo2d/QTAltkEQzsd1mz81lpALKgKwCFQt+
lBZesQE6u0LKj/u5NKa6qhemS05lT7RaEbukiOh0FMoULC/gBQui5gjRs6fiw5Hoz
UZqWY24zJUNmECQQD0e+slMgzT5C0XaqHwkodtBkvt/JkJv80NrZ2gZcNiwAhXBDn
ibGB0ROdfaTDniCitrxVeNC3q19j5T6qvKbLVAkEA6XxzbDltNl89/alCCo0TNMsk
LSQfsCkhlYMJrZalV5mCWc+asEKOd5pUUkapPJ1mh54g/0ubVL9hP/iLIjPi6wJAG
bIMfNRN1Ndehd+HNamw4hyPTmwGCahG/PEKaBlJ988HEV44Vzvcx1uWlciQg0UkQV
ztegEx8kTNYSamYdKYIQJBAKRxFyW4yFdL+vAFXlLqCwXasK7uSzcZsOKJOK6+c9L
fdfPlCFBtf8NyuUJ9K8JaJRUM5LaJPGwSod6ZIPzEyGMCQDfFATWdPJnfT6EEDmiZ
ihDDrn6TFeA194c6y36ZB1GV2SqSd0sGSkvvT6RJYJmEtu/YgMcaP5wOFQ/lwim5N
zE=
-----END PRIVATE KEY-----]],
        publickey = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCNoAvMLy35cXxoGqy5uAJwUXcE9
gmBs848T7M/MyLVqoWUUm7/G15DhC5mf/gnyWI6GS4a9ItlkF3xBV9Vg3ebqk3SWy
KjrcIvQWmW/HHZ1MotGAoWtEWIaONV8ipwla+sdFlMwfRujGhOzYiDi8w3FQPRahu
JHjIr2Duu/Grw2QIDAQAB
-----END PUBLIC KEY-----]],
    },

    {
        id = 16,
        url = "/texas/payauth/xiaomiphone",
        payauthfunc = DoXiaoMiPhonePay,
        payauthretfunc = ReplyXiaoMiPay,
        appid = "2882303761517311915",
        key = "pDHumcmNm7C0tUD1IebfjA==",
    },

    {
        id = 17,
        url = "/texas/payauth/shiboyun",
        payauthfunc = DoShiBoYunPay,
        payauthretfunc = ReplyShiBoYunPay,
        appid = "2882303761517311915",
        key = "19f0c1",
    },

    {
        id = 18,
        url = "/texas/payauth/dianxin/duan",
        payauthfunc = DoDianxinDuanPay,
        payauthretfunc = ReplyDianxinDuanPay,
        key = "ffd7e09dd63691eb28805734d3f90d2a",
    },

    {
        id = 19,
        url = "/texas/payauth/liantong/duan",
        payauthfunc = DoLiantongDuanPay,
        payauthretfunc = ReplyLiantongDuanPay,
        appid = "909079645520150427183605316000",
        key = "f6c79f4af478638c39b2",
    },

    {
        id = 20,
        url = "/texas/payauth/yidong/duan",
        payauthfunc = DoYidongDuanPay,
        payauthretfunc = ReplyYidongDuanPay,
    },

    {
        url = "/texas/userid/yidong/duan",
        payauthfunc = DoYidongDuanRes,
    },
    {
        id = 21,
        url = "/texas/payauth/tmallbox_new",
        payauthfunc = DoAliPayNew,
        payauthretfunc = ReplyAliPayNew,
        key = "2193f2f522c81516c6cea8ada5ac0f98",
    },

    {
        id = 24,
        url = "/texas/payauth/zhifubaopay_ph",
        payauthfunc = DoZhiFuBaoPay_Ph,
        payauthretfunc = ReplyZhiFuBaoPay_Ph,
        publickey = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCnxj/9qwVfgoUh/
y2W89L6BkRAFljhNhgPdyPuBV64bfQNN1PjbCzkIM6qRdKBoLPXmK
KMiFYnkd6rAoprih3/PrQEB/VsW8OoM8fxn67UDYuyBTqA23MML9q
1+ilIZwBC2AQ2UBVOrFXfFl75p6/B5KsiNG9zpgmLCUYuLkxpLQID
AQAB
-----END PUBLIC KEY-----]],
    },

     {	--贵州欢网--
        id = 25,
        url = "/texas/payauth/guizhouhuanwang",
        payauthfunc = DoHuanFuBaoTVPay_2,
        payauthretfunc = ReplyHuanFuBaoTVPay_2,
        appid = "",
        key = "e2d2d0c260694f495cb424cc62a083b3",
    },

    {
        id = 26,
        url = "/texas/payauth/aibei",
        payauthfunc = DoAiBeiPay,
        payauthretfunc = ReplyAiBeiPay,
        publickey = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCCALu7CpADAt0Xe
oftZ7tmXwCLp4uNOc+OfJhVl0aGt6rBOh+yt5zdQajztb1FPbIW1h
9aa/x7rXUBI21tV5quPZ/b9cuCOS5v4x+KtEt9woI3CfhBNjzt4DF
SDdv9GTQLtRUPGp29ZdcXMBq5YvV7qLbj4Rbr2Tvv4aMR3ThA9QID
AQAB
-----END PUBLIC KEY-----]],
    },

	{
        id = 27,
        url = "/texas/payauth/dianxin/lovepoker/duan",
        payauthfunc = DoDianxinDuanPay,
        payauthretfunc = ReplyDianxinDuanPay,
        key = "ffd7e09dd63691eb28805734d3f90d2a",
    },

    {
        id = 28,
        url = "/texas/payauth/liantong/lovepoker/duan",
        payauthfunc = DoLiantongDuanPay,
        payauthretfunc = ReplyLiantongDuanPay,
        appid = "909079645520150427183605316000",
        key = "f6c79f4af478638c39b2",
    },

    {
        id = 29,
        url = "/texas/payauth/yidong/lovepoker/duan",
        payauthfunc = DoYidongDuanPay,
        payauthretfunc = ReplyYidongDuanPay,
    },

    {
        url = "/texas/userid/yidong/lovepoker/duan",
        payauthfunc = DoYidongDuanRes,
    },
    {
        id = 99999,
        url = "/texas/payauth/zhifubaopay_test",
        payauthfunc = DoAliPayNew,
        payauthretfunc = ReplyAliPayNew,
        key = "2193f2f522c81516c6cea8ada5ac0f98",
    },

    {
        id = 30,
        authid = 3,
        httpoption = 1,
        acc = "http://api.haimawan.com/index.php?m=api&a=validate_token",
        url = "/texas/payauth/haima",
        accauthfunc = DoHaiMaAccAuth,
        accauthretfunc = ReplyHaiMaAccAuth,
        payauthfunc = DoHaiMaPay,
        payauthretfunc = ReplyHaiMaPay,
        appid = "967f8ca60dbbb7ce741c9631b7f29a1c",
        key = "b210cc1fd09229641223aa2944a783a4",
    },

    {
        id = 31,
        authid = 4,
        httpoption = 1,
        acc = "http://query.17waa.com/checkUser",
        url = "/texas/payauth/17waa",
        accauthfunc = Do17WaaAccAuth,
        accauthretfunc = Reply17WaaAccAuth,
        payauthfunc = Do17WaaPay,
        payauthretfunc = Reply17WaaPay,
        appid = "200474-71d613f6-a5151370dc63315d6cab66a6",
        key = "201915-d7a1d90f-b9d964f51931a81d029daf24",
    },

    {
        id = 32,
        url = "/texas/payauth/jin37dainxin",
        payauthfunc = DoJin37DianXinPay,
        payauthretfunc = ReplyJin37DianXinPay,
        appid = "118100001",
        cpid = "1181",
    },

    {
        id = 33,
        url = "/texas/payauth/jin37zhangzhifu",
        payauthfunc = DoJin37ZhangzhifuPay,
        payauthretfunc = ReplyJin37ZhangzhifuPay,
        appid = "1419",
        key = "08708A70EE224B689B8F41EF3B6E16B6",
        cpid="1000100020000339",
    },
    {
        id = 34,
        url = "/texas/payauth/kuaifa",
        payauthfunc = DoKuaiFaPay,
        payauthretfunc = ReplyKuaiFaPay,
        key = "ynLWf4FxvVuF0L9kKLeYaMWrEPrgfmhf",
    },
}
function GetChannelInfoByUrl(url)
    for i,v in ipairs(channels) do
        if v.url == url then
            return v
        end
    end
    return nil
end

function GetChannelInfoById(id)
    for i,v in ipairs(channels) do
        if v.authid == id then
            return v
        end
    end
    return nil
end

function GetChannelInfoByChannelId(id)
    for i,v in ipairs(channels) do
        if v.id == id then
            return v
        end
    end
    return nil
end

