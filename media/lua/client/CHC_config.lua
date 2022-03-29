require 'CHC_main'
require 'luautils'
require 'UI/CHC_menu'


CHC_config = {}
CHC_config.fn = {}
CHC_config.options = {}

-- region config
local is_open = false

local cfg_name = "CraftHelper_config.txt"


CHC_config.fn.encodeSettings = function(t)
    local out = ""
    for k, v in pairs(t) do
        out = out .. k .. "=" .. tostring(v) .. "\n"
    end
    return out
end

CHC_config.fn.loadSettings = function()
    local fileReaderObj = getFileReader(cfg_name, true)
    is_open = true
    local line = fileReaderObj:readLine()
    while line ~= nil do
        local l = strsplit(line, '=')
        if l[2] == 'true' then l[2] = true end
        if l[2] == 'false' then l[2] = false end
        CHC_config.options[l[1]] = tonumber(l[2]) or l[2]
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()
    is_open = false
end

CHC_config.fn.saveSettings = function(t)
    if is_open then return end;

    local fileWriterObj = getFileWriter(cfg_name, true, false)
    is_open = true
    local data = CHC_config.fn.encodeSettings(t)
    fileWriterObj:write(data)
    fileWriterObj:close()
    is_open = false
end

CHC_config.fn.resetSettings = function()
    local data = {}
    data.main_window_x = 100
    data.main_window_y = 100
    data.main_window_w = 1000
    data.main_window_h = 600
    data.main_window_min_w = 400
    data.main_window_min_h = 350
    data.uses_tab_sep_x = 500
    data.uses_filter_name_asc = true
    data.uses_filter_type = "all"
    CHC_config.fn.saveSettings(data)
end

CHC_config.fn.updateSettings = function(menu)
    local data = {}
	local menu = menu or CHC_menu.CHC_Window
	if not menu then return end;

    data.main_window_x = menu:getX()
    data.main_window_y = menu:getY()
    data.main_window_w = menu.width
    data.main_window_h = menu.height
    data.main_window_min_w = menu.minimumWidth
    data.main_window_min_h = menu.minimumHeight
    data.uses_tab_sep_x = menu.usesScreen.column3
    data.uses_filter_name_asc = menu.usesScreen.itemSortAsc == true
    data.uses_filter_type = menu.usesScreen.typeFilter
    CHC_config.fn.saveSettings(data)
    
end
-- endregion