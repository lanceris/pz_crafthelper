CHC_view = {}
CHC_view._list = {}
local sort = table.sort
local insert = table.insert
local utils = require('CHC_utils')

-- region create
function CHC_view:create(filterRowOrderOnClickArgs, mainPanelsData)
    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, CHC_main.common.heights.headers, { CHC_view.onResizeHeaders, self },
        self.sep_x)
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
            width = CHC_main.common.heights.filter_row,
            title = '',
            onclick = CHC_view.sortByName,
            onclickargs = filterRowOrderOnClickArgs,
            defaultTooltip = CHC_view.filterOrderSetTooltip(self),
            defaultIcon = CHC_view.filterOrderSetIcon(self)
        },
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
        { x = x, y = y, w = leftW, h = CHC_main.common.heights.filter_row, backRef = self.backRef }, filterRowData)
    self.filterRow:initialise()
    local leftY = y + CHC_main.common.heights.filter_row
    --endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new(
        { x = x, y = leftY, w = leftW, h = CHC_main.common.heights.search_row, backRef = self.backRef },
        self.searchBarTooltip,
        self.onTextChange, self.searchRowHelpText, self.onCommandEntered)
    self.searchRow:initialise()
    if self.delayedSearch then self.searchRow:setTooltip(self.searchBarDelayedTooltip) end

    leftY = leftY + self.searchRow.height
    -- endregion

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

    -- Add entries to recipeList
    local iph = self.height - self.headers.height
    self.objPanel = mainPanelsData.panelCls:new({ x = rightX, y = y, w = rightW, h = iph, backRef = self.backRef })
    self.objPanel:initialise()
    self.objPanel:instantiate()
    self.objPanel:setAnchorLeft(true)
    self.objPanel:setAnchorBottom(true)

    -- endregion

    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.objList)
    self:addChild(self.objPanel)
end

-- endregion

-- region update

function CHC_view:update()
    if self.needUpdateFont then
        self.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
        self.objList.curFontData = self.curFontData
        if self.objList.font ~= self.curFontData.font then
            self.objList:setFont(self.curFontData.font, self.curFontData.pad)
            self.objList.fontSize = getTextManager():getFontHeight(self.curFontData.font)
        end
        self.needUpdateFont = false
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
    if self.needUpdateTypes then
        self.needUpdateTypes = false
        self:updateTypes()
    end
    if self.needUpdateCategories then
        self.needUpdateCategories = false
        self:updateCategories()
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
end

function CHC_view:updateObjects(categoryField)
    local defCategorySelected = self.selectedCategory == self.defaultCategory
    local defTypeSelected = self.typeFilter == 'all'
    local searchBarEmpty = self.searchRow.searchBar:getInternalText() == ''

    if defCategorySelected and defTypeSelected and searchBarEmpty then
        CHC_view.refreshObjList(self, self.objSource)
        return
    end

    local filtered = {}
    for i = 1, #self.objSource do
        local obj = self.objSource[i]

        local type_filter_state = false
        local search_state = false

        if (obj.displayCategory == self.selectedCategory or defCategorySelected) then
            type_filter_state = CHC_view.objTypeFilter(self, obj[categoryField])
        end
        search_state = CHC_main.common.searchFilter(self, obj, self.searchProcessToken)

        if type_filter_state and search_state then
            insert(filtered, obj)
        end
    end
    CHC_view.refreshObjList(self, filtered)
end

function CHC_view:updateTabNameWithCount(listSize)
    listSize = listSize or self.objListSize
    self.backRef.updateQueue:push({
        targetView = self.ui_type,
        actions = { 'needUpdateSubViewName' },
        data = { needUpdateSubViewName = listSize }
    })
end

function CHC_view:refreshObjList(objects)
    local objL = self.objList
    local wasSelectedId = objL.items[objL.selected]
    if wasSelectedId then
        wasSelectedId = wasSelectedId.item._id
    end
    objL:clear()

    for i = 1, #objects do
        self:processAddObjToObjList(objects[i], self.modData)
    end
    sort(objL.items, self.itemSortFunc)
    if objL.items and #objL.items > 0 then
        local ix
        local ensureVisible = false
        for i = 1, #objL.items do
            if objL.items[i].item._id == wasSelectedId then
                ix = i
                break
            end
        end
        if ix then
        else
            ensureVisible = true
            ix = 1
        end
        objL.selected = ix
        if ensureVisible then objL:ensureVisible(ix) end
        self.objPanel:setObj(objL.items[ix].item)
    end

    self.objListSize = #objL.items
