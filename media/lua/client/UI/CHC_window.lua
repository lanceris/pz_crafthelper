-- Main window, opened when RMB -> Craft Helper 41 on item
require 'ISUI/ISCollapsableWindow'
require 'ISUI/ISTabPanel'
require 'CHC_config'
require 'UI/CHC_uses'
require 'UI/CHC_search'
-- require 'UI/craftHelperUpdSearchScreen';

CHC_window = ISCollapsableWindow:derive("CHC_window")

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
    -- self.panel:setEqualTabWidth(true)
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

    -- region search panel
    if CHC_menu.cachedItemsView then
        self.searchPanel = CHC_menu.cachedItemsView
    else
        self.searchPanel = ISTabPanel:new(1, self.panelY, self.width, self.height - self.panelY)
        self.searchPanel.tabPadX = self.width / 2 - self.width / 4
        self.searchPanel:initialise()
        self.searchPanel:setAnchorRight(true)
        self.searchPanel:setAnchorBottom(true)

        -- region search items screen
        local itemsData = CHC_main.itemsForSearch
        local items_screen_init = self.common_screen_data
        local items_extra = {
            recipeSource = itemsData,
            itemSortAsc = options.search.items.filter_asc,
            typeFilter = options.search.items.filter_type,
            showHidden = options.show_hidden,
            sep_x = math.min(self.width / 2, options.search.items.sep_x)
        }
        for k, v in pairs(items_extra) do items_screen_init[k] = v end
        self.searchItemsScreen = CHC_search:new(items_screen_init)
        if itemsData then
            self.searchItemsScreen:initialise()
            self.searchPanel:addView("Items", self.searchItemsScreen)
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
            sep_x = math.min(self.width / 2, options.search.recipes.sep_x)
        }
        for k, v in pairs(recipes_extra) do recipes_screen_init[k] = v end
        self.searchRecipesScreen = CHC_uses:new(recipes_screen_init)

        if recipesData then
            self.searchRecipesScreen:initialise()
            self.searchPanel:addView("Recipes", self.searchRecipesScreen)
        end
        -- endregion
        CHC_menu.cachedItemsView = self.searchPanel
    end
    self.searchPanel.infoText = getText("UI_infotext_search") .. getText("UI_infotext_common", getText("UI_tab_uses_recipe_title"), getText("UI_tab_uses_details_title"))
    self.panel:addView("[WIP] Search", self.searchPanel)

    --endregion

end

function CHC_window:addFavoriteScreen()
    local options = self.options

    -- region favorites screen
    local favRec = self:getRecipes(true)

    local fav_screen_init = self.common_screen_data
    local fav_extra = {
        recipeSource = favRec,
        itemSortAsc = options.favorites.recipes.filter_asc,
        typeFilter = options.favorites.recipes.filter_type,
        showHidden = options.show_hidden,
        sep_x = math.min(self.width / 2, options.favorites.recipes.sep_x)
    }
    for k, v in pairs(fav_extra) do fav_screen_init[k] = v end
    self.favoritesScreen = CHC_uses:new(fav_screen_init)
    self.favoritesScreen:initialise()
    self.favoritesScreen.infoText = getText("UI_infotext_favorites") .. getText("UI_infotext_common", getText("UI_tab_uses_recipe_title"), getText("UI_tab_uses_details_title"))
    self.panel:addView("[WIP] Favorites", self.favoritesScreen)
    -- endregion

end

function CHC_window:addItemView(item)
    local ifn = item:getFullType()
    local itn = CHC_main.items[ifn]
    local nameForTab = itn.displayName
    -- check if there is existing tab with same name (and same item)
    local existingView = self.panel:getView(nameForTab)
    if existingView ~= nil then
        if existingView.view and existingView.view.item ~= itn then -- same displayName, but different items
            nameForTab = nameForTab .. string.format(" (%s)", itn.fullType)
        else -- same displayName and same item
            self:refresh(nameForTab)
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
    -- self.itemPanel:setEqualTabWidth(true)
    -- endregion
    local usesData = CHC_main.recipesByItem[itn.name]
    local craftData = CHC_main.recipesForItem[itn.name]
    self.panel:addView(nameForTab, self.itemPanel)

    --region uses screen
    local uses_screen_init = self.common_screen_data
    local uses_extra = {
        recipeSource = usesData,
        itemSortAsc = options.uses.filter_asc,
        typeFilter = options.uses.filter_type,
        showHidden = options.show_hidden,
        sep_x = math.min(self.width / 2, options.uses.sep_x),
        item = itn
    }
    for k, v in pairs(uses_extra) do uses_screen_init[k] = v end
    self.usesScreen = CHC_uses:new(uses_screen_init)

    if usesData then
        self.usesScreen:initialise()
        self.itemPanel:addView(getText("UI_tab_uses"), self.usesScreen)
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
        item = itn
    }
    for k, v in pairs(craft_extra) do craft_screen_init[k] = v end
    self.craftScreen = CHC_uses:new(craft_screen_init)

    if craftData then
        self.craftScreen:initialise()
        self.itemPanel:addView(getText("UI_tab_craft"), self.craftScreen)
    end
    -- endregion
    --endregion
    self.itemPanel.infoText = getText("UI_infotext_itemtab", itn.displayName, getText("UI_tab_uses"), getText("UI_tab_craft")) ..
        getText("UI_infotext_common", getText("UI_tab_uses_recipe_title"), getText("UI_tab_uses_details_title"))
    self:refresh()
