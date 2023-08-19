require 'CHC_main'

CHC_main.common = {}

local utils = require('CHC_utils')
local error = utils.chcerror
local insert = table.insert
local contains = string.contains
local globalTextLimit = 1000 -- FIXME


CHC_main.common.fontSizeToInternal = {
    { font = UIFont.Small,  pad = 4, icon = 10 },
    { font = UIFont.Medium, pad = 4, icon = 18 },
    { font = UIFont.Large,  pad = 6, icon = 24 }
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

    if not recipe or not player then return false end
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
            local luaCanPerformFunc = recipe.recipeData.lua.onCanPerform
            if luaCanPerformFunc then
                return luaCanPerformFunc(recipe, player, nil)
            else
                return false
            end
        end
        return true
    end
end

function CHC_main.common.isEvolvedRecipeValid(recipe, containerList)
    local check = CHC_main.common.playerHasItemNearby
    -- local typesAvailable = {}
    local onlySpices = true

    for i = 1, #recipe.recipeData.possibleItems do
        local item = recipe.recipeData.possibleItems[i]
        if check(item, containerList) then
            -- typesAvailable[item.fullType] = true
            if not item.isSpice then
                onlySpices = false
                break
            end
        end
    end

    local cond1 = check(CHC_main.items[recipe.recipeData.baseItem], containerList) and not onlySpices
    local cond2 = check(CHC_main.items[recipe.recipeData.fullResultItem], containerList)
    local isValid = cond1 or cond2

    -- local haveBaseOrResult = (check(CHC_main.items[recipe.recipeData.baseItem], containerList) or
    --     check(recipe.recipeData.result, containerList))
    -- local result = haveBaseOrResult and not utils.empty(typesAvailable)
    return isValid
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

function CHC_main.common.getNearbyItems(containerList, fullTypesToCheck)
    local items = {}
    for i = 0, containerList:size() - 1 do
        for x = 0, containerList:get(i):getItems():size() - 1 do
            local item = containerList:get(i):getItems():get(x)
            local fullType = item:getFullType()
            local result = { item = item, itemObj = CHC_main.items[fullType] }
            if not fullTypesToCheck or utils.any(fullTypesToCheck, fullType) then
                result.displayNameExtra = item:getDisplayName()
                local extraItems = item:getExtraItems()
                if extraItems then
                    local extraItemObjs = {}
                    local extraItemMap = {}
                    for j = 0, extraItems:size() - 1 do
                        local obj = CHC_main.items[extraItems:get(j)]
                        if obj then
                            extraItemMap[obj.fullType] = true
                            insert(extraItemObjs, obj)
                        end
                    end
                    result.extraItemsMap = extraItemMap
                    result.extraItems = extraItemObjs
                end
                if instanceof(item, "Food") then
                    local foodData = CHC_main.common.getFoodData(item)
                    for k, v in pairs(foodData) do
                        result[k] = v
                    end
                end
                insert(items, result)
            end
        end
    end
    return items
end

function CHC_main.common._getFoodDataTemplate()
    return {
        hunger = {
            text = getText("Tooltip_food_Hunger"),
            posGood = false,
            icon = getTexture("media/textures/evolved_food_data/CHC_hunger.png")
        },
        thirst = {
            text = getText("Tooltip_food_Thirst"),
            posGood = false,
            icon = getTexture("media/textures/evolved_food_data/CHC_evolved_thirst.png")
        },
        endurance = {
            text = getText("Tooltip_food_Endurance"),
            posGood = true,
            icon = getTexture("media/textures/evolved_food_data/CHC_endurance.png")
        },
        stress = {
            text = getText("Tooltip_food_Stress"),
            posGood = false,
            icon = getTexture("media/textures/evolved_food_data/CHC_stress.png")
        },
        boredom = {
            text = getText("Tooltip_food_Boredom"),
            posGood = false,
            icon = getTexture("media/textures/evolved_food_data/CHC_boredom.png")
        },
        unhappy = {
            text = getText("Tooltip_food_Unhappiness"),
            posGood = false,
            icon = getTexture("media/textures/evolved_food_data/CHC_unhappiness.png")
        },
        nutr_calories = {
            text = getText("Tooltip_food_Calories"),
            icon = getTexture("media/textures/evolved_food_data/CHC_calories.png")
        },
        nutr_cal_carbs = {
            text = getText("Tooltip_food_Carbs")
        },
        nutr_cal_proteins = {
            text = getText("Tooltip_food_Prots")
        },
        nutr_cal_lipids = {
            text = getText("Tooltip_food_Fat")
        }
    }
end

function CHC_main.common.getFoodData(item)
    local foodDataMapping = {
        hunger = { val = round(item:getHungerChange() * 100, 0) },
        thirst = { val = round(item:getThirstChange() * 100, 0) },
        endurance = { val = round(item:getEnduranceChange() * 100, 0) },
        stress = { val = round(item:getStressChange() * 100, 0) },
        boredom = { val = round(item:getBoredomChange(), 0) },
        unhappy = { val = round(item:getUnhappyChange(), 0) },
        nutr_calories = {
            val = round(item:getCalories(), 0),
            valPrecise = round(item:getCalories(), 2)
        },
        nutr_cal_carbs = { val = round(item:getCarbohydrates(), 2) },
        nutr_cal_proteins = { val = round(item:getProteins(), 2) },
        nutr_cal_lipids = { val = round(item:getLipids(), 2) }

    }
    local foodData = CHC_main.common._getFoodDataTemplate()
    for key, value in pairs(foodDataMapping) do
        for _k, _v in pairs(value) do
            foodData[key][_k] = _v
        end
    end
    local result = {}
    result.foodData = foodData

    local extraSpices = item:getSpices()
    if extraSpices then
        local extraSpiceObjs = {}
        local extraSpiceMap = {}
        for j = 0, extraSpices:size() - 1 do
            local obj = CHC_main.items[extraSpices:get(j)]
            if obj then
                extraSpiceMap[obj.fullType] = true
                insert(extraSpiceObjs, obj)
            end
        end
        result.extraSpicesMap = extraSpiceMap
        result.extraSpices = extraSpiceObjs
    end
    return result
end

function CHC_main.common.getFoodDataSpice(baseItem, item, evoRecipe, cookLvl)
    -- zombie.scripting.objects.EvolvedRecipe.addItem
    local use = evoRecipe:getItemRecipe(item):getUse() / 100
    local var7 = cookLvl / 15 + 1

    local hung = baseItem:getHungChange()
    local var8 = math.abs(use / hung)
    if var8 > 1 then var8 = 1 end
    local calories = 0 --item:getCalories() * var7 * var8
    local proteins = 0 --item:getProteins() * var7 * var8
    local carbs = 0    -- item:getCarbohydrates() * var7 * var8
    local lipids = 0   -- item:getProteins() * var7 * var8
    local boredom = -use * 200
    local unhappy = -use * 200
    --TODO: handle if baseItem rotten (cookLvl > 8)
    local foodDataMapping = {
        hunger = { val = 0 },
        thirst = { val = 0 },
        endurance = { val = 0 },
        stress = { val = 0 },
        boredom = { val = boredom },
        unhappy = { val = unhappy },
        nutr_calories = {
            val = round(calories, 0),
            valPrecise = round(calories, 2)
        },
        nutr_cal_carbs = { val = carbs },
        nutr_cal_proteins = { val = proteins },
        nutr_cal_lipids = { val = lipids }

    }
    local foodData = CHC_main.common._getFoodDataTemplate()
    for key, value in pairs(foodDataMapping) do
        for _k, _v in pairs(value) do
            foodData[key][_k] = _v
        end
    end
    local result = {}
    result.foodData = foodData
    return result
end

function CHC_main.common.getConcreteItem(containerList, fullType)
    local item = CHC_main.common.getNearbyItems(containerList, { fullType })
    if not item then return end
    item = item[1]
    if not item then return end
    return item.item
end

function CHC_main.common.getNearbyIsoObjectNames(player)
    local nearItemRadius = 2
    local plX, plY, plZ = player:getX(), player:getY(), player:getZ()
    local square
    local res = { [1] = {}, [2] = {} }
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
        error('No way to compare hashes', 'CHC_main.common.compareContainersHash', nil, false)
    end
    if not prev then prev = 0 end
    return current == prev
end

function CHC_main.common.handleTextOverflow(labelObj, limit)
    local text = labelObj.name
    local newText = text
    local iconW = labelObj.icon and labelObj.iconSize + 3 or 0
    local ma = 100
    local textLen = round(getTextManager():MeasureStringX(labelObj.font, newText) + 3, 0) + iconW
    limit = round(limit, 0)

    if textLen > limit or textLen < limit - 5 then
        if textLen < limit then
            while textLen < limit do
                if ma < 0 or #newText >= #labelObj.origName then break end
                newText = labelObj.origName:sub(1, #newText + 1)
                textLen = getTextManager():MeasureStringX(labelObj.font, newText) + iconW
                ma = ma - 1
            end
        else
            while textLen > limit do
                if ma < 0 then break end
                newText = newText:sub(1, #newText - 1)
                textLen = getTextManager():MeasureStringX(labelObj.font, newText) + iconW
                ma = ma - 1
            end
        end
    end
    return newText
end

function CHC_main.common.getNextState(states, cur)
    if type(cur) ~= "number" then
        for key, value in pairs(states) do
            if value == cur then
                cur = key
                break
            end
        end
    end
    if type(cur) ~= "number" then utils.chcerror("Could not determine current state index", "getNextState", nil, false) end
    local newStateIx = cur + 1
    if #states < newStateIx then
        newStateIx = 1
    end
    return states[newStateIx]
end

function CHC_main.common.getRandom(options)
    return options[ZombRand(1, #options + 1)]
end

CHC_main.common.getFavItemModDataStr = function(item)
    local fullType
    if item.fullType then
        fullType = item.fullType
    elseif instanceof(item, 'InventoryItem') then
        fullType = item:getFullType()
    elseif type(item) == 'string' then
        fullType = item
    end
    local text = 'itemFavoriteCHC:' .. fullType
    return text
end

CHC_main.common.getFavoriteRecipeModDataString = function(recipe)
    if recipe.recipeData.isSynthetic then return 'testCHC' .. recipe.recipe:getOriginalname() end
    recipe = recipe.recipe
    local text = 'craftingFavorite:' .. recipe:getOriginalname()
    if instanceof(recipe, 'EvolvedRecipe') then
        text = text .. ':' .. recipe:getBaseItem()
        text = text .. ':' .. recipe:getResultItem()
    else
        for i = 0, recipe:getSource():size() - 1 do
            local source = recipe:getSource():get(i)
            for j = 1, source:getItems():size() do
                text = text .. ':' .. source:getItems():get(j - 1)
            end
        end
    end
    return text
end
