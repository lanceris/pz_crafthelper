-- Main window, opened when RMB -> Craft Helper 41 on item
require 'CHC_config'
require 'UI/CHC_recipe_view'
require 'UI/CHC_item_view'
require 'UI/components/CHC_presets'

---@class CHC_window:ISCollapsableWindow
---@field x number
---@field y number
---@field width number
---@field height number
CHC_window = ISCollapsableWindowJoypad:derive('CHC_window')
local utils = require('CHC_utils')
local error = utils.chcerror
local print = utils.chcprint
local pairs = pairs
local format = string.format
local lower = string.lower
local concat = table.concat

CHC_window.icons = {
    main = getTexture('media/textures/CHC_ctx_icon.png'),
    common = {
        copy = getTexture("media/textures/CHC_copy_icon.png"),
        paste = getTexture('media/textures/CHC_paste_icon.png'),
        help_tooltip = getTexture("media/textures/keybinds_help.png"),
        mod = getTexture('media/textures/CHC_mod.png'),
        search = getTexture("media/textures/search_icon.png"),
        new_tab = getTexture("media/textures/CHC_open_new_tab.png"),
        add = getTexture("media/textures/CHC_evolved_add.png"),
        type_all = getTexture('media/textures/type_filt_all.png'),
        filter = getTexture("media/textures/CHC_filter_icon.png"),
        expanded = getTexture("media/ui/TreeExpanded.png"),
        collapsed = getTexture("media/ui/TreeCollapsed.png")
    },
    item = {
        favorite = {
            default = getTexture('media/textures/CHC_item_favorite_star.png'),
            checked = getTexture('media/textures/CHC_item_favorite_star_checked.png'),
            unchecked = getTexture('media/textures/CHC_item_favorite_star_outline.png'),
            remove_all = getTexture('media/textures/CHC_item_favorite_star_remove_all.png')
        },
    },
    recipe = {
        favorite = {
            default = getTexture('media/textures/CHC_recipe_favorite_star.png'),
            checked = getTexture('media/textures/CHC_recipe_favorite_star_checked.png'),
            unchecked = getTexture('media/textures/CHC_recipe_favorite_star_outline.png'),
            remove_all = getTexture('media/textures/CHC_recipe_favorite_star_remove_all.png')
        },
        type_all = getTexture('media/textures/type_filt_all.png'),
        type_valid = getTexture('media/textures/type_filt_valid.png'),
        type_known = getTexture('media/textures/type_filt_known.png'),
        type_invalid = getTexture('media/textures/type_filt_invalid.png'),
        category = getTexture('media/textures/CHC_recipepanel_category.png'),
        result = getTexture('media/textures/CHC_recipepanel_output.png'),
        required_time = getTexture('media/textures/CHC_recipe_required_time.png'),
        block_valid = getTexture("media/textures/CHC_blockAV.png"),
        block_invalid = getTexture("media/textures/CHC_blockUN.png"),
        block_all = getTexture("media/textures/type_filt_all.png"),
        evolved = {
            food_data = {
                hunger = getTexture("media/textures/evolved_food_data/CHC_hunger.png"),
                thirst = getTexture("media/textures/evolved_food_data/CHC_evolved_thirst.png"),
                endurance = getTexture("media/textures/evolved_food_data/CHC_endurance.png"),
                stress = getTexture("media/textures/evolved_food_data/CHC_stress.png"),
                boredom = getTexture("media/textures/evolved_food_data/CHC_boredom.png"),
                unhappy = getTexture("media/textures/evolved_food_data/CHC_unhappiness.png"),
                nutr_calories = getTexture("media/textures/evolved_food_data/CHC_calories.png"),
            },
            add_hovered = getTexture("media/textures/CHC_evolved_add_hovered.png"),
        },
    },
}
CHC_window.icons.presets = {
    save = getTexture("media/textures/bottom_panel/save.png"),
    apply = getTexture("media/textures/bottom_panel/apply.png"),
    rename = getTexture("media/textures/bottom_panel/rename.png"),
    duplicate = CHC_window.icons.common.copy,
    share = getTexture("media/textures/bottom_panel/share.png"),
    import = getTexture("media/textures/bottom_panel/import.png"),
    delete = getTexture("media/textures/bottom_panel/delete.png"),
    more = getTexture("media/textures/bottom_more.png")
}

-- region create

function CHC_window:initialise()
    ISCollapsableWindowJoypad.initialise(self)
    self:create()
    self.infoButton:setOnClick(CHC_window.onInfo, self)
end

function CHC_window:create()
    ISCollapsableWindowJoypad.createChildren(self)

    local tbh = self:titleBarHeight()
    -- region main container (search, favorites and all selected items)
    self.panel = ISTabPanel:new(0, tbh, self.width, self.height - 52)

    self.panel:initialise()
    self.panel:setTabsTransparency(0.4)
    self.panel:setAnchorRight(true)
    self.panel.onRightMouseDown = self.onMainTabRightMouseDown
    self.panel.onActivateView = CHC_window.onActivateView
    self.panel.target = self
    self.panel:setEqualTabWidth(false)
    -- endregion
    self.panelY = tbh + self.panel.tabHeight
    self.common_screen_data = {
        x = 0,
        y = self.panelY + self.panel.tabHeight,
        w = self.width,
        h = self.panel.height - self.panelY - 4
    }

    self:updateFavorites()
    self:addSearchPanel()
    self:addFavoriteScreen()

    -- add tab for each selected item
    if self.items then
        for i = 1, #self.items do
            local item = self.items[i]
            if not instanceof(item, 'InventoryItem') then
                item = item.items[1]
            end
            self:addItemView(item)
        end
    end

    local bottomPanelMoreBtnOptions = {
        save = {
            icon = CHC_window.icons.presets.save,
            title = getText("IGUI_BottomPanelMoreSave"),
            onclick = self.presets.onMoreBtnSaveClick,
            tooltip = getText("IGUI_BottomPanelMoreSaveTooltip"),
        },
        apply = {
            icon = CHC_window.icons.presets.apply,
            title = getText("IGUI_BottomPanelMoreApply"),
            onclick = self.presets.onMoreBtnApplyClick,
            tooltip = getText("IGUI_BottomPanelMoreApplyTooltip"),
        },
        rename = {
            icon = CHC_window.icons.presets.rename,
            title = getText("ContextMenu_RenameBag"),
            onclick = self.presets.onMoreBtnRenameClick,
            tooltip = nil
        },
        -- compare = {
        --     icon = getTexture("media/textures/bottom_panel/compare.png"),
        --     title = getText("IGUI_BottomPanelMoreCompare"),
        --     onclick = self.onMoreBtnCompareClick,
        --     tooltip = getText("IGUI_BottomPanelMoreCompareTooltip"),
        -- },
        duplicate = {
            icon = CHC_window.icons.presets.duplicate,
            title = getText("IGUI_BottomPanelMoreDuplicate"),
            onclick = self.presets.onMoreBtnDuplicateClick,
            tooltip = getText("IGUI_BottomPanelMoreDuplicateTooltip")
        },
        share = {
            icon = CHC_window.icons.presets.share,
            title = getText("IGUI_BottomPanelMoreShare"),
            onclick = self.presets.onMoreBtnShareClick,
            tooltip = getText("IGUI_BottomPanelMoreShareTooltip")
        },
        import = {
            icon = CHC_window.icons.presets.import,
            title = getText("IGUI_BottomPanelMoreImport"),
            onclick = self.presets.onMoreBtnImportClick,
            tooltip = getText("IGUI_BottomPanelMoreImportTooltip")
        },
        delete = {
            icon = CHC_window.icons.presets.delete,
            title = getText("IGUI_BottomPanelMoreDelete"),
            onclick = self.presets.onMoreBtnDeleteClick,
            tooltip = getText("IGUI_BottomPanelMoreDeleteTooltip")
        },
    }

    self.bottomPanel = CHC_presets:new(1, self.panel.y + self.panel.height, self.width / 2, 24, self,
        bottomPanelMoreBtnOptions, "presets")
    self.bottomPanel:initialise()
    self.bottomPanel:setVisible(true)
    self.bottomPanel:setAnchorLeft(true)
    self.bottomPanel:setAnchorTop(true)
    -- self.bottomPanel:setAnchorRight(true)
    -- self.bottomPanel:setAnchorBottom(true)

    --region filtersUI
    local w = 300

    ---@type CHC_filters_ui
    self.filtersUIItems = CHC_filters_ui:new(self.x - w, self.y, w, self.height, self,
        getText("UI_search_items_tab_name"))
    self.filtersUIItems:initialise()
    self.filtersUIItems:instantiate()
    self.filtersUIItems:setVisible(false)
    ---@type CHC_filters_ui
    self.filtersUIRecipes = CHC_filters_ui:new(self.x - w, self.y, w, self.height, self,
        getText("UI_search_recipes_tab_name"))
    self.filtersUIRecipes:initialise()
    self.filtersUIRecipes:instantiate()
    self.filtersUIRecipes:setVisible(false)

    self.filtersUI = self.filtersUIItems
    --endregion


    -- self:addChild(self.controlPanel)
    self:addChild(self.panel)
    self:addChild(self.bottomPanel)

    self:refresh(self.favViewName)