end

function CHC_window:refresh(viewName, panel)
    local panel = panel or self.panel
    -- viewName = viewName or nil
    if viewName then
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
    panel:activateView(viewName)
end

function CHC_window:getRecipes(favOnly)
    favOnly = favOnly or false
    local favoriteRecipes = {}
    local allrec = CHC_main.allRecipes
    local insert = table.insert
    for i = 1, #allrec do
        if (favOnly and allrec[i].favorite) or (not favOnly) then
            insert(favoriteRecipes, allrec[i])
        end
    end
    return favoriteRecipes
end

function CHC_window:onMainTabRightMouseDown(x, y)
    local x = self:getMouseX()
    local y = self:getMouseY()
    if y <= 0 or y > self.tabHeight then
        return
    end
    local tabIndex = self:getTabIndexAtX(x)
    if tabIndex <= 2 then return end -- dont interact with search and favorites
    local context = ISContextMenu.get(0, getMouseX() - 50, getMouseY() - 35)
    context:addOption(getText("IGUI_CraftUI_Close"), self, CHC_window.closeTab, tabIndex)
end

function CHC_window:closeTab(tabIndex)
    local view = self.viewList[tabIndex].view
    self:removeView(view)
    self.parent:refresh()
end

-- region keyboard controls
function CHC_window:onKeyRelease(key)
    if self.isCollapsed then return end

    local shiftDown = isShiftKeyDown()
    local ctrlDown = isCtrlKeyDown()
    local altDown = isAltKeyDown()
    -- print(string.format("shift: %s", tostring(shiftDown)))
    -- print(string.format("ctrl: %s", tostring(ctrlDown)))
    -- print(string.format("alt: %s", tostring(altDown)))

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
        if not sr.searchBar then end
        if sr then
            local sb = nil
        end
        print(fkfk:kffk())
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
    if key == CHC_settings.keybinds.move_tab_left.key then
        newvSel = newvSel - 1
        if newvSel <= 0 then newvSel = #pTabs end
    elseif key == CHC_settings.keybinds.move_tab_right.key then
        newvSel = newvSel + 1
        if newvSel > #pTabs then newvSel = 1 end
    end
    if newvSel ~= oldvSel then
        self:refresh(pTabs[newvSel].name)
    end
    -- endregion

    -- region select recipe/category

    -- region recipes
    if key == CHC_settings.keybinds.move_up.key then
        rl.selected = rl.selected - 1
        if rl.selected <= 0 then
            rl.selected = #rl.items
        end
    elseif key == CHC_settings.keybinds.move_down.key then
        rl.selected = rl.selected + 1
        if rl.selected > #rl.items then
            rl.selected = 1
        end
    end

    local selectedItem = rl.items[rl.selected]
    if selectedItem then
        subview.objList:ensureVisible(rl.selected)
        if subview.objPanel then
            subview.objPanel:setRecipe(selectedItem.item)
        end
    end
    -- endregion

    -- region categories
    local cs = subview.filterRow.categorySelector
    local oldcsSel = cs.selected
    if key == CHC_settings.keybinds.move_left.key then
        cs.selected = cs.selected - 1
        if cs.selected <= 0 then cs.selected = #cs.options end
    elseif key == CHC_settings.keybinds.move_right.key then
        cs.selected = cs.selected + 1
        if cs.selected > #cs.options then cs.selected = 1 end
    end
    if oldcsSel ~= cs.selected then
        subview.onChangeCategory(subview.filterRow, nil, cs.options[cs.selected])
    end
    -- endregion
    -- endregion

    -- endregion

    -- region favorite
    if key == CHC_settings.keybinds.favorite_recipe.key then
        rl:addToFavorite(rl.selected)
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
        if view.viewList then
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

function CHC_window:serializeWindowData()
    local vl = self.panel
    CHC_settings.config.main_window = {
        x = self:getX(), y = self:getY(),
        w = self:getWidth(), h = self:getHeight()
    }
    -- CHC_settings.config.uses = { sep_x = 500, filter_asc = true, filter_type = "all" }
    -- CHC_settings.config.craft = { sep_x = 500, filter_asc = true, filter_type = "all" }
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
    -- local fref_i =
    -- local fref_r =
    CHC_settings.config.favorites = {
        items = {
            sep_x = fref.headers.typeHeader.x,
            filter_asc = fref.itemSortAsc == true,
            filter_type = fref.typeFilter
        },
        recipes = {
            sep_x = fref.headers.typeHeader.x,
            filter_asc = fref.itemSortAsc == true,
            filter_type = fref.typeFilter
        }
    }
end

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

    o.title = 'Craft Helper 41'
    --o:noBackground();
    o.th = o:titleBarHeight()
    o.rh = o:resizeWidgetHeight()
    local fontHgtSmall = getTextManager():getFontHeight(UIFont.Small);
    o.headerHgt = fontHgtSmall + 1
    o.player = args.player or nil

    o.options = CHC_settings.config

    o:setWantKeyEvents(true)

    return o;
end
