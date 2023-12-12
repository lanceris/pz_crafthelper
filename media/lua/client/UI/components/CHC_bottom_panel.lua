require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'
local utils = require('CHC_utils')

CHC_bottom_panel = ISPanelJoypad:derive('CHC_bottom_panel')

local insert = table.insert
local pairs = pairs
--region create
function CHC_bottom_panel:initialise()
    ISPanelJoypad.initialise(self)
    self:create()
end

function CHC_bottom_panel:create()
    local x, y, w, h = 0, 0, 24, 24
    local font = UIFont.Small -- TODO: move to options

    -- region infoButton
    self.infoButton = ISButton:new(x, y, w, h, nil, self)
    self.infoButton.borderColor.a = 0
    self.infoButton.backgroundColor.a = 0
    self.infoButton:initialise()
    self.infoButton:setImage(self.infoButtonTex)
    self.infoButton.updateTooltip = self.updateInfoBtnTooltip
    self.infoButton:setTooltip(self:createInfoText())
    -- endregion

    -- region selector
    self.categorySelector = ISComboBox:new(self.infoButton.width, 0, 0, 24, self, self.onSelectorChange)
    self.categorySelector:setWidth(self.width - self.categorySelector.x - 24)
    self.categorySelector.font = font
    self.categorySelector.onChange = CHC_bottom_panel.onChangePreset
    self.categorySelector.prerender = CHC_bottom_panel.prerenderSelector
    self.categorySelector:initialise()
    self.categorySelector:setEditable(CHC_settings.config.editable_category_selector)
    -- endregion

    -- region btn
    self.moreButton = ISButton:new(self.categorySelector.x + self.categorySelector.width, 0, 24, 24, nil, self,
        self.onMoreButtonClick)
    self.moreButton.borderColor.a = 0
    self.moreButton.backgroundColor.a = 0
    self.moreButton:initialise()
    self.moreButton:setImage(self.moreButtonTex)
    self.moreButton._options = {
        save = {
            icon = getTexture("media/textures/bottom_panel/save.png"),
            title = getText("IGUI_BottomPanelMoreSave"),
            onclick = self.onMoreBtnSaveClick,
            tooltip = getText("IGUI_BottomPanelMoreSaveTooltip"),
        },
        apply = {
            icon = getTexture("media/textures/bottom_panel/apply.png"),
            title = getText("IGUI_BottomPanelMoreApply"),
            onclick = self.onMoreBtnApplyClick,
            tooltip = getText("IGUI_BottomPanelMoreApplyTooltip"),
        },
        rename = {
            icon = getTexture("media/textures/bottom_panel/rename.png"),
            title = getText("ContextMenu_RenameBag"),
            onclick = self.onMoreBtnRenameClick,
            tooltip = nil
        },
        compare = {
            icon = getTexture("media/textures/bottom_panel/compare.png"),
            title = getText("IGUI_BottomPanelMoreCompare"),
            onclick = self.onMoreBtnCompareClick,
            tooltip = getText("IGUI_BottomPanelMoreCompareTooltip"),
        },
        duplicate = {
            icon = getTexture("media/textures/CHC_copy_icon.png"),
            title = getText("IGUI_BottomPanelMoreDuplicate"),
            onclick = self.onMoreBtnDuplicateClick,
            tooltip = getText("IGUI_BottomPanelMoreDuplicateTooltip")
        },
        share = {
            icon = getTexture("media/textures/bottom_panel/share.png"),
            title = getText("IGUI_BottomPanelMoreShare"),
            onclick = self.onMoreBtnShareClick,
            tooltip = getText("IGUI_BottomPanelMoreShareTooltip")
        },
        import = {
            icon = getTexture("media/textures/bottom_panel/import.png"),
            title = getText("IGUI_BottomPanelMoreImport"),
            onclick = self.onMoreBtnImportClick,
            tooltip = getText("IGUI_BottomPanelMoreImportTooltip")
        },
        delete = {
            icon = getTexture("media/textures/bottom_panel/delete.png"),
            title = getText("IGUI_BottomPanelMoreDelete"),
            onclick = self.onMoreBtnDeleteClick,
            tooltip = getText("IGUI_BottomPanelMoreDeleteTooltip")
        },

    }
    -- endregion

    self:addChild(self.infoButton)
    self:addChild(self.categorySelector)
    self:addChild(self.moreButton)

    self.categorySelector.popup.doDrawItem = self.doDrawItemSelectorPopup
