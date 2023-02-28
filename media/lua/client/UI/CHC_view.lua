CHC_view = ISPanel:derive('CHC_view')

local sort = table.sort

-- region create

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
        self.objList.shouldShowIcons = CHC_settings.config.show_icons
        self.needUpdateShowIcons = false
    end
    if self.needUpdateObjects then
        self:updateObjects(self.selectedCategory)
        CHC_view.updateTabNameWithCount(self)
        self.needUpdateObjects = false
    end
    if self.needUpdateFavorites then
        self:handleFavorites()
        self.needUpdateFavorites = false
    end
    if self.needUpdateTypes then
        self:updateTypes()
        self.needUpdateTypes = false
    end
    if self.needUpdateCategories then
        self:updateCategories()
        self.needUpdateCategories = false
    end
end

function CHC_view:updateTabNameWithCount(listSize)
    listSize = listSize and listSize or self.objListSize
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

function CHC_view:onTextChange()
    self.needUpdateObjects = true
    self.needUpdateCategories = true
    self.needUpdateTypes = true
end

function CHC_view:onFilterTypeMenu(button, data, typeSortFunc)
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 10, y)

    local txt
    for i = 1, #data do
        if data[i].num and data[i].num > 0 then
            txt = CHC_view.filterSortMenuGetText(data[i].txt, data[i].num)
            context:addOption(txt, self, typeSortFunc, data[i].arg)
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
