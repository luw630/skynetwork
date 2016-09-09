-- 公共库函数

module(..., package.seeall)

-- @brief 记录错误日志
-- @param msg 错误信息
-- @return none
function LogErr(msg)
     ----- 日志分日期存储------
    local CurrentTime = os.date("%Y_%m_%d", os.time())
    local LogPath = "../../log/LuaScriptLog/"..CurrentTime
    local FileName = LogPath.."/luaerr.txt"
    os.execute("mkdir -p "..LogPath)

    local f = io.open(FileName, "a+")
    if f ~= nil then
        f:write("["..os.date("%Y-%m-%d %X", os.time()).."] "..msg.."\n")
        f:close()
    end
end

-- @brief 记录正常日志
-- @param msg 消息信息
-- @return none
function LogInfo(msg)
    ----- 日志分日期存储------
    local CurrentTime = os.date("%Y_%m_%d", os.time())
    local LogPath = "../../log/LuaScriptLog/"..CurrentTime
    local FileName = LogPath.."/luainfo.txt"
    os.execute("mkdir -p "..LogPath)

    local f = io.open(FileName, "a+")
    if f ~= nil then
        f:write("["..os.date("%Y-%m-%d %X", os.time()).."] "..msg.."\n")
        f:close()
    end
end

-- @brief 构建支付回调处理结果
-- @param errcode    错误码
-- @param payinfo    订单信息
-- @return 返回支付处理结果
function PayRet(errcode, payinfo)
    local t = {}
    t.errcode = errcode
    t.payinfo = payinfo
    return t;
end

-- @brief 构建订单信息
-- @param uid        玩家id
-- @param gametype   游戏类型id
-- @param orderid    订单id
-- @param fee        支付金额
-- @param prodcount  商品数目
-- @param channelid  渠道ID 
-- @return 返回包含订单信息的table
function PayInfo(orderid)
    local t = {}
    --local _, _, value = string.find(uid, "^(%d-)%a*$")
    --if value == nil then
    --    value = "33"
    --end
    --t.uid       = value
    --t.gametype  = gametype
    t.orderid   = orderid
    --t.fee       = fee
    --t.prodcode  = 0 
    --t.prodcount = prodcount
    --t.ordertype = ordertype
	--t.channelid = channelid
    return t;
end

-- @brief 在支付回调参数串中查找kv对
-- @return 查找成功则返回value，失败则返回nil
function FindValueOfKey(paramstr, key)
    local _, _, value = string.find(paramstr, key.."=(.-)&")
    if value == nil then
        _, _, value = string.find(paramstr, key.."=(.-)$")
    end
    return value
end

-- @brief 解析客户端透传的json文本
-- @return 成功则返回订单信息，失败则返回nil
function ParseUserInfo(jsoninfo)
    local json = require("json")
    local retcode, retval = pcall(json.decode, jsoninfo)
    if retcode == false then
        LogErr("decode json failed: "..retval)
        return nil
    end
    if type(retval) == "table" then
        return PayInfo(retval.order_id) 
    end
    return nil
end


-- @brief 转换二进制数值为16进制字符串
function ToHex(b)
    local x = ""
    for i = 1, #b do
        x = x .. string.format("%.2x", string.byte(b, i))
    end
    return x
end

-- @brief 转换16进制字符串为二进制数值
function ToBin(h)
    local b = ""
    for i = 1, #h - 1, 2 do
        local s = string.sub(h, i, i+1)
        local n = tonumber(s, 16)
        if n == 0 then
            b = b .. "\00"
        else
            b = b .. string.format("%c", n)
        end
    end
    return b
end

-- @brief 计算md5签名
function MD5(str)
    local digest = require"openssl".digest
    local ret = digest("md5", str, true)
    if ret ~= nil then
        return ToHex(ret)
    else
        return nil
    end
end

-- @brief 计算hmac签名
function HMAC(str, key)
    local hmac = require"openssl".hmac
    local ret = hmac("sha1", key, str)
    if ret ~= nil then
        return ToHex(ret)
    else
        return nil
    end
