--Runs only once when player enters save/server (after "Click to Start" message)
require 'luautils'

CraftHelperContinued = {}
CHC_main = CraftHelperContinued
CHC_main._meta = {
    id = 'CraftHelperContinued_beta',
    -- workshopId = 2787291513,
    name = 'Craft Helper Continued Beta',
    version = '1.9b1',
    author = 'lanceris',
    previousAuthors = { 'Peanut', 'ddraigcymraeg', 'b1n0m' },
}
CHC_main.isDebug = false or getDebug()

local insert = table.insert
local utils = require('CHC_utils')
local print = utils.chcprint
local pairs = pairs
local sub = string.sub
local rawToStr = KahluaUtil.rawTostring2
local tonumber = tonumber

CheckMyModTable = CheckMyModTable or {} -- Mod Checker
CheckMyModTable[CHC_main._meta.id] = CHC_main._meta.workshopId
local cacheFileName = 'CraftHelperLuaCache.json'
local loadLua = true

local showTime = function(start, st)
    print(string.format('Loaded %s in %s seconds', st, tostring((getTimestampMs() - start) / 1000)))
end

CHC_main.init = function()
    CHC_main.allRecipes = {}
    CHC_main.recipeMap = {}
    CHC_main.recipeStringMap = {}
    CHC_main.recipesByItem = {}
    CHC_main.recipesForItem = {}
    CHC_main.allEvoRecipes = {}
    CHC_main.evoRecipesByItem = {}
    CHC_main.evoRecipesForItem = {}
    CHC_main.traits = {}
    CHC_main.traitsMap = {}
    CHC_main.freeRecipesTraits = {}
    CHC_main.traitsOnlyRecipes = {}
    CHC_main.professions = {}
    CHC_main.professionsMap = {}
    CHC_main.freeRecipesProfessions = {}
    CHC_main.skills = {}
    CHC_main.skillsMap = {}
    CHC_main.itemsManuals = {}
    CHC_main.items = {}
    CHC_main.itemsNoModule = {}
    CHC_main.itemsForSearch = {}
    CHC_main.recipesWithoutItem = {}
    CHC_main.recipesWithLua = {}
    CHC_main.luaRecipeCache = {}
    CHC_main.notAProcZone = {} -- zones from Distributions.lua without corresponding zones in ProceduralDistributions.lua
end

CHC_main.getItemByFullType = function(itemString)
    local item
    if itemString == 'Water' then
        item = CHC_main.items['Base.WaterDrop']
    elseif (string.find(itemString, 'Base%.DigitalWatch2') or string.find(itemString, 'Base%.AlarmClock2')) then
        item = nil
    else
        item = CHC_main.items[itemString]
    end
    return item
end

-- region lua stuff
CHC_main.loadLuaCache = function()
    local luaCache = utils.jsonutil.Load(cacheFileName)
    if not luaCache then
        print('Lua cache is empty, will init new one...')
        CHC_main.luaRecipeCache = {}
    else
        CHC_main.luaRecipeCache = luaCache
    end
end

CHC_main.saveLuaCache = function()
    utils.jsonutil.Save(cacheFileName, CHC_main.luaRecipeCache)
end

CHC_main.handleRecipeLua = function(luaClosure)
    local function findintable(tab, path)
        if not tab then return end
        local pos = path:find(".", 1, true)
        if pos then
            local tab = tab[path:sub(1, pos - 1)]
            if not type(tab) then
                utils.chcerror("Expected value to be table, got " .. type(tab), "handleRecipeLua", nil,
                    false)
            end
            return findintable(tab, path:sub(pos + 1, -1))
        else
            return tab[path]
        end
    end

    local res = _G[luaClosure]
    if not res then
        res = findintable(_G, luaClosure)
    end

    return res
end

CHC_main.parseOnCreate = function(recipeLua)
    -- AddItem and such
end

CHC_main.parseOnCanPerform = function(recipeLua)
    -- ???
end

CHC_main.parseOnGiveXP = function(recipeLua)
    -- AddXP, parse perk, parse amount
end
-- endregion

local function formatOutput(propName, propVal)
    if propName then
        if sub(propName, 1, 3) == 'get' then
            propName = sub(propName, 4)
        elseif sub(propName, 1, 2) == 'is' then
            propName = sub(propName, 3)
        end
    end
    if propVal then
        if type(propVal) ~= 'string' then
            propVal = math.floor(propVal * 10000) / 10000
        end
    end
    return propName, propVal
end

local function processProp(item, prop, isTypeSpecific, isSpecial)
    local propVal
    local propValRaw
    local data
    local propName = prop.name
    local mul = prop.mul
    local defVal = prop.default
    local retRaw = prop.retRaw
    local isIgnoreDefVal = prop.ignoreDefault
    if isSpecial then
        propValRaw = item[prop.path]
        if propValRaw and prop.path2 then propValRaw = propValRaw[prop.path2] end
        -- if propValRaw and prop.path3 then propValRaw = propValRaw[prop.path3] end
    else
        propValRaw = item[propName] and item[propName](item) or nil
    end
    if propValRaw then
        data = {}
        data.skip = prop.skip
        data.skipMap = prop.skipMap
        propVal = rawToStr(propValRaw)
        if tonumber(propVal) then propVal = tonumber(propVal) end
        if mul then propVal = propVal * mul end

        propName, propVal = formatOutput(propName, propVal)
        data.name = propName
        data.value = propVal
        data.isTypeSpecific = isTypeSpecific
        if retRaw then
            data.raw = propValRaw
        end
        if isIgnoreDefVal and propVal == defVal or prop.forceIgnore then
            data.ignore = true
        end -- ignore default values
        return data
    end
end

local function processPropGroup(item, propData, isTypeSpecific, isSpecial)
    local props = {}
    if not propData then return props end
    for i = 1, #propData do
        local _propData = processProp(item, propData[i], isTypeSpecific, isSpecial)
        if _propData then
            insert(props, _propData)
        end
    end
    return props
end

