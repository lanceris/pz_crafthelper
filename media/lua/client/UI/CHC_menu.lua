require 'CHC_main'

CHC_menu = CHC_menu or {}
local utils = require('CHC_utils')
local loadTries = 0

local function setPlayer()
    CHC_menu.player = getPlayer()
    CHC_menu.playerNum = CHC_menu.player:getPlayerNum()
    CHC_menu.playerModData = CHC_menu.player:getModData()
end

--- called just after CHC_main.loadDatas
CHC_menu.init = function()
    setPlayer()
    CHC_menu.applyMigrations()
    CHC_menu.createCraftHelper()
end

CHC_menu.applyMigrations = function()
    --region configs from .json to .lua
    CHC_settings.migrateConfig()
    --endregion

    --region migrateItemFavorites
    local modData = CHC_menu.playerModData
    if not modData or modData.CHC_item_favorites then return end
    modData.CHC_item_favorites = {}
    for name, _ in pairs(modData) do
        if utils.startswith(name, "itemFavoriteCHC:") then
            modData.CHC_item_favorites[strsplit(name, ":")[2]] = true
            modData[name] = nil
        end
    end
    --endregion
end

--- loads config and creates window instance
CHC_menu.createCraftHelper = function()
    if CHC_menu.CHC_window ~= nil and CHC_menu.CHC_window:getIsVisible() then
        CHC_menu.forceCloseWindow(true)
    end
    CHC_settings.Load()
    CHC_settings.LoadPropsData()
    CHC_settings.LoadPresetsData("presets")
    -- CHC_settings.LoadPresetsData("filters")
    local options = CHC_settings.config

    local args = {
        x = options.main_window.x,
        y = options.main_window.y,
        width = options.main_window.w,
        height = options.main_window.h,
        backgroundColor = { r = 0, g = 0, b = 0, a = options.main_window.a },
        minimumWidth = 400,
        minimumHeight = 350,
    }
    CHC_menu.CHC_window = CHC_window:new(args)
    CHC_menu.CHC_window:initialise()
    CHC_menu.CHC_window:setVisible(false)
end

CHC_menu.forceCloseWindow = function(remove)
    local window = CHC_menu.CHC_window
    if window == nil then return end
    window:close()
    if window:getIsVisible() then
        -- force closing
        window:setVisible(false)
        window:removeFromUIManager()
    end
    if remove then CHC_menu.CHC_window = nil end
end

