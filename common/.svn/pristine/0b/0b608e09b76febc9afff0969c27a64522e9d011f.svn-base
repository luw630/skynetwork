local skynet = require "skynet"

local  Marquee = {}

function Marquee.add(msg)
	skynet.send(".marqueemsg","lua", "add", false, msg)
end

function Marquee.queryindex()
    return skynet.call(".marqueemsg", "lua", "queryindex", true)
end

function Marquee.querymsg(index)
    return skynet.call(".marqueemsg", "lua", "querymsg", true, index)
end

return Marquee