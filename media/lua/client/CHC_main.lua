require 'luautils'

CHC_main = {}
CHC_main.author = "lanceris"
CHC_main.previousAuthors = {"Peanut", "ddraigcymraeg", "b1n0m"}
CHC_main.modName = "CraftHelperContinued"
CHC_main.recipesByItem = {}
-- CHC_main.allRecipes = {}
CHC_main.duplicateRecipeNames = {}
CHC_main.skipModules = {}
CHC_main.itemsManuals = {}
CHC_main.items = {}
CHC_main.recipesWithoutSource = {}
CHC_main.missingItems = {}
CHC_main.isDebug = false or getDebug();
CHC_main.temp = nil

local showTime = function (start, st)
	print(string.format("Loaded %s in %s seconds", st, tostring((getTimestampMs()-start)/1000)))
end

CHC_main.handleItems = function(itemString, recipe)
	local item
	if(string.find(itemString, "Radio%.")) then
		item = CHC_main.items[recipe:getModule():getName() .. "." .. itemString]
	elseif (string.find(itemString, "Base%.DigitalWatch2") or string.find(itemString,"Base%.AlarmClock2")) then
		item = nil;
	else
		item = CHC_main.items[itemString]
	end
	return item
end

CHC_main.loadDatas = function()
	CHC_main.loadAllItems()
	CHC_main.loadAllRecipes()
end

CHC_main.loadAllItems = function()
	local allItems = getAllItems();
	local invItem
	local nbItems = 0
	local now = getTimestampMs()

	print("Loading items...")
	for i=0, allItems:size() - 1 do
		local item = allItems:get(i);
		invItem = item:InstanceItem(nil)
		
		if not CHC_main.items[invItem:getFullType()] then
			-- local myItem = {}
			-- myItem.itemObj = invItem
			-- myItem.module = invItem:getModName()
			-- myItem.texture = invItem:getTex()
			-- myItem.itemName = invItem:getDisplayName()
			-- myItem.itemDisplayCategory = invItem:getDisplayCategory()
			CHC_main.items[invItem:getFullType()] = invItem
		else
			print(string.format('Duplicate invItem fullType! (%s)', tostring(invItem.getFullType())))
		end
		

		if item:getTypeString() == "Literature" then
			-- item = item:InstanceItem(nil);

			local teachedRecipes = item:getTeachedRecipes();
			if teachedRecipes ~= nil and teachedRecipes:size() > 0 then
				for j=0, teachedRecipes:size() - 1 do
					local recipeString = teachedRecipes:get(j);
					if CHC_main.itemsManuals[recipeString] == nil then
						CHC_main.itemsManuals[recipeString] = {};
					end
					table.insert(CHC_main.itemsManuals[recipeString], item:getDisplayName())
				end
			end
		end
		nbItems = nbItems + 1
	end
	showTime(now, "All Items")
	print(nbItems .. ' items loaded.')
end

CHC_main.loadAllRecipes = function()
	print('Loading recipes...')
	local nbRecipes = 0;
	local now = getTimestampMs()
	local recCnt = {}

	-- Get all recipes in game (vanilla recipes + any mods recipes)
	local allRecipes = getAllRecipes()

	local modData = getPlayer():getModData()
	-- Go through recipes stack
	for i=0,allRecipes:size() -1 do
		local newItem = {}
		local recipe = allRecipes:get(i)
		local recipeName = recipe:getName()
		if not recCnt[recipeName] then
			recCnt[recipeName] = 1
		else
			recCnt[recipeName] = recCnt[recipeName] + 1
		end
		if recCnt[recipeName] > 1 then
			if not CHC_main.duplicateRecipeNames[recipeName] then
				CHC_main.duplicateRecipeNames[recipeName] = 2
			else
				CHC_main.duplicateRecipeNames[recipeName] = CHC_main.duplicateRecipeNames[recipeName] + 1
			end
		end
		-- local skip_modules = CHC_main.skipModules[allRecipes:get(i):getModule():getName()]
		-- table.insert(CHC_main.allRecipes, recipe);

		newItem.category = recipe:getCategory() or getText("IGUI_CraftCategory_General")
		newItem.displayCategory = getTextOrNull("IGUI_CraftCategory_"..newItem.category) or newItem.category
		newItem.recipe = recipe
		newItem.favorite = modData[CHC_main.getFavoriteModDataString(recipe)] or false
		local rSources = recipe:getSource()
		if not CHC_main.temp and rSources:size()>1 then
			CHC_main.temp = {obj=rSources, len=rSources:size(), ex1=rSources:get(0), ex2=rSources:get(1)}
		end
		-- Go through items needed by the recipe
		for n=0, rSources:size() - 1 do
			-- Get the item name (not the display name)
			local rSource = rSources:get(n);
			if not rSource then
				table.insert(CHC_main.recipesWithoutSource, recipe)
			end
			local items = rSource:getItems()
			for k=0, rSource:getItems():size() - 1 do
				local itemString = items:get(k)
				local item
				-- todo find out what's wrong with the radio and digital watch (it's not related with recent update @see DismantleDigitalWatch_GetItemTypes)
				item = CHC_main.handleItems(itemString, recipe)

				if item then
					CHC_main.setRecipeForItem(item:getName(), newItem)
				else
					if not CHC_main.missingItems[itemString] then
						CHC_main.missingItems[itemString] = 1
					end
				end
			end
		end
		nbRecipes = nbRecipes + 1;
	end
	showTime(now, "All Recipes")
	print(nbRecipes .. ' recipes loaded.')
end

CHC_main.setRecipeForItem = function(itemName, recipe)
	-- If no recipes has already been set for this item, we initialize the array (empty) of recipes
	local tbl = CHC_main.recipesByItem
	tbl[itemName] = tbl[itemName] or {}
	table.insert(tbl[itemName], recipe);
end

CHC_main.getFavoriteModDataString = function(recipe)
    local text = "craftingFavorite:" .. recipe:getOriginalname();
    if nil then--instanceof(recipe, "EvolvedRecipe") then
        text = text .. ':' .. recipe:getBaseItem()
        text = text .. ':' .. recipe:getResultItem()
    else
        for i=0,recipe:getSource():size()-1 do
            local source = recipe:getSource():get(i)
            for j=1,source:getItems():size() do
                text = text .. ':' .. source:getItems():get(j-1);
            end
        end
    end
    return text;
end

function CHC_main.reloadMod(key)
	if key == Keyboard.KEY_O then
		CHC_main.loadDatas()
		local all = CHC_main
		error('abc')
	end
end

---
-- Load all recipes and items in array when game starts
--
if CHC_main.isDebug then
	Events.OnKeyPressed.Add(CHC_main.reloadMod);
end

Events.OnGameStart.Add(CHC_main.loadDatas);