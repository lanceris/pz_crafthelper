require 'luautils'

CHC_main = {}
CHC_main.author = 'lanceris'
CHC_main.previousAuthors = { 'Peanut', 'ddraigcymraeg', 'b1n0m' }
CHC_main.modName = 'CraftHelperContinued'
CHC_main.version = '1.6.5'
CHC_main.allRecipes = {}
CHC_main.recipesByItem = {}
CHC_main.recipesForItem = {}
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

local cacheFileName = 'CraftHelperLuaCache.json'
local loadLua = false

local showTime = function(start, st)
	print(string.format('Loaded %s in %s seconds', st, tostring((getTimestampMs() - start) / 1000)))
end

CHC_main.handleItems = function(itemString)
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
		local res = { code = code,
			filepath = closureFileName,
			shortname = closureShortFileName,
			startline = closureFirstLine,
			funcname = closureName }
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

CHC_main.getItemProps = function(item, itemType)
	local map = CHC_settings.itemPropsByType
	local typePropData = map[itemType]
	local commonPropData = map["Common"]

	local function formatOutput(propName, propVal)

		if propName then
			if sub(propName, 1, 3) == "get" then
				propName = sub(propName, 4)
			elseif sub(propName, 1, 2) == "is" then
				propName = sub(propName, 3)
			end
		end
		if propVal then
			if type(propVal) ~= "string" then
				propVal = math.floor(propVal * 10000) / 10000
			end
		end
		return propName, propVal
	end

	local function processProp(item, prop, isTypeSpecific)
		local propVal
		local propName = prop.name
		local mul = prop.mul
		local defVal = prop.default
		local isIgnoreDefVal = prop.ignoreDefault
		propVal = item[propName](item)
		if propVal then
			propVal = rawToStr(propVal)
			local val = tonumber(propVal)
			if val then propVal = val end

			if mul then propVal = propVal * mul end
			if isIgnoreDefVal and propVal == defVal then
				return
			end -- ignore default values
			propName, propVal = formatOutput(propName, propVal)
			return { name = propName, value = propVal, isTypeSpecific = isTypeSpecific }
		end
	end

	local function processPropGroup(item, propData, isTypeSpecific)

		local props = {}
		if not propData then return props end
		for i = 1, #propData do
			local _propData = processProp(item, propData[i], isTypeSpecific)
			if propData[i].name == "getUseDelta" then
				local _name, _val = formatOutput("UseDeltaTotal*", 1 / _propData.value)
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
		if uniqueProps["Weight"].value == uniqueProps["ActualWeight"].value then
			uniqueProps["ActualWeight"] = nil
		end

		for _, prop in pairs(uniqueProps) do
			insert(result, prop)
		end

		return result, dupedProps
	end

	local props = {}
	local typeProps
	local dupedProps

	local commonProps = processPropGroup(item, commonPropData, false)
	if itemType == "Radio" then
		typeProps = processPropGroup(item:getDeviceData(), typePropData, true)
	else
		typeProps = processPropGroup(item, typePropData, true)
	end

	for i = 1, #commonProps do insert(props, commonProps[i]) end
	for i = 1, #typeProps do insert(props, typeProps[i]) end

	props, dupedProps = postProcess(props)
	-- if not utils.empty(dupedProps) then
	-- 	CHC_main.dupedProps.items[item:getDisplayName()] = dupedProps
	-- 	CHC_main.dupedProps.size = CHC_main.dupedProps.size + 1
	-- end

	return props
end

CHC_main.loadDatas = function()
	CHC_main.playerModData = getPlayer():getModData()

	CHC_main.loadAllItems()
	if loadLua then CHC_main.loadLuaCache() end
	--CHC_main.loadAllDistributions()

	CHC_main.loadAllRecipes()

	if loadLua then CHC_main.saveLuaCache() end
	CHC_menu.createCraftHelper()
end

