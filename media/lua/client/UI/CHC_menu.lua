require 'CHC_main'

CHC_menu = {};

CHC_menu.cachedItemsView = nil

CHC_menu.doCraftHelperMenu = function(player, context, items)
	local isUsedInRecipe = false;
	local itemsUsedInRecipes = {}

	local item
	-- Go through the items selected (because multiple selections in inventory is possible)
	for i = 1, #items do

		if not instanceof(items[i], "InventoryItem") then
			item = items[i].items[1]
		else
			item = items[i]
		end

		-- We test here if the item is used in any recipes
		local cond1 = type(CHC_main.recipesByItem[item:getName()]) == 'table'
		local cond2 = type(CHC_main.recipesForItem[item:getName()]) == 'table'
		if cond1 or cond2 then
			table.insert(itemsUsedInRecipes, item)
		end
	end

	-- If one or more items tested above are used in a recipe
	-- we effectively add an option in the contextual menu
	if type(itemsUsedInRecipes) == 'table' and #itemsUsedInRecipes > 0 then
		CHC_config.fn.loadSettings() -- load config
		if CHC_config.options.main_window_x == nil then
			CHC_config.fn.resetSettings()
			CHC_config.fn.loadSettings()
		end
		CHC_menu.cfg = CHC_config.options
		context:addOption("Craft Helper 41", itemsUsedInRecipes, CHC_menu.onCraftHelper, player);
	end
end


---
-- Action to perform when the Craft Helper option in contextual menu is clicked
--
CHC_menu.onCraftHelper = function(items, player)

	-- Show craft helper window

	local args = {
		x = CHC_menu.cfg.main_window_x,
		y = CHC_menu.cfg.main_window_y,
		width = CHC_menu.cfg.main_window_w,
		height = CHC_menu.cfg.main_window_h,
		backgroundColor = { r = 0, g = 0, b = 0, a = 1 },
		minimumWidth = CHC_menu.cfg.main_window_min_w,
		minimumHeight = CHC_menu.cfg.main_window_min_h,
		items = items
	}
	CHC_menu.CHC_Window = CHC_window:new(args)
	CHC_menu.CHC_Window:initialise()
	CHC_menu.CHC_Window:addToUIManager()
end


---
-- Call doCraftHelperMenu function when context menu in the inventory is created and displayed
--
Events.OnFillInventoryObjectContextMenu.Add(CHC_menu.doCraftHelperMenu);
