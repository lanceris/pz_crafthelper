-- Main window, opened when RMB -> Craft Helper 41 on item
require 'ISUI/ISCollapsableWindow'
require 'ISUI/ISTabPanel'
require 'CHC_config'
require 'UI/CHC_uses'
require 'UI/CHC_search'

CHC_window = ISCollapsableWindow:derive("CHC_window")
local utils = require('CHC_utils')
local print = utils.chcprint

-- region create

function CHC_window:initialise()
    ISCollapsableWindow.initialise(self)
    self:create()
end

function CHC_window:create()
    ISCollapsableWindow.createChildren(self)

    self.tbh = self:titleBarHeight()
    -- region main container (search, favorites and all selected items)
    self.panel = ISTabPanel:new(1, self.tbh, self.width, self.height - 60)

    self.panel:initialise()
    self.panel:setAnchorRight(true)
    self.panel.onRightMouseDown = self.onMainTabRightMouseDown
    self.panel.onActivateView = CHC_window.onActivateView
    self.panel.target = self
    self.panel:setEqualTabWidth(false)
    -- endregion
    self.panelY = self.tbh + self.panel.tabHeight
    self.common_screen_data = { x = 0, y = self.panelY + self.panel.tabHeight, w = self.width, h = self.panel.height - self.panelY - 4 }

    self:addSearchPanel()
    self:addFavoriteScreen()

    -- add tab for each selected item
    if self.items then
        for i = 1, #self.items do
            local item = self.items[i]
            if not instanceof(item, "InventoryItem") then
                item = item.items[1]
            end
            self:addItemView(item)
        end
    end

    self:addChild(self.panel)

    self:refresh()
end

function CHC_window:addSearchPanel()
    local options = self.options

    local itemsUIType = "search_items"
    local recipesUIType = "search_recipes"

    -- region search panel
    self.searchPanel = ISTabPanel:new(1, self.panelY, self.width, self.height - self.panelY)
    self.searchPanel.tabPadX = self.width / 2 - self.width / 4
    self.searchPanel.onActivateView = CHC_window.onActivateSubView
    self.searchPanel.target = self
    self.searchPanel:initialise()
    self.searchPanel:setAnchorRight(true)
    self.searchPanel:setAnchorBottom(true)

    -- region search items screen
    local itemsData = self:getItems(CHC_main.itemsForSearch)
    local items_screen_init = self.common_screen_data
    local items_extra = {
        recipeSource = itemsData,
        itemSortAsc = options.search.items.filter_asc,
        typeFilter = options.search.items.filter_type,
        showHidden = options.show_hidden,
        ui_type = itemsUIType,
        backRef = self,
        sep_x = math.min(self.width / 2, options.search.items.sep_x)
    }
    for k, v in pairs(items_extra) do items_screen_init[k] = v end
    self.searchItemsScreen = CHC_search:new(items_screen_init)
    if itemsData then
        self.searchItemsScreen:initialise()
        local sivn = getText("UI_search_items_tab_name")
        self.searchPanel:addView(sivn, self.searchItemsScreen)
        self.uiTypeToView[items_extra.ui_type] = { view = self.searchItemsScreen, name = sivn }
    end
    -- endregion

    -- region search recipes screen
    local recipesData = self:getRecipes(false)
    local recipes_screen_init = self.common_screen_data
    local recipes_extra = {
        recipeSource = recipesData,
        itemSortAsc = options.search.recipes.filter_asc,
        typeFilter = options.search.recipes.filter_type,
        showHidden = options.show_hidden,
        ui_type = recipesUIType,
        backRef = self,
        sep_x = math.min(self.width / 2, options.search.recipes.sep_x)
    }
    for k, v in pairs(recipes_extra) do recipes_screen_init[k] = v end
    self.searchRecipesScreen = CHC_uses:new(recipes_screen_init)

    if recipesData then
        self.searchRecipesScreen:initialise()
        local srvn = getText("UI_search_recipes_tab_name")
        self.searchPanel:addView(srvn, self.searchRecipesScreen)
        self.uiTypeToView[recipes_extra.ui_type] = { view = self.searchRecipesScreen, name = srvn }
    end
    -- endregion
    self.searchPanel.infoText = self.searchPanelInfo .. self.infotext_common_items
    self.panel:addView(self.searchViewName, self.searchPanel)

    --endregion

end

