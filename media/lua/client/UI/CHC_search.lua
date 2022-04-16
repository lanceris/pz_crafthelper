require "ISUI/ISPanel"

require "UI/CHC_tabs"
require "UI/CHC_uses_recipelist"
require "UI/CHC_uses"

local utils = require('CHC_utils')

CHC_search = ISPanel:derive("CHC_search")

CHC_search.sortOrderIconAsc = getTexture("media/textures/sort_order_asc.png")
CHC_search.sortOrderIconDesc = getTexture("media/textures/sort_order_desc.png")
CHC_search.typeFiltIconAll = getTexture("media/textures/type_filt_all.png")
CHC_search.typeFiltIconValid = getTexture("media/textures/type_filt_valid.png")
CHC_search.typeFiltIconKnown = getTexture("media/textures/type_filt_known.png")
CHC_search.typeFiltIconInvalid = getTexture("media/textures/type_filt_invalid.png")
CHC_search.searchIcon = getTexture("media/textures/search_icon.png")

local insert = table.insert
local sort = table.sort

function CHC_search:initialise()
    ISPanel.initialise(self)
    self:create()
end

function CHC_search:create()
    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, 20, { self.onResizeHeaders, self }, self.sep_x)
    self.headers:initialise()
    -- endregion


    local x = self.headers.x
    local y = self.headers.y + self.headers.height
    local leftW = self.headers.nameHeader.width
    local rightX = self.headers.typeHeader.x
    local rightW = self.headers.typeHeader.width

    -- region filters UI
    local filterRowData = {
        filterOrderData = {
            width = 24,
            title = "",
            onclick = self.sortByName,
            defaultTooltip = CHC_uses.filterRowOrderSetTooltip(self),
            defaultIcon = CHC_uses.filterRowOrderSetIcon(self)
        },
        filterTypeData = {
            width = 24,
            title = "",
            onclick = self.onFilterTypeMenu,
            defaultTooltip = "TestTooltip",
            defaultIcon = CHC_uses.filterRowTypeSetIcon(self)
        },
        filterSelectorData = {
            defaultCategory = getText("UI_All"),
            defaultTooltip = getText("IGUI_invpanel_Category"),
            onChange = self.onChangeCategory
        }
    }

    self.filterRow = CHC_filter_row:new(x, y, leftW, 24, filterRowData)
    self.filterRow:initialise()
    local leftY = y + 24
    self:catSelUpdateOptions()
    --endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new(x, leftY, leftW, 24, nil, self.onTextChange, getText("UI_searchrow_info"))
    self.searchRow:initialise()
    leftY = leftY + 24
    -- endregion

    -- region recipe list
    local rlh = self.height - self.headers.height - self.filterRow.height - self.searchRow.height
    self.objList = CHC_items_list:new(x, leftY, leftW, rlh);

    self.objList.drawBorder = true
    self.objList:initialise()
    self.objList:instantiate()
    self.objList:setAnchorBottom(true)
    self.objList:setOnMouseDownFunction(self, CHC_uses.onItemChange)

    -- Add entries to recipeList
    -- self:cacheFullRecipeCount(self.itemSource)
    self:updateItems(filterRowData.filterSelectorData.defaultCategory)
    -- endregion

    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.objList)
end

function CHC_search:updateItems(sl)
    local categoryAll = getText("UI_All")
    local searchBar = self.searchRow.searchBar
    local items = self.itemSource

    if sl == categoryAll and self.typeFilter == "all" and searchBar:getInternalText() == "" then
        self:refreshItemsList(items)
        return
    end

    -- filter items
    local filteredItems = {}
    for i = 1, #items do
        local rc = items[i].displayCategory
        -- local rc_tr = getTextOrNull("IGUI_CraftCategory_" .. rc) or rc

        local fav_cat_state = false
        local type_filter_state = false
        local search_state = false
        -- local condFav1 = sl == "* " .. getText("IGUI_CraftCategory_Favorite")
        -- local condFav2 = items[i].favorite
        -- if condFav1 and condFav2 then
        --     fav_cat_state = true
        -- end

        -- if (rc_tr == sl or sl == categoryAll) then
        --     type_filter_state = self:recipeTypeFilter(item)
        -- end
        if rc == sl or (sl == "Item" and not rc) or sl == categoryAll then type_filter_state = true end
        search_state = CHC_uses.searchTypeFilter(self, items[i])
        if type_filter_state and search_state then
            insert(filteredItems, items[i])
        end
    end
    self:refreshItemsList(filteredItems)
end

function CHC_search:onTextChange()
    local s = self.parent.parent
    local stateText = s.searchRow.searchBar:getInternalText()
    if stateText ~= s.searchRow.searchBarLastText or stateText == "" then
        s.searchRow.searchBarLastText = stateText
        local option = s.filterRow.categorySelector
        local sl = option.options[option.selected]
        s:updateItems(sl)
    end
end

