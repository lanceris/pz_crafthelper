require 'luautils'

CHC_main = {}
CHC_main.author = "lanceris"
CHC_main.previousAuthors = { "Peanut", "ddraigcymraeg", "b1n0m" }
CHC_main.modName = "CraftHelperContinued"
CHC_main.version = "1.5.6"
CHC_main.allRecipes = {}
CHC_main.recipesByItem = {}
CHC_main.recipesForItem = {}
CHC_main.itemsManuals = {}
CHC_main.items = {}
CHC_main.itemsForSearch = {}
CHC_main.isDebug = false or getDebug()
CHC_main.recipesWithoutItem = {}

local insert = table.insert

local showTime = function(start, st)
	print(string.format("Loaded %s in %s seconds", st, tostring((getTimestampMs() - start) / 1000)))
end

CHC_main.handleItems = function(itemString, recipe)
	local item
	if (string.find(itemString, "Radio%.")) then
		item = CHC_main.items[recipe:getModule():getName() .. "." .. itemString]
	elseif (string.find(itemString, "Base%.DigitalWatch2") or string.find(itemString, "Base%.AlarmClock2")) then
		item = nil
	else
		item = CHC_main.items[itemString]
	end
	return item
end

CHC_main.loadDatas = function()
	CHC_main.loadAllItems()
	CHC_main.loadAllRecipes()

	CHC_menu.createCraftHelper()
end

CHC_main.processOneItem = function(item)
	local fullType = item:getFullName()
	local invItem = instanceItem(fullType)
	if not CHC_main.items[fullType] then
		local toinsert = {
			item = invItem,
			fullType = invItem:getFullType(),
			name = invItem:getName(),
			modname = invItem:getModName(),
			isVanilla = invItem:isVanilla(),
			IsDrainable = invItem:IsDrainable(),
			displayName = invItem:getDisplayName(),
			hidden = item:isHidden(),
			count = invItem:getCount() or 1,
			displayCategory = invItem:getDisplayCategory() or "Item",
			texture = invItem:getTex()
		}
		CHC_main.items[invItem:getFullType()] = toinsert
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

CHC_main.loadAllItems = function(am)
	local allItems = getAllItems()
	local nbItems = 0
	local now = getTimestampMs()
	local amount = am or allItems:size() - 1

	print("Loading items...")
	for i = 0, amount do
		local item = allItems:get(i)
		CHC_main.processOneItem(item)

		nbItems = nbItems + 1
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

	local modData = getPlayer():getModData()
	-- Go through recipes stack
	for i = 0, allRecipes:size() - 1 do
		local newItem = {}
		local recipe = allRecipes:get(i)

		newItem.category = recipe:getCategory() or getText("IGUI_CraftCategory_General")
		newItem.displayCategory = getTextOrNull("IGUI_CraftCategory_" .. newItem.category) or newItem.category
		newItem.recipe = recipe
		newItem.module = recipe:getModule():getName()
		newItem.favorite = modData[CHC_main.getFavoriteModDataString(recipe)] or false
		newItem.recipeData = {}
		newItem.recipeData.category = recipe:getCategory() or getText("IGUI_CraftCategory_General")
		newItem.recipeData.name = recipe:getName()


		local resultItem = recipe:getResult()
		local resultFullType = resultItem:getFullType()
		local itemres = CHC_main.handleItems(resultFullType, recipe)

		newItem.recipeData.result = {}
		newItem.recipeData.result.fullType = resultFullType
		insert(CHC_main.allRecipes, newItem)
		if itemres then
			CHC_main.setRecipeForItem(CHC_main.recipesForItem, itemres.name, newItem)
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
				local item = CHC_main.handleItems(itemString, recipe)

				if item then
					CHC_main.setRecipeForItem(CHC_main.recipesByItem, item.name, newItem)
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

CHC_main.getFavoriteModDataString = function(recipe)
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