local function postProcess(props)
    local uniqueProps = {}
    local dupedProps = {}
    local result = {}
    for i = 1, #props do
        local prop = props[i]
        if not uniqueProps[prop.name] then
            uniqueProps[prop.name] = prop
        else
            dupedProps[prop.name] = true
        end
    end
    if uniqueProps.ActualWeight and uniqueProps.Weight and
        uniqueProps.Weight.value == uniqueProps.ActualWeight.value then
        uniqueProps.ActualWeight = nil
    end
    if uniqueProps.TeachedRecipes then
        uniqueProps.numTeachedRecipes = {
            isTypeSpecific = true,
            name = "numTeachedRecipes",
            value = uniqueProps.TeachedRecipes.raw:size()
        }
        uniqueProps.TeachedRecipes.raw = nil
    end
    if uniqueProps.MutuallyExclusive then
        local value = uniqueProps.MutuallyExclusive.raw:size()
        if value > 0 then
            uniqueProps.numMutuallyExclusive = {
                isTypeSpecific = true,
                name = "numMutuallyExclusive",
                value = value
            }
            uniqueProps.MutuallyExclusive.raw = nil
        else
            uniqueProps.MutuallyExclusive = nil
        end
    end
    if uniqueProps.XPBoostMap then
        local tbl = transformIntoKahluaTable(uniqueProps.XPBoostMap.raw)
        if not utils.empty(tbl) then
            uniqueProps._XPBoostMap = {
                isTypeSpecific = true,
                name = "_XPBoostMap",
                value = tbl,
                skip = true
            }
        end
        uniqueProps.XPBoostMap = nil
    end
    if uniqueProps.Description then
        -- can't remove pagination :( (seems java side zombie.ui.TextBox.render())
        -- uniqueProps.Description.value = string.gsub(uniqueProps.Description.value, '<br>', '')
    end
    if uniqueProps.UseDelta then
        uniqueProps["UseDeltaTotal*"] = {
            isTypeSpecific = uniqueProps.UseDelta.isTypeSpecific,
            name = "UseDeltaTotal*",
            value = 1 / uniqueProps.UseDelta.value
        }
    end

    for _, prop in pairs(uniqueProps) do
        insert(result, prop)
    end

    return result, dupedProps
end

CHC_main.getItemProps = function(item, itemType, map)
    map = map or CHC_settings.itemPropsByType
    local isSpecial = map ~= CHC_settings.itemPropsByType

    local typePropData, commonPropData
    if not isSpecial then
        typePropData = map[itemType]
        commonPropData = map['Common']
    else
        typePropData = map
    end

    local props = {}
    local propsMap = {}
    local typeProps
    local dupedProps

    if not isSpecial then
        local commonProps = processPropGroup(item, commonPropData, false, false)
        for i = 1, #commonProps do insert(props, commonProps[i]) end
    end

    if itemType == 'Radio' then
        typeProps = processPropGroup(item:getDeviceData(), typePropData, true, isSpecial)
    else
        typeProps = processPropGroup(item, typePropData, true, isSpecial)
    end
    for i = 1, #typeProps do insert(props, typeProps[i]) end

    props, dupedProps = postProcess(props)
    -- if not utils.empty(dupedProps) then
    -- 	CHC_main.dupedProps.items[item:getDisplayName()] = dupedProps
    -- 	CHC_main.dupedProps.size = CHC_main.dupedProps.size + 1
    -- end

    local filteredProps = {}
    for i = 1, #props do
        local prop = props[i]
        if not propsMap[prop.name] and not props.skipMap then
            propsMap[prop.name] = prop
        end
        if not prop.skip then
            insert(filteredProps, prop)
        end
    end

    return filteredProps, propsMap
end

CHC_main.getRecipeRequiredSkills = function(recipe, n, recipeData)
    local result = {}
    for i = 1, n do
        local skill = recipe:getRequiredSkill(i - 1)
        local _perk = skill:getPerk()
        local perk = PerkFactory.getPerk(_perk)
        local perkName = perk and perk:getName() or _perk:name()
        local level = skill:getLevel()
        if level > 0 then
            local perkObj = perk and CHC_main.skillsMap[perk:getId()]
            if perkObj then
                CHC_main.setRecipeForItem(CHC_main.recipesForItem, perkObj.fullType, recipeData)
            end
            insert(result, { skill = perkName, level = level })
        end
    end
    return result
end

-- entry point
CHC_main.loadDatas = function()
    local now = getTimestampMs()
    CHC_main.init()
    CHC_main.CECData = _G['CraftingEnhancedCore']

    CHC_main.loadAllItems()
    CHC_main.loadAllCECItems()
    CHC_main.loadAllTraitsItems()
    CHC_main.loadAllProfessionItems()
    CHC_main.loadAllSkillItems()

    -- if loadLua then CHC_main.loadLuaCache() end
    --CHC_main.loadAllDistributions()

    CHC_main.loadAllRecipes()
    CHC_main.loadAllEvolvedRecipes()
    CHC_main.loadAllCECRecipes()
    CHC_main.loadAllTraitsRecipes()
    CHC_main.loadAllProfessionRecipes()
    CHC_main.loadAllSkillRecipes()

    -- if loadLua then CHC_main.saveLuaCache() end
    -- init UI
    CHC_menu.init()
    showTime(now, 'all')
    print("Initialised. Mod version: " .. CHC_main._meta.version)
end

--region item loading

CHC_main.loadAllItems = function(am)
    local function loadOneItem(item, id)
        local fullType = item:getFullName()

        if CHC_main.items[fullType] then
            -- print(string.format('Duplicate invItem fullType! (%s)', tostring(invItem:getFullType())))
            return
        end
        local invItem = instanceItem(fullType)
        local itemDisplayCategory = invItem:getDisplayCategory()

        local toinsert = {
            _id = id,
            item = invItem,
            fullType = invItem:getFullType(),
            name = invItem:getName(),
            module = item:getModule(),
            modname = invItem:getModName(),
            isVanilla = invItem:isVanilla(),
            IsDrainable = invItem:IsDrainable(),
            displayName = invItem:getDisplayName(),
            tooltip = invItem:getTooltip(),
            hidden = item:isHidden(),
            count = invItem:getCount() or 1,
            category = item:getTypeString(),
            displayCategory = itemDisplayCategory and
                getTextOrNull('IGUI_ItemCat_' .. itemDisplayCategory) or
                getText('IGUI_ItemCat_Item'),
            -- texture = invItem:getTex() -- textures are loaded on demand (CHC_main.common.cacheTex)
        }
        if toinsert.category == "Food" then
            toinsert.foodType = invItem:getFoodType()
            toinsert.isSpice = invItem:isSpice()
        end
        toinsert.module = toinsert.module and toinsert.module:getName() or nil
        -- props are loaded on demand (CHC_main.common.getItemProps)
        -- TODO: make popup with warning if searching by props ($) that this will take a while
        -- toinsert.props, toinsert.propsMap = CHC_main.getItemProps(invItem, toinsert.category)
        toinsert.type = strsplit(toinsert.fullType, ".")[2]

        CHC_main.items[toinsert.fullType] = toinsert
        insert(CHC_main.itemsForSearch, toinsert)
        if not CHC_main.itemsNoModule[toinsert.type] then
            CHC_main.itemsNoModule[toinsert.type] = { toinsert }
        else
            insert(CHC_main.itemsNoModule[toinsert.type], toinsert)
        end

        if toinsert.category == 'Literature' then
            local teachedRecipes = item:getTeachedRecipes()
            if teachedRecipes ~= nil and teachedRecipes:size() > 0 then
                for j = 0, teachedRecipes:size() - 1 do
                    local recipeString = teachedRecipes:get(j)
                    if CHC_main.itemsManuals[recipeString] == nil then
                        CHC_main.itemsManuals[recipeString] = {}
                    end
                    insert(CHC_main.itemsManuals[recipeString], CHC_main.items[toinsert.fullType])
                end
            end
        end
    end

    local allItems = getAllItems()
    local nbItems = 0
    local nbObsolete = 0
    local nbErrors = 0
    local now = getTimestampMs()
    local amount = am or allItems:size() - 1

    print('Loading items...')
    for i = 0, amount do
        local item = allItems:get(i)
        if not item:getObsolete() then
            local ok, err = pcall(loadOneItem, item, i)
            if not ok then
                utils.chcerror("Error when loading item (" .. tostring(item:getName()) .. "): " .. tostring(err), nil,
                    nil, false)
                nbErrors = nbErrors + 1
            else
                nbItems = nbItems + 1
            end
        else
            nbObsolete = nbObsolete + 1
        end
    end
    showTime(now, 'All Items')
    print(nbItems .. ' items loaded.')
    if nbObsolete > 0 then
        print(nbObsolete .. ' obsolete items skipped.')
    end
    if nbErrors > 0 then
        print(nbErrors .. ' items with errors skipped.')
    end
