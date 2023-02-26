require 'CHC_main'

CHC_main.common = {}

local utils = require('CHC_utils')
local insert = table.insert
local contains = string.contains
local globalTextLimit = 1000 -- FIXME


-- parse tokens from search query, determine search type (single/multi) and query type (and/or), get state based on processTokenFunc
function CHC_main.common.searchFilter(self, q, processTokenFunc)
    local stateText = string.trim(self.searchRow.searchBar:getInternalText())
    if #stateText > globalTextLimit then
        self.searchRow:setTooltip(getText('IGUI_TextTooLongTooltip') ..
        '! (' .. #stateText .. ' > ' .. globalTextLimit .. ')')
        return true
    else
        self.searchRow:setTooltip(self.searchRow.origTooltip)
    end
    local tokens, isMultiSearch, queryType = CHC_search_bar:parseTokens(stateText)
    local tokenStates = {}
    local state = false

    if not tokens then return true end

    if isMultiSearch then
        for i = 1, #tokens do
            insert(tokenStates, processTokenFunc(self, tokens[i], q))
        end
        for i = 1, #tokenStates do
            if queryType == 'OR' then
                if tokenStates[i] then
                    state = true
                    break
                end
            end
            if queryType == 'AND' and i > #tokenStates - 1 then
                local allPrev = utils.all(tokenStates, true, 1, #tokenStates)
                if allPrev and tokenStates[i] then
                    state = true
                    break
                end
            end
        end
    else -- one token
        state = processTokenFunc(self, tokens[1], q)
    end
    return state
end

---Sets provided tooltip text to context menu option
---
---@param option table context option (context:addOption(...))
---@param text string text to set to option.description
---@param isAvailable? boolean sets availability of context option (by default true)
---@param isAdd? boolean if true - adds to existing tooltip text
---@param maxTextLength? integer max length of tooltip existing text, if isAdd=true (by default 100)
function CHC_main.common.setTooltipToCtx(option, text, isAvailable, isAdd, maxTextLength)
    maxTextLength = tonumber(maxTextLength) or 100
    if isAvailable == nil then isAvailable = true end
    local _tooltip
    if isAdd then
        _tooltip = option.toolTip
        text = string.sub(_tooltip.description, 1, maxTextLength) .. ' ... ' .. '<LINE>' .. text
    else
        _tooltip = ISToolTip:new()
        _tooltip:initialise()
        _tooltip:setVisible(false)
    end
    option.notAvailable = not isAvailable
    _tooltip.description = text
    option.toolTip = _tooltip
end

function CHC_main.common.addTooltipNumRecipes(option, item)
    local fullType = item.fullType or item:getFullType()
    local recBy = CHC_main.recipesByItem[fullType]
    local recFor = CHC_main.recipesForItem[fullType]
    local evoRecBy = CHC_main.evoRecipesByItem[fullType]
    local evoRecFor = CHC_main.evoRecipesForItem[fullType]
    recBy = recBy and #recBy or 0
    recFor = recFor and #recFor or 0
    if evoRecBy then recBy = recBy + #evoRecBy end
    if evoRecFor then recFor = recFor + #evoRecFor end

    local text = ''
    if recBy > 0 then
        text = text .. getText('UI_item_uses_tab_name') .. ': ' .. recBy .. ' <LINE>'
    end
    if recFor > 0 then
        text = text .. getText('UI_item_craft_tab_name') .. ': ' .. recFor .. ' <LINE>'
    end
    if text then
        CHC_main.common.setTooltipToCtx(option, text)
    end
end

function CHC_main.common.getItemProps(item)
    local attrs = {}
    if CHC_settings.config.show_all_props == true then
        attrs = item.props
    else
        for i = 1, #item.props do
            local prop = item.props[i]
            if prop.ignore ~= true then
                insert(attrs, prop)
            end
        end
    end
    return attrs
end

function CHC_main.common.isEvolvedRecipeValid(recipe, containerList)
    local check = CHC_main.common.playerHasItemNearby
    local typesAvailable = {}
    for i = 1, #recipe.recipeData.possibleItems do
        if check(recipe.recipeData.possibleItems[i], containerList) then
            typesAvailable[recipe.recipeData.possibleItems[i].fullType] = true
            break
        end
    end

    local haveBaseOrResult = (check(CHC_main.items[recipe.recipeData.baseItem], containerList) or
        check(recipe.recipeData.result, containerList))
    local result = haveBaseOrResult and not utils.empty(typesAvailable)
    return result
end

function CHC_main.common.playerHasItemNearby(item, containerList)
    if not item then return false end
    if type(item) == 'string' and contains(item, '.') then

    else
        item = item.fullType
    end
    for i = 0, containerList:size() - 1 do
        if containerList:get(i):containsWithModule(item) then
            return true
        end
    end
    return false
end

function CHC_main.common.areThereRecipesForItem(item, fullType)
    if fullType then item = { fullType = fullType } end
    local cond1 = type(CHC_main.recipesByItem[item.fullType]) == 'table'
    local cond2 = type(CHC_main.recipesForItem[item.fullType]) == 'table'
    local cond3 = type(CHC_main.evoRecipesByItem[item.fullType]) == 'table'
    local cond4 = type(CHC_main.evoRecipesForItem[item.fullType]) == 'table'

    return utils.any({ cond1, cond2, cond3, cond4 }, true)
end

function CHC_main.common.fastListReturn(self, y)
    if y + self.yScroll >= self.height or
        y + self.itemheight + self.yScroll <= 0 or
        y < -self.yScroll - 1 or
        y > self.height - self.yScroll + 1 then
        return true
    end
    return false
end

