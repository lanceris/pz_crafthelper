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
        delayed_search = p.onChangeDelayedSearch
    }
    if map[values.id] then
        map[values.id](inst)
    end

    CHC_settings.f.onModOptionsApply(values)
end

CHC_main.config_apply_funcs.onChangeListFontSize = function(inst)
    inst.updateQueue:push({
        targetView = 'all',
        actions = { 'needUpdateFont' }
    })
end

CHC_main.config_apply_funcs.onChangeShowRecipeModule = function(inst)
    inst.updateQueue:push({
        targetView = 'all',
        actions = { 'needUpdateModRender' },
        exclude = {
            search_items = true,
            fav_items = true
        }
    })
end

CHC_main.config_apply_funcs.onChangeShowIcons = function(inst)
    inst.updateQueue:push({
        targetView = 'all',
        actions = { 'needUpdateShowIcons' }
    })
end

CHC_main.config_apply_funcs.onChangeDelayedSearch = function(inst)
    inst.updateQueue:push({
        targetView = 'all',
        actions = { 'needUpdateDelayedSearch' }
    })
end
