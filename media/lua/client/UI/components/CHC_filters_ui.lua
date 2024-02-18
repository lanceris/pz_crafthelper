require 'UI/components/CHC_sectioned_panel'
require 'UI/components/CHC_presets'

---@class CHC_filters_ui:ISCollapsableWindow
CHC_filters_ui = ISCollapsableWindow:derive('CHC_filters_ui')
local sort = table.sort
local find = string.find
local sub = string.sub
local trim = string.trim
local utils = require('CHC_utils')


-- region create
function CHC_filters_ui:initialise()
    ISCollapsableWindow.initialise(self)
end

function CHC_filters_ui:createChildren()
    ISCollapsableWindow.createChildren(self)

    --region control row
    local crX = 0
    local crY = self:titleBarHeight()
    local h = 24

    local presetOptions = {
        rename = {
            icon = CHC_window.icons.presets.rename,
            title = getText("ContextMenu_RenameBag"),
            onclick = self.onMoreBtnRenameClick,
            tooltip = nil
        },
        duplicate = {
            icon = CHC_window.icons.presets.duplicate,
            title = getText("IGUI_BottomPanelMoreDuplicate"),
            onclick = self.onMoreBtnDuplicateClick,
            tooltip = getText("IGUI_BottomPanelMoreDuplicateTooltip")
        },
        share = {
            icon = CHC_window.icons.presets.share,
            title = getText("IGUI_BottomPanelMoreShare"),
            onclick = self.onMoreBtnShareClick,
            tooltip = getText("IGUI_BottomPanelMoreShareTooltip")
        },
        import = {
            icon = CHC_window.icons.presets.import,
            title = getText("IGUI_BottomPanelMoreImport"),
            onclick = self.onMoreBtnImportClick,
            tooltip = getText("IGUI_BottomPanelMoreImportTooltip")
        },
        delete = {
            icon = CHC_window.icons.presets.delete,
            title = getText("IGUI_BottomPanelMoreDelete"),
            onclick = self.onMoreBtnDeleteClick,
            tooltip = getText("IGUI_BottomPanelMoreDeleteTooltip")
        },
    }

    self.presets = CHC_presets:new(crX, crY, self.width, h, self.backRef, presetOptions, "filters")
    self.presets.buttonRight = true
    self.presets:initialise()

    self.savePresetBtn = ISButton:new(self.presets:getRight(), crY, h, h, nil, self, self.onControlClick)
    self.savePresetBtn.internal = "SAVE"
    self.savePresetBtn:initialise()
    self.savePresetBtn:setImage(CHC_window.icons.presets.save)

    self.applyPresetBtn = ISButton:new(self.savePresetBtn:getRight(), crY, h, h, nil, self, self.onControlClick)
    self.applyPresetBtn.internal = "APPLY"
    self.applyPresetBtn:initialise()
    self.applyPresetBtn:setImage(CHC_window.icons.presets.apply)

    self.newFilterBtn = ISButton:new(self.applyPresetBtn:getRight(), crY, h, h, nil, self, self.onControlClick)
    self.newFilterBtn.internal = "NEWFILTER"
    self.newFilterBtn:initialise()
    self.newFilterBtn:setImage(CHC_window.icons.common.add)
    --endregion

    --region filters
    local panel_args = {
        x = 0,
        y = self.presets:getBottom(),
        w = self.width,
        h = self.height - self.presets.height,
        backRef = self.backRef
    }

    self.filtersPanel = CHC_sectioned_panel:new(panel_args)
    self.filtersPanel:initialise()
    self.filtersPanel:instantiate()
    self.filtersPanel.borderColor.a = 0
    self.filtersPanel:setAnchorTop(true)
    self.filtersPanel:setAnchorBottom(true)
    self.filtersPanel.maintainHeight = false
    self.filtersPanel:setScrollChildren(true)
    self.filtersPanel:setVisible(true)
    --endregion

    self:addChild(self.presets)
    self:addChild(self.savePresetBtn)
    self:addChild(self.applyPresetBtn)
    self:addChild(self.newFilterBtn)
    self:addChild(self.filtersPanel)
end

-- endregion

-- region update

-- endregion

-- region render
function CHC_filters_ui:render()
    ISCollapsableWindow.render(self)
end

function CHC_filters_ui:onResize()
    -- ISCollapsableWindow.onResize(self)
end

function CHC_filters_ui:close()
    if self:getIsVisible() then
        self:removeFromUIManager()
    end
    ISCollapsableWindow.close(self)
end

-- endregion

-- region logic

local filterOperators = {
    --numeric
    gt = function(a, b) return a > b end,
    gte = function(a, b) return a >= b end,
    lt = function(a, b) return a < b end,
    lte = function(a, b) return a <= b end,
    eq = function(a, b) return a == b end,
    --tables
    tcontains = function(t, b) return utils.any(t, b) end,
    tmapcontains = function(t, b) return utils.any(t, b, nil, nil, nil, true) end,
    --strings
    scontains = function(a, b) return find(a, b, 1, true) ~= nil end,
    sstart = function(a, b) return utils.startswith(a, b) end,
    send = function(a, b) return utils.endswith(a, b) end,
    sexact = function(a, b) return trim(a) == trim(b) end
}

-- region event handlers

-- endregion

-- region preset buttons handlers
function CHC_filters_ui:onMoreBtnRenameClick()

end

function CHC_filters_ui:onMoreBtnDuplicateClick()

end

function CHC_filters_ui:onMoreBtnShareClick()

end

function CHC_filters_ui:onMoreBtnImportClick()

end

function CHC_filters_ui:onMoreBtnDeleteClick()

end

function CHC_filters_ui:onControlClick(_, button)

end

-- endregion

function CHC_filters_ui:setPosition()
    local mainX = self.backRef.x
    local mainY = self.backRef.y
    local mainW = self.backRef.width
    local myW = self.width
    local newX = mainX - myW
    if newX <= 0 then
        newX = mainX + mainW
    end
    local newY = mainY

    self:setX(newX)
    self:setY(newY)
end

function CHC_filters_ui:toggleUI()
    CHC_menu.toggleUI(self)
    if self:getIsVisible() then
        self:setPosition()
    end
end

-- endregion

---comment
---@param x number
---@param y number
---@param w number
---@param h number
---@param backRef CHC_window
---@param _type string items | recipes
---@return CHC_filters_ui
function CHC_filters_ui:new(x, y, w, h, backRef, _type)
    local o = {}
    o = ISCollapsableWindow:new(x, y, w, h);
    setmetatable(o, self)
    self.__index = self

    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.moveWithMouse = false
    o.backRef = backRef
    o.resizable = false
    o.parentViewType = _type
    o.title = getText('UI_FiltersUI_Title', _type)

    return o
end
