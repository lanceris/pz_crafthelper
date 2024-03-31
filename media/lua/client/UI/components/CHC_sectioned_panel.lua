local utils = require("CHC_utils")
-- ISSectionedPanel
CHC_sectioned_panel = ISPanel:derive('CHC_sectioned_panel')

-----

CHC_sectioned_panel_section = ISPanel:derive('CHC_sectioned_panel_section')
local CHC_section = CHC_sectioned_panel_section

--region section

function CHC_section:initialise()
    ISPanel.initialise(self)
end

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
    self.headerButton.render = self.renderButton
    self:addChild(self.headerButton)
    self.headerButton.treeexpicon = CHC_window.icons.common.expanded
    self.headerButton.treecolicon = CHC_window.icons.common.collapsed
    self.headerButton.iconH = (self.headerButton.height / 2) - (self.headerButton.treeexpicon:getHeight() / 2)

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

function CHC_section:renderButton()
    local height = getTextManager():MeasureStringY(self.font, self.title)
    local x = 24;
    local tex
    if self.parent.expanded then
        tex = self.treeexpicon
    else
        tex = self.treecolicon
    end

    if tex then
        self:drawTexture(tex, 8, self.iconH, 1, 1, 1, 1)
    end

    if self.enable then
        self:drawText(self.title, x, (self.height / 2) - (height / 2) + self.yoffset, self.textColor.r, self.textColor.g,
            self.textColor.b, self.textColor.a, self.font);
    elseif self.displayBackground and not self.isJoypad and self.joypadFocused then
        self:drawText(self.title, x, (self.height / 2) - (height / 2) + self.yoffset, 0, 0, 0, 1, self.font);
    else
        self:drawText(self.title, x, (self.height / 2) - (height / 2) + self.yoffset, 0.3, 0.3, 0.3, 1, self.font);
    end
    if self.overlayText then
        self:drawTextRight(self.overlayText, self.width, self.height - 10, 1, 1, 1, 0.5, UIFont.Small);
    end
    -- call the onMouseOverFunction
    if (self.mouseOver and self.onmouseover) then
        self.onmouseover(self.target, self, x, y);
    end
end

function CHC_section:onHeaderClick()
    self.expanded = not self.expanded
    self.parent.backRef.panelSectionStates[self._id] = self.expanded
    self.panel:setVisible(self.expanded)
    self:calculateHeights()
end

function CHC_section:calcHeightNonList(panel, numItems)
    return 3 * panel.padY + panel.searchRow.height + numItems * panel.objList.itemheight
end

function CHC_section:calcHeightList(objList, numItems)
    if self.panel.uncollapsedNum then
        numItems = self.panel.uncollapsedNum
    end
    if numItems > self.maxItems then numItems = self.maxItems end
    return numItems * objList.itemheight
end

function CHC_section:calculateHeights()
    local height = self.headerButton:getHeight()
    local panel = self.panel

    if self.expanded then
        local listH
        local isNonList = true
        local objList = panel.objList
        if not objList then
            isNonList = false
            objList = panel
        end
        local numItems = #objList.items
        if numItems < self.maxItems then
            numItems = numItems + 1
        elseif numItems > self.maxItems then
            numItems = self.maxItems
        end
        if isNonList then -- item panels (attributes etc)
            listH = self:calcHeightNonList(panel, numItems)
            numItems = numItems - 1
        else
            listH = self:calcHeightList(objList, numItems) -- recipe panels (ingredients etc)
        end
        objList.vscroll:setHeight(objList.itemheight * numItems)
        objList.vscroll:setVisible(#objList.items > self.maxItems)
        objList:setHeight(objList.itemheight * numItems)
        height = height + listH
    end
    self:setHeight(height)
end

function CHC_section:onResize()
    ISPanel.onResize(self)
    self:setWidth(self.parent.width)
    self.headerButton:setWidth(self.width)
    self.panel:setWidth(self.width)
    if self.panel.vscroll then
        self.panel.vscroll:setX(self.width - self.panel.vscroll.width)
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

function CHC_section:new(x, y, width, height, panel, title, rightMargin, headerWidth, expanded, id, maxItems)
    local o = {}
    o = ISPanel:new(x, y, width, height)

    setmetatable(o, self)
    self.__index = self
    o._id = id
    o.font = UIFont.Small
    o.padX = 0
    o.padY = 3
    o.panel = panel
    o.title = title and title or '???'
    o.enabled = true
    if expanded == nil then expanded = true end
    o.expanded = expanded
    o.rightMargin = rightMargin
    o.headerWidth = headerWidth
    if headerWidth == 'text' then
        o.headerButtonWidth = 2 * o.padX + getTextManager():MeasureStringX(o.font, o.title)
    elseif headerWidth == 'fill' then
        o.headerButtonWidth = o.width
    else
        o.headerButtonWidth = headerWidth
    end
    o.headerBgColor = { r = 0.35, g = 0.35, b = 0.35, a = 0.35 }
    o.headerBgColorMouseOver = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 }
    o.headerBorderColor = { r = 1, g = 1, b = 1, a = 0.3 }
    o.maxItems = maxItems or 10
    return o
end

--endregion


--region section panel

-- function CHC_sectioned_panel:get(sectionTitle)

-- end

function CHC_sectioned_panel:initialise()
    ISPanel.initialise(self)
end

function CHC_sectioned_panel:addSection(panel, id, title, expanded)
    expanded = self.backRef.panelSectionStates[id] == true
    local section = CHC_section:new(0, 0, self.width, 1,
        panel, title, self.rightMargin, self.headerWidth, expanded, id)
    self:addChild(section)
    self.sections[#self.sections + 1] = section
    self.sectionMap[id] = section
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
        self:setScrollHeight(y + 24)
    end

    self:setStencilRect(0, 0, self.width, self.height)
end

function CHC_sectioned_panel:render()
    self:clearStencilRect()
end

-- function CHC_sectioned_panel:onResize()
--     local s = self.sections[1]
--     if not s or not s.panel or not s.panel.objList then return end
-- end

function CHC_sectioned_panel:onMouseWheel(del)
    for i = 1, #self.sections do
        local panel = self.sections[i].panel
        if panel:isMouseOver() then
            local objList = panel.objList
            if not objList then objList = panel end
            local vscroll = objList.vscroll
            if vscroll and vscroll:isReallyVisible() then
                if #objList.items < self.maxItems then
                elseif not isShiftKeyDown() and
                    (
                        (vscroll.pos > 0 and del == -1) or
                        (vscroll.pos < 1 and del == 1)
                    ) then
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
    o.activeSection = nil
    o.maintainHeight = true
    o.padY = 3
    o.rightMargin = args.rightMargin or 10
    o.headerWidth = args.headerWidth or 'fill' -- 'text', 'fill' or integer

    o.anchorTop = true
    o.anchorBottom = true
    o.anchorLeft = true
    o.anchorRight = false
    o.maxItems = 10

    return o
end

--endregion
