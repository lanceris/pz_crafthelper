require 'luautils';

craftHelper41 = {};
craftHelper41.version = "1.1";
craftHelper41.author = "b1n0m";
craftHelper41.modName = "CraftHelper41";
craftHelper41.recipesByItem = {};
craftHelper41.allRecipes = {};
craftHelper41.skipModules = {};
craftHelper41.itemsManuals = {};


craftHelper41.loadDatas = function()
	print('Loading recipes...');
	local nbRecipes = 0;

	-- Get all recipes in game (vanilla recipes + any mods recipes)
	local allRecipes = getScriptManager():getAllRecipes();

	-- Go through recipes stack
	for i=0,allRecipes:size() -1 do
		if craftHelper41.skipModules[allRecipes:get(i):getModule():getName()] == nil or craftHelper41.skipModules[allRecipes:get(i):getModule():getName()] == false then
			table.insert(craftHelper41.allRecipes, allRecipes:get(i));

			-- Go through items needed by the recipe
			 for n=0, allRecipes:get(i):getSource():size() - 1 do
				-- Get the item name (not the display name)

				local recipe = allRecipes:get(i):getSource():get(n);

				if (recipe) then


					for k=0, recipe:getItems():size() - 1 do

					-- Create an instance of the item.
						local itemString = recipe:getItems():get(k);

						local item;
						-- todo find out what's wrong with the radio and digital watch (it's not related with recent update @see DismantleDigitalWatch_GetItemTypes)
						if(string.find(itemString, "Radio%.")) then

							item = InventoryItemFactory.CreateItem(allRecipes:get(i):getModule():getName() .. "." .. itemString);
						elseif (string.find(itemString, "Base%.DigitalWatch2") or string.find(itemString,"Base%.AlarmClock2")) then
							item = nil;
						else
							item = InventoryItemFactory.CreateItem(itemString);
						end

						if item then
							-- Insert the recipe in recipesByItem array
							craftHelper41.setRecipeForItem(item:getName(), allRecipes:get(i));
						end
					end
				end
			 end
			--end
			nbRecipes = nbRecipes + 1;
		end
	end

	table.sort(craftHelper41.allRecipes, craftHelper41.recipeSortByName);

	craftHelper41.loadAllItemsManuals();

	print(nbRecipes .. ' recipes loaded.');

end


---
-- Test if a recipe is already set for an item in the "recipes by item" array
--
craftHelper41.recipeAlreadySet = function(tabRecipes, recipe)
	-- Go through the recipes already set for the item
	-- If the recipe is found, return true to report that the recipe already exists
	for i=1, #tabRecipes do
		if tabRecipes[i]:getName() == recipe:getName() then
			return true;
		end
	end

	return false;
end


---
-- Insert recipe in the "recipes by item" array
--
craftHelper41.setRecipeForItem = function(itemName, recipe)
	-- If no recipes has already been set for this item, we initialize the array (empty) of recipes
	if type(craftHelper41.recipesByItem[itemName]) ~= 'table' then
		craftHelper41.recipesByItem[itemName] = {};
	end

	-- If the recipe has not been already set for the item, we insert it
	--if not craftHelper41.recipeAlreadySet(craftHelper41.recipesByItem[itemName], recipe) then
	--	print("recipe set for:"..itemName);
		table.insert(craftHelper41.recipesByItem[itemName], recipe);
	--end
end


---
-- Used to sort by name our recipes list
--
craftHelper41.recipeSortByName = function(a,b)
    return not string.sort(a:getName(), b:getName());
end

craftHelper41.loadAllItemsManuals = function()
	local allItems = getAllItems();

	for i=0, allItems:size() - 1 do
		local item = allItems:get(i);

		if item:getTypeString() == "Literature" then
			item = item:InstanceItem(nil);

			local teachedRecipes = item:getTeachedRecipes();
			if teachedRecipes ~= nil and teachedRecipes:size() > 0 then
				for j=0, teachedRecipes:size() - 1 do
					local recipeString = teachedRecipes:get(j);
					if craftHelper41.itemsManuals[recipeString] == nil then
						craftHelper41.itemsManuals[recipeString] = {};
					end
					table.insert(craftHelper41.itemsManuals[recipeString], item:getName())
				end
			end
		end
	end
end


---
-- Load all recipes and items in array when game starts
-- 
Events.OnGameBoot.Add(craftHelper41.loadDatas);