CHC_view = {}
CHC_view._list = {}
local sort = table.sort
local floor = math.floor
local ceil = math.ceil

-- region create
function CHC_view:create(mainPanelsData)
    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, CHC_main.common.heights.headers, { CHC_view.onResizeHeaders, self },
        self.sep_x)
    self.headers:initialise()
    -- endregion

    local filterRowHeight = CHC_main.common.heights.filter_row
    local x = self.headers.x
    local y = self.headers.y + self.headers.height
    local leftW = self.headers.nameHeader.width - filterRowHeight
    local rightX = self.headers.typeHeader.x
    local rightW = self.headers.typeHeader.width

    -- region filters UI
    local filterRowData = {
        filterTypeData = {
            width = CHC_main.common.heights.filter_row,
            title = '',
            onclick = CHC_view.onFilterTypeMenu,
            defaultTooltip = self:filterTypeSetTooltip(),
            defaultIcon = CHC_view.filterTypeSetIcon(self)
        },
        filterSelectorData = {
            defaultCategory = getText('UI_All'),
            defaultTooltip = getText('IGUI_invpanel_Category'),
            onChange = CHC_view.onChangeCategory
        }
    }

    self.filterRow = CHC_filter_row:new(
        { x = x, y = y, w = leftW, h = filterRowHeight, backRef = self.backRef }, filterRowData)
    self.filterRow:initialise()

    --endregion
    -- region infoButton
    self.infoButton = ISButton:new(x, y, filterRowHeight, filterRowHeight, nil, self)
    self.infoButton.borderColor.a = 0
    self.infoButton.backgroundColor.a = 0
    self.infoButton:initialise()
    self.infoButton:setImage(CHC_window.icons.common.help_tooltip)
    self.infoButton.updateTooltip = self.updateInfoBtnTooltip
    self.infoButton:setTooltip(CHC_view.createInfoText(self))
    -- endregion
    local leftY = y + CHC_main.common.heights.filter_row

    local searchRowHeight = CHC_main.common.heights.search_row
    -- region search bar
    self.searchRow = CHC_search_bar:new(
        { x = x, y = leftY, w = leftW, h = searchRowHeight, backRef = self.backRef },
        self.searchBarTooltip,
        self.onTextChange, self.searchRowHelpText, self.onCommandEntered)
    self.searchRow:initialise()
    if self.delayedSearch then self.searchRow:setTooltip(self.searchBarDelayedTooltip) end

    -- endregion

    -- region remove all favorites button
    self.removeAllFavBtn = ISButton:new(self.searchRow.width, leftY, searchRowHeight, searchRowHeight,
        nil, self, CHC_view.onRemoveAllFavBtnClick)
    self.removeAllFavBtn.borderColor.a = 0
    self.removeAllFavBtn.backgroundColor.a = 0
    local tooltip = table.concat(
        {
            getText("ContextMenu_Unfavorite"),
            getText("ContextMenu_All"):lower(),
            self.isItemView == true and
            getText("UI_search_items_tab_name"):lower() or
            getText("UI_search_recipes_tab_name"):lower(),
        }, " ")
    self.removeAllFavBtn:setTooltip(tooltip)
    self.removeAllFavBtn:initialise()
    self.removeAllFavBtn:setImage(self.removeAllFavBtnIcon)
    self.removeAllFavBtn:setVisible(false)
    -- endregion
    leftY = leftY + self.searchRow.height


    -- region recipe list
    local rlh = self.height - self.headers.height - self.filterRow.height - self.searchRow.height
    local params = { x = x, y = leftY, w = leftW, h = rlh, backRef = self.backRef }
    if mainPanelsData.extra_init_params then
        for key, value in pairs(mainPanelsData.extra_init_params) do
            params[key] = value
        end
    end
    self.objList = mainPanelsData.listCls:new(params)

    self.objList.drawBorder = true
    self.objList.onRightMouseDown = self.onRMBDownObjList
    self.objList:initialise()
    self.objList:instantiate()
    self.objList:setAnchorBottom(true)
    self.objList:setOnMouseDownFunction(self, CHC_view.onObjectChange)
    self.objList.curFontData = self.curFontData
    self.objList:setFont(self.curFontData.font)
    self.objList.vscroll.backgroundColor.a = 0
    self.objList.vscroll.borderColor.a = 0.25

    -- Add entries to recipeList
    local iph = self.height - self.headers.height
    self.objPanel = mainPanelsData.panelCls:new({ x = rightX, y = y, w = rightW, h = iph, backRef = self.backRef })
    self.objPanel:initialise()
    self.objPanel:instantiate()
    self.objPanel:setAnchorBottom(true)

    -- endregion

    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.removeAllFavBtn)
    self:addChild(self.infoButton)
    self:addChild(self.objList)
    self:addChild(self.objPanel)
