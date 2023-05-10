require 'luautils'

CraftHelperContinued = {}
CHC_main = CraftHelperContinued
CHC_main._meta = {
	id = 'CraftHelperContinued',
	workshopId = 2787291513,
	name = 'Craft Helper Continued',
	version = '1.7.3',
	author = 'lanceris',
	previousAuthors = { 'Peanut', 'ddraigcymraeg', 'b1n0m' },
}
CHC_main.allRecipes = {}
CHC_main.recipesByItem = {}
CHC_main.recipesForItem = {}
CHC_main.allEvoRecipes = {}
CHC_main.evoRecipesByItem = {}
CHC_main.evoRecipesForItem = {}
CHC_main.itemsManuals = {}
CHC_main.items = {}
CHC_main.itemsForSearch = {}
CHC_main.isDebug = false or getDebug()
CHC_main.recipesWithoutItem = {}
CHC_main.recipesWithLua = {}
CHC_main.luaRecipeCache = {}
CHC_main.notAProcZone = {} -- zones from Distributions.lua without corresponding zones in ProceduralDistributions.lua

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
local loadLua = false

local showTime = function(start, st)
	print(string.format('Loaded %s in %s seconds', st, tostring((getTimestampMs() - start) / 1000)))
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
	local luafunc = _G[luaClosure]
	if luafunc then
		local closureFileName = getFilenameOfClosure(luafunc)
		local closureShortFileName = getShortenedFilename(closureFileName)
		local closureFirstLine = getFirstLineOfClosure(luafunc)
		local code
		local closureName = KahluaUtil.rawTostring2(luafunc)
		closureName = string.sub(closureName, 11, string.find(closureName, ' %-%-') - 1)
		local funcData = CHC_main.luaRecipeCache[closureName]
		if funcData and type(funcData.code) == 'table' then
			return funcData
		end
		if CHC_main.isDebug then
			local br = getGameFilesTextInput(closureFileName)
			local cnt = 0

			while closureFirstLine - 2 > cnt do
				br:readLine()
				cnt = cnt + 1
			end

			local maxlines = 300
			local line = br:readLine()
			local firstline = line
			while line ~= nil do
				if line ~= firstline and utils.startswith(string.trim(line), 'function') then
					break
				end
				if maxlines <= 0 then
					print('Max lines reached: ' .. closureName)
					break
				end
				if not code then code = {} end
				local idx = line:find('%-%-')
				if idx then line = line:sub(1, idx - 1) end
				line = line:trim()

				if line ~= '' then
					table.insert(code, line)
				end
				maxlines = maxlines - 1
				line = br:readLine()
			end
			endTextFileInput()
		else
			-- if not debug, we cant get luaclosure source code (check zombie\Lua\LuaManager.java@getGameFilesTextInput)
			-- so we just store filename and starting line
		end
		local res = {
			code = code,
			filepath = closureFileName,
			shortname = closureShortFileName,
			startline = closureFirstLine,
			funcname = closureName
		}
		CHC_main.luaRecipeCache[closureName] = res
		return res
	end
end

CHC_main.parseOnCreate = function(recipeLua)
	-- AddItem and such
end

CHC_main.parseOnTest = function(recipeLua)
	-- ???
end

CHC_main.parseOnCanPerform = function(recipeLua)
	-- ???
end

CHC_main.parseOnGiveXP = function(recipeLua)
	-- AddXP, parse perk, parse amount
end
-- endregion

