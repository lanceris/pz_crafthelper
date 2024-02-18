require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'
require 'UI/components/CHC_filters_ui'

local derivative = ISPanel
---@class CHC_filter_row:ISPanel
CHC_filter_row = derivative:derive('CHC_filter_row')

local utils = require('CHC_utils')
local format = string.format

function CHC_filter_row:initialise()
    derivative.initialise(self)
    self:create()
end

function CHC_filter_row:create()
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- region filtersBtn
    self.filtersUIBtn = ISButton:new(x, 0, h, h, nil, self, self.toggleFiltersUI)
    self.filtersUIBtn.borderColor.a = 0
    self.filtersUIBtn.backgroundColor.a = 0
    self.filtersUIBtn:setTooltip("test")
    self.filtersUIBtn:initialise()
    self.filtersUIBtn:setImage(CHC_window.icons.common.filter)
    self.filtersUIBtn:setVisible(true)
    x = x + self.filtersUIBtn.width
    --endregion

    -- region type btn
    local fto = self.filterTypeData
    self.filterTypeBtn = ISButton:new(x, 0, fto.width or h, h, fto.title or '', self)
    self.filterTypeBtn:initialise()
    self.filterTypeBtn.onclick = fto.onclick
    self.filterTypeBtn.tooltip = fto.defaultTooltip
    self.filterTypeBtn:setImage(fto.defaultIcon)
    self.filterTypeBtn.borderColor.a = 0
    self.filterTypeBtn.backgroundColor.a = 0
    x = x + self.filterTypeBtn.width
    -- endregion

    -- region selector
    local fsd = self.filterSelectorData
    self.categorySelector = ISComboBox:new(x, 0, w - x - h, h)
    self.categorySelector:initialise()

    self.categorySelector.editable = CHC_settings.config.editable_category_selector
    self.categorySelector.font = UIFont.Small -- TODO: move to options
    self.categorySelector.onChange = fsd.onChange
    self.categorySelector.target = self
    self.categorySelector.tooltip = { defaultTooltip = fsd.defaultTooltip }
    self.categorySelector.prerender = self.prerenderSelector
    self.categorySelector.textColor = { r = 0.95, g = 0.95, b = 0.95, a = 1 }
    x = x + self.categorySelector.width
    -- endregion

    self:addChild(self.filtersUIBtn)
    self:addChild(self.filterTypeBtn)
    self:addChild(self.categorySelector)
    self.categorySelector.popup.doDrawItem = self.doDrawItemSelectorPopup
end

function CHC_filter_row:prerenderSelector()
    local selected = self.options[self.selected]
    local alpha = self.borderColor.a + 0.2 * self.fade:fraction()
    if alpha > 1 then alpha = 1 end
    local bg = self.backgroundColor
    local bgmo = self.backgroundColorMouseOver
    local y = (self.height - getTextManager():getFontHeight(self.font)) / 2
    local tc = { r = 0.6, g = 0.6, b = 0.6, a = 1 }

    if not self.disabled then
        self.fade:setFadeIn(self.joypadFocused or self:isMouseOver())
        self.fade:update()
        tc.r = 1
        tc.g = 1
        tc.b = 1
        self:drawRectBorder(0, 0, self.width, self.height, alpha, self.borderColor.r, self.borderColor.g,
            self.borderColor.b)
    end

    if self.expanded then
        self:drawRect(0, 0, self.width, self.height, bg.a, bg.r, bg.g, bg.b)
    elseif not self.joypadFocused then
        self:drawRect(0, 0, self.width, self.height, bgmo.a * 0.5 * self.fade:fraction(), bgmo.r, bgmo.g, bgmo.b);
    else
        self:drawRect(0, 0, self.width, self.height, bgmo.a, bgmo.r, bgmo.g, bgmo.b);
    end

    if self:isEditable() and self.editor and self.editor:isReallyVisible() then
        -- editor is visible, don't draw text
    elseif selected then
        local data = self:getOptionData(self.selected)
        self:clampStencilRectToParent(0, 0, self.width - self.image:getWidthOrig() - 6, self.height)

        local text = self:getOptionText(self.selected)
        local tx = 10
        if data and data.count and type(data.count) == "number" then
            text = format('%s (%d)', text, data.count)
            tc = self.textColor
        end
        if not self.disabled then
            tc = self.textColor
        end
        self:drawText(text, tx, y, tc.r, tc.g, tc.b, tc.a, self.font)
        self:clearStencilRect()
    end

    self:drawRectBorder(0, 0, self.width, self.height, alpha, 0.5, 0.5, 0.5)
    self:drawTexture(self.image, self.width - self.image:getWidthOrig() - 3,
        (self.baseHeight / 2) - (self.image:getHeight() / 2), 1, 1, 1, 1)
end

function CHC_filter_row:doDrawItemSelectorPopup(y, item, alt)
    y = ISComboBoxPopup.doDrawItem(self, y, item, alt)
    local data = self.parentCombo:getOptionData(item.index)
    if not data or not data.count or type(data.count) ~= "number" then return y end
    if self.parentCombo:hasFilterText() then
        if not item.text:lower():contains(self.parentCombo:getFilterText():lower()) then
            return y
        end
    end
    local texX = utils.strWidth(self.font, self.parentCombo:getOptionText(item.index))
    local countStr = ' (' .. data.count .. ')'
    self:drawText(countStr, texX + 10, y - item.height + 5,
        self.parentCombo.textColor.r, self.parentCombo.textColor.g,
        self.parentCombo.textColor.b, self.parentCombo.textColor.a, self.font)

    return y
end

function CHC_filter_row:onResize()
    self.categorySelector:setWidth(self.width - self.categorySelector.x)
end

-- isMouseButtonDown(4)

function CHC_filter_row:toggleFiltersUI()
    ---@type CHC_filters_ui
    local ui = self.backRef.filtersUI
    if not ui then
        error("Could not access Filters UI")
    end
    ui:toggleUI()
end

---comment
---@param args {x:number,y:number,w:number,h:number,backRef:CHC_window}
---@param filtersData table
---@return CHC_filter_row
function CHC_filter_row:new(args, filtersData)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    local o = {}
    o = derivative:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.backgroundColor.a = 0

    o.backRef = args.backRef
    o.filterOrderData = filtersData.filterOrderData
    o.filterData = filtersData.filterData
    o.filterTypeData = filtersData.filterTypeData
    o.filterSelectorData = filtersData.filterSelectorData
    o.filtersUI = nil

    o.needUpdateInfoTooltip = false
    return o
end

local function _scheduleTooltipUpdate()
    if not CHC_menu or not CHC_menu.CHC_window or not CHC_menu.CHC_window.updateQueue then return end
    CHC_menu.CHC_window.updateQueue:push({
        targetViews = { 'all' },
        actions = { 'needUpdateInfoTooltip' }
    })
end

do
    local old_close = MainOptions.close
    function MainOptions:close()
        old_close(self)
        _scheduleTooltipUpdate()
    end

    local old_load = MainOptions.loadKeys
    MainOptions.loadKeys = function(...)
        local result = old_load(...)
        _scheduleTooltipUpdate()
        return result
    end
end