--- called on right-clicking item in inventory/hotbar
CHC_menu.doCraftHelperMenu = function(player, context, items)
    -- check if mod initialised
    local itemsEmpty
    if not CHC_main or not CHC_main.items or utils.empty(CHC_main.items) then
        itemsEmpty = true
    end
    if CHC_main and loadTries >= 5 and itemsEmpty then
        utils.chcerror("Mod failed to initialise 5 times, something is clearly wrong...", "CHC_menu.doCraftHelperMenu",
            nil, true)
        return
    end

    if itemsEmpty then
        utils.chcerror("Mod failed to initialise, trying again...", "CHC_menu.doCraftHelperMenu", nil, false)
        -- re-init mod
        CHC_menu.forceCloseWindow()
        if CHC_menu.CHC_window then
            -- no items but window is here (WTF?)
            utils.chcerror("CHC_window found when mustn't, please contact mod author if you see this error",
                "CHC_menu.doCraftHelperMenu", nil, false)
            CHC_menu.CHC_window = nil
        end
        loadTries = loadTries + 1
        CHC_main.loadDatas()
    elseif not itemsEmpty and CHC_menu.CHC_window == nil then
        -- main init is ok, but window not initialised
        utils.chcerror("CHC_window not found, will create new one...", "CHC_menu.doCraftHelperMenu", nil, false)
        loadTries = loadTries + 1
        CHC_menu.init()
    elseif not itemsEmpty and CHC_menu.CHC_window then
        loadTries = 0
    end

    local itemsUsedInRecipes = {}

    local item
    -- Go through the items selected (because multiple selections in inventory is possible)
    for i = 1, #items do
        -- allows to get ctx option when clicking on hotbar/equipped item
        if not instanceof(items[i], 'InventoryItem') then
            item = items[i].items[1]
        else
            item = items[i]
        end

        -- if item is used in any recipe OR there is a way to create this item - mark item as valid
        local fullType = item:getFullType()
        local isRecipes = CHC_main.common.areThereRecipesForItem(nil, fullType)
        if isRecipes then
            itemsUsedInRecipes[#itemsUsedInRecipes + 1] = item
        end
    end

    -- If one or more items tested above are used in a recipe
    -- we effectively add an option in the contextual menu
    local ctxBehIndex = CHC_settings.config.inv_context_behaviour
    if not ctxBehIndex then
        utils.chcerror("inv_context_behaviour option not initialised", "CHC_menu.doCraftHelperMenu", nil, false)
        ctxBehIndex = 2
    end
    local onContextBehaviourToInternal = {
        { chc = false, find = false, fav = false },
        { chc = true,  find = false, fav = false },
        { chc = true,  find = true,  fav = true },
    }
    local ctxOptions = onContextBehaviourToInternal[ctxBehIndex]

    if ctxOptions.chc then
        if type(itemsUsedInRecipes) == 'table' and #itemsUsedInRecipes > 0 then
            local opt = context:addOption(getText('IGUI_chc_context_onclick'), itemsUsedInRecipes, CHC_menu
                .onCraftHelper,
                player)
            opt.iconTexture = getTexture('media/textures/CHC_ctx_icon.png')
            CHC_main.common.addTooltipNumRecipes(opt, item)
        end
    end

    if ctxOptions.fav then
        local isFav = CHC_menu.playerModData.CHC_item_favorites[CHC_main.common.getFavItemModDataStr(item)] == true
        local favStr = isFav and getText('ContextMenu_Unfavorite') or getText('IGUI_CraftUI_Favorite')
        local optName = favStr .. ' (' .. getText('IGUI_chc_context_onclick') .. ')'
        local favOpt = context:addOption(optName, items, CHC_menu.toggleItemFavorite)
        if isFav then
            favOpt.iconTexture = getTexture('media/textures/CHC_item_favorite_star_outline.png')
        else
            favOpt.iconTexture = getTexture('media/textures/CHC_item_favorite_star.png')
        end
    end

    if ctxOptions.find then
        local findOpt = context:addOption(
            getText('IGUI_find_item') .. ' (' .. getText('IGUI_chc_context_onclick') .. ')', items,
            CHC_menu.onCraftHelper, player, true)
        findOpt.iconTexture = getTexture('media/textures/search_icon.png')
    end
end

CHC_menu.onCraftHelper = function(items, player, itemMode)
    itemMode = itemMode and true or false
    local inst = CHC_menu.CHC_window
    if not inst then
        utils.chcerror("Craft Helper failed to open", "CHC_menu.onCraftHelper", nil, false)
        return
    end

    -- Show craft helper window
    for i = 1, #items do
        local item = items[i]
        if not instanceof(item, 'InventoryItem') then
            item = item.items[1]
        end
        if not itemMode then
            inst:addItemView(item)
        end
    end
    if itemMode then
        local item = items[#items]
        if not instanceof(item, 'InventoryItem') then item = item.items[1] end
        local fullType
        if instanceof(item, "Moveable") then
            fullType = CHC_main.moveablesMap[item:getWorldSprite()]
        else
            fullType = item:getFullType()
        end
        item = CHC_main.items[fullType]
        if item then
            CHC_menu.onCraftHelperItem(inst, item)
        end
    end

    if not inst:getIsVisible() then
        inst:setVisible(true)
        inst:addToUIManager()
        -- local joypadData = JoypadState.players[CHC_menu.playerNum + 1]
        -- if joypadData then
        -- 	CHC_menu.CHC_window.prevFocus = joypadData.focus
        -- 	joypadData.focus = CHC_menu.CHC_window
        -- 	updateJoypadFocus(joypadData)
        -- end
    end
end

CHC_menu.onCraftHelperItem = function(window_inst, item)
    local viewName = getText('UI_search_tab_name')
    local subViewName = window_inst.uiTypeToView['search_items'].name
    window_inst:refresh(viewName) -- activate top level search view
    local top = window_inst.panel.activeView
    if top.name ~= viewName then
        utils.chcerror("Top view incorrect", "CHC_menu.onCraftHelperItem", nil, false)
        return
    end
    top.view:activateView(subViewName)
    local sub = top.view.activeView
    local view = sub.view

    local txt = string.format('#%s,%s', item.displayCategory, item.displayName)
    txt = string.lower(txt)
    view.searchRow.searchBar:setText(txt)
    -- view.searchRow.searchBar:setText('') -- FIXME to change find item behaviour
    view:updateObjects()
    if #view.objList.items ~= 0 then
        local it = view.objList.items
        local c = 1
        for i = 1, #it do
            if string.lower(it[i].text) == string.lower(item.displayName) then
                c = i
                break
            end
        end
        view.objList.selected = c
        view.objList:ensureVisible(c)
        if view.objPanel then
            view.objPanel:setObj(it[c].item)
        end
    end

    window_inst.updateQueue:push({
        targetViews = { view.ui_type },
        actions = { 'needUpdateSubViewName' },
        data = { needUpdateSubViewName = view.objListSize }
    })
end

--- window toggle logic
CHC_menu.toggleUI = function(ui)
    ui = ui or CHC_menu.CHC_window
    if ui then
        if ui:getIsVisible() then
            ui:setVisible(false)
            ui:removeFromUIManager()
        else
            ui:setVisible(true)
            ui:addToUIManager()
        end
    else
        utils.chcerror("No UI found", "CHC_menu.toggleUI", nil, false)
    end
end

CHC_menu.toggleItemFavorite = function(items)
    local modData = CHC_menu.playerModData
    for i = 1, #items do
        local item
        if not instanceof(items[i], 'InventoryItem') then
            item = items[i].items[1]
        else
            item = items[i]
        end
        local isFav = modData.CHC_item_favorites[CHC_main.common.getFavItemModDataStr(item)] == true
        isFav = not isFav
        modData.CHC_item_favorites[CHC_main.common.getFavItemModDataStr(item)] = isFav or nil
        CHC_main.items[item:getFullType()].favorite = isFav
    end
    CHC_menu.CHC_window.updateQueue:push({
        targetViews = { 'fav_items' },
        actions = { 'needUpdateFavorites', 'needUpdateObjects' }
    })
end

---Show/hide Craft Helper window keybind listener
---@param key number key code
CHC_menu.onPressKey = function(key)
    if not MainScreen.instance or
        not MainScreen.instance.inGame or
        MainScreen.instance:getIsVisible() or
        not CHC_menu.CHC_window then
        return
    end
    if key == CHC_settings.keybinds.toggle_window.key then
        CHC_menu.toggleUI()
    end
end

Events.OnFillInventoryObjectContextMenu.Add(CHC_menu.doCraftHelperMenu)
Events.OnCustomUIKey.Add(CHC_menu.onPressKey)