function CHC_search:searchProcessToken(token, item)
    -- check if token is special search
    -- if so
    -- remove special char from token
    -- process special chars
    -- if not, compare token with recipe name
    --return state
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char
    local items = {}
    if not token then return true end

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token) then
        isSpecialSearch = true
        char = token:sub(1, 1)
        token = string.sub(token, 2)
        if token == "" then token = nil end
    end


    local whatCompare
    if isAllowSpecialSearch and char == "^" then
        -- print('fav items(?) here')
        --     -- show favorited reciped and search by them
        --     if not recipe.favorite then return false end
        --     whatCompare = string.lower(recipe.recipe:getName())
    end
    -- if token and isSpecialSearch then
    --     if char == "!" then
    --         -- search by recipe category
    --         local catName = getTextOrNull("IGUI_CraftCategory_" .. recipe.category) or recipe.category
    --         whatCompare = catName
    --     end
    --     local resultItem = CHC_main.items[recipe.recipe:getResult():getFullType()]
    --     if resultItem then
    --         if char == "@" then
    --             -- search by mod name of resulting item
    --             whatCompare = resultItem:getModName()
    --         elseif char == "$" then
    --             -- search by DisplayCategory of resulting item
    --             local displayCat = resultItem:getDisplayCategory() or ""
    --             whatCompare = getText("IGUI_ItemCat_" .. displayCat) or "None"
    --         elseif char == "%" then
    --             -- search by name of resulting item
    --             whatCompare = resultItem:getDisplayName()
    --         end
    --     end
    --     if char == "#" then
    --         -- search by ingredients
    --         local rSources = recipe.recipe:getSource()

    --         -- Go through items needed by the recipe
    --         for n = 0, rSources:size() - 1 do
    --             -- Get the item name (not the display name)
    --             local rSource = rSources:get(n)
    --             local sItems = rSource:getItems()
    --             for k = 0, sItems:size() - 1 do
    --                 local itemString = sItems:get(k)
    --                 local item = CHC_main.items[itemString]
    --                 if item then table.insert(items, item:getDisplayName()) end
    --             end
    --         end
    --         whatCompare = items
    --     end
    -- end
    if token and not isSpecialSearch then
        whatCompare = string.lower(item.displayName)
    end
    state = utils.compare(whatCompare, token)
    return state
end

function CHC_search:refreshItemsList(items)
    self.objList:clear()
    self.objList:setScrollHeight(0)

    local modData = getPlayer():getModData()
    for i = 1, #items do
        self:processAddItemToItemList(items[i], modData)
    end
    sort(self.objList.items, self.itemSortFunc)
end

function CHC_search:processAddItemToItemList(item, modData)
    if not CHC_settings.config.show_hidden and item.hidden then return end
    -- if not self.showHidden and item.recipe:isHidden() then return end
    -- item.favorite = modData[CHC_main.getFavoriteModDataString(item.recipe)] or false
    local name = item.displayName
    if name then
        self.objList:addItem(name, item)
    end
end

function CHC_search:catSelUpdateOptions()

    local selector = self.filterRow.categorySelector
    local uniqueCategories = {}
    local missingDisplayCat = false
    local allItems = self.itemSource
    local c = 1
    local pairs = pairs

    for _, item in pairs(allItems) do
        local ic = item.displayCategory
        if ic then
            if not utils.any(uniqueCategories, ic) then
                uniqueCategories[c] = ic
                c = c + 1
            end
        else
            missingDisplayCat = true
        end
    end

    if missingDisplayCat then
        uniqueCategories[c] = getText("IGUI_ItemCat_Item")
    end
    sort(uniqueCategories)
    for i = 1, #uniqueCategories do
        selector:addOption(uniqueCategories[i])
    end
end

function CHC_search:onChangeCategory(_option, sl)
    sl = sl or _option.options[_option.selected]
    self.parent:updateItems(sl)
end

function CHC_search:onItemChange(item)
    print("imma change item in ItemList")
    -- self.recipePanel:setRecipe(recipe);
    -- self.recipesList:onMouseDown_Recipes(self.recipesList:getMouseX(), self.recipesList:getMouseY())
end

function CHC_search:onResizeHeaders()
    self.filterRow:setWidth(self.headers.nameHeader.width)
    self.searchRow:setWidth(self.headers.nameHeader.width)
    self.objList:setWidth(self.headers.nameHeader.width)
    -- self.recipePanel:setWidth(self.headers.typeHeader.width)
    -- self.recipePanel:setX(self.headers.typeHeader.x)
end

CHC_search.sortByNameAsc = function(a, b)
    return a.text < b.text
end

CHC_search.sortByNameDesc = function(a, b)
    return a.text > b.text
end

function CHC_search:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }

    o.ui_name = args.ui_name
    o.sep_x = args.sep_x
    o.player = getPlayer()

    o.itemSource = args.recipeSource
    o.itemSortAsc = args.itemSortAsc
    o.itemSortFunc = o.itemSortAsc == true and CHC_search.sortByNameAsc or CHC_search.sortByNameDesc
    o.typeFilter = args.typeFilter

    o.numRecipesAll = 0
    o.numRecipesValid = 0
    o.numRecipesKnown = 0
    o.numRecipesInvalid = 0
    return o
