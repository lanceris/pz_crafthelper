-- ISSectionedPanel
CHC_sectioned_panel = ISPanel:derive('CHC_sectioned_panel')

-----

CHC_sectioned_panel_section = ISPanel:derive('CHC_sectioned_panel_section')
local CHC_section = CHC_sectioned_panel_section

--region section

function CHC_section:createChildren()
    self.headerButton = ISButton:new(0, 0, self.width, 24, self.title, self, self.onHeaderClick)
    self.headerButton:initialise()
    self.headerButton:setFont(UIFont.Small)
    self.headerButton.backgroundColor = { r = 0.44, g = 0.44, b = 0.79, a = 0.6 }
    self.headerButton.backgroundColorMouseOver = { r = 0.44, g = 0.44, b = 0.79, a = 0.8 }
    self.headerButton.borderColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 }
    self:addChild(self.headerButton)

    if self.panel then
        self.panel:setY(self.headerButton:getBottom())
        self.panel:setWidth(self.width - 20)
        -- self.panel:setHeight(self.maxH)
        self.panel:setVisible(self.expanded)
        self.panel:setScrollChildren(true)
        self:addChild(self.panel)
        local objList = self.panel.objList
        if objList then
            local numItems = 8
            local mul = math.min(#objList.items, numItems)
            local panelListH = objList.itemheight * mul
            objList:setHeight(panelListH)
            self.panel:setHeight(
                3 * self.panel.padY +
                self.panel.searchRow.height +
                objList.itemheight +
                objList.height
            )
            if #objList.items > numItems then
                objList.vscroll:setVisible(true)
                objList.vscroll:setHeight(objList.itemheight * numItems)
            end
            objList:setScrollHeight(objList.itemheight * numItems)
        end
    end

    self:calculateHeights()
end

function CHC_section:onHeaderClick()
    self.expanded = not self.expanded
    if self.expanded then
        self.parent.expandedSections[self.title] = true
    else
        self.parent.expandedSections[self.title] = nil
    end
    self:calculateHeights()
end

function CHC_section:calculateHeights()
    local height = self.headerButton:getHeight()
    if self.panel then
        self.panel:setVisible(self.expanded)
        if self.expanded then
            height = height + self.panel:getHeight()
        end
    end
    self:setHeight(height)
end

function CHC_section:onResize()
    self:setWidth(self.parent.width)
    self.headerButton:setWidth(self.parent.width)
    self.panel:setWidth(self.parent.width - 10)
    self:calculateHeights()
end

function CHC_section:clear()
    self.enabled = false
end

function CHC_section:prerender()
    if self.panel and self.panelHeight ~= self.panel.height then
        self.panelHeight = self.panel.height
        self:calculateHeights()
    end
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

function CHC_section:new(x, y, width, height, panel, title, maxH)
    local o = {}
    o = ISPanel:new(x, y, width, height)

    setmetatable(o, self)
    self.__index = self
    o.panel = panel
    o.title = title and title or '???'
    o.enabled = true
    o.expanded = true
    o.maxHeight = maxH and maxH or 300
    return o
end

--endregion


--region section panel

-- function CHC_sectioned_panel:get(sectionTitle)

-- end

function CHC_sectioned_panel:addSection(panel, title, maxH)
    local sbarWid = self.vscroll and 17 or 0
    local section = CHC_section:new(0, 0, self.width - sbarWid, 1, panel, title, maxH)
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
    ISPanel.prerender(self)

    local sx, sy, sx2, sy2 = 0, 0, self.width, self.height
    if self.parent and self.parent:getScrollChildren() then
        sx = self.javaObject:clampToParentX(self:getAbsoluteX() + sx) - self:getAbsoluteX()
        sx2 = self.javaObject:clampToParentX(self:getAbsoluteX() + sx2) - self:getAbsoluteX()
        sy = self.javaObject:clampToParentY(self:getAbsoluteY() + sy) - self:getAbsoluteY()
        sy2 = self.javaObject:clampToParentY(self:getAbsoluteY() + sy2) - self:getAbsoluteY()
    end
    self:setStencilRect(sx, sy, sx2 - sx, sy2 - sy)
end

function CHC_sectioned_panel:render()
    self:clearStencilRect()
    ISPanel.render(self)
end

function CHC_sectioned_panel:onMouseWheel(del)
    for _, section in ipairs(self.sections) do
        local panel = section.panel
        if panel:isMouseOver() then
            if panel.objList and panel.objList:isVScrollBarVisible() then
                panel.objList.onMouseWheel(panel.objList, del)
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

    o.backRef = args.backRef
    o.backgroundColor.a = 0.8
    o.sections = {}
    o.sectionMap = {}
    o.expandedSections = {}
    o.activeSection = nil
    o.maintainHeight = true
    return o
end

--endregion