end

-- @brief rsa加密
function RSAEncrypt(str, key)
    local pkey = require"openssl".pkey
    local r, k = pcall(pkey.read, key, true)
    if r == false or k == nil then
        LogErr("import public key failed")
        return nil
    end
    local kinfo = k:parse()
    local ret = ""
    for i = 1, #str, kinfo.size - 11 do
        local d =  string.sub(str, i, i + kinfo.size - 12)
        local r, s = pcall(pkey.encrypt, k, d)
        if r == false or s == nil then
            LogErr("encrypt failed")
            return nil
        end
        ret = ret .. s
    end
    return ToHex(ret)
end

-- @brief rsa解密
function RSADecrypt(dstr, key)
    local pkey = require"openssl".pkey
    local r, k = pcall(pkey.read, key)
    if r == false or k == nil then
        LogErr("import private key failed")
        return nil
    end
    local kinfo = k:parse()
    local ret = ""
    for i = 1, #dstr, kinfo.size do
        local d =  string.sub(dstr, i, i + kinfo.size - 1)
        local r, s = pcall(pkey.decrypt, k, d)
        if r == false or s == nil then
            LogErr("decrypt failed")
            return nil
        end
        ret = ret .. s
    end
    return ret
end

-- @brief rsa签名检查
function RSASignVerify(key, data, sign)
    local pkey = require"openssl".pkey
    local r, k = pcall(pkey.read, key, true)
    if r == false or k == nil then
        LogErr("import public key failed")
        return ""
    end 

    local r, s = pcall(pkey.verify, k, data, Base64Decode(sign))
    if r == false or s == nil then
        return false
    else
        return s
    end 
end

function RSASignVerifyMD5(key, data, sign)
    local pkey = require"openssl".pkey
    local r, k = pcall(pkey.read, key, true)
    if r == false or k == nil then
        LogErr("import public key failed")
        return ""
    end 

   local r, s = pcall(pkey.verify, k, data, Base64Decode(sign), 'MD5')
    if r == false then
        LogErr("fuck")
        return false
    end
    if s == nil then
        LogErr("shit")
        return false
    else
        return s
    end 
end

-- @brief 分隔字符串
function SplitString(str, sep)
	local startIndex = 1
	local splitIndex = 1
	local splitArray = {}
	while true do
	    local lastIndex = string.find(str, sep, startIndex)
	    if not lastIndex then
            splitArray[splitIndex] = string.sub(str, startIndex, string.len(str))
            break
	    end
	    splitArray[splitIndex] = string.sub(str, startIndex, lastIndex - 1)
	    startIndex = lastIndex + string.len(sep)
	    splitIndex = splitIndex + 1
    end
    return splitArray
end

-- @brief 解析客户端透传的文本
-- @return 成功则返回订单信息，失败则返回nil
function ParseUserInfoStr(strinfo)
    local items = SplitString(strinfo, "|")
    local itemCount = #items

    local info = {}

    if itemCount < 1 then
    	return nil
    end
    
    --info.gametype = items[1]
    info.orderid = items[1]

    --因为测试的原因UID需要特殊处理，取"1000502ximixuebb"中的数字
    --info.uid = items[3]
    --info.channelid = items[4]
    --info.prodcount = items[5]
    --info.fee = items[6]    

    --local _, _, value = string.find(info.uid, "^(%d-)%a*$")
    --if value == nil then
    --    value = "33"
    --end

    --info.uid = value

    --info.ordertype = 0
    --info.prodcode = 0
    
    return info
end

