-- Main window, opened when RMB -> Craft Helper 41 on item
require 'ISUI/ISCollapsableWindow'
require 'ISUI/ISTabPanel'
require 'CHC_config'
require 'UI/CHC_uses'
require 'UI/CHC_search'
-- require 'UI/craftHelperUpdSearchScreen';

CHC_window = ISCollapsableWindow:derive("CHC_window");

function CHC_window:initialise()
    ISCollapsableWindow.initialise(self);
end

function CHC_window:refresh()
    local selectedView
    if #self.panel.viewList > 2 then
        -- there is item selected
        selectedView = self.panel.viewList[3].name
    else
        selectedView = self.panel.activeView.name
    end

    self.panel:activateView(selectedView)
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

function CHC_window:addSearchPanel()

    -- region search panel
    if CHC_menu.cachedItemsView then
        self.searchPanel = CHC_menu.cachedItemsView
    else
        self.searchPanel = ISTabPanel:new(1, self:titleBarHeight() + self.panel.tabHeight, self.width, self.height - self.panel.tabHeight - 60)
        self.searchPanel.tabPadX = self.width / 2 - self.width / 4
        self.searchPanel:initialise()
        self.searchPanel:setAnchorRight(true)
        self.searchPanel:setAnchorBottom(true)

        -- region search items screen
        local itemsData = CHC_main.itemsForSearch
        local items_screen_init = self.common_screen_data
        local items_extra = {
            recipeSource = itemsData,
            itemSortAsc = CHC_menu.cfg.uses_filter_name_asc or true,
            typeFilter = CHC_menu.cfg.uses_filter_type or "all",
            showHidden = CHC_menu.cfg.uses_show_hidden_recipes,
            sep_x = CHC_menu.cfg.uses_tab_sep_x or 250
        }
        for k, v in pairs(items_extra) do items_screen_init[k] = v end
        self.searchItemsScreen = CHC_search:new(items_screen_init)
        if itemsData then
            self.searchItemsScreen:initialise()
            self.searchItemsScreen.infoText = getText("UI_infotext_uses") .. getText("UI_infotext_common")
            self.searchPanel:addView("Items", self.searchItemsScreen)
        end
        -- endregion

        -- region search recipes screen
        local recipesData = self:getRecipes(false)
        local recipes_screen_init = self.common_screen_data
        local recipes_extra = {
            recipeSource = recipesData,
            itemSortAsc = CHC_menu.cfg.uses_filter_name_asc or true,
            typeFilter = CHC_menu.cfg.uses_filter_type or "all",
            showHidden = CHC_menu.cfg.uses_show_hidden_recipes,
            sep_x = CHC_menu.cfg.uses_tab_sep_x or 250
        }
        for k, v in pairs(recipes_extra) do recipes_screen_init[k] = v end
        self.searchRecipesScreen = CHC_uses:new(recipes_screen_init)

        if recipesData then
            self.searchRecipesScreen:initialise()
            self.searchRecipesScreen.infoText = getText("UI_infotext_uses") .. getText("UI_infotext_common")
            self.searchPanel:addView("Recipes", self.searchRecipesScreen)
        end
        -- endregion
        CHC_menu.cachedItemsView = self.searchPanel
    end
    self.panel:addView("[WIP] Search", self.searchPanel)

    --endregion

end

function CHC_window:addFavoriteScreen()

    -- region favorites screen
    local favRec = self:getRecipes(true)

    local fav_screen_init = self.common_screen_data
    local fav_extra = {
        recipeSource = favRec,
        itemSortAsc = CHC_menu.cfg.uses_filter_name_asc or true,
        typeFilter = CHC_menu.cfg.uses_filter_type or "all",
        showHidden = CHC_menu.cfg.uses_show_hidden_recipes,
        sep_x = CHC_menu.cfg.uses_tab_sep_x or 250
    }
    for k, v in pairs(fav_extra) do fav_screen_init[k] = v end
    self.favoritesScreen = CHC_uses:new(fav_screen_init)
    self.favoritesScreen:initialise()
    self.favoritesScreen.infoText = getText("UI_infotext_uses") .. getText("UI_infotext_common")
    self.panel:addView("[WIP] Favorites", self.favoritesScreen)
    -- endregion

end