end

-- endregion

-- region update

function CHC_view:update()
    if self.needUpdateFont then
        self.needUpdateFont = false
        self.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
        self.objList.curFontData = self.curFontData
        self.objList:setFont(self.curFontData.font, self.curFontData.pad)
        local fontSize = getTextManager():getFontHeight(self.curFontData.font)
        self.fontSize = fontSize
        self.objList.fontSize = fontSize
        self:updateObjects()
    end
    if self.needUpdateShowIcons then
        self.needUpdateShowIcons = false
        self.objList.shouldShowIcons = CHC_settings.config.show_icons
    end
    if self.needUpdateObjects then
        self.needUpdateObjects = false
        self:updateObjects()
        CHC_view.updateTabNameWithCount(self)
    end
    if self.needUpdateFavorites then
        self.needUpdateFavorites = false
        CHC_view.handleFavorites(self, self.fav_ui_type)
    end
    if self.needUpdateDelayedSearch then
        self.needUpdateDelayedSearch = false
        self.delayedSearch = CHC_settings.config.delayed_search
        if self.delayedSearch then
            self.searchRow:setTooltip(self.searchBarDelayedTooltip)
        else
            self.searchRow:setTooltip(self.searchRow.origTooltip)
        end
    end
    if self.needUpdateInfoTooltip then
        self.needUpdateInfoTooltip = false
        self.infoButton:setTooltip(CHC_view.createInfoText(self))
    end
    if self.needUpdateLayout then
        self.needUpdateLayout = false
        CHC_window.onActivateViewAdjustPositions(self.backRef, CHC_window.getActiveSubView(self.backRef))
    end
end

