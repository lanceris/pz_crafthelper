require "ISUI/ISPanel"

CHC_props_table = ISPanel:derive("CHC_props_table")


-- region create
function CHC_props_table:initialise()
    ISPanel.initialise(self)
end

function CHC_props_table:createChildren()
    ISPanel.createChildren(self)

    local x = self.padX
    local y = self.padY

    self.label = ISLabel:new(x, y, self.fonthgt, "Attributes", 1, 1, 1, 1, self.font, true)
    self.label:initialise()
    y = y + self.padY + self.label.height

    -- region search bar
    self.panelSearchRow = CHC_search_bar:new(x, y, self.width - 2 * self.padX, 24, "search by attributes",
        self.onTextChange, self.searchRowHelpText)
    self.panelSearchRow:initialise()
    self.panelSearchRow.drawBorder = false
    y = y + 2 * self.padY + self.panelSearchRow.height
    -- endregion
    local props_h = self.height - self.panelSearchRow.height - self.label.height - 4 * self.padY
    self.props = ISScrollingListBox:new(x, y, self.width - 2 * self.padX, props_h)
    self.props:setFont(self.font)
    self.props:initialise()
    self.props:instantiate()

    self.props:setY(self.props.y + self.props.itemheight)
    self.props:setHeight(self.props.height - self.props.itemheight)
    self.props.vscroll:setHeight(self.props.height)
    self.props.drawBorder = true
    self.props.doDrawItem = self.drawProps

    -- TODO: add translation
    self.props:addColumn("Name", 0)
    self.props:addColumn("Value", self.width * 0.4)

    self:addChild(self.label)
    self:addChild(self.panelSearchRow)
    self:addChild(self.props)

end

-- endregion


-- region update

-- endregion

-- region render
function CHC_props_table:drawProps(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9
    local xoffset = 10

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b)

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.name, self.columns[1].size + 5, y, 1, 1, 1, a, self.font)
    self:clearStencilRect()

    self:drawText(item.item.value, self.columns[2].size + 5, y, 1, 1, 1, a, self.font)

    -- self:repaintStencilRect(0, clipY, self.width, clipY2 - clipY)

    return y + self.itemheight

end

function CHC_props_table:render()
    ISPanel.render(self)
end

function CHC_props_table:onResize()
    self.panelSearchRow:setWidth(self.width - 2 * self.padX)
    self.props:setWidth(self.width - 2 * self.padX)
    self.props:setHeight(self.height - self.label.height - self.panelSearchRow.height - 6 * self.padY -
        self.props.itemheight)
    self.props.vscroll:setHeight(self.props.height)
end

-- endregion


-- region logic
-- function CHC_props_table:addItem()

-- end

function CHC_props_table:onTextChange()

end

-- endregion

function CHC_props_table:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.font = UIFont.Medium
    o.fonthgt = getTextManager():getFontHeight(o.font)
    o.padY = 5
    o.padX = 5

    o.searchRowHelpText = "Help"

    return o
end
