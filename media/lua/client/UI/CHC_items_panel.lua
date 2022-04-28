require 'ISUI/ISPanel'

local utils = require('CHC_utils')

CHC_items_panel = ISPanel:derive("CHC_items_panel")

-- region create
function CHC_items_panel:initialise()
    ISPanel.initialise(self)
end

function CHC_items_panel:createChildren()
    ISPanel.createChildren(self)
    -- common item properties
    -- - fullType
    -- - name
    -- - weight
    -- - category
    -- - display category
    -- - modname
    -- - count (?)
    -- - texture
    -- - tooltip (?)

    local x, y = 5, 5
    local fnts = getTextManager():getFontHeight(UIFont.Small)
    local fntm = getTextManager():getFontHeight(UIFont.Medium)
    local fntl = getTextManager():getFontHeight(UIFont.Large)
    -- region search bar
    self.panelSearchRow = CHC_search_bar:new(0, 0, self.width - self.margin, 24, "search by attributes", self.onTextChange, self.searchRowHelpText)
    self.panelSearchRow:initialise()
    self.panelSearchRow:setVisible(false)
    y = y + 24 + self.padY
    -- endregion

    -- region general info
    self.mainInfo = ISPanel:new(self.margin, y, self.width - 2 * self.margin, 74)
    self.mainInfo.borderColor = { r = 1, g = 0.53, b = 0.53, a = 0.2 }
    self.mainInfo:initialise()
    self.mainInfo:setVisible(false)

    self.mainImg = ISButton:new(self.margin, 5, 64, 64, "", self, nil)
    self.mainImg:initialise()
    self.mainImg.backgroundColorMouseOver.a = 0
    self.mainImg.backgroundColor.a = 0
    self.mainImg.forcedWidthImage = 60
    self.mainImg.forcedHeightImage = 60
    self.mainImg.onRightMouseDown = self.onRMBDownItemIcon

    local mainPadY = 2
    local mainX = self.margin + 64 + 3
    local mainY = mainPadY
    local mainPriFont = UIFont.Medium
    local mainSecFont = UIFont.Small

    local mr, mg, mb, ma = 1, 1, 1, 1
    self.mainName = ISLabel:new(mainX, mainPadY, fntm, nil, mr, mg, mb, ma, mainPriFont, true)
    self.mainName:initialise()
    self.mainName.maxWidth = self.mainInfo.width - mainX - self.margin
    mainY = mainY + mainPadY + self.mainName.height

    self.mainType = ISLabel:new(mainX, mainY, fnts, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainType:initialise()
    mainY = mainY + mainPadY + self.mainType.height

    self.mainDispCat = ISLabel:new(mainX, mainY, fnts, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainDispCat:initialise()
    mainY = mainY + mainPadY + self.mainDispCat.height

    self.mainMod = ISLabel:new(mainX, mainY, fnts, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainMod:initialise()
    mainY = mainY + mainPadY + self.mainMod.height

    self.mainWeight = ISLabel:new(mainX, mainY, fnts, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainWeight:initialise()
    mainY = mainY + mainPadY + self.mainWeight.height

    self.mainNumRecipes = ISLabel:new(mainX, mainY, fnts, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainNumRecipes:initialise()
    self.mainX = mainX
    self.mainY = mainY

    self.mainInfo:addChild(self.mainImg)
    self.mainInfo:addChild(self.mainName)
    self.mainInfo:addChild(self.mainType)
    self.mainInfo:addChild(self.mainDispCat)
    self.mainInfo:addChild(self.mainMod)
    self.mainInfo:addChild(self.mainWeight)
    self.mainInfo:addChild(self.mainNumRecipes)
    -- endregion

    -- region attributes
    self.attrList = nil -- endregion



    self:addChild(self.panelSearchRow)
    self:addChild(self.mainInfo)

end

-- endregion

-- region render
function CHC_items_panel:onResize()
    self:setHeight(self.parent.height - self.parent.headers.height)
    self.panelSearchRow:setWidth(self.parent.headers.typeHeader.width - self.margin)
    self.mainInfo:setWidth(self.parent.headers.typeHeader.width - self.margin - self.mainInfo.x)
    local children = self.mainInfo.children
    for _, ch in pairs(children) do
        if not ch.isButton then
            ch:setName(ch.name)
        end
    end
end

function CHC_items_panel:render()
    ISPanel.render(self)
    if not self.item then return end
end

-- endregion

-- region logic
function CHC_items_panel:onRMBDownItemIcon(x, y)
    local items_panel = self.parent.parent
    if not items_panel.item then return end
    items_panel.parent.onRMBDownObjList(items_panel, nil, nil, items_panel.item)
end

function CHC_items_panel:onTextChange()
end

function CHC_items_panel:setObj(item)
    self.item = item
    if false then
        local iobj = item.itemObj
        local invItem = item.item
        if instanceof(invItem, "ComboItem") then
            print('ignoring ComboItem')
            return
        end
        local cl = getNumClassFields(invItem)
        if cl == 0 then
            print(string.format('No fields found for %s', invItem:getType()))
        end
        local objAttr = {}

        for i = 0, cl - 1 do
            local meth = getClassField(invItem, i)
            if meth.getType then
                local val = KahluaUtil.rawTostring2(getClassFieldVal(invItem, meth))
                if val then
                    objAttr[meth:getName()] = val
                end
            end
        end
        print(test:test())
    end
    self.panelSearchRow:setVisible(true)

    self.mainImg:setImage(item.texture)
    if self.item.tooltip then
        self.mainImg:setTooltip(getText(self.item.tooltip))
    else
        self.mainImg:setTooltip(nil)
    end

    self.mainName:setName(item.name)
    self.mainName:setTooltip(string.format("%s <LINE>%s", item.name, item.fullType))

    local trCat = self.parent.typeData[item.category].tooltip
    self.mainType:setName(getText("IGUI_invpanel_Type") .. ": " .. trCat)
    self.mainDispCat:setName(getText("IGUI_invpanel_Category") .. ": " .. item.displayCategory)

    self.mainMod:setName(getText("IGUI_mod_chc") .. ": " .. item.modname)
    self.mainWeight:setName(getText("IGUI_invpanel_weight") .. ": " .. round(item.item:getWeight(), 2))
    local maxY = self.mainWeight.y + self.mainWeight.height + 2

    local usesNum = CHC_main.recipesByItem[item.fullType]
    if type(usesNum) == 'table' then usesNum = #usesNum else usesNum = 0 end
    local craftNum = CHC_main.recipesForItem[item.fullType]
    if type(craftNum) == 'table' then craftNum = #craftNum else craftNum = 0 end
    if usesNum + craftNum > 0 then
        self.mainNumRecipes:setName(getText("UI_search_recipes_tab_name") .. ": " .. usesNum + craftNum)
        local tooltip = ""
        if usesNum > 0 then
            tooltip = tooltip .. getText("UI_item_uses_tab_name") .. ": " .. usesNum
            tooltip = tooltip .. " <LINE>"
        end
        if craftNum > 0 then
            tooltip = tooltip .. getText("UI_item_craft_tab_name") .. ": " .. craftNum
        end
        self.mainNumRecipes:setTooltip(tooltip)
        maxY = self.mainNumRecipes.y + self.mainNumRecipes.height + 2
    else
        self.mainNumRecipes:setName(nil)
        self.mainNumRecipes:setTooltip(nil)
    end
    self.mainInfo:setHeight(math.max(74, maxY))
    self.mainInfo:setVisible(true)
    -- self.mainImg.blinkImage = true
end

-- endregion

function CHC_items_panel:new(x, y, w, h)
    local o = {}
    o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    -- o.backgroundColor = { r = 1, g = 0, b = 0, a = 1 }
    -- o:noBackground()
    o.padY = 5
    o.margin = 5
    o.anchorTop = true
    o.anchorBottom = false
    o.searchRowHelpText = "Help"
    o:addScrollBars()

    o.item = nil

    return o
end
