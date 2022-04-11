require 'luautils'
require 'UI/CHC_menu'

CHC_config = {}
CHC_config.fn = {}
CHC_config.options = {}


CHC_settings = {
    settings = {
        options_data = {
            special_search = {
                name = "IGUI_SpecialSearch",
                tooltip = "IGUI_SpecialSearchTooltip",
                default = true
            },
            uses_list_icons = {
                name = "IGUI_UsesListIcons",
                tooltip = "IGUI_UsesListIconsTooltip",
                default = false
            },
            uses_show_hidden_recipes = {
                name = "IGUI_UsesShowHiddenRecipes",
                tooltip = "IGUI_UsesShowHiddenRecipesTooltip",
                default = true
            }
        },
        mod_id = "CraftHelperContinued",
        mod_shortname = "CHC",
        mod_fullname = "Craft Helper Continued"
    },
    keybinds = {
        move_up = { key = Keyboard.KEY_NONE, name = "chc_move_up" },
        move_left = { key = Keyboard.KEY_NONE, name = "chc_move_left" },
        move_down = { key = Keyboard.KEY_NONE, name = "chc_move_down" },
        move_right = { key = Keyboard.KEY_NONE, name = "chc_move_right" },
        craft_one = { key = Keyboard.KEY_NONE, name = "chc_craft_one" },
        favorite_recipe = { key = Keyboard.KEY_NONE, name = "chc_favorite_recipe" },
        craft_all = { key = Keyboard.KEY_NONE, name = "chc_craft_all" },
        close_window = { key = Keyboard.KEY_ESCAPE, name = "chc_close_window" }
    },
    integrations = {
        Hydrocraft = {
            url = "https://steamcommunity.com/sharedfiles/filedetails/?id=2778991696",
            modId = "Hydrocraft",
            luaOnTestReference = {
                ['HCNearCarpybench'] = 'Hydrocraft.HCCarpenterbench',
                ['HCNearHerbatable'] = 'Hydrocraft.HCHerbtable',
                ['HCNearTarkiln'] = 'Hydrocraft.HCTarkiln',
                ['HCNearKiln'] = 'Hydrocraft.HCKiln',
                ['HCNearGrindstone'] = 'Hydrocraft.HCGrindstone' }
        }
    }
}

if ModOptions and ModOptions.getInstance then
    local settings = ModOptions:getInstance(CHC_settings.settings)
    local category = "[chc_category_title]"
    for _, value in pairs(CHC_settings.keybinds) do
        ModOptions:AddKeyBinding(category, value)
    end
    ModOptions:loadFile()

    local search = settings:getData("special_search")
    CHC_config.options.special_search = search.value
    function search:OnApplyInGame(val)
        CHC_config.options.special_search = val
    end

    local uses_list_icons = settings:getData("uses_list_icons")
    CHC_config.options.uses_list_icons = uses_list_icons
    function uses_list_icons:OnApplyInGame(val)
        CHC_config.options.uses_list_icons = val
    end

    local uses_show_hidden_recipes = settings:getData("uses_show_hidden_recipes")
    CHC_config.options.uses_show_hidden_recipes = uses_show_hidden_recipes
    function uses_show_hidden_recipes:OnApplyInGame(val)
        CHC_config.options.uses_show_hidden_recipes = val
    end

else
    CHC_config.options.special_search = true
    CHC_config.options.uses_list_icons = false
    CHC_config.options.uses_show_hidden_recipes = true
end


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
    if is_open then return end
    ;
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
    -- data.uses_tab_sep_x = 500
    -- data.uses_filter_name_asc = true
    -- data.uses_filter_type = "all"
    -- data.craft_tab_sep_x = 500
    -- data.craft_filter_name_asc = true
    -- data.craft_filter_type = "all"
    CHC_config.fn.saveSettings(data)
end

CHC_config.fn.updateSettings = function(menu)
    local data = {}
    local menu = menu or CHC_menu.CHC_Window
    if not menu then return end
    ;
    data.main_window_x = menu:getX()
    data.main_window_y = menu:getY()
    data.main_window_w = menu.width
    data.main_window_h = menu.height
    data.main_window_min_w = menu.minimumWidth
    data.main_window_min_h = menu.minimumHeight
    -- if menu.usesScreen and menu.usesScreen.headers then
    --     data.uses_tab_sep_x = menu.usesScreen.headers.nameHeader.width or 250
    --     data.uses_filter_name_asc = menu.usesScreen.itemSortAsc == true
    --     data.uses_filter_type = menu.usesScreen.typeFilter or "all"
    -- end
    -- if menu.craftScreen and menu.craftScreen.headers then
    --     data.craft_tab_sep_x = menu.craftScreen.headers.nameHeader.width or 250
    --     data.craft_filter_name_asc = menu.craftScreen.itemSortAsc == true
    --     data.craft_filter_type = menu.craftScreen.typeFilter or "all"
    -- end
    CHC_config.fn.saveSettings(data)

end
-- endregion
