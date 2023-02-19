require 'CHC_main'

CHC_menu = {}

--- called just after CHC_main.loadDatas
--- loads config and creates window instance
CHC_menu.createCraftHelper = function()
	CHC_settings.Load()
	CHC_settings.LoadPropsData()
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
		if not instanceof(items[i], 'InventoryItem') then
			item = items[i].items[1]
		else
			item = items[i]
		end

		-- if item is used in any recipe OR there is a way to create this item - mark item as valid
		local fullType = item:getFullType()
		local cond1 = type(CHC_main.recipesByItem[fullType]) == 'table'
		local cond2 = type(CHC_main.recipesForItem[fullType]) == 'table'
		-- also check for evolved recipes
		local cond3 = type(CHC_main.evoRecipesByItem[fullType]) == 'table'
		local cond4 = type(CHC_main.evoRecipesForItem[fullType]) == 'table'
		if cond1 or cond2 or cond3 or cond4 then
			table.insert(itemsUsedInRecipes, item)
		end
	end

	-- If one or more items tested above are used in a recipe
	-- we effectively add an option in the contextual menu
	if type(itemsUsedInRecipes) == 'table' and #itemsUsedInRecipes > 0 then
		local opt = context:addOption(getText('IGUI_chc_context_onclick'), itemsUsedInRecipes, CHC_menu.onCraftHelper,
			player)
		CHC_main.common.addTooltipNumRecipes(opt, item)
	end
	if isShiftKeyDown() and CHC_menu.CHC_window ~= nil then
		local isFav = CHC_main.playerModData[CHC_main.getFavItemModDataStr(item)] == true
		local favStr = isFav and getText('ContextMenu_Unfavorite') or getText('IGUI_CraftUI_Favorite')
		local optName = favStr .. ' (' .. getText('IGUI_chc_context_onclick') .. ')'
		context:addOption(optName, items, CHC_menu.toggleItemFavorite)

		context:addOption(getText('IGUI_find_item') .. ' (' .. getText('IGUI_chc_context_onclick') .. ')', items,
			CHC_menu.onCraftHelper, player, true)
	end
end

CHC_menu.onCraftHelper = function(items, player, itemMode)
	itemMode = itemMode and true or false
	local inst = CHC_menu.CHC_window
	if inst == nil then
		inst = CHC_menu.createCraftHelper()
	end

	-- Show craft helper window
	for i = 1, #items do
		local item = items[i]
		if not instanceof(item, 'InventoryItem') then
			item = item.items[1]
		end
		if not itemMode then
			inst:addItemView(item)
		end
	end
	if itemMode then
		local item = items[#items]
		if not instanceof(item, 'InventoryItem') then item = item.items[1] end
		item = CHC_main.items[item:getFullType()]
		if item then
			CHC_menu.onCraftHelperItem(inst, item)
		end
	end

	if not inst:getIsVisible() then
		inst:setVisible(true)
		inst:addToUIManager()
	end
end

CHC_menu.onCraftHelperItem = function(window_inst, item)
	local backRef = window_inst
	local viewName = getText('UI_search_tab_name')
	backRef:refresh(viewName) -- activate top level search view
	backRef:refresh(backRef.uiTypeToView['search_items'].name,
		backRef.panel.activeView.view) -- activate Items subview
	local view = backRef:getActiveSubView()
	local txt = string.format('#%s,%s', item.displayCategory, item.displayName)
	txt = string.lower(txt)
	view.searchRow.searchBar:setText(txt) -- set text to Items subview search bar
	view:updateItems(view.selectedCategory)
	if #view.objList.items ~= 0 then
		local it = view.objList.items
		local c = 1
		for i = 1, #it do
			if string.lower(it[i].text) == string.lower(item.displayName) then
				c = i
				break
			end
		end
		view.objList.selected = c
		view.objList:ensureVisible(c)
		if view.objPanel then
			view.objPanel:setObj(it[c].item)
			-- view.needSyncFilters = true
		end
	end
end

--- window toggle logic
CHC_menu.toggleUI = function(ui)
	local ui = ui or CHC_menu.CHC_window
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
		if not instanceof(items[i], 'InventoryItem') then
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
