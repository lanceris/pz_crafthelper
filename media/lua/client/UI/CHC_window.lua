-- Main window, opened when RMB -> Craft Helper 41 on item
require 'CHC_config'
require 'UI/CHC_recipe_view'
require 'UI/CHC_item_view'
require 'UI/components/CHC_bottom_panel'

CHC_window = ISCollapsableWindowJoypad:derive('CHC_window')
local utils = require('CHC_utils')
local error = utils.chcerror
local print = utils.chcprint
local pairs = pairs
local format = string.format
local lower = string.lower

-- region create

function CHC_window:initialise()
    ISCollapsableWindowJoypad.initialise(self)
    self:create()
    self.infoButton:setOnClick(CHC_window.onInfo, self)
end

function CHC_window:create()
    ISCollapsableWindowJoypad.createChildren(self)

    self.tbh = self:titleBarHeight()
    -- region main container (search, favorites and all selected items)
    self.panel = ISTabPanel:new(0, self.tbh, self.width, self.height - 52)

    self.panel:initialise()
    self.panel:setTabsTransparency(0.4)
    self.panel:setAnchorRight(true)
    self.panel.onRightMouseDown = self.onMainTabRightMouseDown
    self.panel.onActivateView = CHC_window.onActivateView
    self.panel.target = self
    self.panel:setEqualTabWidth(false)
    -- endregion
    self.panelY = self.tbh + self.panel.tabHeight
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

    self.bottomPanel = CHC_bottom_panel:new(1, self.panel.y + self.panel.height, self.width / 2, 24, self)
    self.bottomPanel:initialise()
    self.bottomPanel:setVisible(true)
    self.bottomPanel:setAnchorLeft(true)
    self.bottomPanel:setAnchorTop(true)
    -- self.bottomPanel:setAnchorRight(true)
    -- self.bottomPanel:setAnchorBottom(true)


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
    local usesData = {}
    local usesRec = CHC_main.recipesByItem[itn.fullType]
    local usesEvoRec = CHC_main.evoRecipesByItem[itn.fullType]
    if usesRec then
        for i = 1, #usesRec do usesData[#usesData + 1] = usesRec[i] end
    end
    if usesEvoRec then
        for i = 1, #usesEvoRec do usesData[#usesData + 1] = usesEvoRec[i] end
    end
    local craftData = {}
    local craftRec = CHC_main.recipesForItem[itn.fullType]
    local craftEvoRec = CHC_main.evoRecipesForItem[itn.fullType]
    if craftRec then
        for i = 1, #craftRec do craftData[#craftData + 1] = craftRec[i] end
    end
    if craftEvoRec then
        for i = 1, #craftEvoRec do craftData[#craftData + 1] = craftEvoRec[i] end
    end
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

function CHC_window:getRecipes(favOnly)
    favOnly = favOnly or false
    local modData = CHC_menu.playerModData
    local showHidden = CHC_settings.config.show_hidden
    local recipes = {}
    local allrec = CHC_main.allRecipes or {}
    local allevorec = CHC_main.allEvoRecipes or {}
    for i = 1, #allrec do
        local isFav = modData[allrec[i].favStr]
        if (not showHidden) and allrec[i].hidden then
        elseif (favOnly and isFav) or (not favOnly) then
            recipes[#recipes + 1] = allrec[i]
            -- for _ = 1, 10, 1 do
            --     recipes[#recipes + 1] = allrec[i]
            -- end
        end
    end
    for i = 1, #allevorec do
        if (favOnly and modData[allevorec[i].favStr]) or (not favOnly) then
            recipes[#recipes + 1] = allevorec[i]
            -- for _ = 1, 10, 1 do
            --     recipes[#recipes + 1] = allevorec[i]
            -- end
        end
    end

    if not showHidden and not favOnly then
        print(format('Removed %d hidden recipes in %s', #allrec + #allevorec - #recipes,
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
    CHC_settings.SavePresetsData()
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
        name.iconTexture = getTexture('media/textures/CHC_copy_icon.png')
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

    if sub.view.ui_type == 'fav_recipes' or sub.view.ui_type == 'fav_items' then
        if self.bottomPanel.categorySelector then
            self.bottomPanel.categorySelector:setVisible(true)
            self.bottomPanel.moreButton:setVisible(true)
        end
        self.bottomPanel.needUpdatePresets = true
        sub.view.needUpdateObjects = true
        local bottomPanelCS = self.bottomPanel.categorySelector
        bottomPanelCS:setWidth(sub.view.headers.nameHeader.width - bottomPanelCS.x)
    else
        if self.bottomPanel.categorySelector then
            self.bottomPanel.categorySelector:setVisible(false)
            self.bottomPanel.moreButton:setVisible(false)
        end
    end
    if sub.view.filterRow then
        local oldval = sub.view.filterRow.categorySelector.editable
        local newval = CHC_settings.config.editable_category_selector
        if oldval ~= newval then
            sub.view.filterRow.categorySelector:setEditable(newval)
        end
    end
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

    if sub.view.ui_type == 'fav_recipes' or sub.view.ui_type == 'fav_items' then
        sub.view.needUpdateObjects = true
        self.bottomPanel.needUpdatePresets = true
        local bottomPanelCS = self.bottomPanel.categorySelector
        bottomPanelCS:setWidth(sub.view.headers.nameHeader.width - bottomPanelCS.x)
    end
    self:setInfo(info)
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
