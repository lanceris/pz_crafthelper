require 'crafthelper41';
require 'UI/craftHelper41Window';

craftHelper41Menu = {};

---
-- Add option in contextual menu when right click is done on an item in inventory panel
--
craftHelper41Menu.doCraftHelperMenu = function(player,context, items)
	local isUsedInRecipe = false;
	
	-- Go through the items selected (because multiple selections in inventory is possible)
	for _,item in ipairs(items) do
		
		if not instanceof(item, "InventoryItem") then
            item = item.items[1];
			
        end
		
		-- We test here if the item is used in any recipes
		if type(craftHelper41.recipesByItem[item:getName()]) == 'table' then
			isUsedInRecipe = true;
		end
	end
	
	-- If one or more items tested above are used in a recipe
	-- we effectively add an option in the contextual menu
	if isUsedInRecipe then
		context:addOption("Craft Helper 41", items, craftHelper41Menu.onCraftHelper, player);
	end
end


---
-- Action to perform when the Craft Helper option in contextual menu is clicked
--
craftHelper41Menu.onCraftHelper = function(items, player)
	-- Go through the items selected (because multiple selections in inventory is possible)
	for _,item in ipairs(items) do
		
		if not instanceof(item, "InventoryItem") then
            item = item.items[1];
        end
		
		-- Show craft helper window
		craftHelper41Menu.craftHelperWindow = craftHelper41Window:new(100, 100, item);
		craftHelper41Menu.craftHelperWindow:initialise();
		craftHelper41Menu.craftHelperWindow:addToUIManager();
	end
end


---
-- Call doCraftHelperMenu function when context menu in the inventory is created and displayed
--
Events.OnFillInventoryObjectContextMenu.Add(craftHelper41Menu.doCraftHelperMenu);