end

function CHC_view:updateTypes(categoryField)
    local typCounts = {}
    local objs
    local suff = false
    local currentCategory = self.selectedCategory
    local defCategorySelected = self.selectedCategory == self.defaultCategory
    if self.searchRow.searchBar:getInternalText() == "" then
        objs = self.objSource
    else
        objs = self.objList.items
        suff = true
        if not objs or utils.empty(objs) then
            objs = self.objSource
            suff = false
        end
    end
    for _, val in pairs(self.typeData) do
        val.count = 0
    end
    for i = 1, #objs do
        local obj = suff and objs[i].item or objs[i]
        local ic = obj[categoryField]
        local idc = obj.displayCategory
        if idc == currentCategory or defCategorySelected then
            if not typCounts[ic] then
                typCounts[ic] = 1
            else
                typCounts[ic] = typCounts[ic] + 1
            end
        end
    end

    local allcnt = 0
    for typ, cnt in pairs(typCounts) do
        self.typeData[typ].count = cnt
        allcnt = allcnt + cnt
    end
    self.typeData.all.count = allcnt


    if self.typeFilter ~= 'all' and self.typeData[self.typeFilter].count == 0 then
        CHC_view.sortByType(self, 'all')
    end
    if self.typeDataPrev ~= self.typeData then
        self.needUpdateObjects = true
    end
    self.typeDataPrev = self.typeData
end

function CHC_view:updateCategories(categoryField)
    local catCounts = {}
    local newCats = {}
    local selector = self.filterRow.categorySelector
    local objs
    local suff = false
    local currentType = self.typeFilter
    local defTypeSelected = self.typeFilter == 'all'

    if self.searchRow.searchBar:getInternalText() == "" then
        objs = self.objSource
    else
        objs = self.objList.items
        suff = true
        if not objs or utils.empty(objs) then
            objs = self.objSource
            suff = false
        end
    end

    for i = 1, #objs do
        local obj = suff and objs[i].item or objs[i]
        local ic = obj[categoryField]
        local idc = obj.displayCategory
        if ic == currentType or defTypeSelected then
            if not catCounts[idc] then
                insert(newCats, idc)
                catCounts[idc] = 1
            else
                catCounts[idc] = catCounts[idc] + 1
            end
        end
    end

    selector:clear()
    selector:addOptionWithData(self.defaultCategory, { count = self.typeData.all.count })
    sort(newCats)
    for i = 1, #newCats do
        selector:addOptionWithData(newCats[i], { count = catCounts[newCats[i]] })
    end

    selector:select(self.selectedCategory)
end

function CHC_view:handleFavorites(fav_ui_type)
    if self.ui_type == fav_ui_type then
        self.objSource = self.backRef[self.objGetter](self, true)
        self.needUpdateObjects = true
    else
        self.backRef.updateQueue:push({
            targetView = fav_ui_type,
            actions = { 'needUpdateFavorites', 'needUpdateObjects', 'needUpdateTypes' }
        })
    end
    self.needUpdateCategories = true
    self.needUpdateTypes = true
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

function CHC_view:onResizeHeaders()
    self.filterRow:setWidth(self.headers.nameHeader.width)
    self.searchRow:setWidth(self.headers.nameHeader.width)
    self.objList:setWidth(self.headers.nameHeader.width)
    self.objPanel:setWidth(self.headers.typeHeader.width)
    self.objPanel:setX(self.headers.typeHeader.x)
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
    self.parent.needUpdateTypes = true
end

function CHC_view:onProcessSearch()
    self.needUpdateObjects = true
    self.needUpdateCategories = true
    self.needUpdateTypes = true
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
        insert(data, { txt = d.tooltip, num = d.count, arg = typ })
    end

    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 10, y)

    local txt
    for i = 1, #data do
        if data[i].num and data[i].num > 0 then
            txt = CHC_view.filterSortMenuGetText(data[i].txt, data[i].num)
            context:addOption(txt, self.parent, CHC_view.sortByType, data[i].arg)
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
    return self.typeFilter == 'all' and true or self.typeFilter == condition
