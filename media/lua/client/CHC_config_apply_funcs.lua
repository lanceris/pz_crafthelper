require 'CHC_main'

CHC_main.config_apply_funcs = CHC_main.config_apply_funcs or {}


CHC_main.config_apply_funcs.process = function(values)
    local inst = CHC_menu.CHC_window
    if not inst then return end

    local p = CHC_main.config_apply_funcs
    local map = {
        list_font_size = p.onChangeListFontSize,
        show_recipe_module = p.onChangeShowRecipeModule,
        show_icons = p.onChangeShowIcons,
        delayed_search = p.onChangeDelayedSearch,
        recipe_selector_modifier = p.onChangeSelectorModifier,
        category_selector_modifier = p.onChangeSelectorModifier,
        tab_selector_modifier = p.onChangeSelectorModifier,
        tab_close_selector_modifier = p.onChangeSelectorModifier,
    }
    if map[values.id] then
        map[values.id](inst)
    end

    CHC_settings.f.onModOptionsApply(values)
end

CHC_main.config_apply_funcs.onChangeListFontSize = function(inst)
    inst.updateQueue:push({
        targetViews = { 'all' },
        actions = { 'needUpdateFont', 'needUpdateObjects' }
    })
end

CHC_main.config_apply_funcs.onChangeShowRecipeModule = function(inst)
    inst.updateQueue:push({
        targetViews = { 'all' },
        actions = { 'needUpdateModRender', 'needUpdateObjects' },
        exclude = {
            search_items = true,
            fav_items = true
        }
    })
end

CHC_main.config_apply_funcs.onChangeShowIcons = function(inst)
    inst.updateQueue:push({
        targetViews = { 'all' },
        actions = { 'needUpdateShowIcons' }
    })
end

CHC_main.config_apply_funcs.onChangeDelayedSearch = function(inst)
    inst.updateQueue:push({
        targetViews = { 'all' },
        actions = { 'needUpdateDelayedSearch' }
    })
end

CHC_main.config_apply_funcs.onChangeSelectorModifier = function(inst)
    inst.updateQueue:push({
        targetViews = { 'all' },
        actions = { 'needUpdateInfoTooltip' }
    })
end