end

local modifierOptionToKey = {
    [1] = 'none',
    [2] = 'CTRL',
    [3] = 'SHIFT',
    [4] = 'CTRL + SHIFT'
}

---@return string text
function CHC_bottom_panel:createInfoText()
    local text = "<H1><LEFT> " .. getText("UI_BottomPanelInfoTitle") .. " <TEXT>\n\n"
    if not CHC_settings or not CHC_settings.keybinds then return text end
    local extra_map = {
        move_up = "recipe_selector_modifier",
        move_down = "recipe_selector_modifier",
        move_left = "category_selector_modifier",
        move_right = "category_selector_modifier",
        move_tab_left = "tab_selector_modifier",
        move_tab_right = "tab_selector_modifier",
        close_tab = "tab_close_selector_modifier"
    }
    for name, data in pairs(CHC_settings.keybinds) do
        local extra_key = modifierOptionToKey[CHC_settings.config[extra_map[name]]]
        if not extra_key or extra_key == "none" then
            extra_key = ""
        else
            extra_key = extra_key .. " + "
        end
        text = text .. " <LEFT> " .. getText("UI_optionscreen_binding_" .. data.name)
        text = text ..
            ": \n<RGB:0.3,0.9,0.3><CENTER> " .. extra_key .. Keyboard.getKeyName(data.key) .. " <RGB:0.9,0.9,0.9>\n"
    end
    return text
end

--endregion

--region update
function CHC_bottom_panel:updateInfoBtnTooltip()
    ISButton.updateTooltip(self)
    if not self.tooltipUI then return end
    local window = self.parent.parent
    self.tooltipUI.maxLineWidth = 600
    self.tooltipUI:setDesiredPosition(window.x, self:getAbsoluteY() - 300)
    self.tooltipUI.adjustPositionToAvoidOverlap = CHC_bottom_panel.adjustPositionToAvoidOverlap
end

function CHC_bottom_panel:selectDefaultPreset()
    local opt = self.categorySelector:getOptionText(1)
    self.categorySelector:select(opt)
end

