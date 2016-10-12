-- Copyright (c) 2014 ximigame
-- All rights reserved.

-------------------------------------------------------------------
-- 本脚本提供4个标准接口:
-- 1. GenerateHttpAccAuthReq
--    处理第三方帐号鉴权请求，根据渠道编号、游戏类型、
--    玩家id、token信息生成http请求地址+参数+签名并
--    将其返回。
--
-- 2. ProcessHttpAccAuthResp
--    处理第三方帐号鉴权请求的回复，判断其是否成功。
--
-- 3. ProcessHttpPayReq
--    处理http支付请求，根据请求的url地址选择对应
--    的渠道处理函数，渠道处理函数使用统一的接口，
--    其目的是提取订单信息，提取失败则说明请求不合法。
--
-- 4. GenerateHttpPayResp
--    根据渠道编号、errcode生成支付结果回复消息，
--    该消息将被作为http的body返回给第三方支付服务器。
-------------------------------------------------------------------

-- @brief 清空库加载记录，支持lua脚本动态重载
function Reload()
    package.loaded["channels"] = nil
    package.loaded["util"] = nil
end

-- @brief 生成第三方帐号的http鉴权请求
-- @param channelid  第三方渠道id
-- @param gametype   游戏类型id
-- @param uid        第三方帐号uid
-- @param token      鉴权token
-- @return 成功则返回生成的http请求地址，失败则返回nil
function GenerateHttpAccAuthReq(channelid, gametype, uid, token)
    if channelid == nil or gametype == nil
        or uid == nil or token == nil then
        return nil
    end

    util = require("util")
    util.LogInfo("channelid: "..channelid)
    util.LogInfo("gametype: "..gametype)
    util.LogInfo("uid: "..uid)
    util.LogInfo("token: "..token)

    local chinfodb = require("channels")
    local info = chinfodb.GetChannelInfoById(channelid)
    if (info == nil) then
        return nil
    end

    if info.accauthfunc ~= nil then
        return info:accauthfunc(gametype, uid, token)
    else
        return nil
    end
end

-- @brief 生成第三方帐号的http鉴权请求
-- @param channelid  第三方渠道id
-- @param gametype   游戏类型id
-- @param uid        第三方帐号uid
-- @param token      鉴权token
-- @return 成功则返回生成的http请求地址，失败则返回nil
function NewGenerateHttpAccAuthReq(channelid, gametype, uid, token)
    if channelid == nil or gametype == nil
        or uid == nil or token == nil then
        return nil
    end

    util = require("util")
    util.LogInfo("AutchReq channelid: "..channelid)
    util.LogInfo("AutchReq gametype: "..gametype)
    util.LogInfo("AutchReq uid: "..uid)
    util.LogInfo("AutchReq token: "..token)

    local httptable = {}
    local chinfodb = require("channels")
    local info = chinfodb.GetChannelInfoById(channelid)
    if (info == nil) then
        return httptable
    end

    if (info.httpoption == nil) then
        httptable.httpoption = 0
    else
        httptable.httpoption = info.httpoption
    end

    httptable.accurl = info.acc
    httptable.httpparam = ""

    if info.accauthfunc ~= nil then
        httptable.httpparam = info:accauthfunc(gametype, uid, token)
    end

    return httptable
end

-- @brief 处理第三方帐号鉴权回复，判断是否成功
-- @param channelid  第三方渠道id
-- @param retcode    鉴权回复结果
-- @return 返回0表示成功，否则表示失败
function ProcessHttpAccAuthResp(channelid, retcode)
    if channelid == nil or retcode == nil then
        return -1
    end

    util = require("util")
    util.LogInfo("AutchRes channelid: "..channelid)
    util.LogInfo("AutchRes retcode: "..retcode)

    local chinfodb = require("channels")
    local info = chinfodb.GetChannelInfoById(channelid)
    if (info == nil) then
        return -1
    end

    if info.accauthretfunc ~= nil then
        return info:accauthretfunc(retcode)
    else
        return -1
    end
