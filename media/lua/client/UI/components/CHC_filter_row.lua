require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'

local derivative = ISPanel
CHC_filter_row = derivative:derive("CHC_filter_row")

function CHC_filter_row:initialise()
    derivative.initialise(self)
    self:create()
end

function CHC_filter_row:create()
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- region order btn
    local foo = self.filterOrderData
    self.filterOrderBtn = ISButton:new(x, 0, foo.width or h, h, foo.title or "", self)
    self.filterOrderBtn:initialise()
    self.filterOrderBtn.onclick = foo.onclick
    self.filterOrderBtn.tooltip = foo.defaultTooltip
    self.filterOrderBtn:setImage(foo.defaultIcon)
    self.filterOrderBtn.borderColor.a = 0
    x = x + self.filterOrderBtn.width
    -- endregion

    -- region type btn
    local fto = self.filterTypeData
    self.filterTypeBtn = ISButton:new(x, 0, fto.width or h, h, fto.title or "", self)
    self.filterTypeBtn:initialise()
    self.filterTypeBtn.onclick = fto.onclick
    self.filterTypeBtn.tooltip = fto.defaultTooltip
    self.filterTypeBtn:setImage(fto.defaultIcon)
    self.filterTypeBtn.borderColor.a = 0
    x = x + self.filterTypeBtn.width
    -- endregion

    -- region selector
    local fsd = self.filterSelectorData
    local dw = self.filterOrderBtn.width + self.filterTypeBtn.width
    self.categorySelector = ISComboBox:new(x, 0, w - dw, h)
    self.categorySelector:initialise()

    self.categorySelector.editable = CHC_settings.config.editable_category_selector
    self.categorySelector.font = UIFont.Small -- TODO: move to options
    self.categorySelector.onChange = fsd.onChange
    self.categorySelector.target = self
    self.categorySelector.tooltip = { defaultTooltip = fsd.defaultTooltip }
    -- endregion

    self:addChild(self.filterOrderBtn)
    self:addChild(self.filterTypeBtn)
    self:addChild(self.categorySelector)
end

function CHC_filter_row:onResize()
    self.categorySelector:setWidth(self.width - self.filterOrderBtn.width - self.filterTypeBtn.width)
end

function CHC_filter_row:new(x, y, width, height, filtersData)
    local o = {};
    o = derivative:new(x, y, width, height)

    setmetatable(o, self)
    self.__index = self

    o.x = x
    o.y = y
    o.w = width
    o.h = height
    o.filterOrderData = filtersData.filterOrderData
    o.filterTypeData = filtersData.filterTypeData
    o.filterSelectorData = filtersData.filterSelectorData
    return o
end
