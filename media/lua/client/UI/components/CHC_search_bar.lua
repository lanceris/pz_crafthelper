require 'luautils'
require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'
require 'ISUI/ISTextEntryBox'

local utils = require('CHC_utils')

local derivative = ISPanel
CHC_search_bar = derivative:derive('CHC_search_bar')

local contains = string.contains
local insert = table.insert
local concat = table.concat

-- region create

function CHC_search_bar:initialise()
    derivative.initialise(self)
    self:create()
end

function CHC_search_bar:create()
    local x, y, w, h = self.x, self.y, self.width, self.height

    self.searchBtn = ISButton:new(0, 0, h, h, '', self, self.searchBtnOnClick)
    self.searchBtn:initialise()
    self.searchBtn.borderColor.a = 0
    self.searchBtn:setImage(self.searchIcon)
    self.searchBtn:setTooltip(getText('UI_ServerOptionDesc_Help'))
    local mw, mh = 600, 350
    local mx, my = getCore():getScreenWidth() / 2 - mw / 2, getCore():getScreenHeight() / 2 - mh / 2
    self.searchBtn.modal = ISModalRichText:new(mx, my, mw, mh, self.searchBtnOnClickText, false, nil)
    self.searchBtn.modal:initialise()
    self.searchBtn.modal:setVisible(false)
    -- self.searchBtn:addChild(self.searchBtn.modal)

    x = self.searchBtn.width

    self.searchBar = ISTextEntryBox:new('', x, 0, w - self.searchBtn.width, h)
    self.searchBar.font = UIFont.Small -- TODO: move to options
    self.searchBar:setTooltip(self.searchBarTooltip)
    self.searchBar.onCommandEntered = self.onCommandEntered
    self.searchBar:initialise()
    self.searchBar:instantiate()
    self.searchBar:setText('')
    self.searchBar:setClearButton(true)
    self.searchBarLastText = self.searchBar:getInternalText()
    self.searchBarText = self.searchBarLastText
    self.searchBar.onTextChange = self.onTextChange
    self.searchBar.onOtherKey = CHC_search_bar.onOtherKey
    self.searchBar.onRightMouseDown = self.onRightMouseDown

    self:addChild(self.searchBtn)
    self:addChild(self.searchBar)
end

-- endregion

-- region update

function CHC_search_bar:updateSearchBarLastText()
    self.searchBarLastText = self.searchBar:getText()
end

-- endregion

-- region render

function CHC_search_bar:onResize()
    self.searchBar:setWidth(self.width - self.searchBtn.width)
end

-- endregion

-- region logic

---Parses the query string with optional list of delimiters
---@param txt string search query, e.g `'t1,@t2,%t3'` or `'t1'`
---@param delim? table<number,string> table (list) of delimiters, by default `{',', '|'}`
---@return table<number,string>|nil tokens table (list) of tokens e.g `{'t1', '@t2', '%t3'}` or `{'t1'}`, `nil` if no tokens found (only `delim`)
---@return boolean isMultiSearch `true` if multiple tokens
---@return string|nil queryType type of search query ('AND' or 'OR'), `nil` if `isMultiSearch==false`
function CHC_search_bar:parseTokens(txt, delim)
    delim = delim or { ',', '|' }
    local regex = '[^' .. concat(delim) .. ']+'
    local queryType

    txt = string.trim(txt)
    if not contains(txt, ',') and not contains(txt, '|') then
        return { txt }, false, nil
    end
    if contains(txt, ',') then
        queryType = 'AND'
    elseif contains(txt, '|') then
        queryType = 'OR'
    end

    local tokens = {}
    for token in txt:gmatch(regex) do
        insert(tokens, string.trim(token))
    end
    if #tokens == 1 then
        return tokens, false, nil
    elseif not tokens then -- just sep (e.g txt=',')
        return nil, false, nil
    end
    return tokens, true, queryType
end