CHC_main.getItemPropsDebug = function(item)
	-- works only in debug mode as getClassField (Field) not exposed
	local function processProp(props, propIdx)
		local meth = getClassField(item, propIdx)

		if meth.getType then
			local strVal = rawToStr(getClassFieldVal(item, meth))
			local methName = meth:getName()
			-- if methName then
			-- 	if not CHC_main.itemProps[methName:lower()] then
			-- 		CHC_main.itemProps[methName:lower()] = true
			-- 	end
			-- end
			if strVal then
				local val = tonumber(strVal)
				insert(props, { name = methName, value = val and math.floor(val * 10000) / 10000 or strVal })
			end
		end
	end

	if instanceof(item, 'ComboItem') then return end
	local cl = getNumClassFields(item)
	if cl == 0 then return end

	local objAttrs = {}
	for i = 0, cl - 1 do
		processProp(objAttrs, i)
	end
	return objAttrs
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

	local function processProp(item, prop, isTypeSpecific)
		local propVal
		local data
		local propName = prop.name
		local mul = prop.mul
		local defVal = prop.default
		local isIgnoreDefVal = prop.ignoreDefault
		if isSpecial then
			propVal = item[prop.path]
			if propVal and prop.path2 then propVal = propVal[prop.path2] end
		else
			propVal = item[propName] and item[propName](item) or nil
		end
		if propVal then
			propVal = rawToStr(propVal)
			if tonumber(propVal) then propVal = tonumber(propVal) end
			if mul then propVal = propVal * mul end

			propName, propVal = formatOutput(propName, propVal)
			data = { name = propName, value = propVal, isTypeSpecific = isTypeSpecific }
			if isIgnoreDefVal and propVal == defVal or prop.forceIgnore then
				data.ignore = true
			end -- ignore default values
			return data
		end
	end

	local function processPropGroup(item, propData, isTypeSpecific)
		local props = {}
		if not propData then return props end
		for i = 1, #propData do
			local _propData = processProp(item, propData[i], isTypeSpecific)
			if propData[i].name == 'getUseDelta' then
				local _name, _val = formatOutput('UseDeltaTotal*', 1 / _propData.value)
				insert(props, { name = _name, value = _val, isTypeSpecific = isTypeSpecific })
			end
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

		for _, prop in pairs(uniqueProps) do
			insert(result, prop)
		end

		return result, dupedProps
	end

	local props = {}
	local propsMap = {}
	local typeProps
	local dupedProps

	if not isSpecial then
		local commonProps = processPropGroup(item, commonPropData, false)
		for i = 1, #commonProps do insert(props, commonProps[i]) end
	end

	if itemType == 'Radio' then
		typeProps = processPropGroup(item:getDeviceData(), typePropData, true)
	else
		typeProps = processPropGroup(item, typePropData, true)
	end
	for i = 1, #typeProps do insert(props, typeProps[i]) end

	props, dupedProps = postProcess(props)
	-- if not utils.empty(dupedProps) then
	-- 	CHC_main.dupedProps.items[item:getDisplayName()] = dupedProps
	-- 	CHC_main.dupedProps.size = CHC_main.dupedProps.size + 1
	-- end
	for i = 1, #props do
		if not propsMap[props[i].name] then
			propsMap[props[i].name] = props[i]
		end
	end

	return props, propsMap
end

CHC_main.getRecipeRequiredSkills = function(recipe, n)
	local result = {}
	for i = 1, n do
		local skill = recipe:getRequiredSkill(i - 1)
		local _perk = skill:getPerk()
		local perk = PerkFactory.getPerk(_perk)
		local perkName = perk and perk:getName() or _perk:name()
		insert(result, { skill = perkName, level = skill:getLevel() })
	end
	return result
end

CHC_main.loadDatas = function()
	CHC_main.playerModData = getPlayer():getModData()
	CHC_main.CECData = _G['CraftingEnhancedCore']

	CHC_main.loadAllItems()
	CHC_main.loadItemsIntegrations()

	if loadLua then CHC_main.loadLuaCache() end
	--CHC_main.loadAllDistributions()

	CHC_main.loadAllRecipes()
	CHC_main.loadAllEvolvedRecipes()
	CHC_main.loadRecipesIntegrations()

	if loadLua then CHC_main.saveLuaCache() end
	CHC_menu.createCraftHelper()
	print("Initialised. Mod version: " .. CHC_main._meta.version)
end

CHC_main.processOneItem = function(item, id)
	local fullType = item:getFullName()

	if CHC_main.items[fullType] then
		-- print(string.format('Duplicate invItem fullType! (%s)', tostring(invItem:getFullType())))
		return
	end
	local invItem = instanceItem(fullType)
	local itemDisplayCategory = invItem:getDisplayCategory()

	local toinsert = {
		_id = id,
		itemObj = item,
		item = invItem,
		fullType = invItem:getFullType(),
		name = invItem:getName(),
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
		texture = invItem:getTex()
	}
	toinsert.props, toinsert.propsMap = CHC_main.getItemProps(invItem, toinsert.category)
	CHC_main.items[toinsert.fullType] = toinsert
	insert(CHC_main.itemsForSearch, toinsert)


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