end

------------------------------------------------------------------------------------------------------------------------------------
CHC_items_list = ISScrollingListBox:derive("CHC_items_list")

function CHC_items_list:initialise()
    self.ft = true
    ISScrollingListBox.initialise(self)
end

function CHC_items_list:prerender()
    local now
    if self.ft then
        now = getTimestampMs()
    end
    if not self.items then return end

    local stencilX = 0
    local stencilY = 0
    local stencilX2 = self.width
    local stencilY2 = self.height

    self:drawRect(0, -self:getYScroll(), self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);

    if self.drawBorder then
        self:drawRectBorder(0, -self:getYScroll(), self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
        stencilX = 1
        stencilY = 1
        stencilX2 = self.width - 1
        stencilY2 = self.height - 1
    end

    if self:isVScrollBarVisible() then
        stencilX2 = self.vscroll.x + 3 -- +3 because the scrollbar texture is narrower than the scrollbar width
    end

    self:setStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)

    local y = 0;
    local alt = false;

    --	if self.selected ~= -1 and self.selected < 1 then
    --		self.selected = 1
    if self.selected ~= -1 and self.selected > #self.items then
        self.selected = #self.items
    end


    self.listHeight = 0;
    local i = 1;  --@@@
    for j = 1, #self.items do
        self.items[j].index = i;
        local y2 = self:doDrawItem(y, self.items[j], alt);
        self.listHeight = y2;
        self.items[j].height = y2 - y
        y = y2

        alt = not alt;
        i = i + 1;

    end

    self:setScrollHeight((y));
    self:clearStencilRect();

    if self.doRepaintStencil then
        self:repaintStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)
    end

    local mouseY = self:getMouseY()
    self:updateSmoothScrolling()

    if mouseY ~= self:getMouseY() and self:isMouseOver() then
        self:onMouseMove(0, self:getMouseY() - mouseY)
    end
    self:updateTooltip()

    if #self.columns > 0 then
        --		print(self:getScrollHeight())
        self:drawRectBorderStatic(0, 0 - self.itemheight, self.width, self.itemheight - 1, 1, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        self:drawRectStatic(0, 0 - self.itemheight - 1, self.width, self.itemheight - 2, self.listHeaderColor.a, self.listHeaderColor.r, self.listHeaderColor.g, self.listHeaderColor.b);
        local dyText = (self.itemheight - FONT_HGT_SMALL) / 2
        for i, v in ipairs(self.columns) do
            self:drawRectStatic(v.size, 0 - self.itemheight, 1, self.itemheight + math.min(self.height, self.itemheight * #self.items - 1), 1, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            if v.name then
                self:drawText(v.name, v.size + 10, 0 - self.itemheight - 1 + dyText - self:getYScroll(), 1, 1, 1, 1, UIFont.Small);
            end
        end
    end

    if self.ft then
        -- print(rerp:rer())
        print(string.format("total: %s", getTimestampMs() - now))
        self.ft = false
        -- 177 ms per frame, need to reduce to at least 50 for smooth UX
    end
end

function CHC_items_list:doDrawItem(y, item, alt)

    if y + self:getYScroll() >= self.height then return y + item.height end
    if y + item.height + self:getYScroll() <= 0 then return y + item.height end
    if y < -self:getYScroll() - 1 then return y + item.height; end
    if y > self:getHeight() - self:getYScroll() + 1 then return y + item.height; end

    local itemObj = item.item
    local a = 0.9

    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    local iconsEnabled = CHC_settings.config.show_icons

    -- region icons
    if iconsEnabled then
        local itemIcon = itemObj.texture
        self:drawTextureScaled(itemIcon, 6, y + 6, item.height - 12, item.height - 12, 1)
    end
    --endregion

    --region text
    local clr = { txt = item.text, x = iconsEnabled and item.height or 15,
        y = (y) + itemPadY, a = 0.9, font = self.font }
    clr['r'] = 1
    clr['g'] = 1
    clr['b'] = 1
    clr['a'] = a
    self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font)
    --endregion


    --region filler
    local sc = { x = 0, y = y, w = self:getWidth(), h = item.height - 1, a = 0.2, r = 0.75, g = 0.5, b = 0.5 }
    local bc = { x = sc.x, y = sc.y, w = sc.w, h = sc.h + 1, a = 0.25, r = 1, g = 1, b = 1 }
    -- fill selected entry
    if self.selected == item.index then
        self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b);
    end
    -- border around entry
    self:drawRectBorder(bc.x, bc.y, bc.w, bc.h, bc.a, bc.r, bc.g, bc.b);
    --endregion

    y = y + item.height;
    return y;
end

function CHC_items_list:new(x, y, width, height)
    local o = {}

    o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    o.anchorTop = true
    o.anchorBottom = true
    return o
end