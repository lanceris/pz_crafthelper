require 'ISUI/ISPanel'

CHC_props_table = ISPanel:derive('CHC_props_table')
local insert = table.insert
local sort = table.sort
local find = string.find
local sub = string.sub
local utils = require('CHC_utils')

-- region create
function CHC_props_table:initialise()
    ISPanel.initialise(self)
end

function CHC_props_table:createChildren()
    ISPanel.createChildren(self)

    local x = self.padX
    local y = self.padY

    -- self.optionsUI = CHC_options_ui:new({ x = self.backRef.x + self.backRef.width, y = self.backRef.y, w = 100, h = 150,
    --     backRef = self.backRef })
    -- self.optionsUI:initialise()
    -- self.optionsUI:setTitle('Temp title')
    -- self.optionsUI:setResizable(false)
    -- self.optionsUI:setVisible(false)

    -- self.label = ISLabel:new(x, y, self.fonthgt, 'Attributes', 1, 1, 1, 1, self.font, true)
    -- self.label:initialise()
    -- y = y + self.padY + self.label.height

    -- region search bar row
    local h = 20
    -- self.optionsBtn = ISButton:new(x, y, h, h, '', self, self.onOptionsMouseDown)
    -- self.optionsBtn:initialise()
    -- self.optionsBtn.borderColor.a = 0
    -- self.optionsBtn:setImage(self.optionsBtnIcon)
    -- self.optionsBtn:setTooltip('testTooltip')


    self.searchRow = CHC_search_bar:new({ x = x, y = y, w = self.width - 2 * self.padX, h = h,
        backRef = self.backRef }, nil,
        self.onTextChange, self.searchRowHelpText)
    self.searchRow:initialise()
    self.searchRow.drawBorder = false
    y = y + self.padY + self.searchRow.height
    -- endregion
    local props_h = self.height - self.searchRow.height - 4 * self.padY -- - self.label.height
    self.objList = ISScrollingListBox:new(x, y, self.width - 2 * self.padX, props_h)
    self.objList:setFont(self.font)

    self.objList.onRightMouseDown = self.onRMBDownObjList
    self.objList:initialise()
    self.objList:instantiate()

    self.objList:setY(self.objList.y + self.objList.itemheight)
    self.objList:setHeight(self.objList.height - self.objList.itemheight)
    self.objList.vscroll:setHeight(self.objList.height)
    self.objList.drawBorder = false
    self.objList.doDrawItem = self.drawProps
    self.objList.doRepaintStencil = true

    -- TODO: add translation
    self.objList:addColumn(getText('IGUI_CopyNameProps_ctx'), 0)
    self.objList:addColumn(getText('IGUI_CopyValueProps_ctx'), self.width * 0.4)

    -- self:addChild(self.optionsBtn)
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
    local props = self.propData
    if not props then return end

    local filteredProps = {}
    for i = 1, #props do
        search_state = CHC_main.common.searchFilter(self, props[i], self.searchProcessToken)

        if search_state then
            insert(filteredProps, props[i])
        end
    end
    self:refreshObjList(filteredProps)
    if self.savedPos ~= -1 then
        self.objList:ensureVisible(self.savedPos >= #self.objList.items and #self.objList.items or self.savedPos)
        self.savedPos = -1
    end
end

-- endregion

-- region render
function CHC_props_table:drawProps(y, item, alt)
    if y + self:getYScroll() >= self.height then return y + self.itemheight end
    if y + self.itemheight + self:getYScroll() <= 0 then return y + self.itemheight end
    if y < -self:getYScroll() - 1 then return y + self.itemheight; end
    if y > self:getHeight() - self:getYScroll() + 1 then return y + self.itemheight; end

    local a = 0.9
    local xoffset = 10

    local rectP = { r = 0.3, g = 0.3, b = 0.3, a = 0 }

    if alt then
        rectP = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 }
    end

    if self.selected == item.index then
        rectP = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 }
    end

    if CHC_settings.mappings.pinnedItemProps[item.item.name:lower()] then
        rectP = { r = 1, g = 0.75, b = 0.25, a = 0.3 }
    end
    if CHC_settings.mappings.ignoredItemProps[item.item.name:lower()] then
        rectP = { r = 0.27, g = 0.15, b = 0, a = 0.75 }
    end

    self:drawRect(0, (y), self:getWidth(), self.itemheight, rectP.a, rectP.r, rectP.g, rectP.b)

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b)

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    self:clampStencilRectToParent(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.name, self.columns[1].size + 5, y, 1, 1, 1, a, self.font)
    self:clearStencilRect()

    self:drawText(tostring(item.item.value), self.columns[2].size + 5, y, 1, 1, 1, a, self.font)

    return y + self.itemheight