CHC_main.loadAllItems = function(am)
	local allItems = getAllItems()
	local nbItems = 0
	local now = getTimestampMs()
	local amount = am or allItems:size() - 1

	print('Loading items...')
	for i = 0, amount do
		local item = allItems:get(i)
		if not item:getObsolete() then
			CHC_main.processOneItem(item, i)
			nbItems = nbItems + 1
		end
	end
	showTime(now, 'All Items')
	print(nbItems .. ' items loaded.')
end

CHC_main.processOneRecipe = function(recipe, id)
	local newItem = {}
	newItem._id = id
	newItem.category = recipe:getCategory() or getText('IGUI_CraftCategory_General')
	newItem.displayCategory = getTextOrNull('IGUI_CraftCategory_' .. newItem.category) or newItem.category
	newItem.recipe = recipe
	newItem.module = recipe:getModule():getName()
	newItem.hidden = recipe:isHidden()
	newItem.recipeData = {}
	newItem.recipeData.lua = {}
	newItem.recipeData.lua.onCanPerform = recipe:getCanPerform()
	newItem.recipeData.category = newItem.category
	newItem.recipeData.name = recipe:getName()
	newItem.recipeData.nearItem = recipe:getNearItem()
	newItem.recipeData.needToBeLearn = recipe:needToBeLearn()
	newItem.recipeData.originalName = recipe:getOriginalname()
	newItem.recipeData.requiredSkillCount = recipe:getRequiredSkillCount()
	if newItem.recipeData.requiredSkillCount > 0 then
		newItem.recipeData.requiredSkills = CHC_main.getRecipeRequiredSkills(recipe,
			newItem.recipeData.requiredSkillCount)
	end
	if newItem.recipeData.nearItem == "Anvil" and
		not getActivatedMods():contains("Blacksmith41") then
		return
	end

	newItem.favorite = CHC_main.playerModData[CHC_main.getFavoriteRecipeModDataString(newItem)] or false

	if loadLua then
		local onCreate = recipe:getLuaCreate()
		local onTest = recipe:getLuaTest()
		local onCanPerform = recipe:getCanPerform()
		local onGiveXP = recipe:getLuaGiveXP()
		if onCreate or onTest or onCanPerform or onGiveXP then
			newItem.recipeData.lua = {}
			if onCreate then
				newItem.recipeData.lua.onCreate = CHC_main.handleRecipeLua(onCreate)
			end
			if onTest then
				newItem.recipeData.lua.onTest = CHC_main.handleRecipeLua(onTest)
			end
			if onCanPerform then
				newItem.recipeData.lua.onCanPerform = CHC_main.handleRecipeLua(onCanPerform)
			end
			if onGiveXP then
				newItem.recipeData.lua.onGiveXP = CHC_main.handleRecipeLua(onGiveXP)
			end
		end
		if newItem.recipeData.lua then
			CHC_main.recipesWithLua[newItem.recipeData.name] = newItem.recipeData.lua
		end
	end


	local resultItem = recipe:getResult()
	if not resultItem then return end

	--region integrations
	--check for hydrocraft furniture
	local hydrocraftFurniture = CHC_main.processHydrocraft(recipe)
	if hydrocraftFurniture then
		newItem.recipeData.hydroFurniture = hydrocraftFurniture
		newItem.isNearItem = true
		CHC_main.setRecipeForItem(CHC_main.recipesByItem, hydrocraftFurniture.obj.fullType, newItem)
	end

	--check for CEC furniture
	if newItem.recipeData.nearItem then
		local CECFurniture = CHC_main.processCEC(newItem.recipeData.nearItem, CHC_main.CECData)
		if CECFurniture and not utils.empty(CECFurniture) then
			newItem.recipeData.CECFurniture = CECFurniture
			newItem.isNearItem = true
			CHC_main.setRecipeForItem(CHC_main.recipesByItem, CECFurniture.obj.fullType, newItem)
		end
	end

	-- if CHC_main.itemsManuals[newItem.recipeData.name] then
	-- 	for _, value in pairs(CHC_main.itemsManuals[newItem.recipeData.name]) do
	-- 		newItem.isBook = true
	-- 		CHC_main.setRecipeForItem(CHC_main.recipesByItem, value.fullType, newItem)
	-- 	end
	-- end
	--endregion

	local resultFullType = resultItem:getFullType()
	local itemres = CHC_main.getItemByFullType(resultFullType)

	insert(CHC_main.allRecipes, newItem)
	if itemres then
		newItem.recipeData.result = itemres
		CHC_main.setRecipeForItem(CHC_main.recipesForItem, itemres.fullType, newItem)
	else
		insert(CHC_main.recipesWithoutItem, resultItem:getFullType())
	end
	local rSources = recipe:getSource()

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