function CHC_bottom_panel:updatePresets()
    local ui_type = self:getUiType()
    local presets = CHC_settings.presets[ui_type]
    if not presets then return end
    self.categorySelector:clear()
    self.categorySelector:addOption({ text = self.defaultPresetName })
    for name, data in pairs(presets) do
        local option = {
            text = name,
            data = { count = #data },
            tooltip = self:createTooltip(ui_type, data)
        }
        self.categorySelector:addOption(option)
    end
    self:selectDefaultPreset()
end

function CHC_bottom_panel:update()
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


--- get item object from string
---@param str string item FullType (Base.Hammer)
function CHC_bottom_panel:parseItemString(str)
    return CHC_main.items[str]
end

--- get recipe object from string
---@param str string recipe string (craftingFavorite:Recipe Name:Module.Item1:Module.Item2)
function CHC_bottom_panel:parseRecipeString(str)
    return CHC_main.recipeStringMap[str]
end

function CHC_bottom_panel:getItemTooltip(str)
    local item = self:parseItemString(str)
    local entry = {}
    if not item then return entry end
    insert(entry, "<IMAGE:")
    if item.texture_name then
        insert(entry, item.texture_name)
    else
        insert(entry, self.defaultItemTexName)
    end
    insert(entry, "> ")
    insert(entry, item.displayName)
    insert(entry, "\n")
    return table.concat(entry, "")
end

function CHC_bottom_panel:getRecipeTooltip(str)
    local recipe = self:parseRecipeString(str)
    local entry = {}
    if not recipe then return entry end
    local resultItem = recipe.recipeData.result
    if resultItem and resultItem.texture_name then
        insert(entry, "<IMAGE:")
        insert(entry, resultItem.texture_name)
        insert(entry, "> ")
    end
    insert(entry, recipe.recipeData.name)
    insert(entry, "\n")
    return table.concat(entry, "")
end

function CHC_bottom_panel:createTooltip(ui_type, objs, limit)
    limit = limit or 20
    limit = math.min(#objs, limit)
    local handlers = {
        items = CHC_bottom_panel.getItemTooltip,
        recipes = CHC_bottom_panel.getRecipeTooltip
    }
    local tooltip = { "<SIZE:small>" }
    for i = 1, limit do
        insert(tooltip, handlers[ui_type](self, objs[i]))
    end
    if #objs > limit then
        insert(tooltip, "... + " .. #objs - limit)
    end

    return table.concat(tooltip, "")
end

function CHC_bottom_panel:getUiType()
    local subview = self.window:getActiveSubView()
    if not subview then return end
    return subview.view.isItemView and "items" or "recipes"
end

function CHC_bottom_panel:getCurrentFavorites()
    local subview = self.window:getActiveSubView()
    if not subview then return end
    return subview.view.objList
end

function CHC_bottom_panel:getCurrentFavoritesFromModData(ui_type)
    local favorites = {}
    if ui_type == "items" then
        for key, _ in pairs(CHC_menu.playerModData.CHC_item_favorites) do
            insert(favorites, key)
        end
    elseif ui_type == "recipes" then
        for key, value in pairs(CHC_menu.playerModData) do
            if utils.startswith(key, "craftingFavorite:") and value == true then
                insert(favorites, key)
            end
        end
    end
    return favorites
end

function CHC_bottom_panel:onMoreButtonClick(button)
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 24, y)

    for _, option in pairs(button._options) do
        local opt = context:addOption(option.title, self, option.onclick)
        if option.tooltip then
            local tooltip = ISToolTip:new()
            tooltip:initialise()
            tooltip:setName("Test")
            tooltip.description = option.tooltip
            opt.toolTip = tooltip
        end
        opt.iconTexture = option.icon
    end
end

function CHC_bottom_panel:onResize()
    self.categorySelector:setWidth(self.width - 2 * 24)
    self.moreButton:setX(self.categorySelector.x + self.categorySelector.width)
end

function CHC_bottom_panel:adjustPositionToAvoidOverlap(avoidRect)
    local myRect = { x = self.x, y = self.y, width = self.width, height = self.height }

    if self.contextMenu and not self.contextMenu.joyfocus and self.contextMenu.currentOptionRect then
        myRect.y = avoidRect.y
        local r = self:placeRight(myRect, avoidRect)
        if self:overlaps(r, avoidRect) then
            r = self:placeLeft(myRect, avoidRect)
            if self:overlaps(r, avoidRect) then
                r = self:placeAbove(myRect, avoidRect)
            end
        end
        self:setX(r.x)
        self:setY(r.y)
        return
    end

    if self:overlaps(myRect, avoidRect) then
        local r = self:placeLeft(myRect, avoidRect)
        if self:overlaps(r, avoidRect) then
            r = self:placeAbove(myRect, avoidRect)
            if self:overlaps(r, avoidRect) then
                r = self:placeRight(myRect, avoidRect)
            end
        end
        self:setX(r.x)
        self:setY(r.y)
    end
end

function CHC_bottom_panel:onChangePreset()
    -- set temporary list of items until
    local selected = self:getSelectedPreset()
    local currentFav = self:getCurrentFavorites()
    if not selected or not currentFav then return end
    if selected.text == self.defaultPresetName then
        local sub = self.window:getActiveSubView()
        sub.view.needUpdateFavorites = true
        return
    end
    local ui_type = self:getUiType()
    local to_load = CHC_settings.presets[ui_type][selected.text]
    if not to_load then return end
    local handlers = {
        items = CHC_bottom_panel.parseItemString,
        recipes = CHC_bottom_panel.parseRecipeString,
    }
    local objects = {}
    for i = 1, #to_load do
        insert(objects, handlers[ui_type](self, to_load[i]))
    end
    CHC_view.refreshObjList(currentFav.parent, objects)
end

function CHC_bottom_panel:transformFavoriteObjListToModData(ui_type, asMap)
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
            insert(entries, entryname)
        end
    end
    return entries
end

--region moreButton handlers
function CHC_bottom_panel:getSelectedPreset()
    local options = self.categorySelector.options
    local selected = self.categorySelector.selected
    if not options or selected <= 0 then return end
    return options[selected]
end

local function addModal(params, onTop)
    if not onTop then onTop = true end
    local w = params.w or 250
    local h = params.h or 100
    local x = params._parent.x + params._parent.width / 2 - w / 2
    local y = params._parent.y + params._parent.height / 2 - h / 2

    local modal = params.type:new(x, y, w, h, params.text)
    for key, value in pairs(params) do
        if not utils.any({ "type", "x", "y", "w", "h", "_parent", "text" }, key) then
            modal[key] = value
        end
    end
    modal:initialise()
    modal:addToUIManager()
    modal:setAlwaysOnTop(onTop)
    return modal
end

local function handleInvalidInput(text, params)
    local minlen = 1
    local maxlen = 50
    local len = text:len()
    local msg
    local invalid = true
    if len < minlen then
        msg = "Name too short!" .. string.format(" (%d < %d)", len, minlen)
    elseif len > maxlen then
        msg = "Name too long!" .. string.format(" (%d > %d)", len, maxlen)
        -- elseif not text:match("[a-zA-Z0-9_]") or text:match("%W") then
        --     msg = "Only letters and numbers are allowed!"
        -- elseif text:sub(1, 1):match("%d") then
        --     msg = "First character must be letter!"
    else
        invalid = false
    end

    if invalid then
        params.yesno = false
        params.text = msg
        addModal(params)
    end
    return not invalid
end

function CHC_bottom_panel:_savePreset(text)
    local ui_type = self:getUiType()
    local to_save = CHC_settings.presets[ui_type]
    to_save[text] = self:getCurrentFavoritesFromModData(ui_type)
    CHC_settings.SavePresetsData()
    self.needUpdatePresets = true
end

---Overwrite existing preset
---@param text string new preset name
---@param existing string | table<integer, string> existing preset name OR list of current favorites
---@param overwrite boolean? true if `existing` is `string`
function CHC_bottom_panel:_overwritePreset(text, existing, overwrite)
    local to_save = CHC_settings.presets[self:getUiType()]
    local to_overwrite
    if overwrite == true then
        to_overwrite = to_save[existing]
    else
        to_overwrite = existing
    end
    to_save[text] = copyTable(to_overwrite)
    if overwrite == true then
        to_save[existing] = nil
    end
    CHC_settings.SavePresetsData()
    self.needUpdatePresets = true
end

function CHC_bottom_panel:onMoreBtnSaveClick()
    local ui_type = self:getUiType()
    local to_save = CHC_settings.presets[ui_type]
    local selectedPreset = self:getSelectedPreset()

    local function onOverwritePreset(_, button, name)
        if button.internal == "YES" then
            self:_savePreset(name)
            button.parent.parent:destroy()
        end
    end

    local function savePreset(_, button)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = text,
            }
            local validInput = handleInvalidInput(text, params)
            if not validInput then return end
            if to_save[text] then
                params.parent = button.parent
                addModal(params)
            else
                self:_savePreset(text)
                button.parent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
        end
    end
    -- popup with input and save/cancel buttons
    -- check for overwriting
    -- on save add to CHC_settings.presets
    -- and save to disk
    local params = {
        type = ISTextBox,
        _parent = self.window,
        text = "Enter name:",
        defaultEntryText = "",
        onclick = savePreset,
        showError = true, -- to prevent destroying on click
        errorMsg = ""
    }
    if selectedPreset and selectedPreset.text ~= self.defaultPresetName then
        params.defaultEntryText = selectedPreset.text
    end
    addModal(params)
end

function CHC_bottom_panel:onMoreBtnApplyClick()
    -- popup "are you sure? this will overwrite existing"
    -- overwrite existing favorites with preset
    local selectedPreset = self:getSelectedPreset()
    local ui_type = self:getUiType()

    local function applyPreset(_, button)
        if button.internal ~= "YES" then return end

        local favorites = self:transformFavoriteObjListToModData(ui_type, true)
        local modData = CHC_menu.playerModData
        if ui_type == "items" then
            modData.CHC_item_favorites = favorites
        elseif ui_type == "recipes" then
            for key, value in pairs(modData) do
                if utils.startswith(key, "craftingFavorite:") and value == true then
                    modData[key] = nil
                end
            end
            for key, _ in pairs(favorites) do
                if utils.startswith(key, "craftingFavorite:") then
                    modData[key] = true
                end
            end
        end
        local sub = self.window:getActiveSubView()
        if not sub then return end
        sub.view.needUpdateFavorites = true
    end

    local msg = "This will overwrite existing favorites, are you sure?"
    local yesno = true
    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        yesno = false
        msg = "Please select preset!"
    end
    local params = {
        type = ISModalDialog,
        _parent = self.window,
        text = msg,
        yesno = yesno,
        onclick = applyPreset
    }
    addModal(params)
end

function CHC_bottom_panel:onMoreBtnRenameClick()
    -- popup with input (prefilled?) and ok/cancel buttons
    -- on ok remove old entry and add new one to CHC_settings.presets
    local selectedPreset = self:getSelectedPreset()
    local ui_type = self:getUiType()
    local to_save = CHC_settings.presets[ui_type]

    ---@param _ any
    ---@param button table
    ---@param existing string
    ---@param new string
    local function onOverwritePreset(_, button, existing, new)
        if button.internal == "YES" then
            self:_overwritePreset(new, existing, true)
            button.parent.parent:destroy()
        end
    end

    ---@param _ any
    ---@param button table
    ---@param existingName string
    local function renamePreset(_, button, existingName)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = existingName,
                param2 = text,
            }
            local validInput = handleInvalidInput(text, params)
            if not validInput then return end
            if existingName == text then
                button.parent.showError = false
            elseif to_save[text] then
                params.parent = button.parent
                addModal(params)
            else
                self:_overwritePreset(text, existingName, true)
                button.parent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
        end
    end

    local params = {
        _parent = self.window,
    }

    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        params.type = ISModalDialog
        params.yesno = false
        params.text = "Please select preset!"
        addModal(params)
    else
        params.type = ISTextBox
        params.defaultEntryText = selectedPreset.text
        params.text = "Enter new name: "
        params.onclick = renamePreset
        params.param1 = selectedPreset.text
        params.showError = true -- to prevent destroying on click
        params.errorMsg = ""
        addModal(params)
    end
