require "ISUI/ISPanel"

CHC_props_table = ISPanel:derive("CHC_props_table")
local insert = table.insert
local sort = table.sort
local utils = require('CHC_utils')

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
    self.searchRow = CHC_search_bar:new(x, y, self.width - 2 * self.padX, 24, "search by attributes",
        self.onTextChange, self.searchRowHelpText)
    self.searchRow:initialise()
    self.searchRow.drawBorder = false
    y = y + 2 * self.padY + self.searchRow.height
    -- endregion
    local props_h = self.height - self.searchRow.height - self.label.height - 4 * self.padY
    self.objList = ISScrollingListBox:new(x, y, self.width - 2 * self.padX, props_h)
    self.objList:setFont(self.font)
    self.objList:initialise()
    self.objList:instantiate()

    self.objList:setY(self.objList.y + self.objList.itemheight)
    self.objList:setHeight(self.objList.height - self.objList.itemheight)
    self.objList.vscroll:setHeight(self.objList.height)
    self.objList.drawBorder = true
    self.objList.doDrawItem = self.drawProps

    -- TODO: add translation
    self.objList:addColumn("Name", 0)
    self.objList:addColumn("Value", self.width * 0.4)

    self:addChild(self.label)
    self:addChild(self.searchRow)
    self:addChild(self.objList)

end

-- endregion


-- region update
function CHC_props_table:update()
    if self.needUpdateObjects == true then
        self:updatePropsList()
        self.needUpdateObjects = false
    end
end

function CHC_props_table:updatePropsList()
    local search_state
    local props = self.parent.item.props
    if not props then return end

    local filteredProps = {}
    for i = 1, #props do
        search_state = CHC_main.common.searchFilter(self, props[i], self.searchProcessToken)

        if search_state then
            insert(filteredProps, props[i])
        end
    end
    self:refreshObjList(filteredProps)
end

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
    self.searchRow:setWidth(self.width - 2 * self.padX)
    self.objList:setWidth(self.width - 2 * self.padX)
    self.objList:setHeight(self.height - self.label.height - self.searchRow.height - 6 * self.padY -
        self.objList.itemheight)
    self.objList.vscroll:setHeight(self.objList.height)
end

-- endregion


-- region logic
-- function CHC_props_table:addItem()

-- end

function CHC_props_table:refreshObjList(props)
    self.objList:clear()
    self.objList:setScrollHeight(0)

    for i = 1, #props do
        self:processAddObjToObjList(props[i], self.modData)
    end
    -- TODO: add filter button
    local sortFunc = function(a, b) return a.item.name:upper() < b.item.name:upper() end
    sort(self.objList.items, sortFunc)
end

function CHC_props_table:processAddObjToObjList(prop, modData)
    local name = prop.name
    self.objList:addItem(name, prop)
end

function CHC_props_table:onTextChange()
    self.needUpdateObjects = true
end

-- search rules
function CHC_props_table:searchProcessToken(token, prop)
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token, { "!", "@" }) then
        isSpecialSearch = true
        char = token:sub(1, 1)
        token = string.sub(token, 2)
    end

    local whatCompare
    if isAllowSpecialSearch and char == "!" then
        -- search by name
        whatCompare = string.lower(prop.name)
    end
    if isAllowSpecialSearch and char == "@" then
        -- search by value
        whatCompare = string.lower(prop.value)
    end
    if token and not isSpecialSearch then
        whatCompare = string.lower(prop.name)
    end
    state = utils.compare(whatCompare, token)
    if not token then state = true end
    return state
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
    o.modData = CHC_main.playerModData

    o.needUpdateObjects = false

    return o
end
