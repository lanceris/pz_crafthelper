require "ISUI/ISScrollingListBox"

CHC_uses_recipelist = ISScrollingListBox:derive("CHC_uses_recipelist")

local fontSizeToInternal = {
	{ font = UIFont.Small, pad = 4, icon = 10 },
	{ font = UIFont.Medium, pad = 4, icon = 18 },
	{ font = UIFont.Large, pad = 6, icon = 24 }
}

-- region create
function CHC_uses_recipelist:initialise()
	ISScrollingListBox.initialise(self)
end

-- endregion

-- region update

function CHC_uses_recipelist:isMouseOverFavorite(x)
	return (x >= self.width - 40) and not self:isMouseOverScrollBar()
end

-- endregion

-- region render

function CHC_uses_recipelist:prerender()
	ISScrollingListBox.prerender(self)
	self:getContainers();
end

function CHC_uses_recipelist:doDrawItem(y, item, alt)
	local shouldDrawMod = CHC_settings.config.show_recipe_module
	local curFontData = fontSizeToInternal[CHC_settings.config.list_font_size]
	if not curFontData then curFontData = fontSizeToInternal[3] end
	if self.font ~= curFontData.font then
		self:setFont(curFontData.font, curFontData.pad)
	end

	if shouldDrawMod then
		if item.item.module == 'Base' then
			shouldDrawMod = false
		end
	end

	item.height = curFontData.icon + 2 * curFontData.pad
	if shouldDrawMod then
		item.height = item.height + 2 + getTextManager():getFontHeight(UIFont.Small)
	end

	if y < -self:getYScroll() - 1 then return y + item.height; end
	if y > self.height - self:getYScroll() + 1 then return y + item.height; end
	if y + self:getYScroll() >= self.height then return y + item.height end
	if y + item.height + self:getYScroll() <= 0 then return y + item.height end

	local recipe = item.item
	local a = 0.9
	local favoriteStar = nil
	local favoriteAlpha = a
	local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
	local iconsEnabled = CHC_settings.config.show_icons

	-- region icons
	if iconsEnabled then
		local resultItem = recipe.recipeData.result
		if resultItem then
			local tex = resultItem.texture
			if tex then
				self:drawTextureScaled(tex, 6, y + 6, curFontData.icon, curFontData.icon, 1)
			end
		end
	end
	--endregion

	--region text
	local clr = { txt = item.text, x = iconsEnabled and (curFontData.icon + 8) or 15, y = (y) + itemPadY,
		a = 0.9, font = self.font }
	if not self.player:isRecipeKnown(recipe.recipe) then
		-- unknown recipe, red text
		clr['r'], clr['g'], clr['b'] = 0.7, 0, 0
	elseif RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.containerList) then
		-- can craft, green text
		clr['r'], clr['g'], clr['b'] = 0, 0.7, 0
	else
		-- known but cant craft, white text
		clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
	end
	self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font)
	if shouldDrawMod then
		local modY = clr.y + getTextManager():getFontHeight(self.font)
		self:drawText("Mod: " .. item.item.module, clr.x + 5, modY, 1, 1, 1, 0.8, UIFont.Small)
	end
	--endregion

	--region favorite handler
	local favYPos = self.width - 30
	if item.index == self.mouseoverselected and not self:isMouseOverScrollBar() then
		if self:getMouseX() >= favYPos - 20 then
			favoriteStar = item.item.favorite and self.favCheckedTex or self.favNotCheckedTex
			favoriteAlpha = 0.9
		else
			favoriteStar = item.item.favorite and self.favoriteStar or self.favNotCheckedTex
			favoriteAlpha = item.item.favorite and a or 0.3
		end
	elseif item.item.favorite then
		favoriteStar = self.favoriteStar
	end
	if favoriteStar then
		self:drawTexture(favoriteStar, favYPos, y + (item.height / 2 - favoriteStar:getHeight() / 2), favoriteAlpha, 1, 1, 1);
	end
	--endregion

	--region filler
	local sc = { x = 0, y = y, w = self:getWidth(), h = item.height - 1, a = 0.2, r = 0.75, g = 0.5, b = 0.5 }
	local bc = { x = sc.x, y = sc.y, w = sc.w, h = sc.h + 1, a = 0.25, r = 1, g = 1, b = 1 }
	-- fill selected entry
	if self.selected == item.index then
		self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b);
	end
	-- border around entry
	self:drawRectBorder(bc.x, bc.y, bc.w, bc.h, bc.a, bc.r, bc.g, bc.b);
	--endregion

	y = y + item.height;
	return y;
