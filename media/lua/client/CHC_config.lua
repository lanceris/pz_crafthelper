require 'luautils'
require 'UI/CHC_menu'
require 'CHC_config_apply_funcs'

local utils = require('CHC_utils')

local dir = utils.configDir
local config_name = 'beta_craft_helper_config.lua'
local mappings_name = 'beta_CHC_mappings.json'

local char = string.char
local byte = string.byte
local concat = table.concat

CHC_settings = {
    f = {},
    config = {},
    keybinds = {
        move_up = { key = Keyboard.KEY_NONE, name = 'chc_move_up' },
        move_down = { key = Keyboard.KEY_NONE, name = 'chc_move_down' },
        move_left = { key = Keyboard.KEY_NONE, name = 'chc_move_left' },
        move_right = { key = Keyboard.KEY_NONE, name = 'chc_move_right' },
        move_tab_left = { key = Keyboard.KEY_NONE, name = 'chc_move_tab_left' },
        move_tab_right = { key = Keyboard.KEY_NONE, name = 'chc_move_tab_right' },
        toggle_uses_craft = { key = Keyboard.KEY_NONE, name = 'chc_toggle_uses_craft' },
        close_tab = { key = Keyboard.KEY_NONE, name = "chc_close_tab" },
        toggle_window = { key = Keyboard.KEY_NONE, name = 'chc_toggle_window' },
        close_window = { key = Keyboard.KEY_NONE, name = 'chc_close_window' },
        craft_one = { key = Keyboard.KEY_NONE, name = 'chc_craft_one' },
        craft_all = { key = Keyboard.KEY_NONE, name = 'chc_craft_all' },
        favorite_recipe = { key = Keyboard.KEY_NONE, name = 'chc_favorite_recipe' },
        toggle_focus_search_bar = { key = Keyboard.KEY_NONE, name = 'chc_toggle_focus_search_bar' },
    },
    integrations = {
        Hydrocraft = {
            url = 'https://steamcommunity.com/sharedfiles/filedetails/?id=2778991696',
            modId = 'Hydrocraft',
            luaOnTestReference = {
                ['HCNearCarpybench'] = 'Hydrocraft.HCCarpenterbench',
                ['HCNearHerbatable'] = 'Hydrocraft.HCHerbtable',
                ['HCNearTarkiln'] = 'Hydrocraft.HCTarkiln',
                ['HCNearKiln'] = 'Hydrocraft.HCKiln',
                ['HCNearGrindstone'] = 'Hydrocraft.HCGrindstone'
            }
        }
    },
    mappings = {},
    presets = {
        items = {},
        recipes = {}
    },
    filters = {
        items = {},
        recipes = {}
    },
}

local init_cfg = {
    show_recipe_module = true,
    show_fav_items_inventory = true,
    editable_category_selector = false,
    recipe_selector_modifier = 1, -- none
    category_selector_modifier = 1,
    tab_selector_modifier = 1,
    tab_close_selector_modifier = 1,
    list_font_size = 3, -- medium
    show_icons = true,
    allow_special_search = true,
    show_hidden = false,
    close_all_on_exit = false,
    show_all_props = false,
    delayed_search = false,
    inv_context_behaviour = 2,
    window_opacity = 8,
    scroll_speed = 3,
    main_window = { x = 100, y = 100, w = 1000, h = 600, a = 0.6 },
    uses = { sep_x = 500, filter_asc = true, filter_type = 'all' },
    craft = { sep_x = 500, filter_asc = true, filter_type = 'all' },
    search = {
        items = { sep_x = 500, filter_asc = true, filter_type = 'all' },
        recipes = { sep_x = 500, filter_asc = true, filter_type = 'all' }
    },
    favorites = {
        items = { sep_x = 500, filter_asc = true, filter_type = 'all' },
        recipes = { sep_x = 500, filter_asc = true, filter_type = 'all' }
    }
}

local init_mappings = {
    ignoredItemProps = {},
    pinnedItemProps = {}
}

local init_presets = {
    items = {},
    recipes = {}
}

local applyBlacklist = {
    main_window = true,
    uses = true,
    craft = true,
    search = true,
    favorites = true,

}