function CHC_window:addFavoriteScreen()
    local options = self.options

    -- region favorites panel
    self.favPanel = ISTabPanel:new(1, self.panelY, self.width, self.height - self.panelY)
    self.favPanel.tabPadX = self.width / 2 - self.width / 4
    self.favPanel.onActivateView = CHC_window.onActivateSubView
    self.favPanel.target = self
    self.favPanel:initialise()
    self.favPanel:setAnchorRight(true)
    self.favPanel:setAnchorBottom(true)

    -- region fav items screen
    local itemsData = self:getItems(CHC_main.itemsForSearch, nil, true)
    local items_screen_init = self.common_screen_data
    local items_extra = {
        recipeSource = itemsData,
        itemSortAsc = options.favorites.items.filter_asc,
        typeFilter = options.favorites.items.filter_type,
        showHidden = options.show_hidden,
        ui_type = "fav_items",
        backRef = self,
        sep_x = math.min(self.width / 2, options.favorites.items.sep_x)
    }
    for k, v in pairs(items_extra) do items_screen_init[k] = v end
    self.favItemsScreen = CHC_search:new(items_screen_init)

    if itemsData then
        self.favItemsScreen:initialise()
        local fivn = getText("UI_search_items_tab_name")
        self.favPanel:addView(fivn, self.favItemsScreen)
        self.uiTypeToView[items_extra.ui_type] = { view = self.favItemsScreen, name = fivn }
    end
    -- endregion

    -- region search recipes screen
    local recipesData = self:getRecipes(false)
    local recipes_screen_init = self.common_screen_data
    local recipes_extra = {
        recipeSource = recipesData,
        itemSortAsc = options.favorites.recipes.filter_asc,
        typeFilter = options.favorites.recipes.filter_type,
        showHidden = options.show_hidden,
        ui_type = "fav_recipes",
        backRef = self,
        sep_x = math.min(self.width / 2, options.favorites.recipes.sep_x)
    }
    for k, v in pairs(recipes_extra) do recipes_screen_init[k] = v end
    self.favRecipesScreen = CHC_uses:new(recipes_screen_init)

    if recipesData then
        self.favRecipesScreen:initialise()
        local frvn = getText("UI_search_recipes_tab_name")
        self.favPanel:addView(frvn, self.favRecipesScreen)
        self.uiTypeToView[recipes_extra.ui_type] = { view = self.favRecipesScreen, name = frvn }
    end
    -- endregion
    --favoritesScreen
    self.favPanel.infoText = self.favPanelInfo .. self.infotext_common_items
    self.panel:addView(self.favViewName, self.favPanel)
    -- endregion

end