end

function CHC_bottom_panel:onMoreBtnCompareClick()
    -- window with differences between favorites
    -- aka modcomparer but simpler (no ordering)
    -- close button
    local a = CHC_main
    local selected = self:getSelectedPreset()
    if not selected then return end
    local to_load = CHC_settings.presets[self:getUiType()][selected.text]
    df:df()
end

function CHC_bottom_panel:onMoreBtnDuplicateClick()
    local selectedPreset = self:getSelectedPreset()
    local ui_type = self:getUiType()
    local to_save = CHC_settings.presets[ui_type]

    local function onOverwritePreset(_, button, existing, text)
        if button.internal ~= "YES" then return end
        self:_overwritePreset(text, existing, true)
        button.parent.parent:destroy()
    end

    local function duplicatePreset(_, button, existingName)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = existingName,
                param2 = text,
            }
            local validInput = handleInvalidInput(text, params)
            if not validInput then return end
            if to_save[text] then
                params.parent = button.parent
                addModal(params)
            else
                self:_overwritePreset(text, self:transformFavoriteObjListToModData(ui_type))
                button.parent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
        end
    end

    local params = {
        _parent = self.window,
    }

    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        params.type = ISModalDialog
        params.yesno = false
        params.text = "Please select preset!"
        addModal(params)
        return
    end
    params.type = ISTextBox
    params.defaultEntryText = selectedPreset.text .. " (Copy)"
    params.text = "Enter name: "
    params.onclick = duplicatePreset
    params.param1 = selectedPreset.text
    params.showError = true -- to prevent destroying on click
    params.errorMsg = ""
    addModal(params)