end

function CHC_props_table:render()
    ISPanel.render(self)
end

function CHC_props_table:onResize()
    -- ISPanel.onResize(self)
    self.searchRow:setWidth(self.width - 2 * self.padX)
    self.objList:setWidth(self.width - 2 * self.padX)
    self.objList.columns[2].size = self.objList.width * 0.4
end

-- endregion

-- region logic

-- region event handlers

function CHC_props_table:onRMBDownObjList(x, y, item)
    if not item then
        local row = self:rowAt(x, y)
        if row == -1 then return end
        item = self.items[row].item
        if not item then return end
    end

    -- item.name, item.value
    local context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())
    local pinned = CHC_settings.mappings.pinnedItemProps
    local blacklisted = CHC_settings.mappings.ignoredItemProps

    local function chccopy(_, param)
        if param then
            Clipboard.setClipboard(tostring(param))
        end
    end

    local function triggerUpdate()
        self.parent.savedPos = self:rowAt(x, y)
        self.parent.needUpdateObjects = true
    end

    local function pin(_, val, reverse)
        if reverse then
            pinned[val] = nil
        else
            pinned[val] = true
        end
        triggerUpdate()
    end

    local function unpinAll(_)
        CHC_settings.mappings.pinnedItemProps = {}
        triggerUpdate()
    end

    local function unblacklistAll(_)
        CHC_settings.mappings.ignoredItemProps = {}
        triggerUpdate()
    end

    local function blacklist(_, val, reverse)
        if reverse then
            blacklisted[val] = nil
        else
            blacklisted[val] = true
        end
        triggerUpdate()
    end

    local function _setTooltip(option, tooltip, _add)
        local _tooltip
        if _add then
            _tooltip = option.toolTip
            tooltip = string.sub(_tooltip.description, 1, 100) .. ' ... ' .. '<LINE>' .. tooltip
        else
            _tooltip = ISToolTip:new()
            _tooltip:initialise()
            _tooltip:setVisible(false)
        end
        _tooltip.description = tooltip
        option.toolTip = _tooltip
    end

    local function handleLongText(option, value, limit, tooltipDesc, _add)
        if value > limit then
            _setTooltip(option, tooltipDesc, _add)
        end
    end

    -- region copy submenu
    local name = context:addOption(getText('IGUI_chc_Copy') .. ' (' .. getText('UI_chat_local_chat_title_id') .. ')', nil
        , nil)
    local subMenuName = ISContextMenu:getNew(context)
    context:addSubMenu(name, subMenuName)

    subMenuName:addOption(getText('IGUI_CopyNameProps_ctx') .. ' (' .. item.name .. ')', self, chccopy, item.name)
    local value = tostring(item.value)
    if sub(value, 1, 1) == '[' then
        value = '[list]'
        if isShiftKeyDown() then
            local val = tostring(item.value)
            val = val:gsub('[%[%]]', '')
            val = val:gsub(',', '|')
            local newOpt = subMenuName:addOption(getText('IGUI_CopyValueSearchProps_ctx'), self, chccopy, val)
            handleLongText(newOpt, #val, 100, getText('IGUI_TextTooLongTooltip') .. '! (' .. #val .. ' > ' .. 100 .. ')')
        end
    end
    if sub(value, 1, 1) == '"' then
        -- try to interpret as an item
        value = value:gsub('"', '')
        if isShiftKeyDown() then
            local itemFromStr = CHC_main.items[value]
            if itemFromStr then
                context = self.parent.backRef.onRMBDownObjList(self, nil, nil, itemFromStr, nil, context)
            end
        end
    end
    local newOpt = subMenuName:addOption(getText('IGUI_CopyValueProps_ctx') .. ' (' .. value .. ')', self, chccopy,
        item.value)
    handleLongText(newOpt, #value, 100, getText('IGUI_TextTooLongTooltip') .. '! (' .. #value .. ' > ' .. 100 .. ')')

    -- region comparison
    local newOptFull = subMenuName:addOption(getText('IGUI_CopyNameProps_ctx') ..
        ' + ' .. getText('IGUI_CopyValueProps_ctx'), nil, nil)
    local subMenuName2 = ISContextMenu:getNew(subMenuName)
    subMenuName:addSubMenu(newOptFull, subMenuName2)
    local eq = subMenuName2:addOption('=', self, chccopy, item.name .. '=' .. item.value)
    local ne = subMenuName2:addOption('~=', self, chccopy, item.name .. '~=' .. item.value)
    local gt = subMenuName2:addOption('>', self, chccopy, item.name .. '>' .. item.value)
    local lt = subMenuName2:addOption('<', self, chccopy, item.name .. '<' .. item.value)

    for _, opt in ipairs({ eq, ne, gt, lt }) do
        _setTooltip(opt, opt.param1)
        handleLongText(opt, #opt.param1, 100,
            getText('IGUI_TextTooLongTooltip') .. '! (' .. #opt.param1 .. ' > ' .. 100 .. ')', true)
    end

    --endregion



    -- endregion

    local name = tostring(item.name:lower())
    if not blacklisted[name] then
        if pinned[name] then
            context:addOption(getText('IGUI_UnpinProps_ctx'), self, pin, name, true)
        else
            context:addOption(getText('IGUI_PinProps_ctx'), self, pin, name, false)
        end
    end
    if not pinned[name] then
        if blacklisted[name] then
            context:addOption(getText('IGUI_UnblacklistProps_ctx'), self, blacklist, name, true)
        else
            context:addOption(getText('IGUI_BlacklistProps_ctx'), self, blacklist, name, false)
        end
    end

    if isShiftKeyDown() then
        context:addOption(getText('IGUI_UnpinProps_ctx') .. ' ' .. string.lower(getText('ContextMenu_All')), self,
            unpinAll)
        context:addOption(getText('IGUI_UnblacklistProps_ctx') .. ' ' .. string.lower(getText('ContextMenu_All')), self,
            unblacklistAll)
    end

end

-- function CHC_props_table:onOptionsMouseDown(x, y)
--     CHC_menu.toggleUI(self.optionsUI)
--     self.optionsUI:setPosition()
-- end

-- endregion

function CHC_props_table:refreshObjList(props)
    self.objList:clear()
    self.objList:setScrollHeight(0)

    local blacklisted = CHC_settings.mappings.ignoredItemProps
    local pinned = CHC_settings.mappings.pinnedItemProps

    local pinnedItems = {}
    local blacklistedItems = {}
    local usualItems = {}
    for i = 1, #props do
        if pinned[props[i].name:lower()] then
            insert(pinnedItems, props[i])
        elseif blacklisted[props[i].name:lower()] then
            insert(blacklistedItems, props[i])
        else
            insert(usualItems, props[i])
        end
    end

    local sortFunc = function(a, b) return a.name:upper() < b.name:upper() end
    sort(pinnedItems, sortFunc)
    sort(usualItems, sortFunc)
    sort(blacklistedItems, sortFunc)

    local items = {}

    for i = 1, #pinnedItems do insert(items, pinnedItems[i]) end
    for i = 1, #usualItems do insert(items, usualItems[i]) end
    for i = 1, #blacklistedItems do insert(items, blacklistedItems[i]) end

    for i = 1, #items do
        self:processAddObjToObjList(items[i])
    end
    -- TODO: add filter button
end

function CHC_props_table:processAddObjToObjList(prop)
    local name = prop.name
    -- if bl[name:lower()] then return end
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

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token, { '!', '@' }) then
        isSpecialSearch = true
        char = token:sub(1, 1)
        token = string.sub(token, 2)
    end

    local whatCompare
    if not isSpecialSearch then
        local opIx = find(token, '[><=]')
        if opIx then
            opIx = find(token, '[~><=]')
            local whatCompName = prop.name
            local toCompName = sub(token, 1, opIx - 1)
            local stateName = utils.compare(whatCompName, toCompName)

            local whatCompVal = prop.value
            local toCompVal = sub(token, opIx, #token)
            local stateVal = utils.compare(whatCompVal, toCompVal)

            if stateName and stateVal then return true end
            return false
        end
    end

    if isAllowSpecialSearch and char == '!' then
        -- search by name
        whatCompare = string.lower(prop.name)
    end
    if isAllowSpecialSearch and char == '@' then
        -- search by value
        whatCompare = type(prop.value) == 'number' and prop.value or string.lower(prop.value)
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

    o.backRef = args.backRef

    o.searchRowHelpText = getText('UI_searchrow_info',
        getText('UI_searchrow_info_item_attributes_special'),
        getText('UI_searchrow_info_item_attributes_examples')
    )
    o.modData = CHC_main.playerModData
    -- o.optionsBtnIcon = getTexture('media/textures/options_icon.png')

    o.isOptionsOpen = false

    o.needUpdateObjects = false
    o.propData = nil
    o.savedPos = -1

    return o
end
