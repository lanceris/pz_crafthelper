require 'luautils'

CHC_main = {}
CHC_main.author = "lanceris"
CHC_main.previousAuthors = { "Peanut", "ddraigcymraeg", "b1n0m" }
CHC_main.modName = "CraftHelperContinued"
CHC_main.version = "1.6.1"
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

local insert = table.insert
local utils = require('CHC_utils')
local print = utils.chcprint

local cacheFileName = "CraftHelperLuaCache.json"

local showTime = function(start, st)
	print(string.format("Loaded %s in %s seconds", st, tostring((getTimestampMs() - start) / 1000)))
end

CHC_main.handleItems = function(itemString)
	local item
	if itemString == "Water" then
		item = CHC_main.items["Base.WaterDrop"]
	elseif (string.find(itemString, "Base%.DigitalWatch2") or string.find(itemString, "Base%.AlarmClock2")) then
		item = nil
	else
		item = CHC_main.items[itemString]
	end
	return item
end

-- region lua stuff
CHC_main.handleRecipeLua = function(luaClosure)
	local luafunc = _G[luaClosure]
	if luafunc then
		local closureFileName = getFilenameOfClosure(luafunc)
		local closureShortFileName = getShortenedFilename(closureFileName)
		local closureFirstLine = getFirstLineOfClosure(luafunc)
		local code
		local closureName = KahluaUtil.rawTostring2(luafunc)
		closureName = string.sub(closureName, 11, string.find(closureName, " %-%-") - 1)
		local funcData = CHC_main.luaRecipeCache[closureName]
		if funcData and type(funcData.code) == "table" then
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
				if line ~= firstline and utils.startswith(string.trim(line), "function") then
					break
				end
				if maxlines <= 0 then
					print('Max lines reached: ' .. closureName)
					break
				end
				if not code then code = {} end
				local idx = line:find("%-%-")
				if idx then line = line:sub(1, idx - 1) end
				line = line:trim()

				if line ~= "" then
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

CHC_main.loadDatas = function()
	CHC_main.playerModData = getPlayer():getModData()

	CHC_main.loadAllItems()
	local luaCache = utils.jsonutil.Load(cacheFileName)
	if not luaCache then
		print('Lua cache is empty, will init new one...')
		CHC_main.luaRecipeCache = {}
	else
		CHC_main.luaRecipeCache = luaCache
	end
	CHC_main.loadAllRecipes()

	-- if not luaCache then
	utils.jsonutil.Save(cacheFileName, CHC_main.luaRecipeCache)
	-- end

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
			displayCategory = itemDisplayCategory and getTextOrNull("IGUI_ItemCat_" .. itemDisplayCategory) or getText("IGUI_ItemCat_Item"),
			texture = invItem:getTex()
		}
		-- toinsert.favorite = CHC_main.playerModData[CHC_main.getFavItemModDataStr(toinsert)] or false
		CHC_main.items[toinsert.fullType] = toinsert
		insert(CHC_main.itemsForSearch, toinsert)
		-- CHC_main.items[fullType] = invItem
	else
		error(string.format('Duplicate invItem fullType! (%s)', tostring(invItem.getFullType())))
	end


	if item:getTypeString() == "Literature" then
		local teachedRecipes = item:getTeachedRecipes()
		if teachedRecipes ~= nil and teachedRecipes:size() > 0 then
			for j = 0, teachedRecipes:size() - 1 do
				local recipeString = teachedRecipes:get(j)
				if CHC_main.itemsManuals[recipeString] == nil then
					CHC_main.itemsManuals[recipeString] = {}
				end
				insert(CHC_main.itemsManuals[recipeString], item:getDisplayName())
			end
		end
	end
end

-- CHC_main.loadAllBooks = function()
-- 	local allItems = getAllItems()
-- 	local nbBooks = 0

-- 	print('Loading books')
-- end

CHC_main.loadAllItems = function(am)
	local allItems = getAllItems()
	local nbItems = 0
	local now = getTimestampMs()
	local amount = am or allItems:size() - 1

	print("Loading items...")
	for i = 0, amount do
		local item = allItems:get(i)
		if not item:getObsolete() then
			CHC_main.processOneItem(item)
			nbItems = nbItems + 1
		end
	end
	showTime(now, "All Items")
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

		newItem.category = recipe:getCategory() or getText("IGUI_CraftCategory_General")
		newItem.displayCategory = getTextOrNull("IGUI_CraftCategory_" .. newItem.category) or newItem.category
		newItem.recipe = recipe
		newItem.module = recipe:getModule():getName()
		newItem.favorite = CHC_main.playerModData[CHC_main.getFavoriteRecipeModDataString(recipe)] or false
		newItem.recipeData = {}
		newItem.recipeData.category = recipe:getCategory() or getText("IGUI_CraftCategory_General")
		newItem.recipeData.name = recipe:getName()
		newItem.recipeData.nearItem = recipe:getNearItem()

		-- local onCreate = recipe:getLuaCreate()
		-- local onTest = recipe:getLuaTest()
		-- local onCanPerform = recipe:getCanPerform()
		-- local onGiveXP = recipe:getLuaGiveXP()
		-- if onCreate or onTest or onCanPerform or onGiveXP then
		-- 	newItem.recipeData.lua = {}
		-- 	if onCreate then
		-- 		newItem.recipeData.lua.onCreate = CHC_main.handleRecipeLua(onCreate)
		-- 	end
		-- 	if onTest then
		-- 		newItem.recipeData.lua.onTest = CHC_main.handleRecipeLua(onTest)
		-- 	end
		-- 	if onCanPerform then
		-- 		newItem.recipeData.lua.onCanPerform = CHC_main.handleRecipeLua(onCanPerform)
		-- 	end
		-- 	if onGiveXP then
		-- 		newItem.recipeData.lua.onGiveXP = CHC_main.handleRecipeLua(onGiveXP)
		-- 	end
		-- end
		-- if newItem.recipeData.lua then
		-- 	CHC_main.recipesWithLua[newItem.recipeData.name] = newItem.recipeData.lua
		-- end

		--check for hydrocraft furniture
		local hydrocraftFurniture = CHC_main.processHydrocraft(recipe)
		if hydrocraftFurniture then
			newItem.recipeData.hydroFurniture = hydrocraftFurniture
		end

		local resultItem = recipe:getResult()
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
	end
	showTime(now, "All Recipes")
	print(nbRecipes .. ' recipes loaded.')
end

CHC_main.setRecipeForItem = function(tbl, itemName, recipe)
	tbl[itemName] = tbl[itemName] or {}
	insert(tbl[itemName], recipe)
end

CHC_main.getFavItemModDataStr = function(item)
	local fullType
	if item.fullType then
		fullType = item.fullType
	elseif instanceof(item, "InventoryItem") then
		fullType = item:getFullType()
	elseif type(item) == "string" then
		fullType = item
	end
	local text = "itemFavoriteCHC:" .. fullType
	return text
end

CHC_main.getFavoriteRecipeModDataString = function(recipe)
	local text = "craftingFavorite:" .. recipe:getOriginalname()
	if nil then --instanceof(recipe, "EvolvedRecipe") then
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
	if not getActivatedMods():contains("Hydrocraft") then return end

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
