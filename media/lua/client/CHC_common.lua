require 'CHC_main'

CHC_main.common = {}

local utils = require('CHC_utils')
local insert = table.insert
local contains = string.contains
local globalTextLimit = 1000 -- FIXME


CHC_main.common.fontSizeToInternal = {
    { font = UIFont.Small,  pad = 2, icon = 10, ymin = 2 },
    { font = UIFont.Medium, pad = 4, icon = 18, ymin = -2 },
    { font = UIFont.Large,  pad = 6, icon = 24, ymin = -4 }
}

CHC_main.common.heights = {
    headers = 24,
    filter_row = 24,
    search_row = 24
}

-- parse tokens from search query, determine search type (single/multi) and query type (and/or), get state based on processTokenFunc
function CHC_main.common.searchFilter(self, q, processTokenFunc)
    local stateText = string.trim(self.searchRow.searchBar:getInternalText())
    if #stateText > globalTextLimit then
        return true
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
    elseif item.props then
        for i = 1, #item.props do
            local prop = item.props[i]
            if prop.ignore ~= true then
                insert(attrs, prop)
            end
        end
    end
    return attrs
end

function CHC_main.common.isRecipeValid(recipe, player, containerList, knownRecipes, playerSkills, nearbyIsoObjects)
    local function checkSkills()
        for i = 1, #recipe.recipeData.requiredSkills do
            local skillData = recipe.recipeData.requiredSkills[i]
            if playerSkills[skillData.skill] < skillData.level then
                -- print('skill')
                return false
            end
        end
        return true
    end

    local function checkNearItem()
        local nameToCheck
        if recipe.recipeData.nearItem then
            nearbyIsoObjects = nearbyIsoObjects[2]
            nameToCheck = recipe.recipeData.nearItem
        elseif recipe.recipeData.hydroFurniture then
            nearbyIsoObjects = nearbyIsoObjects[1]
            nameToCheck = recipe.recipeData.hydroFurniture.obj.displayName
        elseif recipe.isSynthetic then
            nearbyIsoObjects = nearbyIsoObjects[2]
            nameToCheck = recipe.recipeData.displayName
        end
        if nameToCheck and not nearbyIsoObjects[nameToCheck] then
            -- print('near')
            return false
        end
        return true
    end

    if not recipe.recipeData.result or utils.empty(recipe.recipeData.result) then
        -- print('result')
        return false
    elseif recipe.recipeData.needToBeLearn and not knownRecipes[recipe.recipeData.originalName] then
        -- print('known')
        return false
    elseif not RecipeManager.HasAllRequiredItems(recipe.recipe, player, nil, containerList) then
        -- print('items')
        return false
    elseif recipe.recipeData.requiredSkillCount ~= 0 and not checkSkills() then
        return false
    elseif (recipe.recipeData.nearItem or recipe.isNearItem) and not checkNearItem() then
        return false
        -- elseif (not hasHeat(var0, var2, var3, var1)) then -- not needed
        --     return false
    else
        if recipe.recipeData.lua.onCanPerform then
            -- print('lua')
            local luaCanPerformObj = _G[recipe.recipeData.lua.onCanPerform]
            if luaCanPerformObj then
                return luaCanPerformObj(recipe, player, nil)
            end
        end
        return true
    end
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

function CHC_main.common.getKnownRecipes(player)
    local recipes = player:getKnownRecipes()
    local result = {}
    for i = 0, recipes:size() - 1 do
        result[recipes:get(i)] = true
    end
    return result
end

function CHC_main.common.getPlayerSkills(player)
    -- local perks = player:getPerkList()
    local result = {}
    for i = 0, Perks.getMaxIndex() - 1 do
        local perk = PerkFactory.getPerk(Perks.fromIndex(i))
        if perk and perk:getParent() ~= Perks.None then
            result[perk:getName()] = player:getPerkLevel(Perks.fromIndex(i))
        end
    end
    return result
end

function CHC_main.common.getNearbyIsoObjectNames(player)
    local nearItemRadius = 2
    local plX, plY, plZ = player:getX(), player:getY(), player:getZ()
    local square
    local res = { [1] = {},[2] = {} }
    for x = -nearItemRadius, nearItemRadius do
        for y = -nearItemRadius, nearItemRadius do
            square = player:getCell():getGridSquare(plX + x, plY + y, plZ)
            if square then
                local o = square:getObjects()
                for i = 0, o:size() - 1 do
                    local obj = o:get(i):getName()
                    if obj then
                        res[2][obj] = true
                        if math.abs(x) <= 1 and math.abs(y) <= 1 then
                            res[1][obj] = true
                        end
                    end
                end
            end
        end
    end
    return res
end

function CHC_main.common.getContainersHash(containerList)
    local hashSum = 0
    for i = 0, containerList:size() - 1 do
        local itemsHash = containerList:get(i):getItems():hashCode()
        hashSum = hashSum + itemsHash
    end
    return hashSum
end

function CHC_main.common.compareContainersHash(current, prev)
    if not current then
        error("No way to compare hashes")
    end
    if not prev then prev = 0 end
    return current == prev
end
