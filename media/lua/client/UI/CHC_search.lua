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

-- region create
function CHC_search:initialise()
    ISPanel.initialise(self)

    self.categoryData = { -- .count for each calculated in catSelUpdateOptions
        all = {
            tooltip = getText("UI_All"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        AlarmClock = {
            tooltip = getText("IGUI_ItemCat_AlarmClock"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        AlarmClockClothing = {
            tooltip = getText("IGUI_CHC_ItemCat_AlarmClockClothing"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Clothing = {
            tooltip = getText("IGUI_ItemCat_Clothing"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Container = {
            tooltip = getText("IGUI_ItemCat_Container"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Drainable = {
            tooltip = getText("IGUI_CHC_ItemCat_Drainable"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Food = {
            tooltip = getText("IGUI_ItemCat_Food"),
            icon = getTexture("media/textures/type_filt_valid.png")
        },
        Key = {
            tooltip = getText("IGUI_CHC_ItemCat_Key"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Literature = {
            tooltip = getText("IGUI_ItemCat_Literature"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Map = {
            tooltip = getText("IGUI_CHC_ItemCat_Map"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Moveable = {
            tooltip = getText("IGUI_CHC_ItemCat_Moveable"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Normal = {
            tooltip = getText("IGUI_CHC_ItemCat_Normal"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Radio = {
            tooltip = getText("IGUI_CHC_ItemCat_Radio"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Weapon = {
            tooltip = getText("IGUI_ItemCat_Weapon"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        WeaponPart = {
            tooltip = getText("IGUI_ItemCat_WeaponPart"),
            icon = getTexture("media/textures/type_filt_all.png")
        }
    }


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
            defaultTooltip = self:filterRowOrderSetTooltip(),
            defaultIcon = self:filterRowOrderSetIcon()
        },
        filterTypeData = {
            width = 24,
            title = "",
            onclick = self.onFilterTypeMenu,
            defaultTooltip = self:filterRowTypeSetTooltip(),
            defaultIcon = self:filterRowTypeSetIcon()
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
    self.objList:setOnMouseDownFunction(self, self.onItemChange)

    -- Add entries to recipeList
    -- self:cacheFullRecipeCount(self.itemSource)

    -- endregion

    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.objList)

    self:catSelUpdateOptions()
    -- self:cacheCategoryCounts()
    self:updateItems(self.selectedCategory)
end

--endregion

--region update

function CHC_search:update()
    if self.needUpdateFavorites == true then
        self.needUpdateFavorites = false
    end
    if self.needUpdateObjects == true then
        self:updateItems(self.selectedCategory)
        self.needUpdateObjects = false
    end
end

function CHC_search:onTextChange()
    self.needUpdateObjects = true
end

function CHC_search:onChangeCategory(_option, sl)
    self.parent.selectedCategory = sl or _option.options[_option.selected].text
    self.parent.needUpdateObjects = true
end

function CHC_search:cacheItemCounts()

end

function CHC_search:updateItems(sl)
    -- print(sl)
    if type(sl) == 'table' then sl = sl.text end
    local categoryAll = self.categorySelectorDefaultOption
    local searchBar = self.searchRow.searchBar
    local items = self.ui_type == 'fav_items' and self.favrec or self.itemSource

    if sl == categoryAll and self.typeFilter == "all" and searchBar:getInternalText() == "" then
        CHC_uses.refreshObjList(self, items)
        return
    end

    -- filter items
    local filteredItems = {}
    for i = 1, #items do
        local rc = items[i].displayCategory

        local fav_cat_state = false
        local type_filter_state = false
        local search_state = false
        -- local condFav1 = sl == "* " .. getText("IGUI_CraftCategory_Favorite")
        -- local condFav2 = items[i].favorite
        -- if condFav1 and condFav2 then
        --     fav_cat_state = true
        -- end

        if (rc == sl or sl == categoryAll) then
            type_filter_state = self:itemTypeFilter(items[i])
        end
        search_state = CHC_uses.searchTypeFilter(self, items[i])

        if type_filter_state and search_state then
            insert(filteredItems, items[i])
        end
    end
    CHC_uses.refreshObjList(self, filteredItems)
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

function CHC_search:processAddObjToObjList(item, modData)
    if not CHC_settings.config.show_hidden and item.hidden then return end
    -- if not self.showHidden and item.recipe:isHidden() then return end
    -- item.favorite = modData[CHC_main.getFavoriteModDataString(item.recipe)] or false
    local name = item.displayName
    if name then
        self.objList:addItem(name, item)
    end
end

function CHC_search:onItemChange(item)
    print("imma change item in ItemList")
    -- self.recipePanel:setRecipe(recipe);
    -- self.recipesList:onMouseDown_Recipes(self.recipesList:getMouseX(), self.recipesList:getMouseY())
end

function CHC_search:catSelUpdateOptions()

    local selector = self.filterRow.categorySelector
    local uniqueCategories = {}
    local dcatCounts = {}
    local catCounts = {}
    local allItems = self.ui_type == 'fav_items' and self.favrec or self.itemSource
    local c = 1

    for i = 1, #allItems do
        local ic = allItems[i].category
        if not catCounts[ic] then
            catCounts[ic] = 1
        else
            catCounts[ic] = catCounts[ic] + 1
        end

        local idc = allItems[i].displayCategory
        if not utils.any(uniqueCategories, idc) then
            uniqueCategories[c] = idc
            dcatCounts[idc] = 1
            c = c + 1
        else
            dcatCounts[idc] = dcatCounts[idc] + 1
        end
    end

    selector:clear()
    selector:addOptionWithData(self.categorySelectorDefaultOption, { count = #allItems })

    -- WIP favorite category

    sort(uniqueCategories)
    for i = 1, #uniqueCategories do
        selector:addOptionWithData(uniqueCategories[i], { count = dcatCounts[uniqueCategories[i]] })
    end

    self.categoryData.all.count = #allItems
    for cat, cnt in pairs(catCounts) do
        self.categoryData[cat].count = cnt
    end
end

function CHC_search:handleFavorites()

end

-- endregion

--region filters

-- region filter onClick handlers
function CHC_search:onFilterTypeMenu(button)
    local self = self.parent
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 10, y)

    local data = {}
    for cat, d in pairs(self.categoryData) do
        insert(data, { txt = d.tooltip, num = d.count, arg = cat })
    end

    local txt
    for i = 1, #data do
        txt = CHC_uses.filterSortMenuGetText(self, data[i].txt, data[i].num)
        context:addOption(txt, self, CHC_search.sortByType, data[i].arg)
    end

end

function CHC_search:itemTypeFilter(item)
    local state = true
    if self.typeFilter == 'all' then
        state = true
    elseif self.typeFilter ~= item.category then
        state = false
    end
    return state
end

-- region filterRow setters
function CHC_search:filterRowOrderSetTooltip()
    local cursort = self.itemSortAsc and getText("IGUI_invpanel_ascending") or getText("IGUI_invpanel_descending")
    return getText("UI_settings_st_title") .. " (" .. cursort .. ")"
end

function CHC_search:filterRowOrderSetIcon()
    return self.itemSortAsc and self.sortOrderIconAsc or self.sortOrderIconDesc
end

function CHC_search:filterRowTypeSetTooltip()
    local curtype = self.categoryData[self.typeFilter].tooltip
    return getText("UI_settings_av_title") .. " (" .. curtype .. ")"
end

function CHC_search:filterRowTypeSetIcon()
    return self.categoryData[self.typeFilter].icon
end

-- endregion

CHC_search.sortByNameAsc = function(a, b)
    return a.text < b.text
end

CHC_search.sortByNameDesc = function(a, b)
    return a.text > b.text
end

function CHC_search:sortByName()
    local self = self.parent
    local option = self.filterRow.categorySelector
    local sl = option.options[option.selected].text
    self.itemSortAsc = not self.itemSortAsc
    self.itemSortFunc = self.itemSortAsc and CHC_search.sortByNameAsc or CHC_search.sortByNameDesc

    local newIcon = self:filterRowOrderSetIcon()
    self.filterRow.filterOrderBtn:setImage(newIcon)
    local newTooltip = self:filterRowOrderSetTooltip()
    self.filterRow.filterOrderBtn:setTooltip(newTooltip)
    self.selectedCategory = sl
    self.needUpdateObjects = true
end

function CHC_search:sortByType(_type)
    if _type ~= self.typeFilter then
        self.typeFilter = _type
        self.filterRow.filterTypeBtn:setTooltip(self:filterRowTypeSetTooltip())
        self.filterRow.filterTypeBtn:setImage(self:filterRowTypeSetIcon())
        self.needUpdateObjects = true
    end
end

-- endregion

--region render

function CHC_search:onResizeHeaders()
    self.filterRow:setWidth(self.headers.nameHeader.width)
    self.searchRow:setWidth(self.headers.nameHeader.width)
    self.objList:setWidth(self.headers.nameHeader.width)
    -- self.recipePanel:setWidth(self.headers.typeHeader.width)
    -- self.recipePanel:setX(self.headers.typeHeader.x)
end

--endregion


function CHC_search:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }

    o.ui_type = args.ui_type
    o.sep_x = args.sep_x
    o.player = getPlayer()

    o.favCatName = "* " .. getText("IGUI_CraftCategory_Favorite")
    o.categorySelectorDefaultOption = getText("UI_All")
    o.selectedCategory = o.categorySelectorDefaultOption
    o.backRef = args.backRef

    o.itemSource = args.recipeSource
    o.itemSortAsc = args.itemSortAsc
    o.itemSortFunc = o.itemSortAsc == true and CHC_search.sortByNameAsc or CHC_search.sortByNameDesc
    o.typeFilter = args.typeFilter
    o.showHidden = args.showHidden
    o.favNum = 0 -- WIP favorite items

    o.needUpdateFavorites = false
    o.needUpdateCounts = false
    o.needUpdateObjects = false
    o.updCountsWithCur = false

    return o
end

------------------------------------------------------------------------------------------------------------------------------------
--region items list
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

    o.favoriteStar = getTexture("media/ui/FavoriteStar.png")
    o.favCheckedTex = getTexture("media/ui/FavoriteStarChecked.png")
    o.favNotCheckedTex = getTexture("media/ui/FavoriteStarUnchecked.png")
    return o
end

--endregion
