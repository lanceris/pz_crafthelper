require 'luautils'
require 'UI/CHC_menu'



CHC_settings = {
    config = {},
    keybinds = {
        move_up = { key = Keyboard.KEY_NONE, name = "chc_move_up" },
        move_left = { key = Keyboard.KEY_NONE, name = "chc_move_left" },
        move_down = { key = Keyboard.KEY_NONE, name = "chc_move_down" },
        move_right = { key = Keyboard.KEY_NONE, name = "chc_move_right" },
        craft_one = { key = Keyboard.KEY_NONE, name = "chc_craft_one" },
        favorite_recipe = { key = Keyboard.KEY_NONE, name = "chc_favorite_recipe" },
        craft_all = { key = Keyboard.KEY_NONE, name = "chc_craft_all" },
        close_window = { key = Keyboard.KEY_ESCAPE, name = "chc_close_window" },
        toggle_window = { key = Keyboard.KEY_NONE, name = "chc_toggle_window" },
        toggle_uses_craft = { key = Keyboard.KEY_NONE, name = "chc_toggle_uses_craft" },
        move_tab_left = { key = Keyboard.KEY_NONE, name = "chc_move_tab_left" },
        toggle_focus_search_bar = { key = Keyboard.KEY_NONE, name = "chc_toggle_focus_search_bar" },
        move_tab_right = { key = Keyboard.KEY_NONE, name = "chc_move_tab_right" }
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

local function onModOptionsApply(values)
    CHC_settings.config.allow_special_search = values.settings.options.allow_special_search
    CHC_settings.config.show_icons = values.settings.options.show_icons
    CHC_settings.config.show_hidden = values.settings.options.show_hidden
    CHC_settings.config.close_all_on_exit = values.settings.options.close_all_on_exit
    if not CHC_settings.config.main_window then
        CHC_settings.Load()
    end
    CHC_settings.Save()
end

if ModOptions and ModOptions.getInstance then
    CHC_settings.settings = {
        options_data = {
            allow_special_search = {
                name = "IGUI_AllowSpecialSearch",
                tooltip = "IGUI_AllowSpecialSearchTooltip",
                default = true,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
            show_icons = {
                name = "IGUI_ShowIcons",
                tooltip = "IGUI_ShowIconsTooltip",
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
            show_hidden = {
                name = "IGUI_ShowHidden",
                tooltip = "IGUI_ShowHiddenTooltip",
                default = true,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
            close_all_on_exit = {
                name = "IGUI_CloseAllOnExit",
                tooltip = "IGUI_CloseAllOnExitTooltip",
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            }
        },
        mod_id = "CraftHelperContinued",
        mod_shortname = "CHC",
        mod_fullname = "Craft Helper Continued"
    }

    ModOptions:getInstance(CHC_settings.settings)
    local category = "[chc_category_title]"
    for _, value in pairs(CHC_settings.keybinds) do
        ModOptions:AddKeyBinding(category, value)
    end
    ModOptions:loadFile()

else
    CHC_settings.config.allow_special_search = true
    CHC_settings.config.show_icons = false
    CHC_settings.config.show_hidden = true
    CHC_settings.config.close_all_on_exit = false
end

local Json = require("Json")
local cfg_name = "craft_helper_config.json"

CHC_settings.Save = function()
    local fileWriterObj = getFileWriter(cfg_name, true, false)
    local json = Json.Encode(CHC_settings.config)
    fileWriterObj:write(json)
    fileWriterObj:close()
end

CHC_settings.Load = function()
    local fileReaderObj = getFileReader(cfg_name, true)
    local json = ""
    local line = fileReaderObj:readLine()
    while line ~= nil do
        json = json .. line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    if json and json ~= "" then
        CHC_settings.config = Json.Decode(json)
    else
        local init_cfg = {
            show_icons = false,
            allow_special_search = true,
            show_hidden = true,
            close_all_on_exit = false,
            main_window = { x = 100, y = 100, w = 1000, h = 600 },
            uses = { sep_x = 500, filter_asc = true, filter_type = "all" },
            craft = { sep_x = 500, filter_asc = true, filter_type = "all" },
            search = {
                items = { sep_x = 500, filter_asc = true, filter_type = "all" },
                recipes = { sep_x = 500, filter_asc = true, filter_type = "all" }
            },
            favorites = {
                items = { sep_x = 500, filter_asc = true, filter_type = "all" },
                recipes = { sep_x = 500, filter_asc = true, filter_type = "all" }
            }
        }
        CHC_settings.config = init_cfg
        CHC_settings.Save()
    end
end