end

function CHC_view:filterOrderSetTooltip()
    local cursort = self.itemSortAsc and getText('IGUI_invpanel_ascending') or getText('IGUI_invpanel_descending')
    return getText('UI_settings_st_title') .. ' (' .. cursort .. ')'
end

function CHC_view:filterOrderSetIcon()
    return self.itemSortAsc and self.sortOrderIconAsc or self.sortOrderIconDesc
end

function CHC_view:sortByName(cls, ascFunc, descFunc)
    local self = cls.parent.parent
    self.itemSortAsc = not self.itemSortAsc
    self.itemSortFunc = self.itemSortAsc and ascFunc or descFunc

    local newIcon = CHC_view.filterOrderSetIcon(self)
    local newTooltip = CHC_view.filterOrderSetTooltip(self)
    self.filterRow.filterOrderBtn:setImage(newIcon)
    self.filterRow.filterOrderBtn:setTooltip(newTooltip)
    self.needUpdateObjects = true
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
    return self.typeData[self.typeFilter].icon
end

-- endregion


--region objlist
function CHC_view._list:isMouseOverFavorite(x)
    return (x >= self.width - 40) and not self:isMouseOverScrollBar()
end

function CHC_view._list:prerender()
    if not self.items then return end
    if utils.empty(self.items) then return end

    if self.items and self.parent.objListSize > 1000 then
        if self.needUpdateScroll then
            self.yScroll = self:getYScroll()
            self.needUpdateScroll = false
        end
        if self.needUpdateMousePos then
            self.mouseX = self:getMouseX()
            self.mouseY = self:getMouseY()
            self.needUpdateMousePos = false
        end
    else
        self.yScroll = self:getYScroll()
        self.mouseX = self:getMouseX()
        self.mouseY = self:getMouseY()
    end

    local stencilX = 0
    local stencilY = 0
    local stencilX2 = self.width
    local stencilY2 = self.height

    local bg = {
        x = 0,
        y = -self.yScroll,
        w = self.width,
        h = self.height,
        a = self.backgroundColor.a,
        r = self.backgroundColor.r,
        g = self.backgroundColor.g,
        b = self.backgroundColor.b
    }
    self:drawRect(bg.x, bg.y, bg.w, bg.h, bg.a, bg.r, bg.g, bg.b)

    if self.drawBorder then
        self:drawRectBorder(0, -self.yScroll, self.width, self.height, self.borderColor.a, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
        stencilX = 1
        stencilY = 1
        stencilX2 = self.width - 1
        stencilY2 = self.height - 1
    end

    if self:isVScrollBarVisible() then
        stencilX2 = self.vscroll.x + 3 -- +3 because the scrollbar texture is narrower than the scrollbar width
    end

    self:setStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)

    local y = 0
    local alt = false

    if self.selected ~= -1 and self.selected > #self.items then
        self.selected = #self.items
    end

    self.listHeight = 0
    local i = 1
    for j = 1, #self.items do
        self.items[j].index = i
        self.items[j].height = self.curFontData.icon + 2 * self.curFontData.pad
        if not self.parent.isItemView and
            CHC_settings.config.show_recipe_module and
            self.items[j].item.module ~= 'Base' then
            self.items[j].height = self.items[j].height + self.fontSize - self.curFontData.pad
        end
        local y2 = self:doDrawItem(y, self.items[j], alt)
        self.listHeight = y2
        self.items[j].height = y2 - y
        y = y2
        --alt = not alt
        i = i + 1
    end

    self:setScrollHeight((y))
    self:clearStencilRect()

    if self.doRepaintStencil then
        self:repaintStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)
    end

    local mouseY = self.mouseY
    self:updateSmoothScrolling()

    if mouseY ~= self.mouseY and self:isMouseOver() then
        self:onMouseMove(0, self.mouseY - mouseY)
    end
    self:updateTooltip()
end

--endregion
