require 'CHC_main';
require 'CHC_config'
require 'UI/CHC_window';

CHC_menu = {};

CHC_menu.doCraftHelperMenu = function(player,context, items)
	local isUsedInRecipe = false;
	
	-- Go through the items selected (because multiple selections in inventory is possible)
	-- todo: remove/refactor multiple windows when multiple items
	for _,item in ipairs(items) do
		
		if not instanceof(item, "InventoryItem") then
            item = item.items[1];
        end
		
		-- We test here if the item is used in any recipes
		if type(CHC_main.recipesByItem[item:getName()]) == 'table' then
			isUsedInRecipe = true;
		end
	end
	
	-- If one or more items tested above are used in a recipe
	-- we effectively add an option in the contextual menu
	if isUsedInRecipe then
		CHC_config.fn.loadSettings() -- load config
		if CHC_config.options.main_window_x == nil then
			CHC_config.fn.resetSettings()
			CHC_config.fn.loadSettings()
		end
		CHC_menu.cfg = CHC_config.options
		context:addOption("Craft Helper 41", items, CHC_menu.onCraftHelper, player);
	end
end


---
-- Action to perform when the Craft Helper option in contextual menu is clicked
--
CHC_menu.onCraftHelper = function(items, player)
	-- Go through the items selected (because multiple selections in inventory is possible)
	for _,item in ipairs(items) do
		
		if not instanceof(item, "InventoryItem") then
            item = item.items[1];
        end
		-- Show craft helper window
		
		local args = {
			x=CHC_menu.cfg.main_window_x,
			y=CHC_menu.cfg.main_window_y,
			width=CHC_menu.cfg.main_window_w,
			height=CHC_menu.cfg.main_window_h,
			backgroundColor = {r=0, g=0, b=0, a=1},
			minimumWidth = CHC_menu.cfg.main_window_min_w,
			minimumHeight = CHC_menu.cfg.main_window_min_h,
			item=item

		};
		CHC_menu.CHC_Window = CHC_window:new(args);
		CHC_menu.CHC_Window:initialise();
		CHC_menu.CHC_Window:addToUIManager();
	end
end


---
-- Call doCraftHelperMenu function when context menu in the inventory is created and displayed
--
Events.OnFillInventoryObjectContextMenu.Add(CHC_menu.doCraftHelperMenu);