CHC_main.loadAllRecipes = function()
	print('Loading recipes...')
	local nbRecipes = 0
	local now = getTimestampMs()

	-- Get all recipes in game (vanilla recipes + any mods recipes)
	local allRecipes = getAllRecipes()

	-- Go through recipes stack
	for i = 0, allRecipes:size() - 1 do
		local recipe = allRecipes:get(i)
		CHC_main.processOneRecipe(recipe, i)
		nbRecipes = nbRecipes + 1
	end
	showTime(now, 'All Recipes')
	print(nbRecipes .. ' recipes loaded.')
end

CHC_main.processOneEvolvedRecipe = function(recipe, _id)
	if recipe:isHidden() then return end
	local data = {
		_id = "e" .. tostring(_id),
		isEvolved = true,
		recipe = recipe,
		category = getText('IGUI_CHC_RecipeCat_Evolved'),
		displayCategory = getText('IGUI_CHC_RecipeCat_Evolved'),
		hidden = recipe:isHidden(),
		module = recipe:getModule():getName(),
	}

	local recipeData = {
		category = data.category,
		name = recipe:getName(),
		originalName = recipe:getOriginalname(),
		untranslatedName = recipe:getUntranslatedName(),
		baseItem = recipe:getBaseItem(),
		--itemsList = recipe:getItemsList(), -- Map
		_possibleItems = recipe:getPossibleItems(), -- ArrayList
		resultItem = recipe:getResultItem(),
		fullResultItem = recipe:getFullResultItem(),
		isCookable = recipe:isCookable(),
		maxItems = recipe:getMaxItems(),
		addIngredientSound = recipe:getAddIngredientSound(),
		isAllowFrozenItem = recipe:isAllowFrozenItem()
	}
	if not recipeData.baseItem:contains('.') then
		recipeData.baseItem = "Base." .. recipeData.baseItem
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
				if _item.propsMap and _item.propsMap["Spice"] and tostring(_item.propsMap["Spice"].value) == "true" then
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

	data.favorite = CHC_main.playerModData[CHC_main.getFavoriteRecipeModDataString(data)] or false

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

	insert(CHC_main.allEvoRecipes, data)
end

CHC_main.loadAllEvolvedRecipes = function()
	print('Loading evolved recipes...')
	local nbRecipes = 0
	local now = getTimestampMs()

	local allEvolvedRecipes = RecipeManager.getAllEvolvedRecipes()

	for i = 0, allEvolvedRecipes:size() - 1 do
		CHC_main.processOneEvolvedRecipe(allEvolvedRecipes:get(i), i)
		nbRecipes = nbRecipes + 1
	end


	showTime(now, 'All Evolved Recipes')
	print(nbRecipes .. ' recipes loaded.')
end

CHC_main.loadAllBooks = function()
	local allItems = getAllItems()
	local nbBooks = 0

	print('Loading books')
end

CHC_main.processDistrib = function(zone, d, data, isJunk, isProcedural)
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

CHC_main.loadAllDistributions = function()
	-- first check SuburbsDistributions (for non-procedural items and procedural refs)
	-- then ProceduralDistributions
	-- TODO add junk items
	local function norm(val, min, max)
		return (val - min) / (max - min) * 100
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

CHC_main.setRecipeForItem = function(tbl, itemName, recipe)
	tbl[itemName] = tbl[itemName] or {}
	insert(tbl[itemName], recipe)
end

CHC_main.getFavItemModDataStr = function(item)
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

CHC_main.getFavoriteRecipeModDataString = function(recipe)
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