local presetStorageToFilename = {
    presets = 'beta_CHC_presets.lua',
    filters = 'beta_CHC_filter_presets.lua'
}

function CHC_settings.f.onModOptionsApply(values)
    if CHC_settings.config.main_window == nil then
        CHC_settings.Load()
    end
    for key, _ in pairs(CHC_settings.config) do
        if not applyBlacklist[key] then
            CHC_settings.config[key] = values.settings.options[key]
        end
    end
    CHC_settings.Save()
end

if ModOptions and ModOptions.getInstance then
    CHC_settings.settings = {
        options_data = {
            allow_special_search = {
                name = 'IGUI_AllowSpecialSearch',
                tooltip = 'IGUI_AllowSpecialSearchTooltip',
                default = true,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            },
            show_icons = {
                name = 'IGUI_ShowIcons',
                tooltip = 'IGUI_ShowIconsTooltip',
                default = true,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            show_hidden = {
                name = 'IGUI_ShowHidden',
                tooltip = 'IGUI_ShowHiddenTooltip',
                default = false,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            },
            close_all_on_exit = {
                name = 'IGUI_CloseAllOnExit',
                tooltip = 'IGUI_CloseAllOnExitTooltip',
                default = false,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            },
            list_font_size = {
                getText('UI_optionscreen_NewSmall'),
                getText('UI_optionscreen_Small'),
                getText('UI_optionscreen_Medium'),
                getText('UI_optionscreen_Large'),
                name = 'IGUI_ListFontSize',
                tooltip = 'IGUI_ListFontSizeTooltip',
                default = 3,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            recipe_selector_modifier = {
                getText('IGUI_None'),
                getText('UI_optionscreen_CycleContainerKey1'),
                getText('UI_optionscreen_CycleContainerKey2'),
                getText('UI_optionscreen_CycleContainerKey3'),
                name = 'IGUI_RecipeSelectorModifier',
                tooltip = getText('IGUI_RecipeSelectorModifierTooltip',
                    getText('UI_optionscreen_binding_chc_move_up'),
                    getText('UI_optionscreen_binding_chc_move_down')
                ),
                default = 1,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            category_selector_modifier = {
                getText('IGUI_None'),
                getText('UI_optionscreen_CycleContainerKey1'),
                getText('UI_optionscreen_CycleContainerKey2'),
                getText('UI_optionscreen_CycleContainerKey3'),
                name = 'IGUI_CategorySelectorModifier',
                tooltip = getText('IGUI_CategorySelectorModifierTooltip',
                    getText('UI_optionscreen_binding_chc_move_left'),
                    getText('UI_optionscreen_binding_chc_move_right')
                ),
                default = 1,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            tab_selector_modifier = {
                getText('IGUI_None'),
                getText('UI_optionscreen_CycleContainerKey1'),
                getText('UI_optionscreen_CycleContainerKey2'),
                getText('UI_optionscreen_CycleContainerKey3'),
                name = 'IGUI_TabSelectorModifier',
                tooltip = getText('IGUI_TabSelectorModifierTooltip',
                    getText('UI_optionscreen_binding_chc_move_tab_left'),
                    getText('UI_optionscreen_binding_chc_move_tab_right')
                ),
                default = 1,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            tab_close_selector_modifier = {
                getText('IGUI_None'),
                getText('UI_optionscreen_CycleContainerKey1'),
                getText('UI_optionscreen_CycleContainerKey2'),
                getText('UI_optionscreen_CycleContainerKey3'),
                name = 'IGUI_TabCloseSelectorModifier',
                tooltip = getText('IGUI_TabCloseSelectorModifierTooltip',
                    getText('UI_optionscreen_binding_chc_close_tab')),
                default = 1,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            show_recipe_module = {
                name = 'IGUI_ShowRecipeModule',
                tooltip = 'IGUI_ShowRecipeModuleTooltip',
                default = true,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            show_fav_items_inventory = {
                name = 'IGUI_ShowFavItemsInventory',
                tooltip = 'IGUI_ShowFavItemsInventoryTooltip',
                default = true,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            },
            editable_category_selector = {
                name = 'IGUI_EditableCategorySelector',
                tooltip = 'IGUI_EditableCategorySelectorTooltip',
                default = false,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            },
            show_all_props = {
                name = 'IGUI_ShowAllItemProps',
                tooltip = 'IGUI_ShowAllItemPropsTooltip',
                default = false,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            },
            delayed_search = {
                name = 'IGUI_DelayedSearch',
                tooltip = 'IGUI_DelayedSearchTooltip',
                default = false,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_main.config_apply_funcs.process
            },
            inv_context_behaviour = {
                getText('IGUI_None'),
                getText('IGUI_OnContextBehaviourDefaultOption'),
                getText('IGUI_OnContextBehaviourExtraOption'),
                getText('IGUI_OnContextBehaviourDefaultShiftOption'),
                name = 'IGUI_OnContextBehaviour',
                tooltip = getText("IGUI_OnContextBehaviourTooltip",
                    getText("IGUI_OnContextBehaviourTooltipFirst",
                        getText("IGUI_None")),
                    getText("IGUI_OnContextBehaviourTooltipSecond",
                        getText("IGUI_OnContextBehaviourDefaultOption"),
                        getText("IGUI_chc_context_onclick")),
                    getText("IGUI_OnContextBehaviourTooltipThird",
                        getText("IGUI_OnContextBehaviourExtraOption"),
                        getText("IGUI_chc_context_onclick"),
                        getText("IGUI_CraftUI_Favorite"),
                        getText("IGUI_find_item")),
                    getText("IGUI_OnContextBehaviourTooltipFourth",
                        getText("IGUI_OnContextBehaviourDefaultShiftOption"),
                        getText("IGUI_chc_context_onclick"),
                        getText("IGUI_CraftUI_Favorite"),
                        getText("IGUI_find_item"))
                ),
                default = 2,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            },
            window_opacity = {
                "0%",
                "10%",
                "20%",
                "30%",
                "40%",
                "50%",
                "60%",
                "70%",
                "80%",
                "90%",
                "100%",
                name = 'IGUI_WindowOpacity',
                tooltip = 'IGUI_WindowOpacityTooltip',
                default = 8,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply

            },
            scroll_speed = {
                "10",
                "50",
                "100",
                "200",
                "500",
                name = "IGUI_ScrollSpeed",
                tooltip = "IGUI_ScrollSpeedTooltip",
                default = 3,
                OnApplyMainMenu = CHC_settings.f.onModOptionsApply,
                OnApplyInGame = CHC_settings.f.onModOptionsApply
            }
        },
        mod_id = 'CraftHelperContinued',
        mod_shortname = 'CHC',
        mod_fullname = 'Craft Helper Continued'
    }

    ModOptions:getInstance(CHC_settings.settings)
    local category = '[chc_category_title]'
    for _, value in pairs(CHC_settings.keybinds) do
        ModOptions:AddKeyBinding(category, value)
    end
    ModOptions:loadFile()
else
    -- defaults in case 'Mod Options' not installed
    CHC_settings.config.show_recipe_module = true
    CHC_settings.config.show_fav_items_inventory = true
    CHC_settings.config.editable_category_selector = false
    CHC_settings.config.recipe_selector_modifier = 1
    CHC_settings.config.category_selector_modifier = 1
    CHC_settings.config.tab_selector_modifier = 1
    CHC_settings.config.tab_close_selector_modifier = 1
    CHC_settings.config.list_font_size = 3
    CHC_settings.config.allow_special_search = true
    CHC_settings.config.show_icons = true
    CHC_settings.config.show_hidden = false
    CHC_settings.config.close_all_on_exit = false
    CHC_settings.config.show_all_props = false
    CHC_settings.config.delayed_search = false
    CHC_settings.config.inv_context_behaviour = 2
    CHC_settings.config.window_opacity = 8
    CHC_settings.config.scroll_speed = 3
end


CHC_settings.Save = function(config)
    config = config or CHC_settings.config
    local status = pcall(utils.tableutil.save, config_name, config)
    if not status then
        -- config is corrupted, create new
        CHC_settings.Save(init_cfg)
    end
end

CHC_settings.Load = function()
    local status, config = pcall(utils.tableutil.load, config_name)
    if not status or not config then
        config = copyTable(init_cfg)
        CHC_settings.Save(config)
    end
    CHC_settings.checkConfig(config)
    config = CHC_settings.validateConfig(config)
    CHC_settings.config = config
end

CHC_settings.migrateConfig = function()
    local oldName = "craft_helper_config.json"
    local oldCfgr = getFileReader(oldName, false)
    if not oldCfgr then return end
    oldCfgr:close()
    local status, oldConfig = pcall(utils.jsonutil.Load, oldName)
    if not status then return end
    local defaultStr = "Safe to remove"
    utils.jsonutil.Save(oldName, { defaultStr })
    if not oldConfig or
        utils.empty(oldConfig) or
        oldConfig[1] == defaultStr then
        return
    end
    utils.tableutil.save(config_name, oldConfig)
end

CHC_settings.checkConfig = function(config)
    local shouldReSave = false
    for name, _ in pairs(init_cfg) do
        if config[name] == nil then
            config[name] = init_cfg[name]
            shouldReSave = true
        end
    end
    if shouldReSave == true then
        CHC_settings.Save(config)
    end
end

CHC_settings.validateConfig = function(config)
    local win = config.main_window
    if not win then return config end
    local init = init_cfg.main_window
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    if win.x > screenW or win.x < 0 then
        win.x = init.x
    end
    if win.y > screenH or win.y < 0 then
        win.y = init.y
    end
    if win.w > screenW or win.w < 0 then
        win.w = init.w
    end
    if win.h > screenH or win.h < 0 then
        win.h = init.h
    end
    return config
end


CHC_settings.SavePropsData = function(config)
    config = config or CHC_settings.mappings
    local status = pcall(utils.tableutil.save, mappings_name, config)
    if not status then
        -- config is corrupted, create new
        CHC_settings.SavePropsData(init_mappings)
    end
end

CHC_settings.LoadPropsData = function()
    local status, config = pcall(utils.tableutil.load, mappings_name)
    if not status or not config then
        config = init_mappings
        CHC_settings.SavePropsData(config)
    end
    CHC_settings.mappings = config
end

local function utf8_from(t)
    local bytearr = {}
    for _, v in ipairs(t) do
        local utf8byte = v < 0 and (0xff + v + 1) or v
        bytearr[#bytearr + 1] = char(utf8byte)
    end
    return concat(bytearr)
end

local types = { "items", "recipes" }

CHC_settings.SavePresetsData = function(storageKey, filename, backup_filename)
    filename = filename or presetStorageToFilename[storageKey]
    if not filename then
        error("Could not determine filename to save presets to!")
    end
    backup_filename = backup_filename or ("backup_" .. filename)
    local config = copyTable(init_presets)
    for i = 1, #types do
        local _type = types[i]
        for name, entries in pairs(CHC_settings[storageKey][_type]) do
            local entry = {
                name = concat({ byte(name, 1, -1) }, ","),
                entries = entries,
            }
            config[_type][#config[_type] + 1] = entry
        end
    end

    local status = pcall(utils.tableutil.save, filename, config)
    if not status then
        -- config is corrupted, create new
        utils.tableutil.save(filename, init_presets)
    else
        utils.tableutil.save(backup_filename, config)
    end
end

---Load presets data for `storageKey`
---@param storageKey string key to set data to
---@param filename? string filename to load data from
CHC_settings.LoadPresetsData = function(storageKey, filename)
    filename = filename or presetStorageToFilename[storageKey]
    if not storageKey then
        error("Could not determine filename to load presets from!")
    end
    local status, config = pcall(utils.tableutil.load, filename)
    if not status or not config then
        config = copyTable(init_presets)
    end
    local cfg = copyTable(init_presets)
    for i = 1, #types do
        local _type = types[i]
        for _, entry in pairs(config[_type]) do
            local decoded_name = strsplit(entry.name, ",")
            for k = 1, #decoded_name do
                decoded_name[k] = tonumber(decoded_name[k])
            end
            cfg[_type][utf8_from(decoded_name)] = entry.entries
        end
    end

    CHC_settings[storageKey] = cfg
end
