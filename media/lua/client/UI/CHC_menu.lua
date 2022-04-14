require 'CHC_main'

CHC_menu = {}

CHC_menu.cachedItemsView = nil


CHC_menu.createCraftHelper = function()
	CHC_settings.Load()
	local options = CHC_settings.config

	local args = {
		x = options.main_window.x,
		y = options.main_window.y,
		width = options.main_window.w,
		height = options.main_window.h,
		backgroundColor = { r = 0, g = 0, b = 0, a = 1 },
		minimumWidth = 400,
		minimumHeight = 350
	}
	CHC_menu.CHC_window = CHC_window:new(args)
	CHC_menu.CHC_window:initialise()
	CHC_menu.CHC_window:setVisible(false)
end

CHC_menu.doCraftHelperMenu = function(player, context, items)
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
		context:addOption(getText("IGUI_chc_context_onclick"), itemsUsedInRecipes, CHC_menu.onCraftHelper, player);
	end
end


---
-- Action to perform when the Craft Helper option in contextual menu is clicked
--

CHC_menu.onCraftHelper = function(items, player)
	local inst = CHC_menu.CHC_window

	-- Show craft helper window
	for i = 1, #items do
		local item = items[i]
		if not instanceof(item, "InventoryItem") then
			item = item.items[1]
		end
		inst:addItemView(item)
	end
	if not inst:getIsVisible() then
		inst:setVisible(true)
		inst:addToUIManager()
	end
end

CHC_menu.toggleUI = function()
	local ui = CHC_menu.CHC_window
	if ui then
		if ui:getIsVisible() then
			ui:setVisible(false)
			ui:removeFromUIManager()
		else
			ui:setVisible(true)
			ui:addToUIManager()
		end
	end
end


CHC_menu.onPressKey = function(key)
	if not MainScreen.instance or not MainScreen.instance.inGame or MainScreen.instance:getIsVisible() then
		return
	end
	if key == CHC_settings.keybinds.toggle_window.key then
		CHC_menu.toggleUI()
	end
end

---
-- Call doCraftHelperMenu function when context menu in the inventory is created and displayed
--
Events.OnFillInventoryObjectContextMenu.Add(CHC_menu.doCraftHelperMenu)

Events.OnCustomUIKey.Add(CHC_menu.onPressKey)