-- region integrations

CHC_main.loadItemsIntegrations = function()
	CHC_main.getCECItems()
end

CHC_main.loadRecipesIntegrations = function()
	CHC_main.getCECRecipes()
end

CHC_main.processHydrocraft = function(recipe)
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

CHC_main.getCECItems = function()
	-- TODO: synthetic recipes for cec tables (tData.recipe)
	if not getActivatedMods():contains('craftingEnhancedCore') then return end
	local map = CHC_settings.itemPropsByType.Integrations.CraftingEnhanced

	for tID, tData in pairs(CHC_main.CECData.tables) do
		local fullType = tID
		if not CHC_main.items[fullType] then
			local toinsert = {
				item = tData,
				fullType = 'CEC.' .. fullType,
				name = tData.nameID,
				modname = 'Crafting Enhanced Core',
				isVanilla = false,
				IsDrainable = false,
				displayName = tData.displayName,
				tooltip = tData.tooltipDescription,
				hidden = false,
				count = 1,
				category = 'Moveable',
				displayCategory = getText('IGUI_CHC_ItemCat_Moveable'),
				texture = getTexture(tData.tooltipTexture),
				textureMult = 2
			}
			toinsert.item.fullType = toinsert.fullType
			toinsert.item.getFullType = function() return toinsert.fullType end
			toinsert.props, toinsert.propsMap = CHC_main.getItemProps(tData, toinsert.category, map)
			CHC_main.items[toinsert.fullType] = toinsert
			insert(CHC_main.itemsForSearch, toinsert)
		end
	end
end

CHC_main.getCECRecipes = function()
	local function getSource()

	end

	if not getActivatedMods():contains('craftingEnhancedCore') then return end
	print('Loading CraftingEnhancedCore recipes...')
	local nbRecipes = 0
	local now = getTimestampMs()

	for tID, tData in pairs(CHC_main.CECData.tables) do
		local newItem = {}
		newItem._id = tID
		newItem.category = 'CraftingEnhanced'
		newItem.displayCategory = newItem.category
		newItem.module = 'CraftingEnhancedCore'
		newItem.hidden = false
		newItem.isSynthetic = true
		newItem.recipeData = {}
		newItem.recipeData.category = newItem.category
		newItem.recipeData.name = 'Build ' .. tData.displayName
		newItem.recipeData.displayName = tData.displayName
		newItem.recipeData.ingredients = tData.recipe
		newItem.recipeData.isSynthetic = true
		-- newItem.recipeData.nearItem = recipe:getNearItem()
		newItem.recipe = {
			getOriginalname = function() return newItem.recipeData.name end,
			getSource = getSource,
			getName = function() return newItem.recipeData.name end
		}
		newItem.favorite = CHC_main.playerModData[CHC_main.getFavoriteRecipeModDataString(newItem)] or false

		local resultItem = 'CEC.' .. tID
		insert(CHC_main.allRecipes, newItem)

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
		nbRecipes = nbRecipes + 1
	end
	showTime(now, 'CraftingEnhancedCore Recipes')
	print(nbRecipes .. ' recipes loaded.')
end

CHC_main.processCEC = function(nearItem, CECData)
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

-- endregion

function CHC_main.reloadMod(key)
	-- if key == Keyboard.KEY_O then
	-- 	CHC_main.loadDatas()
	-- 	local all = CHC_main
	-- 	-- error('debug')
	-- end
	-- if key == Keyboard.KEY_Z then
	-- 	local items = {}
	-- 	local num = 100
	-- 	for i = 1, num, 1 do
	-- 		insert(items, CHC_main.itemsForSearch[i])
	-- 	end
	-- 	local now = getTimestampMs()
	-- 	for i = 1, #items do
	-- 		CHC_main.getItemProps(items[i].item, items[i].category)
	-- 	end
	-- 	showTime(now, num .. "test props")
	-- end
end

if CHC_main.isDebug then
	Events.OnKeyPressed.Add(CHC_main.reloadMod)
end

-- catch all lua changes to recipes/items/etc (DoParam and stuff)
local ensureLoadedLast = function()
	Events.OnLoad.Add(function()
		CHC_main.loadDatas()
	end)
end

Events.OnLoad.Add(ensureLoadedLast)