-- @brief 解析客户端透传的文本, 主要是爱游戏透传长度不够所以只透传了2个参数，这里特殊处理
-- @return 成功则返回订单信息，失败则返回nil
function ParseUserInfoStr_LoveGame(strinfo)
    local items = SplitString(strinfo, "z")
    local itemCount = #items

    local info = {}

    if itemCount < 3 then
    	return nil
    end

    --uid可以从orderid里面提取出来
    info.orderid = items[1]
    if itemCount-3 > 0 then
        for i=2,itemCount-2 do
            info.orderid = info.orderid.."z"..items[i]
        end 
    end 

    info.channelid = items[itemCount - 1]  
    info.uid = items[itemCount]    

    --由于透传长度的限制，后面的参数需要根据实际情况处理，这里暂时填0
    info.gametype = 0 
    info.prodcount = 0 
    info.fee = 0 
    info.ordertype = 0
    info.prodcode = 0
    
    return info
end

--洋葱
function ParseUserInfoStr_YangCong(strinfo)
    local items = SplitString(strinfo, "_")
    local itemCount = #items

    local info = {}

    if itemCount < 6 then
    	return nil
    end
    
    info.gametype = items[1]
    info.orderid = items[2]

    --因为测试的原因UID需要特殊处理，取"1000502ximixuebb"中的数字
    info.uid = items[3]
    info.channelid = items[4]
    info.prodcount = items[5]
    info.fee = items[6]    

    local _, _, value = string.find(info.uid, "^(%d-)%a*$")
    if value == nil then
        value = "33"
    end

    info.uid = value

    info.ordertype = 0
    info.prodcode = 0
    
    return info
end

--联通的渠道由于透传参数太短，这里只需要传一部分参数，购买个数和金额都不用传
function ParseUserInfoStr_LianTong(strinfo)
    local items = SplitString(strinfo, "|")
    local itemCount = #items

    local info = {}

    if itemCount < 4 then
    	return nil
    end
    
    info.gametype = items[1]
    info.orderid = items[2]

    --因为测试的原因UID需要特殊处理，取"1000502ximixuebb"中的数字
    info.uid = items[3]
    info.channelid = items[4]
    info.prodcount = 0 
    info.fee = 0 

    local _, _, value = string.find(info.uid, "^(%d-)%a*$")
    if value == nil then
        value = "33"
    end

    info.uid = value

    info.ordertype = 0
    info.prodcode = 0
    
    return info
end



-- @brief base64 encode
function Base64Encode(data)
    local base64 = require"base64"
    return base64.encode(data)
end

-- @brief base64 decode
function Base64Decode(data)
    local base64 = require"base64"
    return base64.decode(data)
end

-- @brief DES Encrypt DES加密 
function DESEncrypt(str, key)
    local openssl = require"openssl"
    local evp_cipher = openssl.cipher.get('des-ecb')
    return evp_cipher:encrypt(str,key)
end

-- @brief DES Decrypt DES解密
function DESDecrypt(str, key)
    local openssl = require"openssl"
    local evp_cipher = openssl.cipher.get('des')
    return evp_cipher:decrypt(str,key)
end

-- @brief AES Decrypt AES
function AESDecrypt(str, key)
    local openssl = require"openssl"
    local evp_cipher = openssl.cipher.get('aes-128-ecb')
    return evp_cipher:decrypt(str,key)
end

-- @brief 计算sha1签名
function SHA1(str)
    local digest = require"openssl".digest
    local ret = digest("sha1", str, true)
    if ret ~= nil then
        return ToHex(ret)
    else
        return nil
    end
end

--@brief 向第三方主动发起订单查询
--@requestAddress 第三方渠道服务器请求地址
--@isPost 是否是POST方式 true/false 
--@postParams POST请求body
--@return result 返回查询结果
function queryOrderRequest(requestAddress, isPost, postParams)

    --初始化CURL库
    require("curl")

    local result = ""
    c = curl.easy_init()
        
    if isPost == "true" then
        c:setopt(curl.OPT_POSTFIELDS, postParams) 
    end 

    c:setopt(curl.OPT_SSL_VERIFYHOST, 0)
    c:setopt(curl.OPT_SSL_VERIFYPEER, 0)
    c:setopt(curl.OPT_URL, requestAddress)

    --设置回调函数
    c:setopt(curl.OPT_WRITEFUNCTION, 
        function(buffer)
            result = result..buffer
            return #buffer
        end)
        
    c:perform()
        
    --返回结果
    return result
