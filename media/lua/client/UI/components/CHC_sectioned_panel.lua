-- ISSectionedPanel
CHC_sectioned_panel = ISPanel:derive('CHC_sectioned_panel')

-----

CHC_sectioned_panel_section = ISPanel:derive('CHC_sectioned_panel_section')
local CHC_section = CHC_sectioned_panel_section

--region section

function CHC_section:createChildren()
    local btnH = math.max(24, getTextManager():MeasureStringY(self.font, self.title) + 2 * self.padY)
    self.headerButton = ISButton:new(0, 0, self.headerButtonWidth, btnH, self.title, self,
        self.onHeaderClick)
    self.headerButton:initialise()
    self.headerButton:setFont(self.font)
    self.headerButton.backgroundColor = self.headerBgColor
    self.headerButton.backgroundColorMouseOver = self.headerBgColorMouseOver
    self.headerButton.borderColor = self.headerBorderColor
    self:addChild(self.headerButton)

    -- if self.panel then
    self.panel:setY(self.headerButton:getBottom())
    self.panel:setWidth(self.width)
    self.panel:setVisible(self.expanded)
    self.panel:setScrollChildren(true)

    self:addChild(self.panel)
    -- end
    self:calculateHeights()
end

function CHC_section:onHeaderClick()
    self.expanded = not self.expanded
    if self.expanded then
        self.parent.expandedSections[self.title] = true
    else
        self.parent.expandedSections[self.title] = nil
    end
    self.panel:setVisible(self.expanded)
    self:calculateHeights()
end

