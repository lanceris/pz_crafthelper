require 'CHC_main'

CHC_menu = {}

--- called just after CHC_main.loadDatas
--- loads config and creates window instance
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

--- called on right-clicking item in inventory/hotbar
CHC_menu.doCraftHelperMenu = function(player, context, items)
	local itemsUsedInRecipes = {}

	local item
	-- Go through the items selected (because multiple selections in inventory is possible)
	for i = 1, #items do

		-- allows to get ctx option when clicking on hotbar/equipped item
		if not instanceof(items[i], "InventoryItem") then
			item = items[i].items[1]
		else
			item = items[i]
		end

		-- if item is used in any recipe OR there is a way to create this item - mark item as valid
		local cond1 = type(CHC_main.recipesByItem[item:getFullType()]) == 'table'
		local cond2 = type(CHC_main.recipesForItem[item:getFullType()]) == 'table'
		if cond1 or cond2 then
			table.insert(itemsUsedInRecipes, item)
		end
	end

	-- If one or more items tested above are used in a recipe
	-- we effectively add an option in the contextual menu
	if type(itemsUsedInRecipes) == 'table' and #itemsUsedInRecipes > 0 then
		context:addOption(getText("IGUI_chc_context_onclick"), itemsUsedInRecipes, CHC_menu.onCraftHelper, player);
	end
	if isShiftKeyDown() and CHC_menu.CHC_window ~= nil then
		local optName = getText("UI_servers_addToFavorite") .. " (" .. getText("IGUI_chc_context_onclick") .. ")"
		context:addOption(optName, items, CHC_menu.toggleItemFavorite)
	end
end

CHC_menu.onCraftHelper = function(items, player)
	local inst = CHC_menu.CHC_window
	if inst == nil then
		inst = CHC_menu.createCraftHelper()
	end

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

--- window toggle logic
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

CHC_menu.toggleItemFavorite = function(items)
	local modData = CHC_main.playerModData
	for i = 1, #items do
		local item
		if not instanceof(items[i], "InventoryItem") then
			item = items[i].items[1]
		else
			item = items[i]
		end
		local isFav = modData[CHC_main.getFavItemModDataStr(item)] == true
		isFav = not isFav
		modData[CHC_main.getFavItemModDataStr(item)] = isFav or nil
	end
	CHC_menu.CHC_window.updateQueue:push({
		targetView = 'fav_items',
		actions = { 'needUpdateFavorites', 'needUpdateObjects', 'needUpdateTypes', 'needUpdateCategories' }
	})
end

---Show/hide Craft Helper window keybind listener
---@param key number key code
CHC_menu.onPressKey = function(key)
	if not MainScreen.instance or not MainScreen.instance.inGame or MainScreen.instance:getIsVisible() then
		return
	end
	if key == CHC_settings.keybinds.toggle_window.key then
		CHC_menu.toggleUI()
	end
end

Events.OnFillInventoryObjectContextMenu.Add(CHC_menu.doCraftHelperMenu)
Events.OnCustomUIKey.Add(CHC_menu.onPressKey)
