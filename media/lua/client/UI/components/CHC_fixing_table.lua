require 'ISUI/ISPanel'

CHC_fixing_table = ISPanel:derive('CHC_fixing_table')
local sort = table.sort
local find = string.find
local lower = string.lower
local upper = string.upper
local sub = string.sub
local tostring = tostring
local concat = table.concat
local utils = require('CHC_utils')

-- region create
function CHC_fixing_table:initialise()
    ISPanel.initialise(self)
end

function CHC_fixing_table:createChildren()
    ISPanel.createChildren(self)

    local x = self.padX
    local y = self.padY

    -- region search bar row
    local h = 24

    self.searchRow = CHC_search_bar:new({
            x = x,
            y = y,
            w = self.width - 2 * self.padX,
            h = h,
            backRef = self.backRef
        }, nil,
        self.onTextChange, self.searchRowHelpText, self.onCommandEntered)
    self.searchRow.anchorRight = false
    self.searchRow:initialise()
    if self.delayedSearch then self.searchRow:setTooltip(self.searchBarDelayedTooltip) end
    self.searchRow.drawBorder = false
    y = y + self.padY + self.searchRow.height
    -- endregion
    local props_h = self.height - self.searchRow.height
    self.objList = ISScrollingListBox:new(x, y, self.width - 2 * self.padX, props_h)
    self.objList.backgroundColor.a = 0
    self.objList.borderColor = { r = 0.15, g = 0.15, b = 0.15, a = 0 }
    self.objList:setFont(UIFont.NewSmall) -- TODO configurable

    self.objList.onRightMouseDown = self.onRMBDownObjList
    self.objList:initialise()
    self.objList:instantiate()

    self.objList:setY(self.objList.y + self.objList.itemheight)
    self.objList.doDrawItem = self.drawItems
    self.objList.prerender = self.prerender
    self.objList.doRepaintStencil = true
    self.objList.vscroll.backgroundColor.a = 0
    self.objList.vscroll.borderColor.a = 0.3

    -- self:addChild(self.optionsBtn)
    self:addChild(self.searchRow)
    self:addChild(self.objList)
end

-- endregion

-- region update
function CHC_fixing_table:update()
    if self.needUpdateObjects == true then
        self.needUpdateObjects = false
        self:updateObjects()
    end
end

