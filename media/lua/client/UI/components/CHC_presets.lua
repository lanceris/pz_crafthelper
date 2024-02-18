require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'
require 'UI/CHC_preset_tooltip'
require 'UI/components/CHC_filter_row'

local utils = require('CHC_utils')
CHC_presets = ISPanelJoypad:derive('CHC_presets')

local pairs = pairs
local tsort = table.sort
local concat = table.concat
local format = string.format
--region create
function CHC_presets:initialise()
    ISPanelJoypad.initialise(self)
    self:create()
end

function CHC_presets:create()
    local x, y, w, h = 0, 0, 24, 24

    -- region btn
    self.moreButton = ISButton:new(x, y, w, h, nil, self, self.onMoreButtonClick)
    self.moreButton.borderColor.a = 0
    self.moreButton.backgroundColor.a = 0
    self.moreButton:initialise()
    self.moreButton:setImage(self.moreButtonTex)
    self.moreButton._options = self.moreButtonOptions
    -- endregion

    -- region selector
    self.categorySelector = ISComboBox:new(self.moreButton.width, y, w, h, self, self.onSelectorChange)
    self.categorySelector:initialise()
    self.categorySelector:instantiate()
    self.categorySelector.font = self.font
    self.categorySelector.onChange = CHC_presets.onChangePreset
    self.categorySelector.prerender = self.prerenderSelector
    self.categorySelector:setWidth(30) --self.width - self.categorySelector.x)
    self.categorySelector:setEditable(CHC_settings.config.editable_category_selector)
    -- endregion

    self:addChild(self.moreButton)
    self:addChild(self.categorySelector)

    self.categorySelector.popup.doDrawItem = self.doDrawItemSelectorPopup

    if self.buttonRight then
        self.categorySelector:setX(0)
        self.moreButton:setX(self.categorySelector.width)
    end
end

--endregion

--region update

function CHC_presets:selectDefaultPreset()
    local opt = self.categorySelector:getOptionText(1)
    self.categorySelector:select(opt)
end

function CHC_presets:updatePresets()
    local ui_type = CHC_main.common.getCurrentUiType(self.window)
    local presets = self:getPresetStorage()
    if not presets then return end
    self.categorySelector:clear()
    self.categorySelector:addOption({ text = self.defaultPresetName })
    for name, data in pairs(presets) do
        local dqn = 0
        for _, _ in pairs(data) do dqn = dqn + 1 end
        local option = {
            text = name,
            data = { count = dqn },
            tooltip = self:createTooltip(ui_type, data)
        }
        option.tooltip:setOwner(self.categorySelector.popup)
        self.categorySelector:addOption(option)
    end
    self:selectDefaultPreset()
end

function CHC_presets:update()
    if self.needUpdatePresets then
        self.needUpdatePresets = false
        self:updatePresets()
        local selected = self:getSelectedPreset()
        if selected and selected.text == self.defaultPresetName then
            local sub = self.window:getActiveSubView()
            sub.view.needUpdateFavorites = true
            return
        end
    end
end

--endregion

--region logic

---ensure only one modal can be active
---@param params table modal parameters
---@return table modal
function CHC_presets:addModal(params)
    if self.window.openedModal then self.window.openedModal:destroy() end
    local modal = CHC_main.common.addModal(params)
    self.window.openedModal = modal
    return modal
end

--- get item object from string
---@param str string item FullType (Base.Hammer)
function CHC_presets:parseItemString(str)
    return CHC_main.items[str]
end

--- get recipe object from string
---@param str string recipe string (craftingFavorite:Recipe Name:Module.Item1:Module.Item2)
function CHC_presets:parseRecipeString(str)
    return CHC_main.recipeStringMap[str]
end

function CHC_presets:getItemTooltip(str)
    local item = self:parseItemString(str)
    local entry = {}
    if not item then return end
    if not item.texture then
        CHC_main.common.cacheTex(item)
    end
    entry.texture = item.texture
    entry.texture_name = item.texture_name or self.defaultItemTexName
    entry.name = item.displayName
    if item.category == "Moveable" then
        entry.texture_multiplier = 2
    else
        entry.texture_multiplier = 1
    end
    return entry
end

function CHC_presets:getRecipeTooltip(str)
    local recipe = self:parseRecipeString(str)
    local entry = {}
    if not recipe then return end
    local resultItem = recipe.recipeData.result
    if resultItem then
        if not resultItem.texture then
            CHC_main.common.cacheTex(resultItem)
        end
        entry.texture = resultItem.texture
        entry.texture_name = resultItem.texture_name
    else
        entry.texture_name = self.defaultItemTexName
    end
    entry.name = recipe.recipeData.name
    if resultItem.category == "Moveable" then
        entry.texture_multiplier = 2
    else
        entry.texture_multiplier = 1
    end
    return entry
end

