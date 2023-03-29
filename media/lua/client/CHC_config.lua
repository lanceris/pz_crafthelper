require 'luautils'
require 'UI/CHC_menu'
require 'CHC_config_apply_funcs'

local utils = require('CHC_utils')

local dir = utils.configDir
local config_name = 'craft_helper_config.json'
local mappings_name = 'CHC_mappings.json'

CHC_settings = {
    f = {},
    config = {},
    keybinds = {
        move_up = { key = Keyboard.KEY_NONE, name = 'chc_move_up' },
        move_left = { key = Keyboard.KEY_NONE, name = 'chc_move_left' },
        move_down = { key = Keyboard.KEY_NONE, name = 'chc_move_down' },
        move_right = { key = Keyboard.KEY_NONE, name = 'chc_move_right' },
        craft_one = { key = Keyboard.KEY_NONE, name = 'chc_craft_one' },
        favorite_recipe = { key = Keyboard.KEY_NONE, name = 'chc_favorite_recipe' },
        craft_all = { key = Keyboard.KEY_NONE, name = 'chc_craft_all' },
        close_window = { key = Keyboard.KEY_ESCAPE, name = 'chc_close_window' },
        toggle_window = { key = Keyboard.KEY_NONE, name = 'chc_toggle_window' },
        toggle_uses_craft = { key = Keyboard.KEY_NONE, name = 'chc_toggle_uses_craft' },
        move_tab_left = { key = Keyboard.KEY_NONE, name = 'chc_move_tab_left' },
        toggle_focus_search_bar = { key = Keyboard.KEY_NONE, name = 'chc_toggle_focus_search_bar' },
        move_tab_right = { key = Keyboard.KEY_NONE, name = 'chc_move_tab_right' }
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
    mappings = {}
}

local init_cfg = {
    show_recipe_module = true,
    show_fav_items_inventory = false,
    editable_category_selector = false,
    recipe_selector_modifier = 1, -- none
    category_selector_modifier = 1,
    tab_selector_modifier = 1,
    list_font_size = 3, -- large
    show_icons = true,
    allow_special_search = true,
    show_hidden = false,
    close_all_on_exit = false,
    show_all_props = false,
    delayed_search = false,
    main_window = { x = 100, y = 100, w = 1000, h = 600 },
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

function CHC_settings.f.onModOptionsApply(values)
    if CHC_settings.config.main_window == nil then
        CHC_settings.Load()
    end
    CHC_settings.config.show_recipe_module = values.settings.options.show_recipe_module
    CHC_settings.config.show_fav_items_inventory = values.settings.options.show_fav_items_inventory
    CHC_settings.config.editable_category_selector = values.settings.options.editable_category_selector
    CHC_settings.config.recipe_selector_modifier = values.settings.options.recipe_selector_modifier
    CHC_settings.config.category_selector_modifier = values.settings.options.category_selector_modifier
    CHC_settings.config.tab_selector_modifier = values.settings.options.tab_selector_modifier
    CHC_settings.config.list_font_size = values.settings.options.list_font_size
    CHC_settings.config.allow_special_search = values.settings.options.allow_special_search
    CHC_settings.config.show_icons = values.settings.options.show_icons
    CHC_settings.config.show_hidden = values.settings.options.show_hidden
    CHC_settings.config.close_all_on_exit = values.settings.options.close_all_on_exit
    CHC_settings.config.show_all_props = values.settings.options.show_all_props
    CHC_settings.config.delayed_search = values.settings.options.delayed_search
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
                OnApplyInGame = CHC_settings.f.onModOptionsApply
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
                OnApplyInGame = CHC_settings.f.onModOptionsApply
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
                OnApplyInGame = CHC_settings.f.onModOptionsApply
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
                default = false,
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
    CHC_settings.config.show_fav_items_inventory = false
    CHC_settings.config.editable_category_selector = false
    CHC_settings.config.recipe_selector_modifier = 1
    CHC_settings.config.category_selector_modifier = 1
    CHC_settings.config.tab_selector_modifier = 1
    CHC_settings.config.list_font_size = 3
    CHC_settings.config.allow_special_search = true
    CHC_settings.config.show_icons = true
    CHC_settings.config.show_hidden = false
    CHC_settings.config.close_all_on_exit = false
    CHC_settings.config.show_all_props = false
    CHC_settings.config.delayed_search = false
end


CHC_settings.Save = function(config)
    config = config or CHC_settings.config
    local status = pcall(utils.jsonutil.Save, config_name, config)
    if not status then
        -- config is corrupted, create new
        CHC_settings.Save(init_cfg)
    end
end

CHC_settings.Load = function()
    local status, config = pcall(utils.jsonutil.Load, config_name)

    if not status or not config then
        config = init_cfg
        CHC_settings.Save(config)
    end
    CHC_settings.checkConfig(config)
    CHC_settings.config = config
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


CHC_settings.SavePropsData = function(config)
    config = config or CHC_settings.mappings
    local status = pcall(utils.jsonutil.Save, mappings_name, config)
    if not status then
        -- config is corrupted, create new
        CHC_settings.SavePropsData(init_mappings)
    end
end

CHC_settings.LoadPropsData = function()
    local status, config = pcall(utils.jsonutil.Load, mappings_name)
    if not status or not config then
        config = init_mappings
        CHC_settings.SavePropsData(config)
    end
    CHC_settings.mappings = config
end