function CHC_fixing_table:updateObjects()
    local search_state
    local fixing = self.objData
    if not fixing then return end

    local left = self.width * 0.3
    local size = 32
    self.objList:addColumn(getText('IGUI_CopyNameProps_ctx'), 0)
    self.objList:addColumn("n", left)
    self.objList:addColumn("f0", left + 1 * size)
    self.objList:addColumn("f1", left + 2 * size)
    self.objList:addColumn("r0", left + 3 * size)
    self.objList:addColumn("r1", left + 4 * size)
    if self.numSkillColumns > 0 then
        local numSkill = 1
        for i = 1, self.numSkillColumns, 2 do
            self.objList:addColumn("s" .. tostring(numSkill), left + (4 + i) * size)
            self.objList:addColumn("sl" .. tostring(numSkill), left + (5 + i) * size)
            numSkill = numSkill + 1
        end
    end

    local filteredFixing = {}
    for i = 1, #fixing do
        search_state = CHC_main.common.searchFilter(self, fixing[i], self.searchProcessToken)

        if search_state then
            filteredFixing[#filteredFixing + 1] = fixing[i]
        end
    end
    self:refreshObjList(filteredFixing)
    if self.savedPos ~= -1 then
        self.objList:ensureVisible(self.savedPos >= #self.objList.items and #self.objList.items or self.savedPos)
        self.savedPos = -1
    end
end

-- endregion

-- region render
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
function CHC_fixing_table:prerender()
    if self.items == nil then
        return;
    end

    local stencilX = 0
    local stencilY = 0
    local stencilX2 = self.width
    local stencilY2 = self.height

    self:drawRect(0, -self:getYScroll(), self.width, self.height, self.backgroundColor.a, self.backgroundColor.r,
        self.backgroundColor.g, self.backgroundColor.b);
    if self.drawBorder then
        self:drawRectBorder(0, -self:getYScroll(), self.width, self.height, self.borderColor.a, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
        stencilX = 1
        stencilY = 1
        stencilX2 = self.width - 1
        stencilY2 = self.height - 1
    end

    if self:isVScrollBarVisible() then
        stencilX2 = self.vscroll.x + 3 -- +3 because the scrollbar texture is narrower than the scrollbar width
    end

    -- This is to handle this listbox being inside a scrolling parent.
    if self.parent and self.parent:getScrollChildren() then
        stencilX = self.javaObject:clampToParentX(self:getAbsoluteX() + stencilX) - self:getAbsoluteX()
        stencilX2 = self.javaObject:clampToParentX(self:getAbsoluteX() + stencilX2) - self:getAbsoluteX()
        stencilY = self.javaObject:clampToParentY(self:getAbsoluteY() + stencilY) - self:getAbsoluteY()
        stencilY2 = self.javaObject:clampToParentY(self:getAbsoluteY() + stencilY2) - self:getAbsoluteY()
    end
    self:setStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)

    local y = 0;
    local alt = false;

    --	if self.selected ~= -1 and self.selected < 1 then
    --		self.selected = 1
    if self.selected ~= -1 and self.selected > #self.items then
        self.selected = #self.items
    end

    local altBg = self.altBgColor

    self.listHeight = 0;
    local i = 1;
    for k, v in ipairs(self.items) do
        if not v.height then v.height = self.itemheight end -- compatibililty

        if alt and altBg then
            self:drawRect(0, y, self:getWidth(), v.height - 1, altBg.r, altBg.g, altBg.b, altBg.a);
        else

        end
        v.index = i;
        local y2 = self:doDrawItem(y, v, alt);
        self.listHeight = y2;
        v.height = y2 - y
        y = y2

        alt = not alt;
        i = i + 1;
    end

    self:setScrollHeight((y));
    self:clearStencilRect();
    if self.doRepaintStencil then
        self:repaintStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)
    end

    local mouseY = self:getMouseY()
    self:updateSmoothScrolling()
    if mouseY ~= self:getMouseY() and self:isMouseOver() then
        self:onMouseMove(0, self:getMouseY() - mouseY)
    end
    self:updateTooltip()

    if self.columns and #self.columns > 0 then
        self:drawRectBorderStatic(0, 0 - self.itemheight, self.width, self.itemheight - 1, 1, self.borderColor.r,
            self.borderColor.g, self.borderColor.b);
        self:drawRectStatic(0, 0 - self.itemheight - 1, self.width, self.itemheight - 2, self.listHeaderColor.a,
            self.listHeaderColor.r, self.listHeaderColor.g, self.listHeaderColor.b);
        local dyText = (self.itemheight - FONT_HGT_SMALL) / 2
        for i = 1, #self.columns do
            local columnData = self.columns[i]
            self:drawRectStatic(columnData.size, 0 - self.itemheight, 1,
                self.itemheight + math.min(self.height, self.itemheight * #self.items - 1), 1, self.borderColor.r,
                self.borderColor.g, self.borderColor.b);
            if columnData.name then
                self:drawText(columnData.name, columnData.size + 1, 0 - self.itemheight - 1 + dyText - self:getYScroll(),
                    1, 1, 1, 1,
                    UIFont.Small);
            end
        end
    end
end

function CHC_fixing_table:drawItems(y, item, alt)
    if y + self:getYScroll() >= self.height then return y + self.itemheight end
    if y + self.itemheight + self:getYScroll() <= 0 then return y + self.itemheight end
    if y < -self:getYScroll() - 1 then return y + self.itemheight; end
    if y > self:getHeight() - self:getYScroll() + 1 then return y + self.itemheight; end

    local a = 1

    local rectP = { r = 0.3, g = 0.3, b = 0.3, a = 0 }
    local textP = { r = 1, g = 1, b = 1, a = 0.9 }

    if item.index == self.mouseoverselected then
        local sc = { x = 0, y = y, w = self.width, h = item.height - 1, a = 0.05, r = 0.75, g = 0.5, b = 0.5 }
        self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b)
    end

    if self.selected == item.index then
        rectP = { a = 0.2, r = 0.75, g = 0.5, b = 0.9 }
    end

    self:drawRect(0, (y), self.width, self.itemheight, rectP.a, rectP.r, rectP.g, rectP.b)

    self:drawRectBorder(0, (y), self.width, self.itemheight, a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b)

    if #self.columns < 2 then return y end
    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = y + self:getYScroll()
    local clipY2 = y + self:getYScroll() + self.itemheight
    if clipY < 0 then clipY = 0 end
    if clipY2 > self.height then clipY2 = self.height end

    self:clampStencilRectToParent(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.name, self.columns[1].size + 5, y, textP.r, textP.g, textP.b, textP.a, self.font)
    self:clearStencilRect()

    self:drawText(tostring(item.item.numUses), self.columns[2].size + 5, y, textP.r, textP.g, textP.b,
        textP.a, self.font)
    if #self.columns > 2 then
        self:drawText(tostring(item.item.chanceFail0), self.columns[3].size + 5, y, textP.r, textP.g, textP.b,
            textP.a, self.font)
        self:drawText(tostring(item.item.chanceFail1), self.columns[4].size + 5, y, textP.r, textP.g, textP.b,
            textP.a, self.font)
        self:drawText(tostring(item.item.condRepaired0), self.columns[5].size + 5, y, textP.r, textP.g, textP.b,
            textP.a, self.font)
        self:drawText(tostring(item.item.condRepaired1), self.columns[6].size + 5, y, textP.r, textP.g, textP.b,
            textP.a, self.font)
        for i = 6, #self.columns do
            local skillKey = item.item["skillName" .. tostring(i - 5)]
            local skillLevelKey = item.item["skillLevel" .. tostring(i - 5)]
            if skillKey then
                self:drawText(tostring(skillKey), self.columns[i + 1].size + 5, y, textP.r, textP.g,
                    textP.b,
                    textP.a, self.font)
                self:drawText(tostring(skillLevelKey), self.columns[i + 2].size + 5, y, textP.r, textP
                    .g,
                    textP.b,
                    textP.a, self.font)
            end
        end
    end

    return y + self.itemheight
end

function CHC_fixing_table:onResize()
    -- ISPanel.onResize(self)
    self.searchRow:setWidth(self.width - self.searchRow.x - 2 * self.padX)
    self.objList:setWidth(self.width - self.objList.x - 2 * self.padX)
    -- self.objList.columns[2].size = self.objList.width * 0.4
end

-- endregion

-- region logic

-- region event handlers

function CHC_fixing_table:onRMBDownObjList(x, y, item)
    if true then return end
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
    if not pinned or not blacklisted then
        CHC_settings.LoadPropsData()
        pinned = CHC_settings.mappings.pinnedItemProps
        blacklisted = CHC_settings.mappings.ignoredItemProps
    end

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

    local function handleLongText(option, value, limit, tooltipDesc, _add)
        if value > limit then
            CHC_main.common.setTooltipToCtx(option, tooltipDesc, nil, _add)
        end
    end

    local maxTextLength = 1000 --FIXME
    -- region copy submenu
    local name_opt = context:addOption(getText('IGUI_chc_Copy'), nil, nil)
    name_opt.iconTexture = CHC_window.icons.common.copy
    local subMenuName = ISContextMenu:getNew(context)
    context:addSubMenu(name_opt, subMenuName)

    subMenuName:addOption(getText('IGUI_CopyNameProps_ctx') .. ' (' .. item.name .. ')', self, chccopy, item.name)
    local value = tostring(item.value)
    if sub(value, 1, 1) == '[' then
        value = '[list]'
        if isShiftKeyDown() then
            local val = tostring(item.value)
            val = val:gsub('[%[%]]', '')
            val = val:gsub(',', '|')
            local newOpt = subMenuName:addOption(getText('IGUI_CopyValueSearchProps_ctx'), self, chccopy, val)
            CHC_main.common.setTooltipToCtx(newOpt, val)
            handleLongText(newOpt, #val, maxTextLength,
                getText('IGUI_TextTooLongTooltip') .. '! (' .. #val .. ' > ' .. maxTextLength .. ')', true)
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
    CHC_main.common.setTooltipToCtx(newOpt, item.value, nil, nil, 100)
    handleLongText(newOpt, #tostring(item.value), maxTextLength,
        getText('IGUI_TextTooLongTooltip') .. '! (' .. #tostring(item.value) .. ' > ' .. maxTextLength .. ')', true)

    -- region comparison
    local newOptFull = subMenuName:addOption(getText('IGUI_CopyNameProps_ctx') ..
        ' + ' .. getText('IGUI_CopyValueProps_ctx'), nil, nil)
    local subMenuName2 = ISContextMenu:getNew(subMenuName)
    subMenuName:addSubMenu(newOptFull, subMenuName2)
    local eq = subMenuName2:addOption('=', self, chccopy, '$' .. item.name .. '=' .. item.value)
    local ne = subMenuName2:addOption('~=', self, chccopy, '$' .. item.name .. '~=' .. item.value)
    local gt = subMenuName2:addOption('>', self, chccopy, '$' .. item.name .. '>' .. item.value)
    local lt = subMenuName2:addOption('<', self, chccopy, '$' .. item.name .. '<' .. item.value)

    for _, opt in ipairs({ eq, ne, gt, lt }) do
        CHC_main.common.setTooltipToCtx(opt, opt.param1)
        handleLongText(opt, #opt.param1, maxTextLength,
            getText('IGUI_TextTooLongTooltip') .. '! (' .. #opt.param1 .. ' > ' .. maxTextLength .. ')', true)
    end

    --endregion

    -- endregion

    -- region sort by

    -- endregion

    local name = tostring(lower(item.name))
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
        if not utils.empty(pinned) then
            context:addOption(getText('IGUI_UnpinProps_ctx') .. ' ' .. lower(getText('ContextMenu_All')), self,
                unpinAll)
        end
        if not utils.empty(blacklisted) then
            context:addOption(getText('IGUI_UnblacklistProps_ctx') .. ' ' .. lower(getText('ContextMenu_All')),
                self,
                unblacklistAll)
        end
    end
end

-- endregion

local sortFunc = function(a, b) return upper(a.name) < upper(b.name) end
function CHC_fixing_table:refreshObjList(props)
    self.objList:clear()
    sort(props, sortFunc)

    for i = 1, #props do
        self:processAddObjToObjList(props[i])
    end
end

function CHC_fixing_table:processAddObjToObjList(prop)
    local addedItem = self.objList:addItem(name, prop)

    local name = prop.name
    if not self.objList.columns or #self.objList.columns < 2 then return end
    local w = utils.strWidth(self.font, name)
    local wValue = utils.strWidth(self.font, tostring(prop.value))
    local tooltip = {}
    if w + 10 > self.objList.columns[2].size - self.objList.columns[1].size then
        tooltip[#tooltip + 1] = name
    end
    if wValue + 10 > self.objList.width - self.objList.columns[2].size then
        if #tooltip > 0 then tooltip[#tooltip + 1] = " = " end
        tooltip[#tooltip + 1] = tostring(prop.value)
    end
    if utils.empty(tooltip) then tooltip = nil else tooltip = concat(tooltip) end
    addedItem.tooltip = tooltip
end

function CHC_fixing_table:onTextChange()
    if not self.delayedSearch or self.searchRow.searchBar:getInternalText() == '' then
        CHC_view.onTextChange(self)
    end
end

function CHC_fixing_table:onCommandEntered()
    if self.delayedSearch then
        CHC_view.onCommandEntered(self)
    end
end

-- search rules
function CHC_fixing_table:searchProcessToken(token, prop)
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token, { '!', '@' }) then
        isSpecialSearch = true
        char = sub(token, 1, 1)
        token = sub(token, 2)
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
        whatCompare = lower(prop.name)
    end
    if isAllowSpecialSearch and char == '@' then
        -- search by value
        whatCompare = type(prop.value) == 'number' and prop.value or lower(prop.value)
    end
    if token and not isSpecialSearch then
        whatCompare = lower(prop.name)
    end
    state = utils.compare(whatCompare, token)
    if not token then state = true end
    return state
end

-- endregion

function CHC_fixing_table:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.font = UIFont.Medium
    o.fonthgt = getTextManager():getFontHeight(o.font)
    o.padY = 0
    o.padX = 0

    o.backRef = args.backRef

    o.searchRowHelpText = getText('UI_searchrow_info',
        getText('UI_searchrow_info_item_attributes_special'),
        getText('UI_searchrow_info_item_attributes_examples')
    )
    o.modData = CHC_menu.playerModData
    -- o.optionsBtnIcon = getTexture('media/textures/options_icon.png')

    o.isOptionsOpen = false

    o.needUpdateObjects = false
    o.objData = nil
    o.numSkillColumns = 0
    o.savedPos = -1

    o.anchorTop = true
    o.anchorLeft = true

    o.delayedSearch = CHC_settings.config.delayed_search
    o.needUpdateDelayedSearch = false
    o.searchBarDelayedTooltip = getText('IGUI_DelayedSearchBarTooltip')

    return o
end
