require 'ISUI/ISPanel'

local utils = require('CHC_utils')

CHC_items_panel = ISPanel:derive('CHC_items_panel')

local insert = table.insert
local sort = table.sort
local sub = string.sub

-- region create
function CHC_items_panel:initialise()
    ISPanel.initialise(self)
end

function CHC_items_panel:createChildren()
    ISPanel.createChildren(self)

    local x, y = 5, 5
    local fnts = getTextManager():getFontHeight(UIFont.Small)
    local fntm = getTextManager():getFontHeight(UIFont.Medium)
    local fntl = getTextManager():getFontHeight(UIFont.Large)

    -- region general info
    self.mainInfo = ISPanel:new(self.margin, y, self.width - 2 * self.margin, 1)
    self.mainInfo.borderColor = { r = 1, g = 0.53, b = 0.53, a = 0.2 }
    self.mainInfo:initialise()
    self.mainInfo:setVisible(false)

    self.mainImg = ISButton:new(self.margin, 5, 64, 64, '', self, nil)
    self.mainImg:initialise()
    self.mainImg.backgroundColorMouseOver.a = 0
    self.mainImg.backgroundColor.a = 0
    self.mainImg.origWI = 60
    self.mainImg.origHI = 60
    self.mainImg.forcedWidthImage = self.mainImg.origWI
    self.mainImg.forcedHeightImage = self.mainImg.origHI
    self.mainImg.onRightMouseDown = self.onRMBDownItemIcon

    local mainPadY = 2
    local mainX = self.margin + 64 + 3
    local mainY = mainPadY
    local mainPriFont = UIFont.Medium
    local mainSecFont = UIFont.Small

    local mr, mg, mb, ma = 1, 1, 1, 1
    self.mainName = ISLabel:new(mainX, mainPadY, fntm, nil, mr, mg, mb, ma, mainPriFont, true)
    self.mainName:initialise()
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

    self.mainInfo:setHeight(mainY + mainPadY)

    self.mainInfo:addChild(self.mainImg)
    self.mainInfo:addChild(self.mainName)
    self.mainInfo:addChild(self.mainType)
    self.mainInfo:addChild(self.mainDispCat)
    self.mainInfo:addChild(self.mainMod)
    -- self.mainInfo:addChild(self.mainWeight)

    y = y + self.mainInfo:getBottom()
    -- endregion

    -- region stats list
    local stats_args = {
        x = self.margin,
        y = y,
        w = self.width - 2 * self.margin,
        h = self.height - self.mainInfo.height - 4 * self.padY,
        backRef = self.backRef
    }

    self.statsList = CHC_sectioned_panel:new(stats_args)
    self.statsList:initialise()
    self.statsList.maintainHeight = false
    self.statsList:addScrollBars()
    self.statsList:setScrollChildren(true)
    self.statsList:setVisible(false)
    -- endregion

    -- region attributes
    local props_table_args = {
        x = self.margin,
        y = y,
        w = self.width - 2 * self.margin,
        h = 1, --self.height - self.mainInfo.height - self.padY,
        backRef = self.backRef
    }
    self.itemProps = CHC_props_table:new(props_table_args)
    self.itemProps.borderColor.a = 0
    self.itemProps:instantiate()
    -- endregion

    -- region distributions
    self.itemDistrib = CHC_props_table:new(props_table_args)
    self.itemDistrib:instantiate()
    -- endregion

    -- region fixing
    self.itemFixing = CHC_props_table:new(props_table_args)
    self.itemFixing:instantiate()
    -- endregion

    self:addChild(self.mainInfo)
    self:addChild(self.statsList)

    self.mainX = mainX
    self.mainY = mainY
end

-- endregion

-- region render
function CHC_items_panel:onResize()
    self:setHeight(self.parent.height - self.parent.headers.height)
    self.mainInfo:setWidth(self.parent.headers.typeHeader.width - self.margin - self.mainInfo.x)
    local children = self.mainInfo.children
    for _, ch in pairs(children) do
        if not ch.isButton then
            ch:setName(ch.name)
        end
    end

    self.statsList:setWidth(self.parent.headers.typeHeader.width - self.margin - self.statsList.x)
    self.statsList:setHeight(self.height - self.mainInfo.height - 4 * self.padY)
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

