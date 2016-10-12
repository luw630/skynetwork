local filelog = require "filelog"
local codec = require "codec"
local crypt = require "crypt"


local Util = {}

-- @brief 转换二进制数值为16进制字符串
local function tohex(b)
    local x = ""
    for i = 1, #b do
        x = x .. string.format("%.2x", string.byte(b, i))
    end
    return x
end

-- @brief 转换16进制字符串为二进制数值
local function tobin(h)
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

-- @brief 在支付回调参数串中查找kv对
-- @return 查找成功则返回value，失败则返回nil
function Util.find_value_Of_key(paramstr, key)
    local _, _, value = string.find(paramstr, key.."=(.-)&")
    if value == nil then
        _, _, value = string.find(paramstr, key.."=(.-)$")
    end
    return value
end

function Util.escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

function Util.rsa_private_sign(str, privatekey)
    local bs = codec.rsa_private_sign(str, privatekey)
    local sign = codec.base64_encode(bs)
    return sign
end

function Util.rsa_public_verify(str, sign, publickey)
    local dbs = codec.base64_decode(sign)
    local typ = 2
    return codec.rsa_public_verify(str, dbs, publickey, typ)
end

function Util.decodeuri(s)
        s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
            return string.gsub(s, "+", " ")
end

function Util.encodeuri(s)
        s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
            return string.gsub(s, " ", "+")
end

return Util
