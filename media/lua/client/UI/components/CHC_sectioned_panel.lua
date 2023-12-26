local utils = require("CHC_utils")
-- ISSectionedPanel
CHC_sectioned_panel = ISPanel:derive('CHC_sectioned_panel')

-----

CHC_sectioned_panel_section = ISPanel:derive('CHC_sectioned_panel_section')
local CHC_section = CHC_sectioned_panel_section

--region section

function CHC_section:createChildren()
    local btnH = utils.strHeight(self.font, self.title) + 2 * self.padY
    if btnH < 24 then btnH = 24 end
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
    self.panel.borderColor.a = 0.3

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
    local maxItems = #panel.objList.items
    if maxItems > 9 then maxItems = 9 end
    return 3 * panel.padY + panel.searchRow.height + maxItems * panel.objList.itemheight
end

function CHC_section:calcHeightList(objList, maxItems)
    local numItems = #objList.items
    if self.panel.uncollapsedNum then
        numItems = self.panel.uncollapsedNum
    end
    if numItems > maxItems then numItems = maxItems end
    return numItems * objList.itemheight
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
    self:clampStencilRectToParent(0, 0, self.width, self.height)
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
    o.padX = 0
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
    o.headerBgColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.2 }
    o.headerBgColorMouseOver = { r = 0.25, g = 0.25, b = 0.25, a = 0.4 }
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
    self.sections[#self.sections + 1] = section
    self.sectionMap[title] = section
end

function CHC_sectioned_panel:clear()
    local children = {}
    for k, v in pairs(self:getChildren()) do
        children[#children + 1] = v
    end
    for i = 1, #children do
        self:removeChild(children[i])
    end
    for i = 1, #self.sections do
        self.sections[i]:clear()
    end
    self.sections = {}
    self.sectionMap = {}
end

function CHC_sectioned_panel:expandSection(sectionTitle)
    for i = 1, #self.sections do
        local section = self.sections[i]
        if section.title == sectionTitle then
            section.expanded = true
        end
    end
end

function CHC_sectioned_panel:prerender()
    ISPanel.prerender(self)
    local y = 0
    for i = 1, #self.sections do
        local section = self.sections[i]
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

    self:updateScrollbars()
end

function CHC_sectioned_panel:onResize()
    self:updateScrollbars()
end

function CHC_sectioned_panel:onMouseWheel(del)
    for i = 1, #self.sections do
        local panel = self.sections[i].panel
        if panel:isMouseOver() then
            local vscroll = panel.objList and panel.objList.vscroll or panel.vscroll
            if vscroll and vscroll:isReallyVisible() then
                if (vscroll.pos > 0 and del == -1) or (vscroll.pos < 1 and del == 1) then
                    return false
                end
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
    o.backgroundColor.a = 0
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