end

-- @brief 解析处理http支付通知
-- @param url    支付回调路径，如:/payauth/xiaomi
-- @param params 支付回调参数，如:a=1&b=2&c=3
-- @return 返回携带2个值的table:错误码、订单信息
function ProcessHttpPayReq(url, params)
    local util = require("util")

    util = require("util")
    if url == nil or params == nil then
        return util.PayRet(-1, nil)
    end

    util.LogInfo("url: "..url)
    util.LogInfo("params: "..params)

    local chinfodb = require("channels")
    local info = chinfodb.GetChannelInfoByUrl(url)
    if (info == nil) then
        return util.PayRet(-1, nil)
    end

    if info.payauthfunc ~= nil then
        return info:payauthfunc(params)
    else
        return util.PayRet(-1, nil)
    end
end

-- @brief 生成http支付回复结果
-- @param channelid 调路径，如:/payauth/xiaomi
-- @param errcode   调参数，如:a=1&b=2&c=3
-- @return 返回符合渠道要求的回复结果
function GenerateHttpPayResp(channelid, errcode, channelinfo)
    if channelid == nil or errcode == nil then
        return nil
    end

    util = require("util")
    util.LogInfo("channelid: "..channelid)
    util.LogInfo("errcode: "..errcode)

    local chinfodb = require("channels")
    local info = chinfodb.GetChannelInfoByChannelId(channelid)
    if (info == nil) then
        return nil
    end

    if info.payauthretfunc ~= nil then
        return info:payauthretfunc(errcode, channelinfo)
    else
        return nil
    end
end


function GenerateHttpApplePaymentAuth( isSandBox, payment_receipt)
    --iOS payment authrization!
    if payment_receipt == nil then
        return nil
    end

    local json = require("json")
    local util = require("util")
    local receipt_json_param = {["receipt-data"] = payment_receipt}
    local result = {["json_data"] = json.encode(receipt_json_param)}

    if isSandBox == "true" then
        result["url"] = "https://sandbox.itunes.apple.com/verifyReceipt"
    else
        result["url"] = "https://buy.itunes.apple.com/verifyReceipt"
    end
    util.LogInfo(result["url"])
    return result
end

function ProcessHttpApplePaymentAuth( response, transaction_id, product_id )
    --Process payment authrization response!
    local util = require("util")
    local json = require("json")
    local retcode, retval = pcall(json.decode, response)
    util.LogInfo(transaction_id)
    util.LogInfo(product_id)
    util.LogInfo(response)
    if retcode == false then
        util.LogErr("iOS decode json failed: "..response)
        return -1 
    end

    if type(retval) ~= "table" then
        util.LogErr("iOS retval not json")
        return -1
    end 

    if retval.status == nil then
        util.LogErr("iOS status nil")
        return -1
    end
    if retval.status ~= 0 then
        if retval.status == 21007 then
            util.LogErr("iOS sandbox status")
            return 1
        else
            util.LogErr("iOS status: "..retval.status)
            return -1
        end
    end
    if retval.receipt == nil then
        util.LogErr("iOS receipt or receipt.in_app nil")
        return -1
    end
    if retval.receipt.in_app == nil then
        if retval.receipt.product_id == product_id and retval.receipt.transaction_id == transaction_id then
            util.LogInfo("iOS verify succ")
            return 0
        end
        util.LogErr("iOS invalid transaction_id: "..transaction_id.." and product_id: "..product_id)
        return -1
    else
        local in_app = retval.receipt.in_app
        for key, value in pairs(in_app) do
            util.LogInfo(key)
            util.LogInfo(value.transaction_id)
            util.LogInfo(value.product_id)
            if value.transaction_id ~= nil and value.product_id ~= nil then
                if value.transaction_id == transaction_id and value.product_id == product_id then
                    util.LogInfo("iOS verify succ")
                    return 0
                end
            end
        end
    end

    util.LogErr("iOS invalid transaction_id: "..transaction_id.." and product_id: "..product_id)
    return -1
end