end
-----------add by zhangwei----
function FindStringIndex(convertTable,chactor)
    local loop = 1
    if nil == convertTable then
	    return nil
	end
    local length = #convertTable

	while loop<=length do
	    if(convertTable[loop] == chactor) then
		    return loop-1
		end
		loop = loop+1
	end
	return nil
end


function Get62StringToTen(source)
	require('BigNum')
    local ret = BigNum.new(0)
	local temp =""
	local index = 1
	local stepValue = 0
	local stepValueBig = BigNum.new("0")
	local  devM = BigNum.new("62")
	local devN = BigNum.new("0")
    local convertTable =
	{
	  "0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p",
	  "q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
	  "Q","R","S","T","U","V","W","X","Y","Z"
	}
   local length = string.len(source)
   
   LogInfo("length: "..length)
   --for
   while index<= length do
       LogInfo("char: "..string.sub(source,index,index))
	   LogInfo("char: "..index)
       stepValue = FindStringIndex(convertTable,string.sub(source,index,index))
	   --print("this is:"..string.sub(source,index,index))
	  if(nil == stepValue) then
	      --print("can not find the stepvalue")
		  break
	  end
	  stepValueBig = BigNum.new(string.format("%d",stepValue))
	  --print("stepValue ="..BigNum.mt.tostring(stepValueBig))

	  devN = BigNum.new(length-index)
	  --print("devN ="..BigNum.mt.tostring(devN))
	  local ji = BigNum.mt.pow(devM,devN)
	  --print("ji ="..BigNum.mt.tostring(ji))
	  local Nji =BigNum.mt.mul(stepValueBig, ji)
	   --print("Nji ="..BigNum.mt.tostring(Nji))
	  ret =  BigNum.mt.add(Nji,ret);
      index = index+1
   end
   return BigNum.mt.tostring(ret)
end
--add by zhangwei --
function CancleZreoString(str)
     local length = 0
	 local ret =""
	 local  index = 1
	 local notzero = 0
	 if str==nil then
	     return nil
	 end

	 local strchar = string.gsub(str," ","")
	 length=string.len(strchar)
	 while index<=length do
              if(string.sub(strchar,index,index) == "0") then
				 notzero = notzero+1
			  else
				 break
			  end
              index = index +1
	 end

	 return string.sub(strchar,notzero+1,length)

end

function ParseUserInfoStr_MobilePhone(strinfo)

    local info = {}
    info.gametype = string.sub(strinfo, 1, 3)
    info.orderid = string.sub(strinfo, 4)

	local len = string.len(info.orderid)
	if len<3 then
	   --print("error args")
	   return nil
	end
	--获取（UID + 时间）62进制
	strWithOutProuCode = string.sub(info.orderid,1,-3)
	--print("uid+time:"..strWithOutProuCode)
    LogInfo("strWithOutProuCode: "..strWithOutProuCode)
	--获取UID串
	--*****Warnning:当UID 大于14000000的时候会有问题，需注意******
	local all = Get62StringToTen(strWithOutProuCode)
    LogInfo("all: "..all)
	local uuid = string.sub(all,1,-11)
	--print(""..all)
	--print("uid ="..uuid)

    local ProductCode = string.sub(info.orderid,-2,-1)
    --print("ProductCode ="..ProductCode)

    info.orderid = CancleZreoString(info.orderid)

	--print("no have zero:"..info.orderid)

	info.uid =uuid
	info.prodcode =ProductCode
	info.ordertype = 0
    info.prodcode = 0
    return info
end


-----------end by zhangwei -----
--------------URL ENCODE AND DECODE----------------
function decodeURI(s)
        s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
            return s
end

function encodeURI(s)
        s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
            return string.gsub(s, " ", "+")
end
-----------end by tangqiang-----------------------