function CHC_window:addItemView(item, focusOnNew, focusOnTabIdx)
    local ifn = item:getFullType()
    local itn = CHC_main.items[ifn]
    local nameForTab = itn.displayName
    -- check if there is existing tab with same name (and same item)
    local existingView = self.panel:getView(nameForTab)
    if existingView ~= nil then

        if existingView.item.fullType ~= ifn then -- same displayName, but different items
            nameForTab = nameForTab .. string.format(" (%s)", ifn)
        else -- same displayName and same item
            self:refresh(nameForTab, nil, focusOnNew, focusOnTabIdx)
            return
        end
    end
    local options = self.options

    -- region item screens
    self.common_screen_data = { x = 0, y = self.panelY + self.panel.tabHeight, w = self.width - 2, h = self.panel.height - self.panelY - 4 }

    --region item container
    self.itemPanel = ISTabPanel:new(1, self.panelY, self.width, self.height - self.panelY)
    self.itemPanel.tabPadX = self.width / 4
    self.itemPanel:initialise()
    self.itemPanel:setAnchorRight(true)
    self.itemPanel:setAnchorBottom(true)
    self.itemPanel.item = itn
    -- endregion
    local usesData = CHC_main.recipesByItem[itn.fullType]
    local craftData = CHC_main.recipesForItem[itn.fullType]
    self.panel:addView(nameForTab, self.itemPanel)

    --region uses screen
    local uses_screen_init = self.common_screen_data
    local uses_extra = {
        recipeSource = usesData,
        itemSortAsc = options.uses.filter_asc,
        typeFilter = options.uses.filter_type,
        showHidden = options.show_hidden,
        sep_x = math.min(self.width / 2, options.uses.sep_x),
        ui_type = "item_uses",
        backRef = self,
        item = itn
    }
    for k, v in pairs(uses_extra) do uses_screen_init[k] = v end
    self.usesScreen = CHC_uses:new(uses_screen_init)

    if usesData then
        self.usesScreen:initialise()
        local iuvn = getText("UI_item_uses_tab_name")
        self.itemPanel:addView(iuvn, self.usesScreen)
        if not self.uiTypeToView[uses_extra.ui_type] then
            self.uiTypeToView[uses_extra.ui_type] = { { view = self.usesScreen, name = iuvn } }
        else
            table.insert(self.uiTypeToView[uses_extra.ui_type], { view = self.usesScreen, name = iuvn })
        end
    end
    --endregion

    -- region crafting screen

    local craft_screen_init = self.common_screen_data
    local craft_extra = {
        recipeSource = craftData,
        itemSortAsc = options.craft.filter_asc,
        typeFilter = options.craft.filter_type,
        showHidden = options.show_hidden,
        sep_x = math.min(self.width / 2, options.craft.sep_x),
        ui_type = "item_craft",
        backRef = self,
        item = itn
    }
    for k, v in pairs(craft_extra) do craft_screen_init[k] = v end
    self.craftScreen = CHC_uses:new(craft_screen_init)

    if craftData then
        self.craftScreen:initialise()
        local icvn = getText("UI_item_craft_tab_name")
        self.itemPanel:addView(icvn, self.craftScreen)
        if not self.uiTypeToView[craft_extra.ui_type] then
            self.uiTypeToView[craft_extra.ui_type] = { { view = self.craftScreen, name = icvn } }
        else
            table.insert(self.uiTypeToView[craft_extra.ui_type], { view = self.craftScreen, name = icvn })
        end
    end
    -- endregion
    --endregion
    self.itemPanel.infoText = getText(self.itemPanelInfo, itn.displayName) .. self.infotext_common_recipes
    self:refresh(nil, nil, focusOnNew, focusOnTabIdx)
end

