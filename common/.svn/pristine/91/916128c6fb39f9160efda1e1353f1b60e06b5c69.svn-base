local skynet = require "skynet"
local json = require "cjson"
require "skynet.manager"

local svr_id = ...
local svr_conf = {} --{path}
local CMD = {}

--[[
.MsgItem {
    msg_id 0 : integer
    send_rid 1 : integer #发送消息的玩家rid
    to_id 2 : integer    #目标玩家的rid或是群id
    time 3 : integer
    msg_type 4 : integer
    msg 5 : string
}
]]
local function create_filename(msgtype, sendrid, to_id, last_time)
    local date = os.date("%Y_%m_%d", last_time)
    if msgtype >= 3 then
        sendrid = 0
    end
    if sendrid < to_id then
        return (sendrid.."_"..to_id.."_"..date..".msg")
    else
        return (to_id.."_"..sendrid.."_"..date..".msg")
    end
end

local function get_file_name(msgitem)

    local filename = create_filename(msgitem.msg_type, msgitem.send_rid, msgitem.to_id, msgitem.time)
    local path = svr_conf.path
    if path == nil then
    	path = "."
    end

    local datedir = os.date("%Y_%m_%d", msgitem.time)
    local log_path = path.."/"..datedir.."/"
    local filename = log_path.."/"..filename
    os.execute("mkdir -p "..log_path)
    return filename
end

local function write_log(file, msgitem)
    local f = io.open(file, "a+")
    if f ~= nil then
        local data = json.encode(msgitem)
        f:write(data)
        f:write("\n")
        f:close()
    end	
end

function CMD.init(conf)
    if conf ~= nil then
        svr_conf = conf
    end
end

function CMD.reload(conf)
    if conf ~= nil then
        svr_conf = conf
    end
end

function CMD.record(msgitem)
    local file = get_file_name(msgitem)
    write_log(file, msgitem)
end

function CMD.exit(...)
    skynet.exit()
end

function CMD.start(...)
end

skynet.dispatch("lua", function(_, address,  cmd, ...)
	    local f = CMD[cmd]

        if cmd == "init" then
            skynet.retpack(f(...))
            return
        end
        
		if f ~= nil then            
            f(...)
        end
end)
skynet.start(function()
    CMD.start()
    skynet.register(svr_id)
end)