function CHC_presets:createTooltip(ui_type, objs, limit)
    limit = limit or 20
    if limit > #objs then limit = #objs end
    local tooltip = PresetTooltip.addToolTip()
    self:updateTooltipData(tooltip, ui_type, objs, limit)
    return tooltip
end

function CHC_presets:updateTooltipData(tooltip, ui_type, objs, limit)
    tooltip:reset()
    local handlers = {
        items = CHC_presets.getItemTooltip,
        recipes = CHC_presets.getRecipeTooltip
    }
    local x = 0
    local y = 0
    local margin = 4
    local texSize = 32
    local cnt = 0
    local to_add = {}
    for _, obj in pairs(objs) do
        if cnt > limit then
            break
        end
        local entry = handlers[ui_type](self, obj)
        if not entry then
            -- display fulltype/recipe name
            entry = {
                texture_multiplier = 1,
                texture_name = self.defaultItemTexName,
                name = ui_type == "recipes" and strsplit(obj, ":")[2] or obj
            }
        end
        to_add[#to_add + 1] = entry
    end
    tsort(to_add, function(a, b) return a.name:lower() < b.name:lower() end)
    for i = 1, #to_add do
        local entry = to_add[i]
        local tS = texSize * entry.texture_multiplier
        local lH = tS > tooltip.fontHgt and tS or tooltip.fontHgt
        if entry.texture then
            tooltip:addImage(x, y, tS, nil, entry.texture)
        else
            tooltip:addImage(x, y, tS, entry.texture_name)
        end
        tooltip:addText(x + tS + margin, y, entry.name)
        y = y + lH
        cnt = cnt + 1
    end
    if #objs > limit then
        local t = "... + " .. #objs - limit
        tooltip:addText(x, y, t)
    end
end

function CHC_presets:getCurrentFavorites()
    local subview = self.window:getActiveSubView()
    if not subview then return end
    return subview.view.objList
end

function CHC_presets:getCurrentFavoritesFromModData(ui_type)
    local favorites = {}
    if ui_type == "items" then
        for key, _ in pairs(CHC_menu.playerModData.CHC_item_favorites) do
            favorites[#favorites + 1] = key
        end
    elseif ui_type == "recipes" then
        for key, value in pairs(CHC_menu.playerModData) do
            if utils.startswith(key, "craftingFavorite:") and value == true then
                favorites[#favorites + 1] = key
            end
        end
    end
    return favorites
end

function CHC_presets:onMoreButtonClick(button)
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 24, y)

    for _, option in pairs(button._options) do
        local opt = context:addOption(option.title, self, option.onclick)
        if option.tooltip then
            local tooltip = ISToolTip:new()
            tooltip:initialise()
            -- tooltip:setName("Test")
            tooltip.description = option.tooltip
            opt.toolTip = tooltip
        end
        opt.iconTexture = option.icon
    end
end

function CHC_presets:validatePreset(i, objStr, ui_type)
    local handlers = {
        items = CHC_presets.parseItemString,
        recipes = CHC_presets.parseRecipeString,
    }
    local _errors = {}
    local entry = handlers[ui_type](self, objStr)
    if not entry then
        local missing = {}
        if ui_type == "recipes" then
            --parse each item and find missing
            local missingItems = {}
            local items = strsplit(objStr, ":")
            if items[1] ~= "craftingFavorite" then
                missingItems[#missingItems + 1] = "craftingFavorite"
            end
            if not CHC_main.recipeMap[items[2]] then
                missingItems[#missingItems + 1] = items[2]
            end
            for j = 3, #items do
                if not handlers.items(self, items[j]) then
                    missingItems[#missingItems + 1] = items[j]
                end
            end
            if utils.empty(missingItems) then
                -- all ingredients are ok but recipe not found (altered order?)
                missingItems[#missingItems + 1] = format("Recipe object for %s", items[2])
            end
            missing = missingItems
        else
            missing = { objStr }
        end
        for j = 1, #missing do
            _errors[#_errors + 1] = format('[%s] = `%s` missing', i, missing[j])
        end
    end
    return entry, objStr, _errors
end

function CHC_presets:onChangePreset()
    local selected = self:getSelectedPreset()
    local currentFav = self:getCurrentFavorites()
    if not selected or not currentFav then return end
    if selected.text == self.defaultPresetName then
        local sub = self.window:getActiveSubView()
        sub.view.needUpdateFavorites = true
        return
    end
    local ui_type = CHC_main.common.getCurrentUiType(self.window)
    local presetStorage = self:getPresetStorage()
    local to_load = presetStorage[selected.text]
    if not to_load then return end

    local objects = {}
    local validObjects = {}
    local fullTypes = {}
    local errors = {}
    local errMap = {}
    for i, value in pairs(to_load) do
        local obj, objFullType, err = self:validatePreset(i, value, ui_type)
        objects[#objects + 1] = obj
        fullTypes[#fullTypes + 1] = objFullType
        if not utils.empty(err) then
            errMap[objFullType] = true
            errors = utils.concat(errors, err)
        else
            validObjects[#validObjects + 1] = obj
        end
    end

    local function handleErrors(_, button)
        if button.internal == "CANCEL" then
            -- remove missing and save
            local valid = {}
            for i = 1, #fullTypes do
                if not errMap[fullTypes[i]] then
                    valid[#valid + 1] = fullTypes[i]
                end
            end
            if utils.empty(valid) then
                -- remove preset and select default
                presetStorage[selected.text] = nil
                self:saveData()
                self:updatePresets()
                return
            end
            presetStorage[selected.text] = valid
            objects = validObjects
            selected.data.count = #objects
            self:updateTooltipData(selected.tooltip, ui_type, valid, 20)
            self:saveData()
        end
        -- load preset
        CHC_view.refreshObjList(currentFav.parent, objects)
    end

    if not utils.empty(errors) then
        local params = {
            _parent = self.window,
            outerParent = button.parent.outerParent,
            type = ISTextBox,
            text = getText("UI_BottomPanel_onChangePreset_Validation_Title"),
            onclick = handleErrors,
            defaultEntryText = concat(errors, "\n"),
            width = 450,
            height = 450
        }
        local modal = self:addModal(params)
        modal.yes:setTitle(getText("UI_BottomPanel_onChangePreset_Validation_LoadAnyway"))
        modal.no:setTitle(getText("UI_BottomPanel_onChangePreset_Validation_Remove"))
        modal.yes:setWidthToTitle()
        modal.no:setWidthToTitle()
        modal.entry:setMultipleLine(true)
        modal.entry:setEditable(true)
        modal.entry:addScrollBars()
        modal.entry:setHeight(modal.height - modal.yes.height - 40)

        modal.entry:setY(25)
    else
        CHC_view.refreshObjList(currentFav.parent, objects)
    end
end

function CHC_presets:transformFavoriteObjListToModData(ui_type, asMap)
    local favorites = self:getCurrentFavorites()
    if not favorites then return end
    local entries = {}
    for i = 1, #favorites.items do
        local entryname = favorites.items[i].item
        if ui_type == "items" then
            entryname = CHC_main.common.getFavItemModDataStr(entryname)
        elseif ui_type == "recipes" then
            entryname = CHC_main.common.getFavoriteRecipeModDataString(entryname)
        else
            error("unknown ui_type")
        end
        if asMap then
            entries[entryname] = true
        else
            entries[#entries + 1] = entryname
        end
    end
    return entries
end

function CHC_presets:getSelectedPreset()
    local options = self.categorySelector.options
    local selected = self.categorySelector.selected
    if not options or selected <= 0 then return end
    return options[selected]
end

--region render
function CHC_presets:prerenderSelector()
    CHC_filter_row.prerenderSelector(self)
    if PresetTooltip.tooltipsUsedNum > 0 and self.popup and not self.expanded then
        PresetTooltip.releaseAll()
    end
end

function CHC_presets:doDrawItemSelectorPopup(y, item, alt)
    y = ISComboBoxPopup.doDrawItem(self, y, item, alt)
    local data = self.parentCombo:getOptionData(item.index)
    if not data or not data.count or type(data.count) ~= "number" then return y end
    local tooltip = self.parentCombo:getOptionTooltip(item.index)
    if self:isMouseOver() and tooltip and item.index == self.mouseoverselected then
        tooltip:setVisible(true)
        tooltip:addToUIManager()
        tooltip:setDesiredPosition(self.x + self.width, self.y)
    else
        if tooltip and tooltip:getIsVisible() then
            tooltip:setVisible(false)
            tooltip:removeFromUIManager()
        end
    end
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

--endregion

---comment
---@param x number
---@param y number
---@param w number
---@param h number
---@param window CHC_window | ISPanel parent window
---@param moreButtonOptions {string: {icon: Texture, title: string, onclick:function, tooltip:string}} options to show when clicking on three dots button
---@param presetStorageKey string key to use in config
---@param presetFilename string? filename to save presets data to
---@return CHC_presets
function CHC_presets:new(x, y, w, h, window, moreButtonOptions, presetStorageKey, presetFilename)
    local o = {}
    o = ISPanelJoypad:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.defaultPresetName = "Select preset"
    o.moreButtonTex = CHC_window.icons.presets.more
    o.defaultItemTexName = "media/inventory/Question_On.png"
    o.needUpdatePresets = true
    o.needUpdateInfoTooltip = false
    o.window = window
    o.presetStorageKey = presetStorageKey
    o.presetFilename = presetFilename
    o.font = UIFont.Small
    o.buttonRight = false
    o.moreButtonOptions = moreButtonOptions
    return o
end

function CHC_presets:getPresetStorage()
    return CHC_settings[self.presetStorageKey][CHC_main.common.getCurrentUiType(self.window)]
end

function CHC_presets:saveData()
    CHC_settings.SavePresetsData(self.presetStorageKey, self.presetFilename)
end