function CHC_view:initTypesAndCategories(typeField, categoryField)
    local curType = self.typeFilter
    local objs = self.objSource
    local typCounts = {}
    local catCounts = {}
    local newCats = {}
    local curCat = self.selectedCategory

    for i = 1, #objs do
        local obj = objs[i]

        -- types
        local ic = obj[typeField]
        local idc = obj[categoryField]
        --types
        typCounts[ic] = typCounts[ic] and typCounts[ic] + 1 or 1

        -- categories
        if not catCounts[idc] then
            newCats[#newCats + 1] = idc
            catCounts[idc] = 1
        else
            catCounts[idc] = catCounts[idc] + 1
        end
    end

    CHC_view.updateTypes(self, typCounts, curType)

    CHC_view.updateCategories(self, catCounts, curCat, newCats)
end

---check if one object passes filters and can be added to objList
---@param filters {number: {args: table, func: function, name: string}} list of filters
---@return boolean ok true if all filters passed
---@return {string: true} passed map of passed filters `{filter.name: true}`
function CHC_view:checkFilters(obj, filters)
    local passed = {}
    local ok = true
    for i = 1, #filters do
        if not ok then break end
        local filter = filters[i]
        -- print("check " .. filter.name .. " for " .. obj.fullType)
        if filter.func(self, filter.args[1], filter.args[2], filter.args[3], filter.args[4]) == true then
            passed[filter.name] = true
        else
            ok = false
        end
    end
    return ok, passed
end

function CHC_view:updateObjects(typeField, categoryField, extraFilters)
    categoryField = categoryField or "displayCategory"
    local objs = self.objSource
    local curType = self.typeFilter
    local defTypeSelected = curType == 'all'
    local typCounts = {}
    local catCounts = {}
    local newCats = {}
    local curCat = self.selectedCategory
    local defCatSelected = curCat == self.defaultCategory
    local searchBarEmpty = self.searchRow.searchBar:getInternalText() == ''

    if not self.initDone or (defCatSelected and defTypeSelected and searchBarEmpty) then
        local skipUpdate = true
        -- skip updating object only if not running first time
        if not self.initDone then skipUpdate = false end
        CHC_view.initTypesAndCategories(self, typeField, categoryField)
        CHC_view.refreshObjList(self, objs)
        if skipUpdate then return end
    end

    local filtered = {}
    for i = 1, #objs do
        local obj = objs[i]

        local filters = {
            { name = "type",     func = CHC_view.objTypeFilter,       args = { obj[typeField] } },
            { name = "category", func = CHC_view.objCategoryFilter,   args = { obj[categoryField] } },
            { name = "search",   func = CHC_main.common.searchFilter, args = { obj, self.searchProcessToken } },
        }

        if extraFilters then
            for j = 1, #extraFilters do
                filters[#filters + 1] = extraFilters[j]
            end
        end
        local ok, filterStates = CHC_view.checkFilters(self, obj, filters)

        if ok then
            filtered[#filtered + 1] = obj
        end
        --types
        if filterStates.category and filterStates.search then
            local ic = obj[typeField]
            typCounts[ic] = typCounts[ic] and typCounts[ic] + 1 or 1
        end

        if filterStates.type and filterStates.search then
            -- categories
            local idc = obj[categoryField]
            if not catCounts[idc] then
                newCats[#newCats + 1] = idc
                catCounts[idc] = 1
            else
                catCounts[idc] = catCounts[idc] + 1
            end
        end
    end
    CHC_view.refreshObjList(self, filtered)

    if not defCatSelected then
        CHC_view.updateTypes(self, typCounts, curType)
    end
    local delayUpdateObj = false
    if not defTypeSelected then
        delayUpdateObj = CHC_view.updateCategories(self, catCounts, curCat, newCats)
    end
    if delayUpdateObj then
        CHC_view.updateObjects(self, typeField, categoryField)
    end
end

function CHC_view:updateTypes(typCounts, curType)
    --nullify counts
    for _, val in pairs(self.typeData) do val.count = 0 end
    local allTypeCnt = 0
    for typ, cnt in pairs(typCounts) do
        -- print(typ .. " | " .. cnt)
        self.typeData[typ].count = cnt
        allTypeCnt = allTypeCnt + cnt
    end
    self.typeData.all.count = allTypeCnt

    -- check if current has no entries and reset to default
    if curType ~= 'all' and self.typeData[curType].count == 0 then
        CHC_view.sortByType(self, 'all')
    end
end

function CHC_view:updateCategories(catCounts, curCat, newCats)
    local selCatData = self.categoryData[curCat]
    local selector = self.filterRow.categorySelector
    local defCatSelected = curCat == self.defaultCategory

    --nullify counts
    for _, val in pairs(self.categoryData) do val.count = 0 end
    local allCatCnt = 0
    for cat, cnt in pairs(catCounts) do
        if not self.categoryData[cat] then
            self.categoryData[cat] = { count = 0 }
        end
        self.categoryData[cat].count = cnt
        allCatCnt = allCatCnt + cnt
    end
    self.categoryData[self.defaultCategory].count = allCatCnt

    -- check if current has no entries and reset to default
    local delayUpdateObj = false
    if not defCatSelected and selCatData.count == 0 then
        self.selectedCategory = self.defaultCategory
        delayUpdateObj = true
    end
    -- remove existing categories all fill new ones
    selector:clear()
    selector:addOptionWithData(self.defaultCategory, { count = self.categoryData[self.defaultCategory].count })
    sort(newCats)
    for i = 1, #newCats do
        selector:addOptionWithData(newCats[i], { count = catCounts[newCats[i]] })
    end

    selector:select(self.selectedCategory)
    return delayUpdateObj
end

function CHC_view:updateTabNameWithCount(listSize)
    listSize = listSize or self.objListSize
    self.backRef.updateQueue:push({
        targetViews = { self.ui_type },
        actions = { 'needUpdateSubViewName' },
        data = { needUpdateSubViewName = listSize }
    })
end

function CHC_view:refreshObjList(objects, conditions)
    -- local function sort_on_values(t, a)
    --     sort(t, function(u, v)
    --         for i = 1, #a do
    --             if u[a[i]] and v[a[i]] then
    --                 if u[a[i]] > v[a[i]] then return false end
    --                 if u[a[i]] < v[a[i]] then return true end
    --             end
    --             return false
    --         end
    --     end)
    -- end

    local objL = self.objList
    local wasSelectedId = objL.items[objL.selected]
    if wasSelectedId then
        wasSelectedId = wasSelectedId.item._id
    end
    objL:clear()

    for i = 1, #objects do
        self:processAddObjToObjList(objects[i], CHC_menu.playerModData)
    end
    if self.isItemView then
        sort(objL.items, function(a, b) return a.text < b.text end)
    else
        sort(objL.items, function(a, b) return a.item.recipeData.name < b.item.recipeData.name end)
    end
    -- if not conditions then
    -- else
    --     sort_on_values(objL.items, conditions)
    -- end

    self.objListSize = #objL.items


    if #objL.items == 0 then return end
    local ix
    local ensureVisible = false
    for i = 1, #objL.items do
        if objL.items[i].item._id == wasSelectedId then
            ix = i
            break
        end
    end
    if not ix then
        ensureVisible = true
        ix = 1
    end
    objL.selected = ix
    if ensureVisible then objL:ensureVisible(ix) end
    self.objPanel:setObj(objL.items[ix].item)
end

function CHC_view:handleFavorites(fav_ui_type)
    if self.ui_type == fav_ui_type then
        self.objSource = self.backRef[self.objGetter](self, true)
        self:updateObjects()
        CHC_view.updateTabNameWithCount(self)
    else
        self.backRef.updateQueue:push({
            targetViews = { fav_ui_type },
            actions = { 'needUpdateFavorites', 'needUpdateObjects' }
        })
    end
end

local modifierOptionToKey = {
    [1] = 'none',
    [2] = 'CTRL',
    [3] = 'SHIFT',
    [4] = 'CTRL + SHIFT'
}

---@return string text
function CHC_view:createInfoText()
    local text = "<H1><LEFT> " .. getText("UI_InfoTitle") .. " <TEXT>\n\n"
    if not CHC_settings or not CHC_settings.keybinds then return text end
    local extra_map = {
        move_up = "recipe_selector_modifier",
        move_down = "recipe_selector_modifier",
        move_left = "category_selector_modifier",
        move_right = "category_selector_modifier",
        move_tab_left = "tab_selector_modifier",
        move_tab_right = "tab_selector_modifier",
        close_tab = "tab_close_selector_modifier"
    }
    for name, data in pairs(CHC_settings.keybinds) do
        local extra_key = modifierOptionToKey[CHC_settings.config[extra_map[name]]]
        if not extra_key or extra_key == "none" then
            extra_key = ""
        else
            extra_key = extra_key .. " + "
        end
        text = text .. " <LEFT> " .. getText("UI_optionscreen_binding_" .. data.name)
        text = text ..
            ": \n<RGB:0.3,0.9,0.3><CENTER> " .. extra_key .. Keyboard.getKeyName(data.key) .. " <RGB:0.9,0.9,0.9>\n"
    end
    return text
end

function CHC_view:updateInfoBtnTooltip()
    ISButton.updateTooltip(self)
    if not self.tooltipUI then return end
    local window = self.parent.backRef
    self.tooltipUI.maxLineWidth = 600
    self.tooltipUI:setDesiredPosition(window.x, self:getAbsoluteY() - 300)
    self.tooltipUI.adjustPositionToAvoidOverlap = CHC_view.adjustPositionToAvoidOverlap
end

function CHC_view:adjustPositionToAvoidOverlap(avoidRect)
    local myRect = { x = self.x, y = self.y, width = self.width, height = self.height }

    if self.contextMenu and not self.contextMenu.joyfocus and self.contextMenu.currentOptionRect then
        myRect.y = avoidRect.y
        local r = self:placeLeft(myRect, avoidRect)
        if self:overlaps(r, avoidRect) then
            r = self:placeRight(myRect, avoidRect)
            if self:overlaps(r, avoidRect) then
                r = self:placeAbove(myRect, avoidRect)
            end
        end
        self:setX(r.x)
        self:setY(r.y)
        return
    end

    if self:overlaps(myRect, avoidRect) then
        local r = self:placeLeft(myRect, avoidRect)
        if self:overlaps(r, avoidRect) then
            r = self:placeAbove(myRect, avoidRect)
            if self:overlaps(r, avoidRect) then
                r = self:placeRight(myRect, avoidRect)
            end
        end
        self:setX(r.x)
        self:setY(r.y)
    end
end

-- endregion

-- region render
function CHC_view:render()
    ISPanel.render(self)
    if self.needUpdateScroll then
        self.objList.needUpdateScroll = true
        self.objPanel.needUpdateScroll = true
        self.needUpdateScroll = false
    end
    if self.needUpdateMousePos then
        self.objList.needUpdateMousePos = true
        self.objPanel.needUpdateMousePos = true
        self.needUpdateMousePos = false
    end
end

function CHC_view:onResize()
    CHC_view.onResizeHeaders(self)
end

function CHC_view:onResizeHeaders()
    if self.removeAllFavBtn:isVisible() then
        self.searchRow:setWidth(self.headers.nameHeader.width - self.removeAllFavBtn.width)
        self.removeAllFavBtn:setX(self.searchRow.width)
    else
        self.searchRow:setWidth(self.headers.nameHeader.width)
    end
    self.filterRow:setWidth(self.headers.nameHeader.width - self.infoButton.width)
    self.infoButton:setX(self.filterRow.x + self.filterRow.width)

    self.objList:setWidth(self.headers.nameHeader.width)
    self.objPanel:setX(self.headers.typeHeader.x)
    self.objPanel:setWidth(self.headers.typeHeader.width)
    local asw, _ = self.backRef:getActiveSubView()
    if asw.view == self then
        local bottomPanelCS = self.backRef.bottomPanel.categorySelector
        bottomPanelCS:setWidth(self.headers.nameHeader.width - bottomPanelCS.x)
    end
end

-- endregion

-- region logic
function CHC_view:onObjectChange(obj)
    self.objPanel:setObj(obj)
    self.objList:onMouseDownObj(self.objList.mouseX, self.objList.mouseY)
end

function CHC_view:onChangeCategory(_option, sl)
    self.parent.selectedCategory = sl or _option.options[_option.selected].text
    self.parent.needUpdateObjects = true
end

function CHC_view:onProcessSearch()
    self.needUpdateObjects = true
end

function CHC_view:onTextChange()
    CHC_view.onProcessSearch(self)
end

function CHC_view:onCommandEntered()
    CHC_view.onProcessSearch(self)
end

function CHC_view:onFilterTypeMenu(button)
    local data = {}
    for typ, d in pairs(self.parent.typeData) do
        local icon = d.icon
        if not icon and d.item then
            CHC_main.common.cacheTex(d.item)
            icon = d.item.texture
        end
        data[#data + 1] = { txt = d.tooltip, num = d.count, arg = typ, icon = icon }
    end

    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 10, y)

    local txt
    for i = 1, #data do
        -- print(data[i].num)
        if data[i].num and data[i].num > 0 then
            txt = CHC_view.filterSortMenuGetText(data[i].txt, data[i].num)
            local opt = context:addOption(txt, self.parent, CHC_view.sortByType, data[i].arg)
            opt.iconTexture = data[i].icon
        end
    end
end

function CHC_view.filterSortMenuGetText(textStr, value)
    local txt = getTextOrNull(textStr) or textStr
    if value then
        txt = txt .. ' (' .. tostring(value) .. ')'
    end
    return txt
end

function CHC_view:objTypeFilter(condition)
    return self.typeFilter == 'all' or self.typeFilter == condition
end

function CHC_view:objCategoryFilter(condition)
    return self.selectedCategory == self.defaultCategory or self.selectedCategory == condition
end

function CHC_view:sortByType(_type)
    if _type ~= self.typeFilter then
        self.typeFilter = _type
        self.filterRow.filterTypeBtn:setTooltip(self:filterTypeSetTooltip())
        self.filterRow.filterTypeBtn:setImage(CHC_view.filterTypeSetIcon(self))
        self.needUpdateObjects = true
        self.needUpdateFavorites = true
    end
end

function CHC_view:filterTypeSetIcon()
    local entry = self.typeData[self.typeFilter]
    if not entry then return end
    if not entry.icon and not entry.item.texture then CHC_main.common.cacheTex(entry.item) end
    return entry.item and entry.item.texture or entry.icon
end

function CHC_view:onRemoveAllFavBtnClick()
    local function onModalBtnClick(_, button)
        if button.internal == "YES" then
            -- calls function from CHC_item/recipe_view
            self:onRemoveAllFavBtnClick()
        end
    end
    local params = {
        _parent = self.backRef,
        type = ISModalDialog,
        text = getText("UI_Presets_Unfavorite_All",
            CHC_main.common.getCurrentUiTypeLocalized(self.backRef):lower()),
        yesno = true,
        onclick = onModalBtnClick,
    }
    if self.modalAllFav then
        self.modalAllFav:destroy()
        self.modalAllFav = nil
    end
    self.modalAllFav = CHC_main.common.addModal(params)
end

-- endregion


--region objlist
function CHC_view._list:onMouseWheel(del, scrollSpeed)
    scrollSpeed = scrollSpeed or 18
    local yScroll = self.smoothScrollTargetY or self.yScroll
    local topRow = self:rowAt(0, -yScroll)
    if isShiftKeyDown() then
        local oldsel = self.selected
        if del < 0 then
            self.selected = self.selected - (isCtrlKeyDown() and 10 or 1)
            -- end
            if self.selected <= 0 then
                self.selected = #self.items
            end
        else
            self.selected = self.selected + (isCtrlKeyDown() and 10 or 1)
            --end
            if self.selected > #self.items then
                self.selected = 1
            end
        end

        local selectedItem = self.items[self.selected]
        if selectedItem and oldsel ~= self.selected then
            self:ensureVisible(self.selected)
            if self.parent.objPanel then
                self.parent.objPanel:setObj(selectedItem.item)
            end
            return true
        end
    end
    if self.items[topRow] then
        if not self.smoothScrollTargetY then self.smoothScrollY = self.yScroll end
        local y = self:topOfItem(topRow)
        if del < 0 then
            if yScroll == -y and topRow > 1 then
                local prev = self:prevVisibleIndex(topRow)
                y = self:topOfItem(prev)
            end
            self.smoothScrollTargetY = -y;
        else
            self.smoothScrollTargetY = -(y + self.items[topRow].height);
        end
    else
        self.yScroll = self.yScroll - (del * scrollSpeed)
    end
    return true;
end

function CHC_view._list:isMouseOverFavorite(x)
    return (x >= self.width - 40) and not self:isMouseOverScrollBar()
end

function CHC_view._list:prerender()
    if not self.items or #self.items == 0 then return end

    self.yScroll = self:getYScroll()
    self.mouseX = self:getMouseX()
    self.mouseY = self:getMouseY()

    if not self.listHeight then self.listHeight = 0 end
    if not self.curFontData then
        self.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
        if not self.curFontData then
            self.curFontData = { font = UIFont.Small, icon = 20, pad = 3 }
        end
    end
    if not self.fontSize then
        self.fontSize = getTextManager():getFontHeight(self.curFontData.font)
    end

    CHC_view._list.recalcIndexes(self)
    local ms = getTimestampMs()
    if not self.recalcMs or not self.recalcScrollMs or not self.minJ then
        CHC_view._list.recalcItems(self)
        self.prevItems = #self.items
        self.prevUncollapsedNum = self.uncollapsedNum or 0
        self.recalcMs = ms
        self.recalcScrollMs = ms
    end
    local changedItemNum = #self.items ~= self.prevItems
    local changedUncollapsedNum = self.uncollapsedNum ~= self.prevUncollapsedNum

    if changedItemNum or changedUncollapsedNum or self.prevItems < 1000 or ms - self.recalcScrollMs >= 500 * (#self.items / 1000) then
        self:setScrollHeight(self.listHeight or 0)
        self.recalcScrollMs = ms
    end

    if changedItemNum or changedUncollapsedNum or self.prevItems < 1000 or ms - self.recalcMs >= 1000 * (#self.items / 1000) then
        CHC_view._list.recalcItems(self)
        self.prevItems = #self.items
        self.recalcMs = ms
    end
    self:updateTooltip()
    self:updateSmoothScrolling()
end

function CHC_view._list:recalcIndexes()
    self.minJ = floor(-self.yScroll / self.itemheight)
    self.maxJ = ceil((-self.yScroll + self.height) / self.itemheight)
    if self.minJ < 1 then self.minJ = 1 end
    if self.maxJ > #self.items then self.maxJ = #self.items end
end

function CHC_view._list:recalcItems()
    local y = 0
    local indexes = {}
    local data = {
        uncollapsedNum = 0,
        collapsedBlock = nil,
        hiddenBlock = {}
    }
    for j = 1, #self.items do
        local item = self.items[j]
        item.index = j
        if not item.height then item.height = self.itemheight end

        -- determine needed indexes
        if item.item.sourceNum then
            if item.item.multipleHeader then
                if item.item.collapsed then
                    data.collapsedBlock = item.item.sourceNum
                end
                if item.item.isBlockHidden then
                    data.hiddenBlock = { num = item.item.sourceNum, state = item.item.blockHiddenState }
                end
                y = y + item.height
                indexes[#indexes + 1] = j
                data.uncollapsedNum = data.uncollapsedNum + 1
            else
                if item.item.collapsed or item.item.sourceNum == data.collapsedBlock or
                    (item.item.sourceNum == data.hiddenBlock.num and data.hiddenBlock.state == "un" and item.item.available) or
                    (item.item.sourceNum == data.hiddenBlock.num and data.hiddenBlock.state == "av" and not item.item.available) then
                    -- print("Hidden " .. item.text .. "; sourceNum: " .. item.item.sourceNum)
                else
                    y = y + item.height
                    indexes[#indexes + 1] = j
                    data.uncollapsedNum = data.uncollapsedNum + 1
                end
            end
        else
            y = y + item.height
            indexes[#indexes + 1] = j
            data.uncollapsedNum = data.uncollapsedNum + 1
        end
    end
    self.listHeight = y
    self.uncollapsedNum = data.uncollapsedNum

    self._indexes = indexes
end

function CHC_view._list:render()
    -- if true then return end
    if not self._indexes then return end
    local sX = 0
    local sY = 0
    local sX2 = self.width
    local sY2 = self.height

    if self.drawBorder then
        sX = 1
        sY = 1
        sX2 = self.width - 1
        sY2 = self.height - 1
    end

    if self:isVScrollBarVisible() then
        sX2 = self.vscroll.x + 3 -- +3 because the scrollbar texture is narrower than the scrollbar width
    end

    self:clampStencilRectToParent(sX, sY, sX2, sY2)
    for j = 1, #self._indexes do
        local _ix = self._indexes[j]
        local item = self.items[_ix]
        if item and not item.item.texture then CHC_main.common.cacheTex(item.item) end
        if item and (
                (_ix >= self.minJ and _ix <= self.maxJ) or
                (self._internal and self._internal == "ingredientPanel")
            ) then
            self:doDrawItem((j - 1) * self.itemheight, item, false)
        end
    end
    self:clearStencilRect()

    if self.vscroll and self.vscroll.height ~= self.height then
        self.vscroll:setHeight(self.height)
    end
end

--endregion
