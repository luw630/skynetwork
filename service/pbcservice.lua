local skynet = require "skynet"
local filelog = require "filelog"
local base = require "base"
local parser = require "parser"
local protobuf = require "protobuf"  
require "skynet.manager"

local filename = "pbcservice.lua"
local PBCService = {}
--[[
  conf = {
      protofile = ,
      protopath = ,
  }
]]
function  PBCService.init(conf)
  if conf == nil or conf.protofile == nil then
    filelog.sys_error("PBCService.init: invalid params")
    base.skynet_retpack(false)    
    return
  end
  local status, des = pcall(parser.register, conf.protofile, conf.protopath)
  if not status then
     filelog.sys_error("PBCService.init:", des)
     base.skynet_retpack(false)    
     return
  end
  base.skynet_retpack(true)
end

function PBCService.reload(...)
end 

function PBCService.exit(...)
	skynet.exit()
end

function PBCService.get_protobuf_env(...)    
    base.skynet_retpack(protobuf.get_protobuf_env())
end

function PBCService.start(...)
end

skynet.dispatch("lua", function(_, _, cmd, ...)
	  local f = PBCService[cmd]
		if f ~= nil then
        base.pcall(f, ...)
    else
        filelog.sys_error(filename.." [BASIC_PBCService] skynet.dispatch invalid func "..cmd)
    end
end)

skynet.start(function()
    skynet.register(".pbcservice")
end)
