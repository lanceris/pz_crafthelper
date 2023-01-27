require "ISUI/ISPanel"

CHC_props_table = ISPanel:derive("CHC_props_table")
local insert = table.insert
local sort = table.sort

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
    self:addChild(self.panelSearchRow)
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
    local searchBar = self.panelSearchRow.searchBar
    local search_state

    local filteredProps = {}
    for i = 1, #props do
        search_state = self:searchTypeFilter(props[i])

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
    self.panelSearchRow:setWidth(self.width - 2 * self.padX)
    self.objList:setWidth(self.width - 2 * self.padX)
    self.objList:setHeight(self.height - self.label.height - self.panelSearchRow.height - 6 * self.padY -
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
    local sortFunc = function(a, b) return a.name:upper() < b.name:upper() end
    sort(self.objList.items, sortFunc)
end

function CHC_props_table:processAddObjToObjList(prop, modData)
    local name = prop.recipeData.name
    self.objList:addItem(name, prop)
end

function CHC_props_table:onTextChange()
    self.needUpdateObjects = true
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