end

function CHC_bottom_panel:onMoreBtnShareClick()
    local selectedPreset = self:getSelectedPreset()
    if not selectedPreset then return end
    local ui_type = self:getUiType()
    local entries = selectedPreset.text == self.defaultPresetName and
        self:getCurrentFavoritesFromModData(ui_type) or
        copyTable(CHC_settings.presets[ui_type][selectedPreset.text])
    local to_share = {
        entries = entries,
        type = ui_type,
    }
    local to_share_str = utils.tableutil.serialize(to_share)

    local function copy(_, button)
        if button.internal ~= "CANCEL" then return end
        if to_share_str then
            Clipboard.setClipboard(tostring(to_share_str))
        end
    end
    local params = {
        type = ISTextBox,
        _parent = self.window,
        width = 250,
        height = 350,
        text = "Share this string!",
        onclick = copy,
        defaultEntryText = to_share_str or "",
    }

    local modal = addModal(params)
    modal.entry:setMultipleLine(true)
    modal.entry:setEditable(true)
    modal.entry:addScrollBars()
    modal.entry:setHeight(modal.height - modal.yes.height - 40)
    modal.entry:setY(25)
    modal.no:setTitle(getText("IGUI_chc_Copy"))
end

function CHC_bottom_panel:onMoreBtnImportClick()
    -- popup with input box where user should paste string
    -- then validate string, if ok - new popup to enter name
    -- if failed - popup "incorrect string"
    -- if only some failed (i.e some mods missing - show how many will be loaded (e.g. 10/12))
    local ui_type = self:getUiType()
    local to_save = CHC_settings.presets[ui_type]

    local function onOverwritePreset(_, button, name)
        if button.internal ~= "YES" then return end
        self:_savePreset(name)
        button.parent.parent:destroy()
    end

    local function savePreset(_, button)
        if button.internal == "OK" then
            local text = button.parent.entry:getText():trim()
            local params = {
                type = ISModalDialog,
                _parent = self.window,
                text = "This preset already exist. Overwrite?",
                yesno = true,
                onclick = onOverwritePreset,
                param1 = text,
            }
            local validInput = handleInvalidInput(text, params)
            if not validInput then return end
            if to_save[text] then
                params.parent = button.parent
                addModal(params)
            else
                self:_savePreset(text)
                button.parent.showError = false
                button.parent.outerParent.showError = false
            end
        elseif button.internal == "CANCEL" then
            button.parent.showError = false
            button.parent.outerParent.showError = false
        end
    end

    local function validate(text)
        local result = { errors = {}, preset = {} }
        local fn, err = loadstring("return " .. tostring(text))
        if not fn then
            insert(result.errors, string.format("Format invalid, could not load (%s)", err))
            return result
        end
        local status, preset = pcall(fn)
        if not status or not preset then
            insert(result.errors, "Format invalid, could not load")
            preset = {}
        end
        -- validate preset values
        local _type = preset.type or ""
        _type = _type:trim()
        if _type ~= "items" and _type ~= "recipes" then
            insert(result.errors, "Preset type missing or invalid")
            preset.type = "items"
        end

        if not preset.entries or #preset.entries == 0 then
            insert(result.errors, "Preset entries missing or empty")
            preset.entries = {}
        end
        local handlers = {
            items = CHC_bottom_panel.parseItemString,
            recipes = CHC_bottom_panel.parseRecipeString,
        }
        local valid = {}
        for i = 1, #preset.entries do
            local objStr = tostring(preset.entries[i]):trim()
            local entry = handlers[preset.type](self, objStr)
            if not entry then
                insert(result.errors,
                    string.format('[%s] = "%s" missing', i, objStr)
                )
            else
                insert(valid, objStr)
            end
        end
        preset.entries = valid
        result.preset = preset
        return result
    end

    local function onclick(_, button)
        if button.internal ~= "OK" then
            button.parent.showError = false
            return
        end
        -- validate and show errors, if any
        -- if no errors - show popup to enter preset name
        local text = button.parent.entry:getText():trim()
        local validation_data = validate(text)
        local params = {
            _parent = self.window,
            outerParent = button.parent.outerParent
        }

        if not utils.empty(validation_data.errors) then
            params.type = ISModalDialog
            params.yesno = false
            params.text = table.concat(validation_data.errors, "\n")
        else
            params.type = ISTextBox
            params.text = "Entry name:"
            params.defaultEntryText = ""
            params.onclick = savePreset
            params.showError = true
            params.errorMsg = ""
        end
        addModal(params)
    end

    local params = {
        type = ISTextBox,
        _parent = self.window,
        width = 250,
        height = 350,
        onclick = onclick,
        text = "Paste preset here!",
        defaultEntryText = "",
        showError = true, -- to prevent destroying on click
        errorMsg = ""
    }

    local modal = addModal(params)
    modal.entry:setMultipleLine(true)
    modal.entry:setEditable(true)
    modal.entry:addScrollBars()
    modal.entry:setHeight(modal.height - modal.yes.height - 40)
    modal.entry:setY(25)
    modal.outerParent = modal
