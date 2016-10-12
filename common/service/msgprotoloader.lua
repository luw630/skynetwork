local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "mesprotoloader"
local msgproto = require "msgproto"

skynet.start(function()
	sprotoloader.save(msgproto, 1)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
