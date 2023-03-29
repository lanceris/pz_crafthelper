require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'

local derivative = ISPanel
CHC_filter_row = derivative:derive('CHC_filter_row')

function CHC_filter_row:initialise()
    derivative.initialise(self)
    self:create()
end

function CHC_filter_row:create()
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- region order btn
    local foo = self.filterOrderData
    self.filterOrderBtn = ISButton:new(x, 0, foo.width or h, h, foo.title or '', self)
    self.filterOrderBtn:initialise()
    if not foo.onclickargs then foo.onclickargs = {} end
    self.filterOrderBtn:setOnClick(foo.onclick, foo.onclickargs[1], foo.onclickargs[2],
        foo.onclickargs[3], foo.onclickargs[4])
    self.filterOrderBtn.tooltip = foo.defaultTooltip
    self.filterOrderBtn:setImage(foo.defaultIcon)
    self.filterOrderBtn.borderColor.a = 0
    x = x + self.filterOrderBtn.width
    -- endregion

    -- region type btn
    local fto = self.filterTypeData
    self.filterTypeBtn = ISButton:new(x, 0, fto.width or h, h, fto.title or '', self)
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
    self.categorySelector.prerender = self.prerenderSelector
    -- endregion

    self:addChild(self.filterOrderBtn)
    self:addChild(self.filterTypeBtn)
    self:addChild(self.categorySelector)

    self.categorySelector.popup.doDrawItem = self.doDrawItemSelectorPopup
end

function CHC_filter_row:prerenderSelector()
    ISComboBox.prerender(self)
    local selected = self.options[self.selected]
    if not selected then return end

    if self:isEditable() and self.editor and self.editor:isReallyVisible() then
    else
        local data = self:getOptionData(self.selected)
        if not data or not data.count or type(data.count) ~= "number" then return end
        local texX = getTextManager():MeasureStringX(self.font, self:getOptionText(self.selected))
        local y = (self.height - getTextManager():getFontHeight(self.font)) / 2
        self:clampStencilRectToParent(0, 0, self.width - self.image:getWidthOrig() - 6, self.height)
        local countStr = ' (' .. data.count .. ')'
        self:drawText(countStr, texX + 10, y, self.textColor.r, self.textColor.g,
            self.textColor.b, self.textColor.a, self.font)
        self:clearStencilRect()
    end
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
    local texX = getTextManager():MeasureStringX(self.font, self.parentCombo:getOptionText(item.index))
    local countStr = ' (' .. data.count .. ')'
    self:drawText(countStr, texX + 10, y - item.height + 5,
        self.parentCombo.textColor.r, self.parentCombo.textColor.g,
        self.parentCombo.textColor.b, self.parentCombo.textColor.a, self.font)

    return y
end

function CHC_filter_row:onResize()
    self.categorySelector:setWidth(self.width - self.filterOrderBtn.width - self.filterTypeBtn.width)
end

function CHC_filter_row:new(args, filtersData)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    local o = {}
    o = derivative:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.backRef = args.backRef
    o.filterOrderData = filtersData.filterOrderData
    o.filterTypeData = filtersData.filterTypeData
    o.filterSelectorData = filtersData.filterSelectorData
    return o
end