end

function CHC_window:addView(name, view)
    ISTabPanel.addView(self, name, view)
    local viewObj = self.viewList[#self.viewList]
    viewObj.originName = viewObj.name
end

function CHC_window:addSearchPanel()
    local options = self.options

    local itemsUIType = 'search_items'
    local recipesUIType = 'search_recipes'

    -- region search panel
    self.searchPanel = ISTabPanel:new(0, self.panelY, self.width, self.height - self.panelY)
    self.searchPanel.onActivateView = CHC_window.onActivateSubView
    self.searchPanel.target = self
    self.searchPanel:initialise()
    self.searchPanel:setTabsTransparency(0.4)
    self.searchPanel:setAnchorRight(true)
    self.searchPanel:setAnchorBottom(true)

    -- region search items screen
    local itemsData = self:getItems()
    local items_screen_init = self.common_screen_data
    local items_extra = {
        objSource = itemsData,
        itemSortAsc = options.search.items.filter_asc,
        typeFilter = options.search.items.filter_type,
        showHidden = options.show_hidden,
        ui_type = itemsUIType,
        backRef = self,
        sep_x = math.min(self.width / 2, options.search.items.sep_x)
    }
    for k, v in pairs(items_extra) do items_screen_init[k] = v end
    self.searchItemsScreen = CHC_item_view:new(items_screen_init)
    if itemsData then
        self.searchItemsScreen:initialise()
        local sivn = getText('UI_search_items_tab_name')
        self.addView(self.searchPanel, sivn, self.searchItemsScreen)
        self.uiTypeToView[items_extra.ui_type] = { view = self.searchItemsScreen, name = sivn, originName = sivn }
    end
    -- endregion

    -- region search recipes screen
    local recipesData = self:getRecipes(false)
    local recipes_screen_init = self.common_screen_data
    local recipes_extra = {
        objSource = recipesData,
        itemSortAsc = options.search.recipes.filter_asc,
        typeFilter = options.search.recipes.filter_type,
        showHidden = options.show_hidden,
        ui_type = recipesUIType,
        backRef = self,
        sep_x = math.min(self.width / 2, options.search.recipes.sep_x)
    }
    for k, v in pairs(recipes_extra) do recipes_screen_init[k] = v end
    self.searchRecipesScreen = CHC_recipe_view:new(recipes_screen_init)

    if recipesData then
        self.searchRecipesScreen:initialise()
        local srvn = getText('UI_search_recipes_tab_name')
        self.addView(self.searchPanel, srvn, self.searchRecipesScreen)
        self.uiTypeToView[recipes_extra.ui_type] = { view = self.searchRecipesScreen, name = srvn, originName = srvn }
    end
    -- endregion
    self.searchPanel.infoText = self.searchPanelInfo .. self.infotext_common_items
    self.panel:addView(self.searchViewName, self.searchPanel)

    --endregion
end

function CHC_window:addFavoriteScreen()
    local options = self.options

    -- region favorites panel
    self.favPanel = ISTabPanel:new(0, self.panelY, self.width, self.height - self.panelY)
    self.favPanel.tabPadX = self.width / 2 - self.width / 4
    self.favPanel.onActivateView = CHC_window.onActivateSubView
    self.favPanel.target = self
    self.favPanel:initialise()
    self.favPanel:setTabsTransparency(0.4)
    self.favPanel:setAnchorRight(true)
    self.favPanel:setAnchorBottom(true)

    -- region fav items screen
    local itemsData = self:getItems(true)
    local items_screen_init = self.common_screen_data
    local items_extra = {
        objSource = itemsData,
        itemSortAsc = options.favorites.items.filter_asc,
        typeFilter = options.favorites.items.filter_type,
        showHidden = options.show_hidden,
        ui_type = 'fav_items',
        backRef = self,
        sep_x = math.min(self.width / 2, options.favorites.items.sep_x)
    }
    for k, v in pairs(items_extra) do items_screen_init[k] = v end
    self.favItemsScreen = CHC_item_view:new(items_screen_init)

    if itemsData then
        self.favItemsScreen:initialise()
        local fivn = getText('UI_search_items_tab_name')
        self.addView(self.favPanel, fivn, self.favItemsScreen)
        self.uiTypeToView[items_extra.ui_type] = { view = self.favItemsScreen, name = fivn, originName = fivn }
    end
    -- endregion

    -- region fav recipes screen
    local recipesData = self:getRecipes(false)
    local recipes_screen_init = self.common_screen_data
    local recipes_extra = {
        objSource = recipesData,
        itemSortAsc = options.favorites.recipes.filter_asc,
        typeFilter = options.favorites.recipes.filter_type,
        showHidden = options.show_hidden,
        ui_type = 'fav_recipes',
        backRef = self,
        sep_x = math.min(self.width / 2, options.favorites.recipes.sep_x)
    }
    for k, v in pairs(recipes_extra) do recipes_screen_init[k] = v end
    self.favRecipesScreen = CHC_recipe_view:new(recipes_screen_init)

    if recipesData then
        self.favRecipesScreen:initialise()
        local frvn = getText('UI_search_recipes_tab_name')
        self.addView(self.favPanel, frvn, self.favRecipesScreen)
        self.uiTypeToView[recipes_extra.ui_type] = { view = self.favRecipesScreen, name = frvn, originName = frvn }
    end
    -- endregion
    --favoritesScreen
    self.favPanel.infoText = self.favPanelInfo .. self.infotext_common_items
    self.panel:addView(self.favViewName, self.favPanel)
    -- endregion
end

function CHC_window:addItemView(item, focusOnNew, focusOnTabIdx)
    local itn, ifn
    if item.displayName then
        ifn = item.fullType
    else
        ifn = item:getFullType()
    end
    itn = CHC_main.items[ifn]

    local nameForTab = itn.displayName
    -- check if there is existing tab with same name (and same item)
    local existingView = self.panel:getView(nameForTab)
    if existingView ~= nil then
        if existingView.item.fullType ~= ifn then -- same displayName, but different items
            nameForTab = nameForTab .. format(' (%s)', ifn)
        else                                      -- same displayName and same item
            self:refresh(nameForTab, nil, focusOnNew, focusOnTabIdx)
            return
        end
    end
    local options = self.options

    -- region item screens
    self.common_screen_data = {
        x = 0,
        y = self.panelY + self.panel.tabHeight,
        w = self.width - 2,
        h = self.panel.height - self.panelY - 4
    }

    --region item container
    local itemPanel = ISTabPanel:new(0, self.panelY, self.width, self.height - self.panelY)

    itemPanel:initialise()
    itemPanel:setTabsTransparency(0.4)
    itemPanel:setAnchorRight(true)
    itemPanel:setAnchorBottom(true)
    itemPanel.item = itn
    -- endregion
    local usesData = self:getRecipes(false, utils.concat(
        CHC_main.recipesByItem[itn.fullType],
        CHC_main.evoRecipesByItem[itn.fullType]
    ))

    self.panel:addView(nameForTab, itemPanel)

    --region uses screen
    local uses_screen_init = self.common_screen_data
    local uses_extra = {
        objSource = usesData,
        itemSortAsc = options.uses.filter_asc,
        typeFilter = options.uses.filter_type,
        showHidden = options.show_hidden,
        sep_x = math.min(self.width / 2, options.uses.sep_x),
        ui_type = 'item_uses',
        backRef = self,
        item = itn
    }
    for k, v in pairs(uses_extra) do uses_screen_init[k] = v end
    local usesScreen = CHC_recipe_view:new(uses_screen_init)

    if not utils.empty(usesData) then
        usesScreen:initialise()
        usesScreen.ui_type = usesScreen.ui_type .. '|' .. usesScreen.ID
        local iuvn = getText('UI_item_uses_tab_name')
        self.addView(itemPanel, iuvn, usesScreen)
        self.uiTypeToView[usesScreen.ui_type] = { view = usesScreen, name = iuvn, originName = iuvn }
    end
    --endregion

    -- region crafting screen

    local craftData = self:getRecipes(false, utils.concat(
        CHC_main.recipesForItem[itn.fullType],
        CHC_main.evoRecipesForItem[itn.fullType]
    ))

    local craft_screen_init = self.common_screen_data
    local craft_extra = {
        objSource = craftData,
        itemSortAsc = options.craft.filter_asc,
        typeFilter = options.craft.filter_type,
        showHidden = options.show_hidden,
        sep_x = math.min(self.width / 2, options.craft.sep_x),
        ui_type = 'item_craft',
        backRef = self,
        item = itn
    }
    for k, v in pairs(craft_extra) do craft_screen_init[k] = v end
    local craftScreen = CHC_recipe_view:new(craft_screen_init)

    if not utils.empty(craftData) then
        craftScreen:initialise()
        craftScreen.ui_type = craftScreen.ui_type .. '|' .. craftScreen.ID
        local icvn = getText('UI_item_craft_tab_name')
        self.addView(itemPanel, icvn, craftScreen)
        self.uiTypeToView[craftScreen.ui_type] = { view = craftScreen, name = icvn, originName = icvn }
    end
    -- endregion
    --endregion
    itemPanel.infoText = getText(self.itemPanelInfo, itn.displayName) .. self.infotext_common_recipes
    if not utils.empty(usesData) or not utils.empty(craftData) then
        self:refresh(nil, nil, focusOnNew, focusOnTabIdx)
    else
        error('Empty usesData and craftData', 'CHC_window:addItemView')
    end
    itemPanel.maxLength = self.width / #itemPanel.viewList - 2
end

function CHC_window:getItems(favOnly, max)
    favOnly = favOnly or false
    local modData = CHC_menu.playerModData
    local showHidden = CHC_settings.config.show_hidden
    local newItems = {}
    local items = CHC_main.itemsForSearch
    local to = max or #items

    for i = 1, to do
        local item = items[i]
        local isFav = modData.CHC_item_favorites[item.fullType] == true
        item.favorite = isFav
        if (not showHidden) and (item.hidden == true) then
        elseif (favOnly and isFav) or (not favOnly) then
            newItems[#newItems + 1] = item
            -- for _ = 1, 10, 1 do
            --     newItems[#newItems + 1] = item
            -- end
        end
    end
    if not showHidden and not max and not favOnly then
        print(format('Removed %d hidden items', #items - #newItems))
    end
    return newItems
end

function CHC_window:getRecipes(favOnly, recipeList)
    recipeList = recipeList or
        utils.concat(CHC_main.allRecipes, CHC_main.allEvoRecipes)
    favOnly = favOnly or false
    local modData = CHC_menu.playerModData
    local showHidden = CHC_settings.config.show_hidden
    local recipes = {}
    for i = 1, #recipeList do
        local recipe = recipeList[i]
        local isFav = modData[recipe.favStr]
        if (not showHidden) and recipe.hidden then
        elseif (favOnly and isFav) or (not favOnly) then
            recipes[#recipes + 1] = recipe
            -- for _ = 1, 10, 1 do
            --     recipes[#recipes + 1] = allrec[i]
            -- end
        end
    end

    if not showHidden and not favOnly then
        print(format('Removed %d hidden recipes in %s', #recipeList - #recipes,
            self.ui_type or "CHC_window"))
    end
    return recipes
end

function CHC_window:updateFavorites()
    local modData = CHC_menu.playerModData
    local showHidden = CHC_settings.config.show_hidden
    local allrec = CHC_main.allRecipes or {}
    local allevorec = CHC_main.allEvoRecipes or {}
    local items = CHC_main.itemsForSearch
    for i = 1, #items do
        items[i].favorite = modData.CHC_item_favorites[items[i].fullType] or false
    end
    for i = 1, #allrec do
        local recipe = allrec[i]
        if (not showHidden) and recipe.hidden then
        else
            recipe.favorite = modData[recipe.favStr] == true
        end
    end
    for i = 1, #allevorec do
        allevorec[i].favorite = modData[allevorec[i].favStr] == true
    end
end

-- endregion

-- region update

function CHC_window:update()
    if self.updateQueue.len > 0 then
        local toProcess = self.updateQueue:pop()
        if not toProcess.actions then return end
        local targetViewObjs = {}
        if toProcess.targetViews[1] == "all" then
            for _, view in pairs(self.uiTypeToView) do
                if toProcess.exclude then
                    if not toProcess.exclude[view.originName] then
                        targetViewObjs[#targetViewObjs + 1] = view
                    end
                else
                    targetViewObjs[#targetViewObjs + 1] = view
                end
            end
        elseif toProcess.targetViews[1] == "bottom_panel" then
            if not self.bottomPanel then return end
            for i = 1, #toProcess.actions do
                self.bottomPanel[toProcess.actions[i]] = true
            end
            return
        else
            for i = 1, #toProcess.targetViews do
                targetViewObjs[#targetViewObjs + 1] = self.uiTypeToView[toProcess.targetViews[i]]
            end
        end
        if utils.empty(targetViewObjs) then return end
        for j = 1, #targetViewObjs do
            local targetViewObj = targetViewObjs[j]
            if not targetViewObj then return end
            local targetView = targetViewObj.view
            local targetOriginName = targetViewObj.originName

            for i = 1, #toProcess.actions do
                local action = toProcess.actions[i]
                if action == 'needUpdateSubViewName' then
                    local data = toProcess.data[action]
                    local viewObject
                    for k = 1, #targetView.parent.viewList do
                        local _view = targetView.parent.viewList[k]
                        if _view.originName == targetOriginName then
                            viewObject = _view
                        end
                    end
                    if viewObject then
                        if data then
                            viewObject.name = format("%s (%s)", targetOriginName, data)
                        else
                            viewObject.name = targetOriginName
                        end
                        self.uiTypeToView[viewObject.view.ui_type].name = viewObject.name
                    end
                else
                    -- print("Trigger " .. action .. " for " .. targetViewObj.name)
                    targetView[action] = true
                end
            end
        end
    end

    local ms = UIManager.getMillisSinceLastRender()
    for i = 1, #self.updRates do
        local val = self.updRates[i]
        if not val.cur then val.cur = 0 end
        val.cur = val.cur + ms
        if val.cur >= val.rate then
            -- print("\n")
            -- print("Time passed: " .. val.rate)
            for _, view in pairs(self.uiTypeToView) do
                -- print("Trigger " .. val.var .. " for " .. view.name)
                view.view[val.var] = true
            end
            val.cur = 0
        end
    end
    --TODO: refactor
    local a = (CHC_settings.config.window_opacity - 1) / 10
    if self.backgroundColor.a ~= a then
        self.backgroundColor.a = a
    end
end

function CHC_window:refresh(viewName, panel, focusOnNew, focusOnTabIdx)
    panel = panel or self.panel
    if not panel then
        error('Could not find panel', 'CHC_window:refresh')
        return
    end
    if viewName and (focusOnNew == nil or focusOnNew == true) then
        panel:activateView(viewName)
        return
    end
    local vl = panel.viewList
    if not vl or not vl[2] then
        error('Could not find viewList or viewList is wrong (len:' .. tostring(#vl) .. ")", 'CHC_window:refresh')
        return
    end
    if #vl > 2 then
        -- there is item selected
        viewName = vl[#vl].name
    else
        viewName = vl[2].name -- favorites is default
    end
    if focusOnNew == false then
        return
    else
        panel:activateView(viewName)
    end
    if focusOnTabIdx then
        -- uses/craft or items/recipes
        local v = panel.activeView.view
        local vv = v.viewList[focusOnTabIdx]
        if vv then
            if vv.originName then
                vv = vv.originName
            else
                vv = vv.name
            end
            v:activateView(vv)
        end
    end
end

function CHC_window:close()
    -- remove all views except search and favorites
    local vl = self.panel
    if not vl.viewList or utils.empty(vl.viewList) then return end
    if CHC_settings.config.close_all_on_exit then
        if #vl.viewList >= 3 then
            for i = #vl.viewList, 3, -1 do
                vl:removeView(vl.viewList[i].view)
            end
        end
        if #vl.viewList >= 2 then
            vl:activateView(vl.viewList[2].name)
        end
    end
    CHC_menu.toggleUI()
    -- if JoypadState.players[CHC_menu.playerNum + 1] then
    --     if self.prevFocus then
    --         setJoypadFocus(CHC_menu.playerNum, self.prevFocus)
    --     else
    --         setJoypadFocus(CHC_menu.playerNum, nil)
    --     end
    -- end
    self:serializeWindowData()
    CHC_settings.Save()
    CHC_settings.SavePropsData()
    CHC_settings.SavePresetsData("presets")
    -- CHC_settings.SavePresetsData("filters")
end

-- endregion

-- region render


function CHC_window:onResize()
    ISCollapsableWindowJoypad.onResize(self)

    local ui = self
    if not ui.panel or not ui.panel.activeView then return end
    ui.panel:setWidth(self.width)
    ui.panel:setHeight(self.height - 52)
    ui.bottomPanel:setY(ui.panel.y + ui.panel.height)
    local asw = ui:getActiveSubView()
    if asw then
        ui.bottomPanel:setWidth(asw.view.headers.nameHeader.width - ui.bottomPanel.x)
    end

    ui.filtersUIItems:setHeight(ui.height)
    ui.filtersUIRecipes:setHeight(ui.height)


    for _, value in pairs(ui.panel.children) do
        value.maxLength = self.width / #value.viewList - 2
    end
end

function CHC_window:render()
    ISCollapsableWindowJoypad.render(self)
    if self.isCollapsed then return end
end

-- endregion

-- region logic

function CHC_window:onInfo()
    ISCollapsableWindowJoypad.onInfo(self)
    if self.infoRichText and self.infoRichText.alwaysOnTop == true then
        self.infoRichText.alwaysOnTop = false
    end
end

-- Common options for RMBDown + init context
function CHC_window:onRMBDownObjList(x, y, item, isrecipe, context)
    isrecipe = isrecipe and true or false
    context = context or ISContextMenu.get(0, getMouseX() + 10, getMouseY())
    if not item then
        local row = self:rowAt(x, y)
        if row == -1 then return end
        item = self.items[row].item
        if not item then return context end
    end
    if isrecipe then
        item = item.recipeData.result
    end

    item = CHC_main.items[item.fullType]
    if not item then return context end

    local function chccopy(_, param)
        if param then
            Clipboard.setClipboard(tostring(param))
        end
    end

    if isShiftKeyDown() then
        local name = context:addOption(getText('IGUI_chc_Copy') .. ' (' .. item.displayName .. ')', nil, nil)
        name.iconTexture = CHC_window.icons.copy
        local subMenuName = ISContextMenu:getNew(context)
        context:addSubMenu(name, subMenuName)
        local itemType
        if self.parent.isItemView then
            itemType = self.parent.typeData[item.category].tooltip
        else
            itemType = item.category
        end

        local ft = subMenuName:addOption('FullType', self, chccopy, item.fullType)
        local na = subMenuName:addOption('Name', self, chccopy, item.name)
        local ty = subMenuName:addOption('!Type', self, chccopy, '!' .. itemType)
        local ca = subMenuName:addOption('#Category', self, chccopy, '#' .. item.displayCategory)
        local mo = subMenuName:addOption('@Mod', self, chccopy, '@' .. item.modname)

        for _, opt in ipairs({ ft, na, ty, ca, mo }) do
            CHC_main.common.setTooltipToCtx(opt, opt.param1)
        end
    end

    if getDebug() then
        if item and item.fullType then
            local pInv = CHC_menu.CHC_window
            if pInv and pInv.player then
                pInv = pInv.player:getInventory()
                local name = context:addOption('Add item', nil, nil)
                local subMenuName = ISContextMenu:getNew(context)
                context:addSubMenu(name, subMenuName)

                subMenuName:addOption('1x', self.parent, function() pInv:AddItem(item.fullType) end)
                subMenuName:addOption('2x', self.parent, function() for _ = 1, 2 do pInv:AddItem(item.fullType) end end)
                subMenuName:addOption('5x', self.parent, function() for _ = 1, 5 do pInv:AddItem(item.fullType) end end)
                subMenuName:addOption('10x', self.parent, function() for _ = 1, 10 do pInv:AddItem(item.fullType) end end)
            end
        end
    end
    return context
end

function CHC_window:handleFiltersUIState(sub)
    if not self.prevSubViewType then return end
    local prevType = self.prevSubViewType
    local curType = self:getViewType(sub.view)
    if prevType == curType then return end
    local reopen = self.filtersUI:getIsVisible()
    self.filtersUI:close()
    if sub.view.isItemView then
        self.filtersUI = self.filtersUIItems
    else
        self.filtersUI = self.filtersUIRecipes
    end
    if reopen then self.filtersUI:toggleUI() end
end

--region tabs

function CHC_window:getActiveSubView(ui)
    ui = ui or self
    if not ui.panel or not ui.panel.activeView then return end
    local view = ui.panel.activeView -- search, favorites or itemname
    local subview
    if not view.view.activeView then -- no subviews
        subview = view
    else
        subview = view.view.activeView
    end
    return subview, view
end

function CHC_window:onActivateViewAdjustPositions(sub, fromsub)
    if sub.view.ui_type == 'fav_recipes' or sub.view.ui_type == 'fav_items' then
        if self.bottomPanel.categorySelector then
            self.bottomPanel.categorySelector:setVisible(true)
            self.bottomPanel.moreButton:setVisible(true)
        end
        local bottomPanelCS = self.bottomPanel.categorySelector
        bottomPanelCS:setWidth(sub.view.headers.nameHeader.width - bottomPanelCS.x)
        if sub.view.objList and #sub.view.objList.items > 0 then
            sub.view.removeAllFavBtn:setVisible(true)
            sub.view.searchRow:setWidth(sub.view.headers.nameHeader.width - 24)
        else
            sub.view.removeAllFavBtn:setVisible(false)
            sub.view.searchRow:setWidth(sub.view.headers.nameHeader.width)
        end
    else
        sub.view.removeAllFavBtn:setVisible(false)
        sub.view.searchRow:setWidth(sub.view.headers.nameHeader.width)
        if self.bottomPanel.categorySelector then
            self.bottomPanel.categorySelector:setVisible(false)
            self.bottomPanel.moreButton:setVisible(false)
        end
    end
end

function CHC_window:getViewType(view)
    return view.isItemView == true and "items" or "recipes"
end

function CHC_window:onActivateView(target)
    if not target.activeView or not target.activeView.view then return end
    local top = target.activeView -- top level tab
    local sub = top.view.activeView
    if not sub then return end
    if sub.view.isItemView == false then
        sub.view.needUpdateFavorites = true
    end

    -- update item counts for all subviews
    for i = 1, #top.view.viewList do
        local view = top.view.viewList[i]
        if view.view.objList and view.view.objList.items then
            self.updateQueue:push({
                targetViews = { view.view.ui_type },
                actions = { 'needUpdateSubViewName' },
                data = { needUpdateSubViewName = #view.view.objList.items }
            })
        end
    end

    self:onActivateViewAdjustPositions(sub)
    if sub.view.ui_type == 'fav_recipes' or sub.view.ui_type == 'fav_items' then
        self.bottomPanel.needUpdatePresets = true
        sub.view.needUpdateObjects = true
    end

    self:handleFiltersUIState(sub)
    self.prevSubViewType = self:getViewType(sub.view)
end

function CHC_window:onActivateSubView(target)
    local info
    local top = target.parent.activeView
    local sub = target.activeView
    if not top or not sub then return end
    if sub.view.isItemView == false then
        info = self.viewNameToInfoText[top.name] .. self.infotext_common_recipes
        sub.view.needUpdateFavorites = true
    else
        info = self.viewNameToInfoText[top.name] .. self.infotext_common_items
    end

    self:onActivateViewAdjustPositions(sub, true)
    if sub.view.ui_type == 'fav_recipes' or sub.view.ui_type == 'fav_items' then
        self.bottomPanel.needUpdatePresets = true
        sub.view.needUpdateObjects = true
    end
    self:setInfo(info)

    self:handleFiltersUIState(sub)
    self.prevSubViewType = self:getViewType(sub.view)
end

function CHC_window:onMainTabRightMouseDown(x, y)
    local x = self:getMouseX()
    local y = self:getMouseY()
    if y <= 0 or y > self.tabHeight then
        return
    end
    local tabIndex = self:getTabIndexAtX(x)
    if tabIndex <= 2 then return end -- dont interact with search and favorites
    local context = ISContextMenu.get(0, getMouseX() - 50, getMouseY() - 105)
    if #self.viewList > 3 then
        context:addOption(getText('IGUI_tab_ctx_close_others'), self, CHC_window.closeOtherTabs, tabIndex)
        context:addOption(getText('IGUI_CraftUI_Close') .. ' ' .. lower(getText('UI_All')),
            self, CHC_window.closeAllTabs)
    end
    context:addOption(getText('IGUI_CraftUI_Close'), self, CHC_window.closeTab, tabIndex)
    context:setY(getMouseY() - #context.options * 35)
end

-- function CHC_window:togglePinTab(tabIndex)

-- end

function CHC_window:closeOtherTabs()
    local vp = self.parent.panel
    local vl = vp.viewList
    for i = #vl, 3, -1 do
        if vp.activeView ~= vl[i] then
            vp:removeView(vl[i].view)
        end
    end
    vp.scrollX = 0
end

function CHC_window:closeAllTabs()
    local vp = self.parent.panel
    for i = #vp.viewList, 3, -1 do
        vp:removeView(vp.viewList[i].view)
    end
    vp:activateView(vp.viewList[2].name)
    vp.activeView.view:activateView(getText('UI_search_recipes_tab_name'))
    vp.scrollX = 0
end

function CHC_window:closeTab(tabIndex)
    local vl = self.viewList
    if not vl then return end
    local clicked = vl[tabIndex]
    local active = self.activeView

    self:removeView(clicked.view)
    if clicked == active then
        local actIdx = tabIndex + 1
        if actIdx > #vl then actIdx = #vl end

        if not self:getView(vl[actIdx].name) then
            actIdx = actIdx - 1
        end
        self:activateView(vl[actIdx].name)
    end
end

--endregion

-- region keyboard controls

local modifierOptionToKey = {
    [1] = 'none',
    [2] = 'control',
    [3] = 'shift',
    [4] = 'control+shift'
}

local scroll_speed_map = {
    [1] = 10,
    [2] = 50,
    [3] = 100,
    [4] = 200,
    [5] = 500
}

function CHC_window:isModifierKeyDown(_type)
    local modifier
    if _type == 'recipe' then
        modifier = modifierOptionToKey[CHC_settings.config.recipe_selector_modifier]
    elseif _type == 'category' then
        modifier = modifierOptionToKey[CHC_settings.config.category_selector_modifier]
    elseif _type == 'tab' then
        modifier = modifierOptionToKey[CHC_settings.config.tab_selector_modifier]
    elseif _type == 'closetab' then
        modifier = modifierOptionToKey[CHC_settings.config.tab_close_selector_modifier]
    else
        error('Unknown modifier type', format('CHC_window:isModifierKeyDown(%s)', _type))
    end

    if not modifier then error('No modifier found!', 'CHC_window:isModifierKeyDown') end

    if modifier == 'none' then return true end
    if modifier == 'control' then return isCtrlKeyDown() end
    if modifier == 'shift' then return isShiftKeyDown() end
    if modifier == 'control+shift' then
        return isCtrlKeyDown() and isShiftKeyDown()
    end
end

function CHC_window:handleListMove(key, rl, subview)
    if not rl then return end
    local oldsel = rl.selected
    if key == CHC_settings.keybinds.move_up.key and self:isModifierKeyDown('recipe') then
        -- if isShiftKeyDown() then
        --     rl.selected = rl.selected - 10
        -- else
        rl.selected = rl.selected - 1
        -- end
        if rl.selected <= 0 then
            rl.selected = #rl.items
        end
    elseif key == CHC_settings.keybinds.move_down.key and self:isModifierKeyDown('recipe') then
        -- if isShiftKeyDown() then
        --     rl.selected = rl.selected + 10
        -- else
        rl.selected = rl.selected + 1
        --end
        if rl.selected > #rl.items then
            rl.selected = 1
        end
    end

    local selectedItem = rl.items[rl.selected]
    if selectedItem and oldsel ~= rl.selected then
        subview.objList:ensureVisible(rl.selected)
        if subview.objPanel then
            subview.objPanel:setObj(selectedItem.item)
        end
        return
    end
end

function CHC_window:onKeyRepeat(key)
    if self.isCollapsed then return end
    if not self.keyPressedMS then return end
    if (getTimestampMs() - self.keyPressedMS >= scroll_speed_map[CHC_settings.config.scroll_speed]) then
        local subview, _ = self:getActiveSubView()
        if not subview then return end
        subview = subview.view
        local rl = subview.objList
        self:handleListMove(key, rl, subview)
        self.keyPressedMS = getTimestampMs()
    end
end

function CHC_window:onKeyPress(key)
    if self.isCollapsed then return end

    local ui = self
    local activeViewIx = ui.panel:getActiveViewIndex()
    local subview, view = self:getActiveSubView()
    if not subview or not view then
        utils.chcerror("Can't determine (sub-)view", "CHC_window:onKeyPress", nil, false)
        return
    end

    self.keyPressedMS = getTimestampMs()
    subview = subview.view
    local rl = subview.objList

    -- region close
    if key == CHC_settings.keybinds.close_window.key then
        self:close()
        return
    end

    -- active tab
    if key == CHC_settings.keybinds.close_tab.key and self:isModifierKeyDown('closetab') then
        if activeViewIx <= 2 then return end -- dont interact with search and favorites
        self.closeTab(ui.panel, activeViewIx)
        return
    end
    -- endregion

    -- region search bar focus
    if key == CHC_settings.keybinds.toggle_focus_search_bar.key then
        -- try to get search bar
        local sr = subview.searchRow
        if sr and sr.searchBar then
            sr.searchBar:focus()
        end
    end
    -- endregion

    -- region moving

    -- region tabs controls
    if key == CHC_settings.keybinds.toggle_uses_craft.key then
        local vl = view.view.viewList
        local idx
        if vl and #vl == 2 then
            idx = view.view:getActiveViewIndex() == 1 and 2 or 1
            if vl[idx] and vl[idx].name then
                self:refresh(vl[idx].name, view.view)
            end
        end
    end

    local oldvSel = activeViewIx
    local newvSel = oldvSel
    local pTabs = ui.panel.viewList
    if (key == CHC_settings.keybinds.move_tab_left.key) and self:isModifierKeyDown('tab') then
        newvSel = newvSel - 1
        if newvSel <= 0 then newvSel = #pTabs end
    elseif (key == CHC_settings.keybinds.move_tab_right.key) and self:isModifierKeyDown('tab') then
        newvSel = newvSel + 1
        if newvSel > #pTabs then newvSel = 1 end
    end
    if newvSel ~= oldvSel then
        if pTabs[newvSel] and pTabs[newvSel].name then
            self:refresh(pTabs[newvSel].name)
        end
        return
    end
    -- endregion

    -- region select recipe/category

    -- region recipes
    self:handleListMove(key, rl, subview)
    -- endregion

    -- region categories
    local cs = subview.filterRow.categorySelector
    local oldcsSel = cs.selected
    if (key == CHC_settings.keybinds.move_left.key) and self:isModifierKeyDown('category') then
        cs.selected = cs.selected - 1
        if cs.selected <= 0 then cs.selected = #cs.options end
    elseif (key == CHC_settings.keybinds.move_right.key) and self:isModifierKeyDown('category') then
        cs.selected = cs.selected + 1
        if cs.selected > #cs.options then cs.selected = 1 end
    end
    if oldcsSel ~= cs.selected then
        CHC_view.onChangeCategory(subview.filterRow, nil, cs.options[cs.selected].text)
        return
    end
    -- endregion
    -- endregion

    -- endregion

    -- region favorite
    if key == CHC_settings.keybinds.favorite_recipe.key then
        if rl.addToFavorite then
            rl:addToFavorite(nil, true)
        end
    end
    -- endregion

    -- region crafting
    if key == CHC_settings.keybinds.craft_one.key then
        if not subview.objPanel.selectedObj then return end
        subview.objPanel:craft(nil, false)
    elseif key == CHC_settings.keybinds.craft_all.key then
        if not subview.objPanel.selectedObj then return end
        subview.objPanel:craft(nil, true)
    end
    -- endregion
end

function CHC_window:isKeyConsumed(key)
    local isKeyValid = false
    for _, k in pairs(CHC_settings.keybinds) do
        k = k.key
        if key == k then
            isKeyValid = true
            break
        end
    end
    if key == CHC_settings.keybinds.toggle_window.key then isKeyValid = false end

    return isKeyValid
end

-- endregion


--region joypad
-- function CHC_window:onJoypadDown(button)
--     if button == Joypad.BButton then
--         self:close()
--     end
-- end

-- function CHC_window:onJoypadDirUp()
--     local subview = self:getActiveSubView()
--     if not subview then
--         utils.chcerror("Can't determine subview", "CHC_window:onJoypadDirUp", nil, false)
--         return
--     end
--     local rl = subview.objList
--     if rl then
--         self:handleListMove(Joypad.DPadUp, rl, subview)
--     end
-- end

-- function CHC_window:onJoypadDirDown()
--     local subview = self:getActiveSubView()
--     if not subview then
--         utils.chcerror("Can't determine subview", "CHC_window:onJoypadDirDown", nil, false)
--         return
--     end
--     local rl = subview.objList
--     if rl then
--         self:handleListMove(Joypad.DPadDown, rl, subview)
--     end
-- end

-- function CHC_window:onGainJoypadFocus(joypadData)
--     ISPanelJoypad.onGainJoypadFocus(self, joypadData)
--     local subview = self:getActiveSubView()
--     subview = subview.view

--     self.closeButton:setJoypadButton(Joypad.Texture.BButton)
--     if joypadData and subview and subview.objList then
--         joypadData.focus = subview.objList
--         updateJoypadFocus(joypadData)
--     end
--     -- self.drawJoypadFocus = true
--     -- self:loadJoypadButtons(joypadData)
-- end

--endregion

function CHC_window:serializeWindowData()
    local vl = self.panel
    if not vl or not vl.viewList or type(vl.viewList) ~= "table" then return end
    local main_window = {
        x = self:getX(),
        y = self:getY(),
        w = self:getWidth(),
        h = self:getHeight(),
        a = self.backgroundColor.a
    }
    if #vl.viewList < 1 then return end
    local sref = vl.viewList[1].view     -- search view
    if not sref then return end
    local sref_i = sref.viewList[1].view -- search-items subview
    local sref_r = sref.viewList[2].view -- search-recipes subview
    local search = {
        items = {
            sep_x = sref_i.headers.typeHeader.x,
            filter_asc = sref_i.itemSortAsc == true,
            filter_type = sref_i.typeFilter
        },
        recipes = {
            sep_x = sref_r.headers.typeHeader.x,
            filter_asc = sref_r.itemSortAsc == true,
            filter_type = sref_r.typeFilter
        }
    }
    if #vl.viewList < 2 then return end
    local fref = vl.viewList[2].view     -- favorites view
    if not fref then return end
    local fref_i = fref.viewList[1].view -- favorites-items subview
    local fref_r = fref.viewList[2].view -- favorites-recipes subview
    local favorites = {
        items = {
            sep_x = fref_i.headers.typeHeader.x,
            filter_asc = fref_i.itemSortAsc == true,
            filter_type = fref_i.typeFilter
        },
        recipes = {
            sep_x = fref_r.headers.typeHeader.x,
            filter_asc = fref_r.itemSortAsc == true,
            filter_type = fref_r.typeFilter
        }
    }
    CHC_settings.config.main_window = main_window
    CHC_settings.config.search = search
    CHC_settings.config.favorites = favorites
end

function CHC_window:onMouseWheel(del)
    -- don't zoom in game while cursor over window
    return false
end

function CHC_window:onMouseMove(dx, dy)
    ISCollapsableWindow.onMouseMove(self, dx, dy)
    if self.moving then
        self.filtersUIItems:setPosition()
        self.filtersUIRecipes:setPosition()
    end
end

--region preset buttons handlers
CHC_window.presets = {}

function CHC_window.presets.handleInvalidInput(text)
    local minlen = 1
    local maxlen = 50
    local len = text:len()
    local msg
    local invalid = true
    if len < minlen then
        msg = "Name too short!" .. format(" (%d < %d)", len, minlen)
    elseif len > maxlen then
        msg = "Name too long!" .. format(" (%d > %d)", len, maxlen)
        -- elseif not text:match("[a-zA-Z0-9_]") or text:match("%W") then
        --     msg = "Only letters and numbers are allowed!"
        -- elseif text:sub(1, 1):match("%d") then
        --     msg = "First character must be letter!"
    else
        invalid = false
    end

    return not invalid, msg
end

function CHC_window.presets:_savePreset(text)
    local ui_type = CHC_main.common.getCurrentUiType(self.window)
    local to_save = self:getPresetStorage()
    to_save[text] = self:getCurrentFavoritesFromModData(ui_type)
    CHC_presets.saveData(self)
    self.needUpdatePresets = true
end

---Overwrite existing preset
---@param text string new preset name
---@param existing string | table<integer, string> existing preset name OR list of current favorites
---@param overwrite boolean? true if `existing` is `string`
function CHC_window.presets:_overwritePreset(text, existing, overwrite)
    local to_save = self:getPresetStorage()
    local to_overwrite
    if overwrite == true then
        to_overwrite = to_save[existing]
    else
        to_overwrite = existing
    end
    to_save[text] = copyTable(to_overwrite)
    if overwrite == true then
        to_save[existing] = nil
    end
    CHC_presets.saveData(self)
    self.needUpdatePresets = true
end

function CHC_window.presets:onMoreBtnSaveClick()
    local to_save = self:getPresetStorage()
    local selectedPreset = self:getSelectedPreset()
    local currentFav = self:getCurrentFavorites()

    local function onOverwritePreset(_, button, name)
        if button.internal == "YES" then
            CHC_window.presets._savePreset(self, name)
            button.parent.parent:destroy()
        end
    end

    local function savePreset(_, button)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = text,
            }
            local validInput, msg = CHC_window.presets.handleInvalidInput(text)
            if not validInput then
                params.yesno = false
                params.text = msg
                CHC_presets.addModal(self, params)
                return
            end
            if to_save[text] then
                params.parent = button.parent
                CHC_presets.addModal(self, params)
            else
                CHC_window.presets._savePreset(self, text)
                button.parent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
        end
    end
    -- popup with input and save/cancel buttons
    -- check for overwriting
    -- on save add to CHC_settings
    -- and save to disk
    local params = { _parent = self.window }

    if not currentFav or #currentFav.items == 0 then
        params.type = ISModalDialog
        params.yesno = false
        params.text = "No favorites found"
    else
        params.type = ISTextBox
        params.text = "Enter name:"
        params.defaultEntryText = ""
        params.onclick = savePreset
        params.showError = true -- to prevent destroying on click
        params.errorMsg = ""
        if selectedPreset and selectedPreset.text ~= self.defaultPresetName then
            params.defaultEntryText = selectedPreset.text
        end
    end
    CHC_presets.addModal(self, params)
end

function CHC_window.presets:onMoreBtnApplyClick()
    -- popup "are you sure? this will overwrite existing"
    -- overwrite existing favorites with preset
    local selectedPreset = self:getSelectedPreset()
    local ui_type = CHC_main.common.getCurrentUiType(self.window)

    local function applyPreset(_, button)
        if button.internal ~= "YES" then return end

        local favorites = self:transformFavoriteObjListToModData(ui_type, true)
        local modData = CHC_menu.playerModData
        if ui_type == "items" then
            modData.CHC_item_favorites = favorites
        elseif ui_type == "recipes" then
            for key, value in pairs(modData) do
                if utils.startswith(key, "craftingFavorite:") and value == true then
                    modData[key] = nil
                end
            end
            for key, _ in pairs(favorites) do
                if utils.startswith(key, "craftingFavorite:") then
                    modData[key] = true
                end
            end
        end
        local sub = self.window:getActiveSubView()
        if not sub then return end
        sub.view.needUpdateFavorites = true
    end

    local msg = "This will overwrite existing favorites, are you sure?"
    local yesno = true
    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        yesno = false
        msg = "Please select preset!"
    end
    local params = {
        type = ISModalDialog,
        _parent = self.window,
        text = msg,
        yesno = yesno,
        onclick = applyPreset
    }
    CHC_presets.addModal(self, params)
end

function CHC_window.presets:onMoreBtnRenameClick()
    -- popup with input (prefilled?) and ok/cancel buttons
    -- on ok remove old entry and add new one to CHC_settings
    local selectedPreset = self:getSelectedPreset()
    local to_save = self:getPresetStorage()

    ---@param _ any
    ---@param button table
    ---@param existing string
    ---@param new string
    local function onOverwritePreset(_, button, existing, new)
        if button.internal == "YES" then
            CHC_window.presets._overwritePreset(self, new, existing, true)
            button.parent.parent:destroy()
        end
    end

    ---@param _ any
    ---@param button table
    ---@param existingName string
    local function renamePreset(_, button, existingName)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = existingName,
                param2 = text,
            }
            local validInput, msg = CHC_window.presets.handleInvalidInput(text)
            if not validInput then
                params.yesno = false
                params.text = msg
                CHC_presets.addModal(self, params)
                return
            end
            if existingName == text then
                button.parent.showError = false
            elseif to_save[text] then
                params.parent = button.parent
                CHC_presets.addModal(self, params)
            else
                CHC_window.presets._overwritePreset(self, text, existingName, true)
                button.parent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
        end
    end

    local params = {
        _parent = self.window,
    }

    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        params.type = ISModalDialog
        params.yesno = false
        params.text = "Please select preset!"
    else
        params.type = ISTextBox
        params.defaultEntryText = selectedPreset.text
        params.text = "Enter new name: "
        params.onclick = renamePreset
        params.param1 = selectedPreset.text
        params.showError = true -- to prevent destroying on click
        params.errorMsg = ""
    end
    CHC_presets.addModal(self, params)
end

function CHC_window.presets:onMoreBtnAppendClick()
    -- add to existing favorites
    local to_save = self:getPresetStorage()
    local selectedPreset = self:getSelectedPreset()
    local currentFav = self:getCurrentFavorites()
end

function CHC_window.presets:onMoreBtnCompareClick()
    -- window with differences between favorites
    -- aka modcomparer but simpler (no ordering)
    -- close button
    local a = CHC_main
    local selected = self:getSelectedPreset()
    if not selected then return end
    local to_load = self:getPresetStorage()
    df:df()
end

function CHC_window.presets:onMoreBtnDuplicateClick()
    local selectedPreset = self:getSelectedPreset()
    local ui_type = CHC_main.common.getCurrentUiType(self.window)
    local to_save = self:getPresetStorage()

    local function onOverwritePreset(_, button, existing, text)
        if button.internal ~= "YES" then return end
        CHC_window.presets._overwritePreset(self, text, existing, true)
        button.parent.parent:destroy()
    end

    local function duplicatePreset(_, button, existingName)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = existingName,
                param2 = text,
            }
            local validInput, msg = CHC_window.presets.handleInvalidInput(text)
            if not validInput then
                params.yesno = false
                params.text = msg
                CHC_presets.addModal(self, params)
                return
            end
            if to_save[text] then
                params.parent = button.parent
                CHC_presets.addModal(self, params)
            else
                CHC_window.presets._overwritePreset(self, text, self:transformFavoriteObjListToModData(ui_type))
                button.parent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
        end
    end

    local params = {
        _parent = self.window,
    }

    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        params.type = ISModalDialog
        params.yesno = false
        params.text = "Please select preset!"
        CHC_presets.addModal(self, params)
        return
    end
    params.type = ISTextBox
    params.defaultEntryText = selectedPreset.text .. " (Copy)"
    params.text = "Enter name: "
    params.onclick = duplicatePreset
    params.param1 = selectedPreset.text
    params.showError = true -- to prevent destroying on click
    params.errorMsg = ""
    CHC_presets.addModal(self, params)
end

function CHC_window.presets:onMoreBtnShareClick()
    local selectedPreset = self:getSelectedPreset()
    if not selectedPreset then return end
    local ui_type = CHC_main.common.getCurrentUiType(self.window)
    local entries = selectedPreset.text == self.defaultPresetName and
        self:getCurrentFavoritesFromModData(ui_type) or
        copyTable(self:getPresetStorage()[selectedPreset.text])
    local to_share = {
        entries = entries,
        type = ui_type,
    }
    local to_share_str = utils.tableutil.serialize(to_share)

    local function copy(_, button)
        if button.internal ~= "CANCEL" then return end
        if to_share_str then
            Clipboard.setClipboard(tostring(to_share_str))
        end
    end
    local params = {
        type = ISTextBox,
        _parent = self.window,
        width = 250,
        height = 350,
        text = "Share this string!",
        onclick = copy,
        defaultEntryText = to_share_str or "",
    }

    local modal = CHC_presets.addModal(self, params)
    modal.entry:setMultipleLine(true)
    modal.entry:setEditable(true)
    modal.entry:addScrollBars()
    modal.entry:setHeight(modal.height - modal.yes.height - 40)
    modal.entry:setY(25)
    modal.no:setTitle(getText("IGUI_chc_Copy"))
end

function CHC_window.presets:onMoreBtnImportClick()
    -- popup with input box where user should paste string
    -- then validate string, if ok - new popup to enter name
    -- if failed - popup "incorrect string"
    -- if only some failed (i.e some mods missing - show how many will be loaded (e.g. 10/12))
    local to_save = self:getPresetStorage()

    local function onOverwritePreset(_, button, name)
        if button.internal ~= "YES" then return end
        CHC_window.presets._savePreset(self, name)
        button.parent.parent:destroy()
    end

    local function savePreset(_, button)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = text,
            }
            local validInput, msg = CHC_window.presets.handleInvalidInput(text)
            if not validInput then
                params.yesno = false
                params.text = msg
                CHC_presets.addModal(self, params)
                return
            end
            if to_save[text] then
                params.parent = button.parent
                CHC_presets.addModal(self, params)
            else
                CHC_window.presets._savePreset(self, text)
                button.parent.showError = false
                button.parent.outerParent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
            button.parent.outerParent.showError = false
        end
    end

    local function validate(text)
        local result = { errors = {}, preset = {} }
        local fn, _err = loadstring("return " .. tostring(text))
        if not fn then
            result.errors[#result.errors + 1] = format("Format invalid, could not load (%s)", _err)
            return result
        end
        local status, preset = pcall(fn)
        if not status or not preset then
            result.errors[#result.errors + 1] = "Format invalid, could not load"
            preset = {}
        end
        -- validate preset values
        local _type = preset.type or ""
        _type = _type:trim()
        if _type ~= "items" and _type ~= "recipes" then
            result.errors[#result.errors + 1] = "Preset type missing or invalid"
            preset.type = "items"
        end

        if not preset.entries or #preset.entries == 0 then
            result.errors[#result.errors + 1] = "Preset entries missing or empty"
            preset.entries = {}
        end
        local valid = {}
        for i = 1, #preset.entries do
            local objStr = tostring(preset.entries[i]):trim()
            local _, _valid, err = CHC_presets.validatePreset(self, i, objStr, preset.type)
            valid[#valid + 1] = _valid
            result.errors = utils.concat(result.errors, err)
        end
        preset.entries = valid
        result.preset = preset
        return result
    end

    local function onclick(_, button)
        if button.internal ~= "OK" then
            button.parent.showError = false
            return
        end
        -- validate and show errors, if any
        -- if no errors - show popup to enter preset name
        local text = button.parent.entry:getText():trim()
        local validation_data = validate(text)
        local params = {
            _parent = self.window,
            outerParent = button.parent.outerParent
        }

        if not utils.empty(validation_data.errors) then
            params.type = ISTextBox
            params.defaultEntryText = concat(validation_data.errors, "\n")
            params.text = "Validation errors"
            params.width = 250
            params.height = 350

            local modal = CHC_presets.addModal(self, params)
            modal.no:setVisible(false)
            modal.yes:setTitle("OK")
            modal.yes:setX(modal.width / 2 - modal.yes.width / 2)
            modal.entry:setMultipleLine(true)
            modal.entry:setEditable(true)
            modal.entry:addScrollBars()
            modal.entry:setHeight(modal.height - modal.yes.height - 40)
            modal.entry:setY(25)
        else
            params.type = ISTextBox
            params.text = "Entry name:"
            params.defaultEntryText = ""
            params.onclick = savePreset
            params.showError = true
            params.errorMsg = ""
            CHC_presets.addModal(self, params)
        end
    end

    local params = {
        type = ISTextBox,
        _parent = self.window,
        width = 250,
        height = 350,
        onclick = onclick,
        text = "Paste preset here!",
        defaultEntryText = "",
        showError = true, -- to prevent destroying on click
        errorMsg = ""
    }

    local modal = CHC_presets.addModal(self, params)
    modal.entry:setMultipleLine(true)
    modal.entry:setEditable(true)
    modal.entry:addScrollBars()
    modal.entry:setHeight(modal.height - modal.yes.height - 40)
    modal.entry:setY(25)
    modal.outerParent = modal
end

function CHC_window.presets:onMoreBtnDeleteClick()
    -- popup "are you sure?" and ok/cancel
    -- on ok delete entry from CHC_settings and save
    -- if preset not selected - popup (ok) with msg to select preset
    local selectedPreset = self:getSelectedPreset()
    if not selectedPreset then return end

    local function deletePreset(_, button)
        if button.internal ~= "YES" then return end
        self:getPresetStorage()[selectedPreset.text] = nil
        CHC_presets.saveData(self)
        self.needUpdatePresets = true
    end

    local msg = "This will delete selected preset, are you sure?"
    local yesno = true
    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        yesno = false
        msg = "Please select preset!"
    end
    local params = {
        type = ISModalDialog,
        _parent = self.window,
        text = msg,
        yesno = yesno,
        onclick = deletePreset
    }
    CHC_presets.addModal(self, params)
end

--endregion
--endregion

--endregion

function CHC_window:new(args)
    local o = {};
    local x = args.x;
    local y = args.y;
    local width = args.width;
    local height = args.height;

    o = ISCollapsableWindowJoypad:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    for k, v in pairs(args) do
        o[k] = v
    end

    o.title = getText('IGUI_chc_context_onclick')
    --o:noBackground();
    o.th = o:titleBarHeight()
    o.rh = o:resizeWidgetHeight()
    local fontHgtSmall = getTextManager():getFontHeight(UIFont.Small);
    o.headerHgt = fontHgtSmall + 1
    o.player = CHC_menu.player
    o.modData = CHC_menu.playerModData

    o.searchViewName = getText('UI_search_tab_name')
    o.favViewName = getText('IGUI_CraftCategory_Favorite')

    o.options = CHC_settings.config
    o.needUpdateFavorites = false
    o.needUpdateObjects = false
    o.updateQueue = utils.Deque:new()
    o.uiTypeToView = {}

    o.infotext_recipe_type_filter = getText('UI_infotext_recipe_types',
        getText('UI_All'),
        getText('UI_settings_av_valid'),
        getText('UI_settings_av_known'),
        getText('UI_settings_av_invalid')
    )
    o.searchPanelInfo = getText('UI_infotext_search')
    o.favPanelInfo = getText('UI_infotext_favorites')
    o.itemPanelInfo = getText('UI_infotext_itemtab',
        '%1', -- item displayName
        getText('UI_item_uses_tab_name'),
        getText('UI_item_craft_tab_name')
    )

    o.viewNameToInfoText = {
        [o.searchViewName] = o.searchPanelInfo,
        [o.favViewName] = o.favPanelInfo
    }

    o.infotext_common_recipes = getText('UI_infotext_common',
        o.infotext_recipe_type_filter,
        getText('UI_infotext_recipe_details'),
        getText('UI_infotext_recipe_mouse')
    )
    o.infotext_common_items = getText('UI_infotext_common',
        getText('UI_infotext_item_types'),
        getText('UI_infotext_item_details'),
        getText('UI_infotext_item_mouse')
    )
    o:setWantKeyEvents(true)

    o.updRates = {
        { var = "needUpdateScroll",   rate = 50 }, -- TODO move to settings?
        { var = "needUpdateMousePos", rate = 100 }
    }

    return o
end
