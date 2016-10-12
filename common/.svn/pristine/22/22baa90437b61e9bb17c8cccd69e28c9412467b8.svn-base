local filelog = require "filelog"

local filename = "configtool.lua"

local ConfigTool = {}

function ConfigTool.load_config(config_filename)
    if config_filename == nil then
    	filelog.sys_error(filename, " [BASIC_CONFIGTOOL] ConfigTool.load_config config_filename == nil")
        return nil
    end

    local f = io.open(config_filename)
    if f == nil then
    	filelog.sys_error(filename, " [BASIC_CONFIGTOOL] ConfigTool.load_config open "..config_filename.." failed")
        return nil
    end

    local source = f:read "*a"
    f:close()
    if source == nil then
    	filelog.sys_error(filename, " [BASIC_CONFIGTOOL] read ConfigTool.load_config "..config_filename.." failed")
        return nil
    end

    local tmp = {}
    local ftmp, err = load(source, "@"..config_filename, "t", tmp)
    if ftmp == nil then
    	filelog.sys_error(filename.." [BASIC_CONFIGTOOL] ConfigTool.load_config load "..config_filename.." failed", err)
        return nil
    end

    local success, err = pcall(ftmp)
    if not success then
        filelog.sys_error(filename.." [BASIC_CONFIGTOOL] ConfigTool.load_config call "..config_filename.." failed", err)
        return nil
    end

    return tmp
end

return ConfigTool


