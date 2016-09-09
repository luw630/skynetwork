-- 定义所有第三方渠道信息及帐号认证、支付回调处理接口
--package.cpath = "../../skynet/luaclib/?.so;../core/3rd/lua-cjson/?.so;../core/3rd/lua-xml/?.so"
--package.path = "../../skynet/lualib/?.lua;../core/?.lua;../core/3rd/lua-xml/?.lua"

local json = require "cjson"
local md5 = require "md5"
local filelog = require "filelog"
local timetool = require "timetool"
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