end

-- endregion

-- region logic

-- region event handlers

function CHC_uses_recipelist:onMouseDown_Recipes(x, y)
	local row = self:rowAt(x, y)
	if row == -1 then return end
	if self:isMouseOverFavorite(x) then
		self:addToFavorite(row)
	end
end

function CHC_uses_recipelist:onMouseUpOutside(x, y)
	ISScrollingListBox.onMouseUpOutside(self, x, y)
end

-- endregion

function CHC_uses_recipelist:getContainers()
	if not self.player then return end
	local playerNum = self.player and self.player:getPlayerNum() or -1
	-- get all the surrounding inventory of the player, gonna check for the item in them too
	local playerInv = getPlayerInventory(playerNum)
	local playerLoot = getPlayerLoot(playerNum)
	if not playerInv and not playerLoot then return end
	self.containerList = ArrayList.new()
	playerInv = playerInv.inventoryPane.inventoryPage.backpacks
	playerLoot = playerLoot.inventoryPane.inventoryPage.backpacks
	for i = 1, #playerInv do
		self.containerList:add(playerInv[i].inventory)
	end
	for i = 1, #playerLoot do
		self.containerList:add(playerLoot[i].inventory)
	end
end

function CHC_uses_recipelist:addToFavorite(selectedIndex, fromKeyboard)
	if fromKeyboard == true then
		selectedIndex = self.selected
	end
	local selectedItem = self.items[selectedIndex]
	if not selectedItem then return end
	local allr = getPlayerCraftingUI(0).categories
	local fav_idx;
	local parent = self.parent

	--find "Favorite" category
	for i, v in ipairs(allr) do
		if v.category == getText("IGUI_CraftCategory_Favorite") then
			fav_idx = i
			break
		end
	end
	if fav_idx == nil then return end
	local fav_recipes = allr[fav_idx].recipes.items
	selectedItem.item.favorite = not selectedItem.item.favorite;
	self.modData[CHC_main.getFavoriteRecipeModDataString(selectedItem.item.recipe)] = selectedItem.item.favorite
	if selectedItem.item.favorite then
		parent.favRecNum = parent.favRecNum + 1
		table.insert(fav_recipes, selectedItem)
	else
		parent.favRecNum = parent.favRecNum - 1
		local cs = parent.filterRow.categorySelector
		if cs.options[cs.selected].text == parent.favCatName or parent.ui_type == 'fav_recipes' then
			self:removeItemByIndex(selectedIndex)
			parent.needUpdateTypes = true
		end
	end
	if #self.items == 0 then
		parent.needUpdateObjects = true
	end
	parent.needUpdateFavorites = true
end

-- endregion


function CHC_uses_recipelist:new(x, y, width, height)
	local o = {}

	o = ISScrollingListBox:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
	o.anchorTop = true
	o.anchorBottom = true
	local player = getPlayer()
	o.player = player
	o.character = player
	o.playerNum = player and player:getPlayerNum() or -1
	o.modData = CHC_main.playerModData

	o.favoriteStar = getTexture("media/ui/FavoriteStar.png")
	o.favCheckedTex = getTexture("media/ui/FavoriteStarChecked.png")
	o.favNotCheckedTex = getTexture("media/ui/FavoriteStarUnchecked.png")
	return o
end
