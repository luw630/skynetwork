-- 定义所有第三方渠道信息及帐号认证、支付回调处理接口
--package.cpath = "../../skynet/luaclib/?.so;../core/3rd/lua-cjson/?.so;../core/3rd/lua-xml/?.so"
--package.path = "../../skynet/lualib/?.lua;../core/?.lua;../core/3rd/lua-xml/?.lua"

local json = require "cjson"
local md5 = require "md5"
local filelog = require "filelog"
local timetool = require "timetool"
local urllib = require "http.url"
local util = require "util"
require "xmlSimple"
local xmlparser = newParser()

json.encode_sparse_array(true,1,1)

--------------------------------------------------------------
--**********************************************************--
--                  渠道信息配置表                          --
--**********************************************************--
local converttable = {
  "0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p",
  "q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
  "Q","R","S","T","U","V","W","X","Y","Z"
}
-- id, url, id/key
--生成长度小于32位的随机字符串
function generate_randomstr()
    local randomstr = ""
    math.randomseed(timetool.get_time())
    for i=1, 24 do
        randomstr = randomstr..converttable[math.random(1, #converttable)]
    end
    return randomstr
end
--ios支付相关
function do_ios_pay(request, channelinfo)
    return (json.encode({["receipt-data"]=request.option_data}))
end 

function reply_ios_pay(body, channelinfo)
    local retcode, rettable = pcall(json.decode, body)
    return retcode, rettable
end

--微信支付相关
function do_wechat_prepay(request, channelinfo)
    local option_data = json.decode(request.option_data)
    local rechargeconf = json.decode(request.rechargeconf)
    math.randomseed(timetool.get_time())
    local nonce_str = generate_randomstr()
    local post_data = "<xml>\r\n<appid>"..channelinfo.appid.."</appid>\r\n<mch_id>1290374401</mch_id>\r\n<nonce_str>"..nonce_str.."</nonce_str>\r\n<body>"..
                    rechargeconf.des.."</body>\r\n<out_trade_no>"..request.order_id.."</out_trade_no>\r\n<total_fee>"..
                    rechargeconf.price.."</total_fee>\r\n<spbill_create_ip>"..request.ip.."</spbill_create_ip>\r\n<notify_url>"..
                    "http://120.132.94.79:6999"..channelinfo.url.."</notify_url>\r\n<trade_type>APP</trade_type>\r\n" 
    local signstr = "appid="..channelinfo.appid.."&body="..rechargeconf.des.."&mch_id=1290374401&nonce_str="..nonce_str.."&notify_url=http://120.132.94.79:6999"..channelinfo.url.."&out_trade_no="..
                    request.order_id.."&spbill_create_ip="..request.ip.."&total_fee="..rechargeconf.price.."&trade_type=APP&key="..channelinfo.key
    local sign = string.upper(md5.sumhexa(signstr))
    post_data = post_data.."<sign>"..sign.."</sign>\r\n</xml>"
    filelog.sys_obj("webclient", "wechat", "do_wechat_prepay", post_data, signstr, sign)
    return post_data
end

function reply_wechat_prepay(body, channelinfo)
    --去掉CDATA标签
    local str1 = string.gsub(body, "<!%[CDATA%[", "")
    local str2 = string.gsub(str1, "%]%]>", "")
    local xmlparsed = xmlparser:ParseXmlText(str2)

    if xmlparsed == nil or xmlparsed.xml == nil then
        filelog.sys_obj("webclient", "wechat", "reply_wechat_prepay xmlparsed == nil or xmlparsed.xml == nil")
        return false, nil
    end
    if xmlparsed.xml.return_code == nil then
        filelog.sys_obj("webclient", "wechat", "reply_wechat_prepay return_code == nil")
        return false, nil
    end

    if xmlparsed.xml.return_code:value() ~= "SUCCESS" then
        filelog.sys_obj("webclient", "wechat", "reply_wechat_prepay return_code ~= SUCCESS")
        return false, nil
    end 
    
    if xmlparsed.xml.result_code == nil then
        filelog.sys_obj("webclient", "wechat", "reply_wechat_prepay result_code == nil")
        return false, nil
    end

    if xmlparsed.xml.result_code:value() ~= "SUCCESS" then
        filelog.sys_obj("webclient", "wechat", "reply_wechat_prepay result_code ~= SUCCESS")
        return false, nil
    end

    --TO ADD 签名校验

    local wxpay = {
        appid = channelinfo.appid,
        partnerid = 1290374401,
        noncestr = generate_randomstr(),
        timestamp = timetool.get_time(),
        package = "Sign=WXPay",
        prepayid = xmlparsed.xml.prepay_id:value(),
    }
    local signstr = "appid="..channelinfo.appid.."&noncestr="..wxpay.noncestr.."&package="..
                    wxpay.package.."&partnerid="..wxpay.partnerid.."&prepayid="..wxpay.prepayid..
                    "&timestamp="..wxpay.timestamp.."&key="..channelinfo.key
    wxpay.sign=string.upper(md5.sumhexa(signstr))
    return true, wxpay    
end

function do_wechat_pay(body, channelinfo)
    local errret = 0
    local orderinfo = {}
    --去掉CDATA标签
    local str1 = string.gsub(body, "<!%[CDATA%[", "")
    local str2 = string.gsub(str1, "%]%]>", "")

    local xmlparsed = xmlparser:ParseXmlText(str2)
    if xmlparsed == nil or xmlparsed.xml == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay xmlparsed == nil or xmlparsed.xml == nil")
        return -1, nil
    end

    local result_code = xmlparsed.xml.result_code
    if result_code == nil or result_code:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no result_code")        
        return -1, nil        
    end
    result_code = result_code:value()

    if result_code ~= "SUCCESS" then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay result_code is not SUCCESS")        
        return -1, nil
    end

    local out_trade_no = xmlparsed.xml.out_trade_no
    if out_trade_no == nil or out_trade_no:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no out_trade_no")        
        return -1, nil
    end
    out_trade_no = out_trade_no:value()

    local appid = xmlparsed.xml.appid
    if appid == nil or appid:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no appid")
        return -1, nil
    end
    appid = appid:value()

    local bank_type = xmlparsed.xml.bank_type
    if bank_type == nil or bank_type:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no bank_type")
        return -1, nil
    end
    bank_type = bank_type:value()

    local cash_fee = xmlparsed.xml.cash_fee
    if cash_fee == nil or cash_fee:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no cash_fee")
        return -1, nil
    end
    cash_fee = cash_fee:value()

    --fee_type，非必填
    local fee_type = xmlparsed.xml.fee_type
    if fee_type == nil or fee_type:value() == nil then
        --return errret
    else
        fee_type = fee_type:value()
    end

    local is_subscribe = xmlparsed.xml.is_subscribe
    if is_subscribe == nil or is_subscribe:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no is_subscribe")
        return -1, nil
    end
    is_subscribe = is_subscribe:value()

    local mch_id = xmlparsed.xml.mch_id
    if mch_id == nil or mch_id:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no mch_id")
        return -1, nil
    end
    mch_id = mch_id:value()

    local nonce_str = xmlparsed.xml.nonce_str
    if nonce_str == nil or nonce_str:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no nonce_str")
        return -1, nil
    end
    nonce_str = nonce_str:value()

    local openid = xmlparsed.xml.openid
    if openid == nil or openid:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no openid")
        return -1, nil
    end
    openid = openid:value()

    local return_code = xmlparsed.xml.return_code
    if return_code == nil or return_code:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no return_code")
        return -1, nil
    end
    return_code = return_code:value()

    local sign = xmlparsed.xml.sign
    if sign == nil or sign:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no sign")
        return -1, nil
    end
    sign = sign:value()

    local time_end = xmlparsed.xml.time_end
    if time_end == nil or time_end:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no time_end")
        return -1, nil
    end
    time_end = time_end:value()

    local total_fee = xmlparsed.xml.total_fee
    if total_fee == nil or total_fee:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no total_fee")
        return -1, nil
    end
    total_fee = total_fee:value()

    local trade_type = xmlparsed.xml.trade_type
    if trade_type == nil or trade_type:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no trade_type")
        return -1, nil
    end
    trade_type = trade_type:value()

    local transaction_id = xmlparsed.xml.transaction_id
    if transaction_id == nil or transaction_id:value() == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay no transaction_id")
        return -1, nil
    end
    transaction_id = transaction_id:value()

    --拼接签名字符串，参数名ASCII码从小到大排序
    if channelinfo.appid == nil or channelinfo.key == nil then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay can't find appinfo")
        return -1, nil
    end

    local cryptstr = "appid="..appid.."&bank_type="..bank_type.."&cash_fee="..cash_fee

    if fee_type ~= nil and fee_type ~= nil then
        cryptstr = cryptstr.."&fee_type="..fee_type
    end

    cryptstr = cryptstr.."&is_subscribe="..is_subscribe.."&mch_id="..mch_id.."&nonce_str="..nonce_str.."&openid="..openid.."&out_trade_no="..out_trade_no.."&result_code="..result_code.."&return_code="..return_code
    cryptstr = cryptstr.."&time_end="..time_end.."&total_fee="..total_fee.."&trade_type="..trade_type.."&transaction_id="..transaction_id.."&key="..channelinfo.key

    filelog.sys_obj("paycallback", "wechat", "do_wechat_pay cryptstr is", cryptstr)

    local crypt_result = string.upper(md5.sumhexa(cryptstr))
    local crypt_recv = string.upper(sign)

    if crypt_result ~= crypt_recv then
        filelog.sys_obj("paycallback", "wechat", "do_wechat_pay unmatched signature given", crypt_recv, cryptstr)
        return -1, nil
    end

    orderinfo.pay_type = channelinfo.id
    orderinfo.order_id = out_trade_no
    orderinfo.price = tonumber(total_fee)

    return 0, orderinfo
end

function reply_wechat_pay(errcode, info)
    local retstr = nil
    if errcode == 0 then     --发送订单确认消息
        retstr = "<xml>\r\n<return_code><![CDATA[SUCCESS]]></return_code>\r\n<return_msg><![CDATA[OK]]></return_msg>\r\n</xml>"
    else
        retstr = "<xml>\r\n<return_code><![CDATA[FAIL]]></return_code>\r\n<return_msg><![CDATA[NOT OK]]></return_msg>\r\n</xml>"
    end
    filelog.sys_obj("paycallback", "wechat", "reply_wechat_pay", retstr)
    return retstr
end

--支付宝支付
function generate_zhifubao_params(request, rechargeconf, channelinfo)
    local partner = channelinfo.appid

    local notify_url = channelinfo.notify_url..channelinfo.url
    local out_trade_no=request.order_id 
    local subject=rechargeconf.name
    local total_fee=rechargeconf.price / 100
    local payment_type = "1"
    local seller_id = "pay@juzhongjoy.com"
    local body = rechargeconf.des

    local signstr = "partner=\""..partner.."\"&seller_id=\""..seller_id
                    .."\"&out_trade_no=\""..out_trade_no.."\"&subject=\""..subject
                    .."\"&body=\""..body.."\"&total_fee=\""..total_fee
                    .."\"&notify_url=\""..notify_url
                    .."\"&service=\"mobile.securitypay.pay\"&payment_type=\"1\"&_input_charset=\"utf-8\"&it_b_pay=\"30m\"&return_url=\"m.alipay.com\""
    local sign = util.rsa_private_sign(signstr, channelinfo.privatekey)

    --filelog.sys_info(signstr.."&sign=\""..sign.."\"")
    
    local requestpaystr = signstr.."&sign=\""..util.encodeuri(sign).."\"&sign_type=\"RSA\""

    --filelog.sys_info("requestpaystr", requestpaystr)
    return requestpaystr
end

function do_zhifubao_prepay(request, channelinfo)
end
function reply_zhifubao_prepay(body, channelinfo)
end

function do_zhifubao_pay(params, channelinfo)
    local errret = 0
    local orderinfo = {}
    --filelog.sys_obj("paycallback", "zhifubao", params)
    params = util.decodeuri(params)
    --解析notify_time 通知时间
    local notify_time = util.find_value_Of_key(params, "notify_time")
    if notify_time == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find notify_time")
        return -1, nil
    end

    --解析notify_type 通知类型 
    local notify_type = util.find_value_Of_key(params, "notify_type")
    if notify_type == nil then      
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find notify_type")
        return -1, nil
    end

    --notify_id解析通知校验ID 
    local notify_id = util.find_value_Of_key(params, "notify_id")
    if notify_id == nil then      
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find notify_id")
        return -1, nil
    end

    --解析sign_type签名方式
    local sign_type = util.find_value_Of_key(params, "sign_type")
    if sign_type == nil then     
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find sign_type")
        return -1, nil
    end

    --解析sign 签名 
    local sign = util.find_value_Of_key(params, "sign")
    if sign == nil then        
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find sign")
        return -1, nil
    end

    ----------------------------------------------------------------------
    --------------------------------业务参数------------------------------
    --解析out_trade_no 商户网站唯一订单号
    local out_trade_no = util.find_value_Of_key(params, "out_trade_no")
    if out_trade_no == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find out_trade_no")
        return -1, nil
    end
    local discount = util.find_value_Of_key(params, "discount")
    if discount == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find discount")
        return -1, nil
    end
    local payment_type = util.find_value_Of_key(params, "payment_type")
    if payment_type == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find payment_type")
        return -1, nil
    end
    local body = util.find_value_Of_key(params, "body")
    if body == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find body")
        return -1, nil
    end
    local is_total_fee_adjust = util.find_value_Of_key(params, "is_total_fee_adjust")
    if is_total_fee_adjust == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find is_total_fee_adjust")
        return -1, nil
    end
    local use_coupon = util.find_value_Of_key(params, "use_coupon")
    if use_coupon == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find use_coupon")
        return -1, nil
    end

     --解析subject 商品名称 
    local subject = util.find_value_Of_key(params, "subject")
    if subject == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find subject")
        return -1, nil
    end

    --解析trade_no 支付宝交易号
    local trade_no = util.find_value_Of_key(params, "trade_no")
    if trade_no == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find trade_no")
        return -1, nil
    end

    --解析trade_status 交易状态 
    local trade_status = util.find_value_Of_key(params, "trade_status")
    if trade_status == nil then--or trade_status ~= "TRADE_SUCCESS" then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find trade_status")
        return -1, nil
    end

    if trade_status == "WAIT_BUYER_PAY"  or trade_status == "TRADE_FINISHED" then
        return 1000, nil
    end

    --解析gmt_create 交易创建时间
    local gmt_create = util.find_value_Of_key(params, "gmt_create")
    if gmt_create == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find gmt_create")
        return -1, nil
    end

    --解析gmt_payment 交易创建时间
    local gmt_payment = util.find_value_Of_key(params, "gmt_payment")
    if gmt_payment == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find gmt_payment")
        return -1, nil
    end

    --解析seller_email卖家支付宝账号
    local seller_email = util.find_value_Of_key(params, "seller_email")
    if seller_email == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find seller_email")
        return -1, nil
    end

    --解析buyer_email买家支付宝账号
    local buyer_email = util.find_value_Of_key(params, "buyer_email")
    if buyer_email == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find buyer_email")
        return -1, nil
    end

    --解析seller_id卖家支付宝用户号 
    local seller_id = util.find_value_Of_key(params, "seller_id")
    if seller_id == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find seller_id")
        return -1, nil
    end

    --解析buyer_id买家支付宝账号
    local buyer_id = util.find_value_Of_key(params, "buyer_id")
    if buyer_id == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find buyer_id")
        return -1, nil
    end

    --解析price商品单价
    local price = util.find_value_Of_key(params, "price")
    if price == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find price")
        return -1, nil
    end

    --解析quantity购买数量 
    local quantity = util.find_value_Of_key(params, "quantity")
    if quantity == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find quantity")
        return -1, nil
    end

    --解析total_fee交易金额 
    local total_fee = util.find_value_Of_key(params, "total_fee")
    if total_fee == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find total_fee")
        return -1, nil
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

    ---验证签名
    if channelinfo.publickey == nil then
        filelog.sys_obj("paycallback", "zhifubao", "*** ZhiFuBaoUniform: can't find appinfo")
        return -1, nil                        
    end

    sign = string.gsub(sign, ' ', '+')
    local sign_result = util.rsa_public_verify(sigstr, sign, channelinfo.publickey)
    if sign_result ~= true then 
        filelog.sys_obj("paycallback", "zhifubao", "zhifubao ph sign failed...", sign_result, sign, sigstr)
        return errret
    end

    if trade_status == "TRADE_SUCCESS" then
        --解析透传信息
        local orderinfo = {}
        orderinfo.pay_type = channelinfo.id
        orderinfo.order_id = out_trade_no
        orderinfo.price = tonumber(price)*100
        return 0, orderinfo
    end

    return -1, nil
end

function reply_zhifubao_pay(errcode, info)
    if errcode == 1000 then
        return "success"
    elseif errcode == 0 then
        return "success"
    else
        return "failed"
    end
end 

local Channel = {
channels = {
    {
        id = 1,  --支付渠道
        url = "/ios/buy",
        urltest = "/ios/test",
        preurl = "/ios/buy",   
        preurltest = "/ios/test",
        payfunc = do_ios_pay,
        payretfunc = reply_ios_pay,
        prepayfunc = do_ios_pay,
        prepayretfunc = reply_ios_pay,
        appid = "",
        key = "",
        proxy_ip = "127.0.0.1",
        proxy_port = 6999,
        ispost = true,
    }, 
    {
        id = 2,  --支付渠道
        url = "/wechat/pay",
        urltest="/wechat/paytest",
        preurl = "/wechat/prepay",        
        preurltest = "/wechat/prepaytest",
        payfunc = do_wechat_pay,
        payretfunc = reply_wechat_pay,
        prepayfunc = do_wechat_prepay,
        prepayretfunc = reply_wechat_prepay,
        appid = "wxd1789ff94e18ace7",
        key = "6AxWoPufxFuqp8QD6AxWoPufxFuqp8QD",
        proxy_ip = "127.0.0.1",
        proxy_port = 6999,
        ispost = true,
    },  

    {
        id = 3,  --支付宝支付渠道
        url = "/zhifubao/pay",
        urltest="/zhifubao/paytest",
        preurl = "/zhifubao/prepay",        
        preurltest = "/zhifubao/prepaytest",        
        notify_url = "http://106.75.7.48:6888",
        payfunc = do_zhifubao_pay,
        payretfunc = reply_zhifubao_pay,
        prepayfunc = do_zhifubao_prepay,
        prepayretfunc = reply_zhifubao_prepay,
        paramsfunc = generate_zhifubao_params,
        appid = "2088121772403775",
        sellerid = "pay@juzhongjoy.com",
        key = "",
        privatekey = [[-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMJd0vt0T2HxynAt
5dGKG/YROXa9y+ENieUE/On0ziJESFXd1M6OmZgjFOiCEZnfDCdmRKtDG3sunJHN
ohSgXtnXtuU60mpeizoxzcaUycZbSN+CEyvnMYTMeiSBIPcIn7Osx74fs25IheC5
sVhuyoAER47ZnZ8z3Ee8H2uM+2sBAgMBAAECgYEAplcTk/2DXmhGfuDY2Q4gReOR
0Sw3SqCCjcxKApNuwma7nTjewfPKQShs4VtHYu8/gIyGYidpYm+OsT1R4+MnqDq+
UKGl64C764GqV9xc0povf0ONpvRcZZm6XL0AoDkglISd/IEU6/2l3E6v4PxTorqb
JHMyrla4x16kM5O7Co0CQQDu7wXccucGAfmShSp15h5TRGqzBQKG5XgkqlIUXpw/
1DwNcxirXREb6C9uWCNUy9XvvPMNLYxEOAnmm2vVIRLDAkEA0D/gWs5LHWKM4Wc/
cpwcTHRirwAXjpLCpOsOJJmUkxZORxha/Km9id23eyeMhqMKI+MoDyLHblVWYQ76
N+zm6wJBANy74x1K5ZUORAORlK2A32krnqsuKKx41+p/kv6QfScWqjf+qb6+Zuzy
LsdxE4rmGQm29I+rEZeAcd0inpcyS8MCQGne74p6sklgHstBGEqF/wUHblwVqeQ7
zGTXczs8MQKOJoGSaj9ldAyxAWTE+HZCURdplqYLQmRfUijJ2n+wGr0CQFIUSMLb
S0M7posF6Ch0fkPdmrIV23WlHazw7sCT8eDIk0kw9dAadbihY9a9v+0iaS3RvCxh
gbSlsLOphh/QYCY=
-----END PRIVATE KEY-----]],
        publickey = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCnxj/9qwVfgoUh/y2W89L6BkRAF
ljhNhgPdyPuBV64bfQNN1PjbCzkIM6qRdKBoLPXmKKMiFYnkd6rAoprih3/PrQEB/
VsW8OoM8fxn67UDYuyBTqA23MML9q1+ilIZwBC2AQ2UBVOrFXfFl75p6/B5KsiNG9
zpgmLCUYuLkxpLQIDAQAB
-----END PUBLIC KEY-----]],
        proxy_ip = "127.0.0.1",
        proxy_port = 6999,        
        ispost = true,
    },   
}

}

function Channel:get_channel_byurl(url)
    for i,v in ipairs(self.channels) do
        if v.url == url then
            return v
        end
    end
    return nil
end

function Channel:get_channel_byid(id)
    for i,v in ipairs(self.channels) do
        if v.id == id then
            return v
        end
    end
    return nil    
end

return Channel