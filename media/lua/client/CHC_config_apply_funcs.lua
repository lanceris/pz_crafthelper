require 'CHC_main'

CHC_main.config_apply_funcs = CHC_main.config_apply_funcs or {}


CHC_main.config_apply_funcs.process = function(values)
    local inst = CHC_menu.CHC_window
    if not inst then return end

    local p = CHC_main.config_apply_funcs
    local map = { list_font_size = p.onChangeListFontSizeInGame }
    if map[values.id] then
        map[values.id](inst)
    end

    CHC_settings.f.onModOptionsApply(values)
end

CHC_main.config_apply_funcs.onChangeListFontSizeInGame = function(inst)
    inst.updateQueue:push({
        targetView = 'all',
        actions = { 'needUpdateFont' }
    })
end