end

function CHC_bottom_panel:onMoreBtnDeleteClick()
    -- popup "are you sure?" and ok/cancel
    -- on ok delete entry from CHC_settings.presets and save
    -- if preset not selected - popup (ok) with msg to select preset
    local selectedPreset = self:getSelectedPreset()

    local function deletePreset(_, button)
        if button.internal ~= "YES" then return end
        local ui_type = self:getUiType()
        CHC_settings.presets[ui_type][selectedPreset.text] = nil
        CHC_settings.SavePresetsData()
        self.needUpdatePresets = true
    end

    local msg = "This will delete selected preset, are you sure?"
    local yesno = true
    if not selectedPreset or selectedPreset.text == self.defaultPresetName then
        yesno = false
        msg = "Please select preset!"
    end
    local params = {
        type = ISModalDialog,
        _parent = self.window,
        text = msg,
        yesno = yesno,
        onclick = deletePreset
    }
    addModal(params)
end

--endregion
--endregion

--region render
function CHC_bottom_panel:prerenderSelector()
    ISComboBox.prerender(self)
    local selected = self.options[self.selected]
    if self.popup and not self.expanded then
        for i = 1, #self.popup.items do
            local item = self.popup.items[i]
            local tUI = item.tooltipUI
            if tUI then
                item.tooltipUI:setVisible(false)
                item.tooltipUI:removeFromUIManager()
            end
        end
    end
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