function CHC_window:addItemView(item)

    -- region item screens

    --region item container
    self.itemPanel = ISTabPanel:new(1, self:titleBarHeight() + self.panel.tabHeight, self.width, self.height - self.panel.tabHeight - 60)
    self.itemPanel.tabPadX = self.width / 2 - self.width / 4
    self.itemPanel:initialise()
    self.itemPanel:setAnchorRight(true)
    self.itemPanel:setAnchorBottom(true)
    -- self.itemPanel:setEqualTabWidth(true)
    self.panel:addView(item:getDisplayName(), self.itemPanel)

    -- endregion

    --region uses screen
    local usesData = CHC_main.recipesByItem[item:getName()]
    local uses_screen_init = self.common_screen_data
    local uses_extra = {
        recipeSource = usesData,
        itemSortAsc = CHC_menu.cfg.uses_filter_name_asc or true,
        typeFilter = CHC_menu.cfg.uses_filter_type or "all",
        showHidden = CHC_menu.cfg.uses_show_hidden_recipes,
        sep_x = CHC_menu.cfg.uses_tab_sep_x or 250
    }
    for k, v in pairs(uses_extra) do uses_screen_init[k] = v end
    self.usesScreen = CHC_uses:new(uses_screen_init)

    if usesData then
        self.usesScreen:initialise()
        self.usesScreen.infoText = getText("UI_infotext_uses") .. getText("UI_infotext_common")
        self.itemPanel:addView(getText("UI_tab_uses"), self.usesScreen)
    end
    --endregion

    -- region crafting screen
    local craftData = CHC_main.recipesForItem[item:getName()]

    local craft_screen_init = self.common_screen_data
    local craft_extra = {
        recipeSource = craftData,
        itemSortAsc = CHC_menu.cfg.craft_filter_name_asc or true,
        typeFilter = CHC_menu.cfg.craft_filter_type or "all",
        showHidden = CHC_menu.cfg.uses_show_hidden_recipes,
        sep_x = CHC_menu.cfg.craft_tab_sep_x or 250
    }
    for k, v in pairs(craft_extra) do craft_screen_init[k] = v end
    self.craftScreen = CHC_uses:new(craft_screen_init)

    if craftData then
        self.craftScreen:initialise()
        self.craftScreen.infoText = getText("UI_infotext_craft") .. getText("UI_infotext_common")
        self.itemPanel:addView(getText("UI_tab_craft"), self.craftScreen)
    end
    -- endregion
    --endregion

end

function CHC_window:createChildren()
    ISCollapsableWindow.createChildren(self)

    -- region main container (search, favorites and all selected items)
    self.panel = ISTabPanel:new(1, self:titleBarHeight(), self.width, self.height - 60)
    self.panel:initialise()
    self.panel:setAnchorRight(true)
    -- self.panel:setEqualTabWidth(true)
    -- endregion

    self.common_screen_data = { x = 0, y = 8, w = self.width, h = self.panel.height - 60 }

    self:addSearchPanel()
    self:addFavoriteScreen()

    -- add tab for each selected item
    for i = 1, #self.items do
        local item = self.items[i]
        if not instanceof(item, "InventoryItem") then
            item = item.items[1]
        end
        self:addItemView(item)
    end

    self:addChild(self.panel)

    self:refresh()
end

-- region keyboard controls
function CHC_window:onKeyRelease(key)
    local ui = self
    if not ui.itemPanel or not ui.itemPanel.activeView then return end
    local view = ui.itemPanel.activeView.view
    local rl = view.recipesList

    -- region close
    if key == CHC_settings.keybinds.close_window.key then
        self:close()
        return
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
        view.recipesList:ensureVisible(rl.selected)
        view.recipePanel:setRecipe(selectedItem.item)
    end
    -- endregion

    -- region categories
    local cs = view.filterRow.categorySelector
    local oldcsSel = cs.selected
    if key == CHC_settings.keybinds.move_left.key then
        cs.selected = cs.selected - 1
        if cs.selected <= 0 then cs.selected = #cs.options end
    elseif key == CHC_settings.keybinds.move_right.key then
        cs.selected = cs.selected + 1
        if cs.selected > #cs.options then cs.selected = 1 end
    end
    if oldcsSel ~= cs.selected then
        view:onChangeUsesRecipeCategory(nil, cs.options[cs.selected])
    end
    -- endregion
    -- endregion

    -- region favorite
    if key == CHC_settings.keybinds.favorite_recipe.key then
        rl:addToFavorite(rl.selected)
    end
    -- endregion

    -- region crafting
    if key == CHC_settings.keybinds.craft_one.key then
        if not view.recipePanel.newItem then return end
        view.recipePanel:craft(nil, false)
    elseif key == CHC_settings.keybinds.craft_all.key then
        if not view.recipePanel.newItem then return end
        view.recipePanel:craft(nil, true)
    end
    -- endregion

    -- search bar focus
    -- if key == Keyboard.KEY_TAB then
    --     -- if getCore():getGameMode() == "Multiplayer" then return end
    --     if not view.searchRow then return end
    --     local bar = view.searchRow.searchBar
    --     if not bar:isFocused() then
    --         bar:focus()
    --     end
    -- end
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
    -- if key == Keyboard.KEY_TAB then isKeyValid = true end

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
    CHC_config.fn.updateSettings()
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
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

    o:setWantKeyEvents(true);

    return o;
end
