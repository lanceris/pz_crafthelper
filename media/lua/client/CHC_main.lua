require 'luautils';

CHC_main = {};
CHC_main.version = "1.4.1";
CHC_main.author = "lanceris";
CHC_main.previousAuthors = {"Peanut", "ddraigcymraeg", "b1n0m"}
CHC_main.modName = "CraftHelperContinued";
CHC_main.recipesByItem = {};
CHC_main.allRecipes = {};
CHC_main.skipModules = {};
CHC_main.itemsManuals = {};
CHC_main.isDebug = false or getDebug();


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


CHC_main.loadDatas = function()
	print('Loading recipes...');
	local nbRecipes = 0;

	-- Get all recipes in game (vanilla recipes + any mods recipes)
	local allRecipes = getAllRecipes();

	-- Go through recipes stack
	for i=0,allRecipes:size() -1 do
		local newItem = {}
		local skip_modules = CHC_main.skipModules[allRecipes:get(i):getModule():getName()]
		if skip_modules == nil or skip_modules == false then
			table.insert(CHC_main.allRecipes, allRecipes:get(i));

			-- Go through items needed by the recipe
			 for n=0, allRecipes:get(i):getSource():size() - 1 do
				-- Get the item name (not the display name)
				local rec = allRecipes:get(i)
				local recipe = rec:getSource():get(n);

				if rec:getCategory() then
					newItem.category = rec:getCategory();
				else
					newItem.category = getText("IGUI_CraftCategory_General");
				end
				newItem.recipe = rec
				local modData = getPlayer():getModData()
				newItem.favorite = modData[CHC_main.getFavoriteModDataString(rec)] or false

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
							CHC_main.setRecipeForItem(item:getName(), newItem);
						end
					end
				end
			 end
			--end
			nbRecipes = nbRecipes + 1;
		end
	end

	table.sort(CHC_main.allRecipes, CHC_main.recipeSortByName);

	CHC_main.loadAllItemsManuals();

	print(nbRecipes .. ' recipes loaded.');

end


-- Test if a recipe is already set for an item in the "recipes by item" array
CHC_main.recipeAlreadySet = function(tabRecipes, recipe)
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
CHC_main.setRecipeForItem = function(itemName, recipe)
	-- If no recipes has already been set for this item, we initialize the array (empty) of recipes
	if type(CHC_main.recipesByItem[itemName]) ~= 'table' then
		CHC_main.recipesByItem[itemName] = {};
	end

	-- If the recipe has not been already set for the item, we insert it
	table.insert(CHC_main.recipesByItem[itemName], recipe);
end


---
-- Used to sort by name our recipes list
--
CHC_main.recipeSortByName = function(a,b)
    return not string.sort(a:getName(), b:getName());
end

CHC_main.loadAllItemsManuals = function()
	local allItems = getAllItems();

	for i=0, allItems:size() - 1 do
		local item = allItems:get(i);

		if item:getTypeString() == "Literature" then
			item = item:InstanceItem(nil);

			local teachedRecipes = item:getTeachedRecipes();
			if teachedRecipes ~= nil and teachedRecipes:size() > 0 then
				for j=0, teachedRecipes:size() - 1 do
					local recipeString = teachedRecipes:get(j);
					if CHC_main.itemsManuals[recipeString] == nil then
						CHC_main.itemsManuals[recipeString] = {};
					end
					table.insert(CHC_main.itemsManuals[recipeString], item:getName())
				end
			end
		end
	end
end

function CHC_main.reloadMod(key)
	if key == 20 then
		CHC_main.loadDatas();
	end
end

---
-- Load all recipes and items in array when game starts
--
if CHC_main.isDebug then
	Events.OnKeyPressed.Add(CHC_main.reloadMod);
end

Events.OnGameStart.Add(CHC_main.loadDatas);