function CHC_bottom_panel:doDrawItemSelectorPopup(y, item, alt)
    y = ISComboBoxPopup.doDrawItem(self, y, item, alt)
    local data = self.parentCombo:getOptionData(item.index)
    if not data or not data.count or type(data.count) ~= "number" then return y end
    local tooltip = self.parentCombo:getOptionTooltip(item.index)
    if self:isMouseOver() and tooltip and item.index == self.mouseoverselected then
        if not item.tooltipUI then
            item.tooltipUI = ISToolTip:new()
            item.tooltipUI.followMouse = false
            item.tooltipUI:setOwner(self.parentCombo)
            item.tooltipUI:setVisible(false)
            item.tooltipUI:setAlwaysOnTop(true)
        end
        if not item.tooltipUI:getIsVisible() then
            if string.contains(tooltip, "\n") then
                item.tooltipUI.maxLineWidth = 1000 -- don't wrap the lines
            else
                item.tooltipUI.maxLineWidth = 300
            end
            item.tooltipUI:addToUIManager()
            item.tooltipUI:setVisible(true)
        end
        item.tooltipUI.description = tooltip
        item.tooltipUI:setDesiredPosition(self.x + self.width, self.y)
    else
        if item.tooltipUI and item.tooltipUI:getIsVisible() then
            item.tooltipUI:setVisible(false)
            item.tooltipUI:removeFromUIManager()
        end
    end
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

function CHC_bottom_panel:renderInfoButtonTooltip()
    ISToolTip.render(self)
    local window = self.owner
    local ownerRect = {
        x = window:getAbsoluteX(),
        y = window:getAbsoluteY(),
        width = window.width,
        height = window
            .height
    }
    CHC_bottom_panel.adjustPositionToAvoidOverlap(self, ownerRect)
end

--endregion

function CHC_bottom_panel:new(x, y, w, h, window)
    local o = {}
    o = ISPanelJoypad:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.defaultPresetName = "Select preset"
    o.infoButtonTex = getTexture("media/textures/keybinds_help.png")
    o.moreButtonTex = getTexture("media/textures/bottom_more.png")
    o.defaultItemTexName = "media/inventory/Question_On.png"
    o.needUpdatePresets = true
    o.window = window
    return o
end
