local debug = debug
local skynet = require "skynet"
local string = string
local tostring = tostring
local math = math 
local table = table
local Base = {}
local dev = false
local randomnum = 0
local mailcount = 0
--pcall调用
function Base.pcall(func, ...)
	if not dev then
	 	return xpcall(func,  function (err) return debug.traceback(err, 2) end, ...)
	end
	return true, func(...)
end

function Base.skynet_retpack(...)
	pcall(skynet.retpack, ...)
end

function Base.strtrim(str)
	return str:match "^%s*(.-)%s*$"
end

function Base.strsplit(str, delim)
  if type(delim) ~= "string" or string.len(delim) <= 0 then
    return
  end 
  local start = 1
  local t = {}
  while true do
  local pos = string.find (str, delim, start, true) -- plain find
    if not pos then
     break
    end
    table.insert (t, string.sub (str, start, pos - 1))
    start = pos + string.len (delim)
  end
  table.insert (t, string.sub (str, start))
  return t
end

function Base.isdebug()
	return dev
end

--计算字符串的数字hash值
function Base.strtohash(text)
  local counter = 1
  local len = string.len(text)
  for i = 1, len, 3 do 
      counter = math.fmod(counter*8161, 4294967279) +  -- 2^32 - 17: Prime!
      (string.byte(text,i)*16776193) +
      ((string.byte(text,i+1) or (len-i+256))*8372226) +
      ((string.byte(text,i+2) or (len-i+256))*3932164)
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

--获得随机数函数
function Base.get_random(min, max)
    if randomnum == 0 then
      math.randomseed(os.time())
    end
    
    randomnum = randomnum + 1
    if randomnum > 1000 then
      randomnum = 0
    end
    return math.random(min, max)
end

--根据用户生成邮件唯一表示id
function Base.generate_mail_key(rid)
  if mailcount > 100 then
    mailcount = 0
  end
  mailcount = mailcount + 1
  return tostring(rid)..tostring(skynet.time()*100)..mailcount  
end

function Base.RNG()
  local status, urand = pcall(io.open, '/dev/urandom', 'rb')
  if not status then
    return nil
  end
  local b = 4
  local m = 256
  local n, s = 0, urand:read (b)

  for i = 1, s:len () do
    n = m * n + s:byte (i)
  end
  io.close(urand)
  return n
end

return Base