---Checks if `txt` starts with any of the `validSpecialChars`
---@param txt string token
---@param validSpecialChars? table<number,string>  list of special characters to check, by default `{'!', '@', '#', '$', '%', '^', '&'}`
---@return boolean isSpecial
function CHC_search_bar:isSpecialCommand(txt, validSpecialChars)
    validSpecialChars = validSpecialChars or { '!', '@', '#', '$', '%', '^', '&' }

    for i = 1, #validSpecialChars do
        if utils.startswith(txt, validSpecialChars[i]) then return true end
    end
    return false
end

function CHC_search_bar:searchBtnOnClick()
    if self.searchBtn.modal:isVisible() then
        self.searchBtn.modal:setVisible(false)
        self.searchBtn.modal:removeFromUIManager()
    else
        self.searchBtn.modal:setVisible(true)
        self.searchBtn.modal:addToUIManager()
    end
end

function CHC_search_bar:setTooltip(text)
    if not self.origTooltip then
        self.origTooltip = self.searchBarTooltip
    end
    self.searchBarTooltip = text
    self.searchBar:setTooltip(self.searchBarTooltip)
end

-- region event handlers

function CHC_search_bar:onTextChange()
    local s = self.parent
    s:updateSearchBarLastText()

    if s.onTextChangeSB ~= nil then
        s.onTextChangeSB(s.parent)
    end
end

function CHC_search_bar:onCommandEntered()
    local s = self.parent

    if s.onCommandEnteredSB ~= nil then
        s.onCommandEnteredSB(s.parent)
    end
end

function CHC_search_bar:onOtherKey(key)
    if key == Keyboard.KEY_ESCAPE then
        self:unfocus()
    end
end

-- function CHC_search_bar:onPressDown()
--     local sBar = self
--     local sBarText = sBar:getInternalText()
--     sBarText.logIndex = sBarText.logIndex - 1
--     if sBarText.logIndex < 0 then
--         sBarText.logIndex = 0
--     end
--     if sBarText.log and sBarText.log[sBarText.logIndex] then
--         sBar:setText(sBarText.log[sBarText.logIndex])
--     else
--         sBar:setText('')
--     end
-- end

-- function CHC_search_bar:onPressUp()
--     local sBar = self
--     local sBarText = sBar:getInternalText()
--     sBarText.logIndex = sBarText.logIndex + 1
--     if sBarText.logIndex > #sBarText.log then
--         sBarText.logIndex = #sBarText.log
--     end
--     if sBarText.log and sBarText.log[sBarText.logIndex] then
--         sBar:setText(sBarText.log[sBarText.logIndex])
--     end
-- end

function CHC_search_bar:onRightMouseDown()
    local s = self.parent

    local context

    local function chcpaste(_, clip)
        self:setText(clip)
        s.parent:updateObjects()
    end

    local clip = Clipboard.getClipboard()
    if clip and luautils.trim(clip) ~= '' then
        clip = string.sub(clip, 1, 100)
        context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())
        local name = context:addOption(getText('IGUI_chc_Paste') .. ' (' .. clip .. ')', self, chcpaste, clip)
        name.iconTexture = getTexture('media/textures/CHC_paste_icon.png')
    end
    if s.onRightMouseDownSB then
        s.onRightMouseDownSB(s.parent, context)
    end
end

-- endregion

-- endregion

function CHC_search_bar:new(args, searchBarTooltip, onTextChange, searchBtnOnClickText, onCommandEntered)
    local o = {};
    o = derivative:new(args.x, args.y, args.w, args.h)

    setmetatable(o, self)
    self.__index = self

    o.backRef = args.backRef
    o.background = false
    o.searchBtnOnClickText = searchBtnOnClickText
    o.onTextChangeSB = onTextChange
    o.onCommandEnteredSB = onCommandEntered
    -- o.onRightMouseDownSB = onRightMouseDown
    o.searchBarTooltip = searchBarTooltip or string.sub(getText('IGUI_CraftUI_Name_Filter'), 1, -2)
    o.searchIcon = getTexture('media/textures/search_icon.png')
    return o
end