end

CHC_main.loadAllCECItems = function()
    if not getActivatedMods():contains('craftingEnhancedCore') then return end
    local function loadCECItem(id, data, map, _id)
        local fullType = id
        if not CHC_main.items[fullType] then
            local toinsert = {
                _id = "CEC" .. tostring(_id),
                item = data,
                fullType = 'CEC.' .. fullType,
                name = data.nameID,
                modname = 'Crafting Enhanced Core',
                isVanilla = false,
                IsDrainable = false,
                displayName = data.displayName,
                tooltip = data.tooltipDescription,
                hidden = false,
                count = 1,
                category = 'Moveable',
                displayCategory = getText('IGUI_CHC_ItemCat_Moveable'),
                texture = getTexture(data.tooltipTexture),
                textureMult = 2
            }
            toinsert.item.fullType = toinsert.fullType
            toinsert.item.getFullType = function() return toinsert.fullType end
            toinsert.props, toinsert.propsMap = CHC_main.getItemProps(data, toinsert.category, map)
            CHC_main.items[toinsert.fullType] = toinsert
            insert(CHC_main.itemsForSearch, toinsert)
        end
    end

    -- TODO: synthetic recipes for cec tables (tData.recipe)
    local map = CHC_settings.itemPropsByType.Integrations.CraftingEnhanced
    local nbItems = 0
    local nbErrors = 0
    local now = getTimestampMs()
    local ix = 0
    for tID, tData in pairs(CHC_main.CECData.tables) do
        local ok, err = pcall(loadCECItem, tID, tData, map, ix)
        ix = ix + 1
        if not ok then
            utils.chcerror("Error when loading CEC item (" .. tostring(tData.nameID) .. "): " .. tostring(err), nil, nil,
                false)
            nbErrors = nbErrors + 1
        else
            nbItems = nbItems + 1
        end
    end
    showTime(now, 'CraftingEnhancedCore Items')
    print(nbItems .. ' CEC items loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' CEC items with errors skipped.')
    end
end

CHC_main.loadAllTraitsItems = function()
    local function loadOneTrait(trait, map, _id)
        local data = {
            type = trait:getType(),
            texture = trait:getTexture(),
            displayName = trait:getLabel() .. " (Trait)",
            _leftLabel = trait:getLeftLabel(),
            _rightLabel = trait:getRightLabel(),
            cost = trait:getCost(),
            isFree = trait:isFree(),
            description = trait:getDescription(),
            freeRecipes = trait:getFreeRecipes(),
            removeInMp = trait:isRemoveInMP(),
            mutuallyExclusive = trait:getMutuallyExclusiveTraits(),
            XPBoostMap = trait:getXPBoostMap()
        }
        if data.freeRecipes:size() == 0 then data.freeRecipes = nil end
        local fullType = 'CHC_Trait.' .. data.type
        local toinsert = {
            _id = "tr" .. tostring(_id),
            item = data,
            fullType = fullType,
            name = data.displayName,
            modname = 'CHC_Trait',
            isVanilla = false,
            IsDrainable = false,
            displayName = data.displayName,
            tooltip = data.description,
            hidden = false,
            count = 1,
            category = 'Normal',
            displayCategory = 'Trait', --getText('IGUI_ItemCat_Item'),
            texture = data.texture,
            extra = 'trait',
        }
        toinsert.item.fullType = toinsert.fullType
        toinsert.item.getFullType = function() return toinsert.fullType end
        --{isTypeSpecific: bool, name: str,value: any}
        if map then
            toinsert.props, toinsert.propsMap = CHC_main.getItemProps(toinsert, toinsert.category, map)
            if toinsert.propsMap["_XPBoostMap"] then
                toinsert.XPBoostMap = toinsert.propsMap["_XPBoostMap"]
                for skill, boost in pairs(toinsert.XPBoostMap.value) do
                    local entry = {
                        isTypeSpecific = toinsert.XPBoostMap.isTypeSpecific,
                        name = tostring(skill) .. "_XPBoost",
                        value = tostring(boost)
                    }
                    insert(toinsert.props, entry)
                    toinsert.propsMap[entry.name] = entry
                end
            end
        end
        CHC_main.items[toinsert.fullType] = toinsert
        insert(CHC_main.itemsForSearch, toinsert)
        CHC_main.traitsMap[data.type] = data
        insert(CHC_main.traits, data)
    end

    local map = CHC_settings.itemPropsByType.Traits
    local nbTraits = 0
    local nbErrors = 0
    local now = getTimestampMs()
    local allTraits = TraitFactory.getTraits()
    for i = 0, allTraits:size() - 1 do
        local trait = allTraits:get(i)
        local ok, err = pcall(loadOneTrait, trait, map, i + 1)
        if not ok then
            utils.chcerror("Error when loading trait (" .. tostring(trait:getType()) .. "): " .. tostring(err), nil, nil,
                false)
            nbErrors = nbErrors + 1
        else
            nbTraits = nbTraits + 1
        end
    end
    showTime(now, 'Traits')
    print(nbTraits .. ' traits loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' traits with errors skipped.')
    end
end

CHC_main.loadAllProfessionItems = function()
    local function loadProfession(prof, map, _id)
        local item = {
            type = prof:getType(),
            name = prof:getName(),
            texture = prof:getTexture(),
            displayName = prof:getLabel() .. " (Profession)",
            _leftLabel = prof:getLeftLabel(),
            _rightLabel = prof:getRightLabel(),
            cost = prof:getCost(),
            description = prof:getDescription(),
            freeTraits = prof:getFreeTraits(),
            freeRecipes = prof:getFreeRecipes(),
            XPBoostMap = prof:getXPBoostMap(),
        }
        local fullType = 'CHC_Profession.' .. item.type
        local toinsert = {
            _id = "pr" .. tostring(_id),
            item = item,
            fullType = fullType,
            name = item.name,
            modname = 'CHC_Trait',
            isVanilla = false,
            IsDrainable = false,
            displayName = item.displayName,
            tooltip = item.description,
            hidden = false,
            count = 1,
            category = 'Normal',
            displayCategory = 'Profession', --getText('IGUI_ItemCat_Item'),
            texture = item.texture,
            extra = 'profession',
        }
        toinsert.item.fullType = toinsert.fullType
        toinsert.item.getFullType = function() return toinsert.fullType end
        if map then
            toinsert.props, toinsert.propsMap = CHC_main.getItemProps(toinsert, toinsert.category, map)
            if toinsert.propsMap["_XPBoostMap"] then
                toinsert.XPBoostMap = toinsert.propsMap["_XPBoostMap"]
                for skill, boost in pairs(toinsert.XPBoostMap.value) do
                    local entry = {
                        isTypeSpecific = toinsert.XPBoostMap.isTypeSpecific,
                        name = tostring(skill) .. "_XPBoost",
                        value = tostring(boost)
                    }
                    insert(toinsert.props, entry)
                    toinsert.propsMap[entry.name] = entry
                end
            end
        end
        CHC_main.items[toinsert.fullType] = toinsert
        insert(CHC_main.itemsForSearch, toinsert)
        CHC_main.professionsMap[item.type] = item
        insert(CHC_main.professions, item)
    end

    local map = CHC_settings.itemPropsByType.Professions
    local nbOk = 0
    local nbErrors = 0
    local now = getTimestampMs()
    local allProfessions = ProfessionFactory.getProfessions()
    for i = 0, allProfessions:size() - 1 do
        local prof = allProfessions:get(i)
        local ok, err = pcall(loadProfession, prof, map, i + 1)
        if not ok then
            utils.chcerror("Error when loading profession (" .. tostring(prof:getType()) .. "): " .. tostring(err), nil,
                nil,
                false)
            nbErrors = nbErrors + 1
        else
            nbOk = nbOk + 1
        end
    end
    showTime(now, 'Professions')
    print(nbOk .. ' professions loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' professions with errors skipped.')
    end
end

CHC_main.loadAllSkillItems = function()
    local function loadSkill(skill, map, _id)
        local item = {
            id = skill:getId(),
            index = skill:index(),
            name = skill:getName(),
            isCustom = skill:isCustom(),
            isPassiv = skill:isPassiv(),
            parent = skill:getParent(),
            displayName = skill:getName() .. " (Skill)",
        }
        item.xpForLvl = {}
        item.xpForLvlTotal = {}
        for i = 1, 10, 1 do
            item.xpForLvl[i] = skill:getXpForLevel(i)
            item.xpForLvlTotal[i] = skill:getTotalXpForLevel(i)
        end
        local fullType = 'CHC_Skill.' .. item.id
        local toinsert = {
            _id = "sk" .. tostring(_id),
            item = item,
            fullType = fullType,
            name = item.name,
            modname = 'CHC_Skill',
            isVanilla = false,
            IsDrainable = false,
            displayName = item.displayName,
            tooltip = "Skill description",
            hidden = false,
            count = 1,
            category = 'Normal',
            displayCategory = 'Skill', --getText('IGUI_ItemCat_Item'),
            texture = item.texture,
            extra = 'skill',
        }
        toinsert.item.fullType = toinsert.fullType
        toinsert.item.getFullType = function() return toinsert.fullType end
        if map then
            toinsert.props, toinsert.propsMap = CHC_main.getItemProps(toinsert, toinsert.category, map)
            if toinsert.propsMap["xpForLvl"] then
                for i = 1, 10, 1 do
                    local entry = {
                        isTypeSpecific = true,
                        name = "xpForLvl" .. tostring(i),
                        value = tostring(toinsert.item.xpForLvl[i])
                    }
                    insert(toinsert.props, entry)
                    toinsert.propsMap[entry.name] = entry
                end
                toinsert.propsMap["xpForLvl"] = nil
            end
            if toinsert.propsMap["xpForLvlTotal"] then
                for i = 1, 10, 1 do
                    local entry = {
                        isTypeSpecific = true,
                        name = "xpForLvlTotal" .. tostring(i),
                        value = tostring(toinsert.item.xpForLvlTotal[i])
                    }
                    insert(toinsert.props, entry)
                    toinsert.propsMap[entry.name] = entry
                end

                toinsert.propsMap["xpForLvlTotal"] = nil
            end
        end
        CHC_main.items[toinsert.fullType] = toinsert
        insert(CHC_main.itemsForSearch, toinsert)
        CHC_main.skillsMap[item.id] = item
        insert(CHC_main.skills, item)
    end

    local map = CHC_settings.itemPropsByType.Skills
    local nbOk = 0
    local nbErrors = 0
    local now = getTimestampMs()
    for i = 0, Perks.getMaxIndex() - 1 do
        local perk = PerkFactory.getPerk(Perks.fromIndex(i))
        local ok, err = pcall(loadSkill, perk, map, i + 1)
        if not ok then
            utils.chcerror("Error when loading skill (" .. tostring(perk:getName()) .. "): " .. tostring(err), nil,
                nil,
                false)
            nbErrors = nbErrors + 1
        else
            nbOk = nbOk + 1
        end
    end
    showTime(now, 'Skills')
    print(nbOk .. ' skills loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' skills with errors skipped.')
    end
end
--endregion

--region recipe loading

CHC_main.loadAllRecipes = function()
    local function processCEC(nearItem, CECData)
        if not CECData or not getActivatedMods():contains('craftingEnhancedCore') then return end
        local luaTestFunc
        if getActivatedMods():contains('Hydrocraft') then
            -- get isFurnitureNearby function
            luaTestFunc = _G['isFurnitureNearby']
        end
        local furniItem = {}
        for tID, table in pairs(CECData.tables) do
            if table.nameID == nearItem then
                furniItem.obj = CHC_main.items['CEC.' .. tID]
                if luaTestFunc then
                    furniItem.luaTest = luaTestFunc
                    furniItem.luaTestParam = nearItem
                else
                    furniItem.luaTest = {}
                end
            end
        end
        return furniItem
    end

    local function processHydrocraft(recipe)
        if not getActivatedMods():contains('Hydrocraft') then return end

        local luaTest = recipe:getLuaTest()
        if not luaTest then return end
        local integration = CHC_settings.integrations.Hydrocraft.luaOnTestReference
        local itemName = integration[luaTest]
        if not itemName then return end
        local furniItem = {}
        local furniItemObj = CHC_main.items[itemName]
        furniItem.obj = furniItemObj
        furniItem.luaTest = _G[luaTest] -- calling global registry to get function obj
        return furniItem
    end

    local function loadOneRecipe(recipe, id)
        local newItem = {}
        newItem._id = id
        newItem.category = recipe:getCategory() or getText('IGUI_CraftCategory_General')
        newItem.displayCategory = getTextOrNull('IGUI_CraftCategory_' .. newItem.category) or newItem.category
        newItem.recipe = recipe
        newItem.module = recipe:getModule()
        newItem.module = newItem.module and newItem.module:getName() or nil
        newItem.hidden = recipe:isHidden()
        newItem.recipeData = {}
        newItem.recipeData.lua = {}
        newItem.recipeData.lua.onCanPerform = recipe:getCanPerform()
        newItem.recipeData.category = newItem.category
        newItem.recipeData.name = recipe:getName()
        newItem.recipeData.nearItem = recipe:getNearItem()
        newItem.recipeData.needToBeLearn = recipe:needToBeLearn()
        newItem.recipeData.originalName = recipe:getOriginalname()
        if newItem.recipeData.nearItem == "Anvil" and
            not getActivatedMods():contains("Blacksmith41") then
            return
        end
        newItem.recipeData.requiredSkillCount = recipe:getRequiredSkillCount()
        if newItem.recipeData.requiredSkillCount > 0 then
            newItem.recipeData.requiredSkills = CHC_main.getRecipeRequiredSkills(recipe,
                newItem.recipeData.requiredSkillCount, newItem)
        end
        newItem.favStr = CHC_main.common.getFavoriteRecipeModDataString(newItem)


        if loadLua then
            -- local onCreate = recipe:getLuaCreate()
            -- local onTest = recipe:getLuaTest()
            local onCanPerform = recipe:getCanPerform()
            -- local onGiveXP = recipe:getLuaGiveXP()
            -- if onCreate or onTest or onCanPerform or onGiveXP then
            if onCanPerform then
                newItem.recipeData.lua = {}
                -- if onCreate then
                -- 	newItem.recipeData.lua.onCreate = CHC_main.handleRecipeLua(onCreate)
                -- end
                -- if onTest then
                -- 	newItem.recipeData.lua.onTest = CHC_main.handleRecipeLua(onTest)
                -- end
                if onCanPerform then
                    newItem.recipeData.lua.onCanPerform = CHC_main.handleRecipeLua(onCanPerform)
                end
                -- if onGiveXP then
                -- 	newItem.recipeData.lua.onGiveXP = CHC_main.handleRecipeLua(onGiveXP)
                -- end
            end
            -- if newItem.recipeData.lua then
            -- 	CHC_main.recipesWithLua[newItem.recipeData.name] = newItem.recipeData.lua
            -- end
        end


        local resultItem = recipe:getResult()
        if not resultItem then return end

        --region integrations
        --check for hydrocraft furniture
        local hydrocraftFurniture = processHydrocraft(recipe)
        if hydrocraftFurniture then
            newItem.recipeData.hydroFurniture = hydrocraftFurniture
            newItem.isNearItem = true
            CHC_main.setRecipeForItem(CHC_main.recipesByItem, hydrocraftFurniture.obj.fullType, newItem)
        end

        --check for CEC furniture
        if newItem.recipeData.nearItem then
            local CECFurniture = processCEC(newItem.recipeData.nearItem, CHC_main.CECData)
            if CECFurniture and not utils.empty(CECFurniture) then
                newItem.recipeData.CECFurniture = CECFurniture
                newItem.isNearItem = true
                CHC_main.setRecipeForItem(CHC_main.recipesByItem, CECFurniture.obj.fullType, newItem)
            end
        end

        local bookRecipe = CHC_main.itemsManuals[newItem.recipeData.originalName]
        if bookRecipe then
            for _, value in pairs(bookRecipe) do
                newItem.isBook = true
                CHC_main.setRecipeForItem(CHC_main.recipesByItem, value.fullType, newItem)
            end
        end
        --endregion

        local resultFullType = resultItem:getFullType()
        local itemres = CHC_main.getItemByFullType(resultFullType)
        if not itemres then
            itemres = CHC_main.getItemByFullType("Base." .. strsplit(resultFullType, ".")[2])
        end

        insert(CHC_main.allRecipes, newItem)
        if itemres then
            newItem.recipeData.result = itemres
            CHC_main.setRecipeForItem(CHC_main.recipesForItem, itemres.fullType, newItem)
        else
            insert(CHC_main.recipesWithoutItem, resultFullType)
        end
        local rSources = recipe:getSource()


        CHC_main.recipeMap[newItem.recipeData.originalName] = newItem
        CHC_main.recipeStringMap[newItem.favStr] = newItem

        -- Go through items needed by the recipe
        for n = 0, rSources:size() - 1 do
            -- Get the item name (not the display name)
            local rSource = rSources:get(n)
            local items = rSource:getItems()
            for k = 0, rSource:getItems():size() - 1 do
                local itemString = items:get(k)
                local item = CHC_main.getItemByFullType(itemString)

                if item then
                    CHC_main.setRecipeForItem(CHC_main.recipesByItem, item.fullType, newItem)
                end
            end
        end
    end

    print('Loading recipes...')
    local nbRecipes = 0
    local nbErrors = 0
    local now = getTimestampMs()

    -- Get all recipes in game (vanilla recipes + any mods recipes)
    local allRecipes = getAllRecipes()
    for i = 0, allRecipes:size() - 1 do
        local recipe = allRecipes:get(i)
        local ok, err = pcall(loadOneRecipe, recipe, i)
        if not ok then
            utils.chcerror("Error when loading recipe (" .. tostring(recipe:getName()) .. "): " .. tostring(err), nil,
                nil, false)
            nbErrors = nbErrors + 1
        else
            nbRecipes = nbRecipes + 1
        end
    end
    showTime(now, 'All Recipes')
    print(nbRecipes .. ' recipes loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' recipes with errors skipped.')
    end
end

CHC_main.loadAllEvolvedRecipes = function()
    local function loadOneEvolvedRecipe(recipe, _id)
        if not recipe then error("no recipe object found") end
        local data = {
            _id = "ev" .. tostring(_id),
            isEvolved = true,
            recipe = recipe,
            category = getText('IGUI_CHC_RecipeCat_Evolved'),
            displayCategory = getText('IGUI_CHC_RecipeCat_Evolved'),
            hidden = recipe:isHidden(),
            module = recipe:getModule(),
        }
        data.module = data.module and data.module:getName() or nil

        local recipeData = {
            category = data.category,
            name = recipe:getName(),
            originalName = recipe:getOriginalname(),
            untranslatedName = recipe:getUntranslatedName(),
            baseItem = recipe:getBaseItem(),
            --itemsList = recipe:getItemsList(), -- Map
            _possibleItems = recipe:getPossibleItems(), -- ArrayList
            fullResultItem = recipe:getFullResultItem(),
            isCookable = recipe:isCookable(),
            maxItems = recipe:getMaxItems(),
            addIngredientSound = recipe:getAddIngredientSound(),
            isAllowFrozenItem = recipe:isAllowFrozenItem()
        }
        recipeData.resultItem = recipeData.fullResultItem and recipe:getResultItem() or nil
        if not recipeData.resultItem then
            error("getResultItem returned nil")
        end
        if not recipeData.baseItem:contains('.') then
            local baseItem = recipeData.baseItem
            local module
            local noDot = CHC_main.items[baseItem]
            local withBase = CHC_main.items["Base." .. baseItem]
            local withResult = CHC_main.items[recipeData.fullResultItem] -- try to get module from fullresult
            local withItemType = CHC_main.itemsNoModule[baseItem]
            if noDot then
                module = noDot.module
            elseif withItemType then
                module = withItemType[1].module
            elseif withBase then -- possible conflict if base and mod have same name
                module = "Base"
            elseif withResult then
                module = withResult.module
            else
                utils.chcerror(
                    "Could not determine baseItem for evolved recipe, defaulting to Base: " .. recipeData.name, nil, nil,
                    false)
                module = "Base"
            end
            if module == "farming" then
                module = "Base"
            end
            recipeData.baseItem = module .. "." .. recipeData.baseItem
        end
        if not recipeData.fullResultItem:contains('.') then
            recipeData.fullResultItem = "Base." .. recipeData.fullResultItem
        end

        if recipeData._possibleItems then
            recipeData.possibleItems = {}
            for i = 0, recipeData._possibleItems:size() - 1 do
                local item = recipeData._possibleItems:get(i)
                local itemData = {
                    name = item:getName(),
                    use = item:getUse(),
                    fullType = item:getFullType()
                }
                -- check item for obsolete
                local _item = CHC_main.getItemByFullType(itemData.fullType)
                if _item then
                    if _item.propsMap and _item.propsMap["Spice"] and tostring(_item.propsMap["Spice"].value) == "true" or _item.isSpice == true then
                        itemData.isSpice = true
                    else
                        itemData.isSpice = false
                    end
                    insert(recipeData.possibleItems, itemData)
                end
            end
            recipeData._possibleItems = nil
        end

        data.recipeData = recipeData

        if data.recipeData.possibleItems then
            for i = 1, #data.recipeData.possibleItems do
                local itemData = data.recipeData.possibleItems[i]
                local itemres = CHC_main.getItemByFullType(itemData.fullType)
                if itemres then
                    CHC_main.setRecipeForItem(CHC_main.evoRecipesByItem, itemData.fullType, data)
                end
            end
        end

        local baseItemRes = CHC_main.getItemByFullType(data.recipeData.baseItem)
        if baseItemRes then
            CHC_main.setRecipeForItem(CHC_main.evoRecipesByItem, data.recipeData.baseItem, data)
        end

        local resultItem = CHC_main.getItemByFullType(data.recipeData.fullResultItem)
        if resultItem then
            data.recipeData.result = resultItem
            CHC_main.setRecipeForItem(CHC_main.evoRecipesForItem, data.recipeData.fullResultItem, data)
        end

        data.favStr = CHC_main.common.getFavoriteRecipeModDataString(data)
        insert(CHC_main.allEvoRecipes, data)
        CHC_main.recipeStringMap[data.favStr] = data
    end

    print('Loading evolved recipes...')
    local nbRecipes = 0
    local nbHidden = 0
    local nbErrors = 0
    local now = getTimestampMs()

    local allEvolvedRecipes = RecipeManager.getAllEvolvedRecipes()

    for i = 0, allEvolvedRecipes:size() - 1 do
        local recipe = allEvolvedRecipes:get(i)
        if not recipe:isHidden() then
            local ok, err = pcall(loadOneEvolvedRecipe, recipe, i)
            if not ok then
                utils.chcerror(
                    "Error when loading evolved recipe (" .. tostring(recipe:getName()) .. "): " .. tostring(err), nil,
                    nil,
                    false)
                nbErrors = nbErrors + 1
            else
                nbRecipes = nbRecipes + 1
            end
        else
            nbHidden = nbHidden + 1
        end
    end


    showTime(now, 'All Evolved Recipes')
    print(nbRecipes .. ' evolved recipes loaded.')
    if nbHidden > 0 then
        print(nbHidden .. ' hidden evolved recipes skipped.')
    end
    if nbErrors > 0 then
        print(nbErrors .. ' evolved recipes with errors skipped.')
    end
end

CHC_main.loadAllCECRecipes = function()
    local function getSource()

    end

    local function loadCECRecipe(tID, tData, _id)
        local newItem = {}
        newItem._id = "CEC" .. tostring(_id)
        newItem.id = tID
        newItem.category = 'CraftingEnhanced'
        newItem.displayCategory = newItem.category
        newItem.module = 'CraftingEnhancedCore'
        newItem.hidden = false
        newItem.isSynthetic = true
        newItem.recipeData = {}
        newItem.recipeData.category = newItem.category
        newItem.recipeData.name = 'Build ' .. tData.displayName
        newItem.recipeData.originalName = newItem.recipeData.name
        newItem.recipeData.displayName = tData.displayName
        newItem.recipeData.ingredients = tData.recipe
        newItem.recipeData.isSynthetic = true
        -- newItem.recipeData.nearItem = recipe:getNearItem()
        newItem.recipe = {
            getOriginalname = function() return newItem.recipeData.originalName end,
            getSource = getSource,
            getName = function() return newItem.recipeData.name end
        }

        newItem.favStr = CHC_main.common.getFavoriteRecipeModDataString(newItem)
        local resultItem = 'CEC.' .. tID
        insert(CHC_main.allRecipes, newItem)
        CHC_main.recipeStringMap[newItem.favStr] = newItem

        local itemres = CHC_main.getItemByFullType(resultItem)
        if itemres then
            newItem.recipeData.result = itemres
            CHC_main.setRecipeForItem(CHC_main.recipesForItem, itemres.fullType, newItem)
        end

        for i = 1, #tData.recipe do
            local ingrData = tData.recipe[i]
            local itemString = ingrData.type
            local item = CHC_main.getItemByFullType(itemString)
            if item then
                CHC_main.setRecipeForItem(CHC_main.recipesByItem, item.fullType, newItem)
            end
        end
        local tool = tData.requireTool
        if tool then
            if not string.contains(tool, '.') then
                tool = 'Base.' .. tool
            end
            if CHC_main.getItemByFullType(tool) then
                insert(newItem.recipeData.ingredients, { amount = 1, type = tool, isKeep = true }) -- required tool
                CHC_main.setRecipeForItem(CHC_main.recipesByItem, tool, newItem)
            end
        end
    end

    if not getActivatedMods():contains('craftingEnhancedCore') then return end
    print('Loading CraftingEnhancedCore recipes...')
    local nbRecipes = 0
    local nbErrors = 0
    local now = getTimestampMs()
    local ix = 1
    for tID, tData in pairs(CHC_main.CECData.tables) do
        local ok, err = pcall(loadCECRecipe, tID, tData, ix)
        ix = ix + 1
        if not ok then
            utils.chcerror("Error when loading CEC recipe (" .. tostring(tData.displayName) .. "): " .. tostring(err),
                nil, nil,
                false)
            nbErrors = nbErrors + 1
        else
            nbRecipes = nbRecipes + 1
        end
    end
    showTime(now, 'CraftingEnhancedCore Recipes')
    print(nbRecipes .. ' CEC recipes loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' CEC recipes with errors skipped.')
    end
end

CHC_main.loadAllTraitsRecipes = function()
    local function loadTraitFreeRecipe(trait, recipeName)
        CHC_main.setRecipeForItem(CHC_main.freeRecipesTraits, recipeName, trait)
        local recipeObj = CHC_main.recipeMap[recipeName]
        if recipeObj then
            CHC_main.setRecipeForItem(CHC_main.recipesForItem, trait.fullType, recipeObj)
        end
    end

    local nbTraits = 0
    local nbErrors = 0
    local now = getTimestampMs()
    for i = 1, #CHC_main.traits do
        local trait = CHC_main.traits[i]
        if trait.freeRecipes then
            for j = 0, trait.freeRecipes:size() - 1 do
                local recipeName = trait.freeRecipes:get(j)
                local ok, err = pcall(loadTraitFreeRecipe, trait, recipeName)
                if not ok then
                    utils.chcerror("Error when loading trait (" .. tostring(trait.type) .. "): " .. tostring(err), nil,
                        nil,
                        false)
                    nbErrors = nbErrors + 1
                else
                    nbTraits = nbTraits + 1
                end
            end
        end
    end
    showTime(now, 'Traits Recipes')
    print(nbTraits .. ' trait recipes loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' traits with errors skipped.')
    end

    for recipeName, _ in pairs(CHC_main.freeRecipesTraits) do
        if not CHC_main.itemsManuals[recipeName] then
            CHC_main.traitsOnlyRecipes[recipeName] = true
        end
    end
end

CHC_main.loadAllProfessionRecipes = function()
    local function loadProfessionFreeRecipes(prof, recipeName)
        CHC_main.setRecipeForItem(CHC_main.freeRecipesProfessions, recipeName, prof)
        local recipeObj = CHC_main.recipeMap[recipeName]
        if recipeObj then
            CHC_main.setRecipeForItem(CHC_main.recipesForItem, prof.fullType, recipeObj)
        end
    end

    -- inject profession to trait props (as obtainedBy)
    local function loadProfessionFreeTraits(prof, traitType)
        local traitObj = CHC_main.traitsMap[traitType]
        local traitItem = CHC_main.items[traitObj.fullType]
        local entry = {
            isTypeSpecific = true,
            name = "obtainedBy",
            value = prof.displayName
        }
        insert(traitItem.props, entry)
        traitItem.propsMap[entry.name] = entry
    end


    local nbRecipes = 0
    local nbErrorsRecipes = 0
    local nbTraits = 0
    local nbErrorsTraits = 0
    local now = getTimestampMs()
    for i = 1, #CHC_main.professions do
        local prof = CHC_main.professions[i]
        if prof.freeRecipes then
            for j = 0, prof.freeRecipes:size() - 1 do
                local recipeName = prof.freeRecipes:get(j)
                local ok, err = pcall(loadProfessionFreeRecipes, prof, recipeName)
                if not ok then
                    utils.chcerror(
                        "Error when loading profession free recipe (profession=" ..
                        tostring(prof.type) .. ", recipe=" .. tostring(recipeName) .. "): " .. tostring(err),
                        nil,
                        nil,
                        false)
                    nbErrorsRecipes = nbErrorsRecipes + 1
                else
                    nbRecipes = nbRecipes + 1
                end
            end
        end
        if prof.freeTraits then
            for j = 0, prof.freeTraits:size() - 1 do
                local traitType = prof.freeTraits:get(j)
                local ok, err = pcall(loadProfessionFreeTraits, prof, traitType)
                if not ok then
                    utils.chcerror(
                        "Error when loading profession free trait (profession=" ..
                        tostring(prof.type) .. ", trait=" .. tostring(traitName) .. "): " .. tostring(err),
                        nil,
                        nil,
                        false)
                    nbErrorsTraits = nbErrorsTraits + 1
                else
                    nbTraits = nbTraits + 1
                end
            end
        end
    end
    showTime(now, 'Profession free recipes and traits')
    print(nbRecipes .. ' profession free recipes loaded.')
    if nbErrorsRecipes > 0 then
        print(nbErrorsRecipes .. ' Profession free recipes with errors skipped.')
    end
    print(nbTraits .. ' profession traits loaded.')
    if nbErrorsTraits > 0 then
        print(nbErrorsTraits .. ' Profession free traits with errors skipped.')
    end
end

CHC_main.loadAllSkillRecipes = function()
    -- inject trait/proffession to skill props (as xpBoostedBy)
    local function loadSkillRecipes(itemName, type)
        local map = type == "trait" and CHC_main.traitsMap or CHC_main.professionsMap
        local obj = map[itemName]
        obj = CHC_main.items[obj.fullType]
        for i = 1, #obj.props do
            local propName = obj.props[i].name
            if utils.endswith(propName, "_XPBoost") then
                local skillObj = CHC_main.skillsMap[strsplit(propName, "_")[1]]
                if skillObj then
                    skillObj = CHC_main.items[skillObj.fullType]
                    local index = 1
                    for j = 1, #skillObj.props do
                        if utils.startswith(skillObj.props[j].name, "xpBoostedBy") then
                            index = index + 1
                        end
                    end

                    local entry = {
                        isTypeSpecific = true,
                        name = "xpBoostedBy" .. tostring(index),
                        value = obj.displayName
                    }
                    insert(skillObj.props, entry)
                    skillObj.propsMap[entry.name] = entry
                end
            end
        end
    end

    local nbOk = 0
    local nbErrors = 0
    local now = getTimestampMs()
    for i = 1, #CHC_main.traits do
        local trait = CHC_main.traits[i]
        local ok, err = pcall(loadSkillRecipes, trait.type, 'trait')
        if not ok then
            utils.chcerror("Error when loading skill traits (" .. tostring(trait.type) .. "): " .. tostring(err),
                nil,
                nil,
                false)
            nbErrors = nbErrors + 1
        else
            nbOk = nbOk + 1
        end
    end
    showTime(now, 'Skill Traits')
    print(nbOk .. ' skill traits loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' skill traits with errors skipped.')
    end


    nbOk = 0
    nbErrors = 0
    now = getTimestampMs()
    for i = 1, #CHC_main.professions do
        local prof = CHC_main.professions[i]
        local ok, err = pcall(loadSkillRecipes, prof.type, 'profession')
        if not ok then
            utils.chcerror("Error when loading skill professions (" .. tostring(prof.type) .. "): " .. tostring(err),
                nil,
                nil,
                false)
            nbErrors = nbErrors + 1
        else
            nbOk = nbOk + 1
        end
    end

    showTime(now, 'Skill Professions')
    print(nbOk .. ' skill professions loaded.')
    if nbErrors > 0 then
        print(nbErrors .. ' skill professions with errors skipped.')
    end
end

--endregion

--region misc
CHC_main.loadAllBooks = function()
    local allItems = getAllItems()
    local nbBooks = 0

    print('Loading books')
end

CHC_main.loadAllDistributions = function()
    -- first check SuburbsDistributions (for non-procedural items and procedural refs)
    -- then ProceduralDistributions
    -- TODO add junk items
    local function norm(val, min, max)
        return (val - min) / (max - min) * 100
    end

    local function processDistrib(zone, d, data, isJunk, isProcedural)
        local n = d.rolls
        -- local uniqueItems = {}
        for i = 1, #d.items, 2 do
            local itemName = d.items[i]
            if not string.contains(itemName, '.') then
                itemName = 'Base.' .. itemName
            end
            local itemNumber = d.items[i + 1]

            -- if lucky then
            --     itemNumber = itemNumber * 1.1
            -- end
            -- if unlucky then
            --     itemNumber = itemNumber * 0.9
            -- end

            local lootModifier
            if isJunk then
                lootModifier = 1.0
                itemNumber = itemNumber * 1.4
            else
                lootModifier = ItemPickerJava.getLootModifier(itemName)
            end
            local chance = (itemNumber * lootModifier) / 100.0
            local actualChance = (1 - (1 - chance) ^ n)

            if data[itemName] == nil then
                data[itemName] = {}
            end

            if data[itemName][zone] == nil then
                -- data[itemName][zone] = { chance = actualChance, rolls = n, count = 1 }
                data[itemName][zone] = actualChance
            else
                -- data[itemName][zone].chance = data[itemName][zone].chance + actualChance
                data[itemName][zone] = data[itemName][zone] + actualChance
                -- data[itemName][zone].count = data[itemName][zone].count + 1
            end
        end
    end

    local suburbs = SuburbsDistributions
    local procedural = ProceduralDistributions.list
    local data = {}

    for zone, d in pairs(suburbs) do
        if d.rolls and d.rolls > 0 and d.items then
            CHC_main.processDistrib(zone, d, data)
        end
        if not d.rolls then --check second level
            for subzone, dd in pairs(d) do
                if type(dd) == 'table' then
                    if dd.rolls and dd.rolls > 0 and dd.items then
                        local zName = string.format('%s.%s', zone, subzone)
                        CHC_main.processDistrib(zName, dd, data)
                    end
                    if dd.junk and dd.junk.rolls and dd.junk.rolls > 0 and not utils.empty(dd.junk.items) then
                        local zName = string.format('%s.%s.junk', zone, subzone)
                        CHC_main.processDistrib(zName, dd.junk, data, true)
                    end
                end
            end
        end
    end

    -- procedural from suburbs
    for zone, d in pairs(suburbs) do
        if d.procedural then
            print(string.format('smth is wrong, should not trigger (zone: %s)', zone))
        end
        for subzone, dd in pairs(d) do
            if type(dd) == 'table' then
                if dd.procedural and dd.procList then
                    for _, procEntry in pairs(dd.procList) do
                        -- weightChance and forceforX not accounted for
                        local pd = procedural[procEntry.name]
                        if pd ~= nil then
                            if pd.rolls and pd.rolls > 0 and pd.items then
                                local zName = string.format('%s.%s', zone, subzone)
                                CHC_main.processDistrib(zName, pd, data, nil, true)
                            end
                            if pd.junk and pd.junk.rolls and pd.junk.rolls > 0 and not utils.empty(pd.junk.items) then
                                local zName = string.format('%s.%s.junk', zone, subzone)
                                CHC_main.processDistrib(zName, pd, data, true, true)
                            end
                        else
                            insert(CHC_main.notAProcZone, { zone = zone, subzone = subzone, procZone = procEntry.name })
                            -- error(string.format('Procedural entry is nil (zone: %s, proc: %s)', zone .. '-' .. subzone, procEntry.name))
                        end
                    end
                end
            end
        end
    end

    for iN, t in pairs(data) do
        for zN, _ in pairs(t) do
            -- data[iN][zN].chance = round(data[iN][zN].chance * 100, 5) -- to percents (0-100) and round
            data[iN][zN] = round(data[iN][zN] * 100, 5)
        end
        table.sort(data[iN])
    end
    CHC_main.item_distrib = data
end
--endregion

CHC_main.setRecipeForItem = function(tbl, itemName, recipe)
    tbl[itemName] = tbl[itemName] or {}
    insert(tbl[itemName], recipe)
end

function CHC_main.reloadMod(key)
    if key == Keyboard.KEY_O then
        -- reload all
        CHC_main.loadDatas()
    end
    if key == Keyboard.KEY_V then
        -- reload UI
        CHC_menu.createCraftHelper()
    end
end

-- if CHC_main.isDebug then
--     Events.OnKeyPressed.Add(CHC_main.reloadMod)
-- end

local function onCreatePlayer(id)
    if getCore():isDedicated() then return end
    local player = getSpecificPlayer(id)
    if not player or not player:isLocalPlayer() then return end
    if not CHC_menu.CHC_window and MainScreen.instance.inGame then
        CHC_menu.init()
    end
end

local function onPlayerDeath(player)
    if not player:isLocalPlayer() then return end
    CHC_menu.forceCloseWindow(true)
end

-- catch all lua changes to recipes/items/etc (DoParam and stuff)
local ensureLoadedLast = function()
    Events.OnLoad.Add(function()
        CHC_main.loadDatas()
    end)
end

Events.OnLoad.Add(ensureLoadedLast)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerDeath.Add(onPlayerDeath)