CHC_main.processOneItem = function(item)
	local fullType = item:getFullName()
	local invItem = instanceItem(fullType)
	local itemDisplayCategory = invItem:getDisplayCategory()

	if not CHC_main.items[fullType] then
		local toinsert = {
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
			displayCategory = itemDisplayCategory and getTextOrNull('IGUI_ItemCat_' .. itemDisplayCategory) or
				getText('IGUI_ItemCat_Item'),
			texture = invItem:getTex()
		}
		toinsert.props = CHC_main.getItemProps(invItem, toinsert.category)
		CHC_main.items[toinsert.fullType] = toinsert
		insert(CHC_main.itemsForSearch, toinsert)
	else
		error(string.format('Duplicate invItem fullType! (%s)', tostring(invItem:getFullType())))
	end


	if item:getTypeString() == 'Literature' then
		local teachedRecipes = item:getTeachedRecipes()
		if teachedRecipes ~= nil and teachedRecipes:size() > 0 then
			for j = 0, teachedRecipes:size() - 1 do
				local recipeString = teachedRecipes:get(j)
				if CHC_main.itemsManuals[recipeString] == nil then
					CHC_main.itemsManuals[recipeString] = {}
				end
				insert(CHC_main.itemsManuals[recipeString], CHC_main.items[fullType])
			end
		end
	end
end

CHC_main.loadAllBooks = function()
	local allItems = getAllItems()
	local nbBooks = 0

	print('Loading books')
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
			CHC_main.processOneItem(item)
			nbItems = nbItems + 1
		end
	end
	showTime(now, 'All Items')
	print(nbItems .. ' items loaded.')
end

CHC_main.loadAllRecipes = function()
	print('Loading recipes...')
	local nbRecipes = 0
	local now = getTimestampMs()

	-- Get all recipes in game (vanilla recipes + any mods recipes)
	local allRecipes = getAllRecipes()

	-- Go through recipes stack
	for i = 0, allRecipes:size() - 1 do
		local newItem = {}
		local recipe = allRecipes:get(i)

		newItem.category = recipe:getCategory() or getText('IGUI_CraftCategory_General')
		newItem.displayCategory = getTextOrNull('IGUI_CraftCategory_' .. newItem.category) or newItem.category
		newItem.recipe = recipe
		newItem.module = recipe:getModule():getName()
		newItem.favorite = CHC_main.playerModData[CHC_main.getFavoriteRecipeModDataString(recipe)] or false
		newItem.recipeData = {}
		newItem.recipeData.category = recipe:getCategory() or getText('IGUI_CraftCategory_General')
		newItem.recipeData.name = recipe:getName()
		newItem.recipeData.nearItem = recipe:getNearItem()

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

		--check for hydrocraft furniture
		local hydrocraftFurniture = CHC_main.processHydrocraft(recipe)
		if hydrocraftFurniture then
			newItem.recipeData.hydroFurniture = hydrocraftFurniture
		end

		local resultItem = recipe:getResult()
		if resultItem then
			local resultFullType = resultItem:getFullType()
			local itemres = CHC_main.handleItems(resultFullType)

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
					local item = CHC_main.handleItems(itemString)

					if item then
						CHC_main.setRecipeForItem(CHC_main.recipesByItem, item.fullType, newItem)
					end
				end
			end
			nbRecipes = nbRecipes + 1
		else
			-- omg no 'continue' in lua and goto not working :(
		end
	end
	showTime(now, 'All Recipes')
	print(nbRecipes .. ' recipes loaded.')
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
	local text = 'craftingFavorite:' .. recipe:getOriginalname()
	if nil then --instanceof(recipe, 'EvolvedRecipe') then
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

function CHC_main.reloadMod(key)
	if key == Keyboard.KEY_O then
		CHC_main.loadDatas()
		local all = CHC_main
		-- error('debug')
	end
end

if CHC_main.isDebug then
	Events.OnKeyPressed.Add(CHC_main.reloadMod)
end

Events.OnGameStart.Add(CHC_main.loadDatas)