function CHC_window:getItems(items, max, favOnly)
    local insert = table.insert
    local showHidden = CHC_settings.config.show_hidden
    local newItems = {}
    local to = max or #items

    for i = 1, to do
        local isFav = self.modData[CHC_main.getFavItemModDataStr(items[i])] == true
        if (not showHidden) and (items[i].hidden == true) then
        elseif (favOnly and isFav) or (not favOnly) then
            insert(newItems, items[i])
        end
    end
    if not showHidden and not max and not favOnly then
        print(string.format('Removed %d hidden items', #items - #newItems))
    end
    return newItems
end

function CHC_window:getRecipes(favOnly)
    favOnly = favOnly or false
    local recipes = {}
    local allrec = CHC_main.allRecipes
    local insert = table.insert
    for i = 1, #allrec do
        if (favOnly and allrec[i].favorite) or (not favOnly) then
            insert(recipes, allrec[i])
        end
    end
    return recipes
end

-- endregion

-- region update

function CHC_window:update()
    if self.updateQueue and self.updateQueue.len > 0 then
        local toProcess = self.updateQueue:pop()
        local targetView = self.uiTypeToView[toProcess.targetView].view
        if not targetView or not toProcess.actions then return end
        for i = 1, #toProcess.actions do
            targetView[toProcess.actions[i]] = true
        end
    end
end

function CHC_window:refresh(viewName, panel, focusOnNew, focusOnTabIdx)
    local panel = panel or self.panel
    if viewName and (focusOnNew == nil or focusOnNew == true) then
        panel:activateView(viewName)
        return
    end
    local vl = panel.viewList
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
        if v.viewList[focusOnTabIdx] then
            v:activateView(v.viewList[focusOnTabIdx].name)
        end
    end
end

function CHC_window:close()
    -- remove all views except search and favorites
    if CHC_settings.config.close_all_on_exit then
        local vl = self.panel
        for i = #vl.viewList, 3, -1 do
            vl:removeView(vl.viewList[i].view)
        end
        vl:activateView(vl.viewList[2].name)
    end
    CHC_menu.toggleUI()
    self:serializeWindowData()
    CHC_settings.Save()

end

-- endregion

-- region render

function CHC_window:resizeHeaders(headers)
    if headers.nameHeader:getWidth() == headers.nameHeader.minimumWidth then
        headers.nameHeader:setWidth(headers.nameHeader.minimumWidth)
        headers.typeHeader:setX(headers.nameHeader.width)
        headers.typeHeader:setWidth(self.width - headers.nameHeader.width)
        return
    end

    headers.typeHeader:setX(headers.proportion * self.width)
    headers.nameHeader:setWidth(headers.proportion * self.width)
    headers.typeHeader:setWidth((1 - headers.proportion) * self.width)
    headers:setWidth(self.width - 1)
end

function CHC_window:onResize()
    ISPanel.onResize(self)

    local ui = self
    if not ui.panel or not ui.panel.activeView then return end
    ui.panel:setWidth(self.width)
    ui.panel:setHeight(self.height - 60)

    for i = 1, #ui.panel.viewList do
        local view = ui.panel.viewList[i].view
        view:setWidth(self.width)
        view:setHeight(self.height - ui.panel.tabHeight - 60)
        local headers = view.headers
        if headers then
            self:resizeHeaders(headers)
            view:onResizeHeaders()
        end
        if view.viewList then -- handle subviews
            for j = 1, #view.viewList do
                local subview = view.viewList[j].view
                subview:setWidth(self.width)
                subview:setHeight(self.height - 2 * view.tabHeight - 60)
                local headers = subview.headers
                if headers then
                    self:resizeHeaders(headers)
                    subview:onResizeHeaders()
                end
            end
        end
    end
end

function CHC_window:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed then return end
end

-- endregion

-- region logic

--region tabs

function CHC_window:getActiveSubView()
    if not self.panel or not self.panel.activeView then return end
    local view = self.panel.activeView.view -- search, favorites or itemname
    local subview
    if not view.activeView then -- no subviews
        subview = view
    else
        subview = view.activeView.view
    end
    return subview
end

function CHC_window:onActivateView(target)
    if not target.activeView or not target.activeView.view then return end
    local top = target.activeView -- top level tab
    local sub = top.view.activeView
    if sub.view.isItemView == false then
        sub.view.needUpdateFavorites = true
    end

    if sub.view.ui_type == 'fav_recipes' or sub.view.ui_type == 'fav_items' then
        sub.view.needUpdateObjects = true
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

    if sub.view.ui_type == 'fav_recipes' then
        sub.view.needUpdateObjects = true
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
    -- context:addOption("Pin", self, CHC_window.togglePinTab, tabIndex)
    if #self.viewList > 3 then
        context:addOption(getText("IGUI_tab_ctx_close_others"), self, CHC_window.closeOtherTabs, tabIndex)
        context:addOption(getText("IGUI_CraftUI_Close") .. " " .. string.lower(getText("UI_All")), self, CHC_window.closeAllTabs)
    end
    context:addOption(getText("IGUI_CraftUI_Close"), self, CHC_window.closeTab, tabIndex)
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
    local vl = self.parent.panel
    for i = #vl.viewList, 3, -1 do
        vl:removeView(vl.viewList[i].view)
    end
    vl:activateView(vl.viewList[2].name)
    vl.activeView.view:activateView(getText("UI_search_recipes_tab_name"))
    vl.scrollX = 0
end

function CHC_window:closeTab(tabIndex)
    local vl = self.viewList
    local clicked = vl[tabIndex]
    local active = self.activeView

    self:removeView(clicked.view)
    if clicked == active then
        local actIdx = math.min(#vl, tabIndex + 1)
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

function CHC_window:isModifierKeyDown(_type)
    local modifier
    if _type == "recipe" then
        modifier = modifierOptionToKey[CHC_settings.config.recipe_selector_modifier]
    elseif _type == "category" then
        modifier = modifierOptionToKey[CHC_settings.config.category_selector_modifier]
    elseif _type == "tab" then
        modifier = modifierOptionToKey[CHC_settings.config.tab_selector_modifier]
    else
        error("unknown modifier type")
    end

    if not modifier then error("no modifier found!") end

    if modifier == 'none' then return true end
    if modifier == "control" then return isCtrlKeyDown() end
    if modifier == "shift" then return isShiftKeyDown() end
    if modifier == "control+shift" then
        return isCtrlKeyDown() and isShiftKeyDown()
    end
end

function CHC_window:onKeyRelease(key)
    if self.isCollapsed then return end

    local ui = self
    if not ui.panel or not ui.panel.activeView then return end
    local view = ui.panel.activeView.view -- search, favorites or itemname
    local subview
    if not view.activeView then -- no subviews
        subview = view
    else
        subview = view.activeView.view
    end
    local rl = subview.objList

    -- region close
    if key == CHC_settings.keybinds.close_window.key then
        self:close()
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
        local vl = view.viewList
        local idx
        if vl and #vl == 2 then
            idx = view:getActiveViewIndex() == 1 and 2 or 1
            self:refresh(vl[idx].name, view)
        end
    end

    local oldvSel = ui.panel:getActiveViewIndex()
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
        self:refresh(pTabs[newvSel].name)
        return
    end
    -- endregion

    -- region select recipe/category

    -- region recipes
    local oldsel = rl.selected
    if (key == CHC_settings.keybinds.move_up.key) and self:isModifierKeyDown('recipe') then
        -- if isShiftKeyDown() then
        --     rl.selected = rl.selected - 10
        -- else
        rl.selected = rl.selected - 1
        -- end
        if rl.selected <= 0 then
            rl.selected = #rl.items
        end
    elseif (key == CHC_settings.keybinds.move_down.key) and self:isModifierKeyDown('recipe') then
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
        subview.onChangeCategory(subview.filterRow, nil, cs.options[cs.selected].text)
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
        if not subview.objPanel.newItem then return end
        subview.objPanel:craft(nil, false)
    elseif key == CHC_settings.keybinds.craft_all.key then
        if not subview.objPanel.newItem then return end
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


function CHC_window:serializeWindowData()
    local vl = self.panel
    CHC_settings.config.main_window = {
        x = self:getX(), y = self:getY(),
        w = self:getWidth(), h = self:getHeight()
    }
    local sref = vl.viewList[1].view -- search view
    local sref_i = sref.viewList[1].view -- search-items subview
    local sref_r = sref.viewList[2].view -- search-recipes subview
    CHC_settings.config.search = {
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
    local fref = vl.viewList[2].view -- favorites view
    local fref_i = fref.viewList[1].view -- favorites-items subview
    local fref_r = fref.viewList[2].view -- favorites-recipes subview
    CHC_settings.config.favorites = {
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
end

--endregion

function CHC_window:new(args)
    local o = {};
    local x = args.x;
    local y = args.y;
    local width = args.width;
    local height = args.height;

    o = ISCollapsableWindow:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    for k, v in pairs(args) do
        o[k] = v
    end

    o.title = getText("IGUI_chc_context_onclick")
    --o:noBackground();
    o.th = o:titleBarHeight()
    o.rh = o:resizeWidgetHeight()
    local fontHgtSmall = getTextManager():getFontHeight(UIFont.Small);
    o.headerHgt = fontHgtSmall + 1
    o.player = args.player or nil
    o.modData = CHC_main.playerModData

    o.searchViewName = getText("UI_search_tab_name")
    o.favViewName = getText("IGUI_CraftCategory_Favorite")

    o.options = CHC_settings.config
    o.needUpdateFavorites = false
    o.needUpdateCounts = false
    o.needUpdateObjects = false
    o.updateQueue = utils.Deque:new()
    o.uiTypeToView = {}

    o.infotext_recipe_type_filter = getText("UI_infotext_recipe_types",
        getText("UI_All"),
        getText("UI_settings_av_valid"),
        getText("UI_settings_av_known"),
        getText("UI_settings_av_invalid")
    )
    o.searchPanelInfo = getText("UI_infotext_search")
    o.favPanelInfo = getText("UI_infotext_favorites")
    o.itemPanelInfo = getText("UI_infotext_itemtab",
        "%1", -- item displayName
        getText("UI_item_uses_tab_name"),
        getText("UI_item_craft_tab_name")
    )

    o.viewNameToInfoText = {
        [o.searchViewName] = o.searchPanelInfo,
        [o.favViewName] = o.favPanelInfo
    }

    o.infotext_common_recipes = getText("UI_infotext_common",
        o.infotext_recipe_type_filter,
        getText("UI_infotext_recipe_details"),
        getText("UI_infotext_recipe_mouse")
    )
    o.infotext_common_items = getText("UI_infotext_common",
        getText("UI_infotext_item_types"),
        getText("UI_infotext_item_details"),
        getText("UI_infotext_item_mouse")
    )
    o:setWantKeyEvents(true)

    return o;
end