function CHC_items_panel:setObj(item)
    self.item = item

    -- region build main info
    if item.textureMult then
        if not self.itemImgTextureMultApplied then
            self.mainImg.forcedWidthImage = self.mainImg.forcedWidthImage * item.textureMult
            self.mainImg.forcedHeightImage = self.mainImg.forcedHeightImage * item.textureMult
            self.itemImgTextureMultApplied = true
        end
    else
        self.mainImg.forcedWidthImage = self.mainImg.origWI
        self.mainImg.forcedHeightImage = self.mainImg.origHI
        self.itemImgTextureMultApplied = false
    end
    self.mainImg:setImage(item.texture)
    if self.item.tooltip then
        self.mainImg:setTooltip(getText(self.item.tooltip))
    else
        self.mainImg:setTooltip(nil)
    end

    self.mainName:setName(item.name)
    self.mainName:setTooltip(string.format('%s <LINE>%s', item.name, item.fullType))

    local trCat = self.parent.typeData[item.category].tooltip
    self.mainType:setName(getText('IGUI_invpanel_Type') .. ': ' .. trCat)
    self.mainDispCat:setName(getText('IGUI_invpanel_Category') .. ': ' .. item.displayCategory)

    self.mainMod:setName(getText('IGUI_mod_chc') .. ': ' .. item.modname)
    -- self.mainWeight:setName(getText('IGUI_invpanel_weight') .. ': ' .. round(item.item:getWeight(), 2))
    local maxY = self.mainMod.y + self.mainMod.height + 2

    self.mainInfo:setHeight(math.max(74, maxY))
    self.mainInfo:setVisible(true)
    -- self.mainImg.blinkImage = true
    -- endregion

    -- self.itemDistribData = CHC_main.item_distrib[item.fullType]
    -- if self.itemDistribData then
    --     -- item distribution assign
    -- else
    --     self.itemDistribData = nil
    -- end

    -- region build props table
    self.itemProps.objList:clear()
    self.itemProps.propData = nil
    local objProps = self:collectItemProps(item)
    if not utils.empty(objProps) then
        for i = 1, #objProps do
            self.itemProps.objList:addItem(objProps[i].name, objProps[i])
        end
        self.itemProps.propData = objProps
        self.itemProps.needUpdateObjects = true
    end
    -- endregion

    local statsListOpenedSections = self.statsList.expandedSections
    self.statsList:clear()
    self.statsList:setY(self.mainInfo.y + self.mainInfo:getBottom() + self.padY)

    if self.itemProps.propData then
        self.statsList:addSection(self.itemProps, self.attributeSectionName)
    end
    -- self.statsList:addSection(self.itemDistrib, 'Distributions')
    -- self.statsList:addSection(self.itemFixing, 'Fixing')

    for section, _ in pairs(statsListOpenedSections) do
        self.statsList:expandSection(section)
    end

    if self.statsList.sectionMap[self.attributeSectionName] then
        local list_search_txt = self.parent.searchRow.searchBar:getInternalText()
        if utils.startswith(list_search_txt, '$') then
            -- self.itemProps.searchRow.searchBar:setText(list_search_txt:gsub('%$', ''))
            self.itemProps:updateObjects()
        end
    end

    if not utils.empty(self.statsList.sections) then
        self.statsList:setVisible(true)
    else
        self.statsList:setVisible(false)
    end
end

function CHC_items_panel:collectItemProps(item)
    local objAttrs = CHC_main.common.getItemProps(item)

    -- TODO: move to options (keep search query?)
    if true then
        -- will keep search quesry between item changes
        self.itemProps.needUpdateObjects = true
    else
        -- will clear search bar every time item changes
        self.itemProps.searchRow.searchBar:setText('')
    end

    if objAttrs then
        sort(objAttrs, function(a, b) return a.name:upper() < b.name:upper() end)
    end
    return objAttrs
end

-- endregion

function CHC_items_panel:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)
    setmetatable(o, self)
    self.__index = self

    -- o.backgroundColor = { r = 1, g = 0, b = 0, a = 1 }
    -- o:noBackground()
    o.padY = 5
    o.margin = 5
    o.anchorTop = true
    o.anchorBottom = false

    o.backRef = args.backRef
    o.item = nil
    o.itemImgTextureMultApplied = false

    o.attributeSectionName = getText('IGUI_ItemDetails_Attributes_tab')

    return o
end