function CHC_section:calcHeightNonList(panel)
    local maxItems = 8
    return 3 * panel.padY +
        panel.searchRow.height +
        (math.min(#panel.objList.items, maxItems) + 1) * panel.objList.itemheight
end

function CHC_section:calcHeightList(objList, maxItems)
    local numItems = #objList.items
    if self.panel.uncollapsedNum then
        numItems = self.panel.uncollapsedNum
    end
    return math.min(numItems, maxItems) * objList.itemheight
end

function CHC_section:calculateHeights()
    local height = self.headerButton:getHeight()
    local panel = self.panel

    if self.expanded then
        local listH
        if panel.objList then   -- item panels (attributes etc)
            listH = self:calcHeightNonList(panel)
        else                    -- recipe panels (ingredients etc)
            local maxItems = 10 --FIXME allow configuration
            listH = self:calcHeightList(panel, maxItems)

            panel.vscroll:setVisible(#panel.items > maxItems)
            panel:setScrollHeight(listH)
        end
        panel:setHeight(listH)
        height = height + listH
    end
    self:setHeight(height)
end

function CHC_section:onResize()
    ISPanel.onResize(self)
    local parentSBarWid = self.parent.vscroll and self.parent.vscroll.width or 0
    self:setWidth(self.parent.width - parentSBarWid)
    self.headerButton:setWidth(self.width)
    self.panel:setWidth(self.width)
    if self.panel.vscroll then
        self.panel.vscroll:setX(self.width - 17)
    end
end

function CHC_section:clear()
    self.enabled = false
end

function CHC_section:prerender()
    local sx, sy, sx2, sy2 = 0, 0, self.width, self.height
    if true then
        sx = self.javaObject:clampToParentX(self:getAbsoluteX() + sx) - self:getAbsoluteX()
        sx2 = self.javaObject:clampToParentX(self:getAbsoluteX() + sx2) - self:getAbsoluteX()
        sy = self.javaObject:clampToParentY(self:getAbsoluteY() + sy) - self:getAbsoluteY()
        sy2 = self.javaObject:clampToParentY(self:getAbsoluteY() + sy2) - self:getAbsoluteY()
    end
    self:setStencilRect(sx, sy, sx2 - sx, sy2 - sy)
end

function CHC_section:render()
    self:clearStencilRect()
end

function CHC_section:new(x, y, width, height, panel, title, rightMargin, headerWidth)
    local o = {}
    o = ISPanel:new(x, y, width, height)

    setmetatable(o, self)
    self.__index = self
    o.font = UIFont.Small
    o.padX = 5
    o.padY = 3
    o.panel = panel
    o.title = title and title or '???'
    o.enabled = true
    o.expanded = true
    o.rightMargin = rightMargin
    o.headerWidth = headerWidth
    if headerWidth == 'text' then
        o.headerButtonWidth = 2 * o.padX + getTextManager():MeasureStringX(o.font, o.title)
    elseif headerWidth == 'fill' then
        o.headerButtonWidth = o.width
    else
        o.headerButtonWidth = headerWidth
    end
    o.headerBgColor = { r = 0.15, g = 0.15, b = 0.15, a = 0.8 }
    o.headerBgColorMouseOver = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 }
    o.headerBorderColor = { r = 1, g = 1, b = 1, a = 0.3 }
    return o
end

--endregion


--region section panel

-- function CHC_sectioned_panel:get(sectionTitle)

-- end

function CHC_sectioned_panel:initialise()
    ISPanel.initialise(self)
end

function CHC_sectioned_panel:addSection(panel, title)
    local sbarWid = self.vscroll and self.vscroll.width or 0
    local section = CHC_section:new(0, 0, self.width - sbarWid, 1,
        panel, title, self.rightMargin, self.headerWidth)
    self:addChild(section)
    if self:getScrollChildren() then
        section:setScrollWithParent(true)
        section:setScrollChildren(true)
    end
    table.insert(self.sections, section)
    self.sectionMap[title] = section
end

function CHC_sectioned_panel:clear()
    local children = {}
    for k, v in pairs(self:getChildren()) do
        table.insert(children, v)
    end
    for _, child in ipairs(children) do
        self:removeChild(child)
    end
    for _, section in ipairs(self.sections) do
        section:clear()
    end
    self.sections = {}
    self.sectionMap = {}
end

function CHC_sectioned_panel:expandSection(sectionTitle)
    for _, section in ipairs(self.sections) do
        if section.title == sectionTitle then
            section.expanded = true
        end
    end
end

function CHC_sectioned_panel:prerender()
    ISPanel.prerender(self)
    local y = 0
    for _, section in ipairs(self.sections) do
        if section.enabled then
            section:setVisible(true)
            section:setY(y)
            y = y + section:getHeight()
        else
            section:setVisible(false)
        end
    end
    if self.maintainHeight then
        self:setHeight(y)
    elseif self:getScrollChildren() then
        self:setScrollHeight(y)
    end

    local sx, sy, sx2, sy2 = 0, 0, self.width, self.height

    if self:isVScrollBarVisible() then
        sx2 = self.vscroll.x + 3 -- +3 because the scrollbar texture is narrower than the scrollbar width
    end

    if self.parent and self.parent:getScrollChildren() then
        sx = self.javaObject:clampToParentX(self:getAbsoluteX() + sx) - self:getAbsoluteX()
        sx2 = self.javaObject:clampToParentX(self:getAbsoluteX() + sx2) - self:getAbsoluteX()
        sy = self.javaObject:clampToParentY(self:getAbsoluteY() + sy) - self:getAbsoluteY()
        sy2 = self.javaObject:clampToParentY(self:getAbsoluteY() + sy2) - self:getAbsoluteY()
    end
    self:setStencilRect(sx, sy, sx2 - sx, sy2 - sy)

    self:updateScrollbars()
end

function CHC_sectioned_panel:render()
    ISPanel.render(self)
    self:clearStencilRect()
end

function CHC_sectioned_panel:onResize()
    self:updateScrollbars()
end

function CHC_sectioned_panel:onMouseWheel(del)
    for _, section in ipairs(self.sections) do
        local panel = section.panel
        if panel:isMouseOver() then
            if panel.objList and panel.objList:isVScrollBarVisible() then
                panel.objList.onMouseWheel(panel.objList, del)
                return false
            end
            if panel.items and panel:isVScrollBarVisible() then
                panel.onMouseWheel(panel, del)
                return false
            end
        end
    end

    self:setYScroll(self:getYScroll() - (del * 40))
    return true
end

function CHC_sectioned_panel:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)

    setmetatable(o, self)
    self.__index = self

    o.origY = args.y
    o.origH = args.h
    o.backRef = args.backRef
    o.backgroundColor.a = 0.8
    o.sections = {}
    o.sectionMap = {}
    o.expandedSections = {}
    o.activeSection = nil
    o.maintainHeight = true
    o.padY = 3
    o.rightMargin = args.rightMargin or 10
    o.headerWidth = args.headerWidth or 'fill' -- 'text', 'fill' or integer

    o.anchorTop = true
    o.anchorBottom = true
    o.anchorLeft = true
    o.anchorRight = false

    return o
end

--endregion
