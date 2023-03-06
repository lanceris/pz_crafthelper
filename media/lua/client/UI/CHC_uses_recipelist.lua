CHC_uses_recipelist = ISScrollingListBox:derive('CHC_uses_recipelist')

-- region create
function CHC_uses_recipelist:initialise()
	ISScrollingListBox.initialise(self)
	self.fastListReturn = CHC_main.common.fastListReturn
end

-- endregion

-- region render

function CHC_uses_recipelist:prerender()
	CHC_view._list.prerender(self)
end

function CHC_uses_recipelist:doDrawItem(y, item, alt)
	if self:fastListReturn(y) then return y + item.height end

	local recipe = item.item
	local a = 0.9
	local favoriteStar = nil
	local favoriteAlpha = a
	local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2

	local clr = {
		txt = item.text,
		x = self.shouldShowIcons and (self.curFontData.icon + 8) or 15, --FIXME
		y = y + itemPadY,
		a = 0.9,
		font = self.font
	}

	-- region icons
	if self.shouldShowIcons then
		local resultItem = recipe.recipeData.result
		if resultItem then
			local tex = resultItem.texture
			if tex then
				self:drawTextureScaled(tex, 6, y - 2 + self.curFontData.icon / 2,
					self.curFontData.icon, self.curFontData.icon, 1)
			end
		end
	end
	--endregion

	--region text
	if recipe.isSynthetic then
		-- known but cant craft, white text
		clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
	elseif recipe.isEvolved then
		if recipe.valid then
			-- can 'craft', green text
			clr['r'], clr['g'], clr['b'] = 0, 0.7, 0
		else
			clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
		end
	else
		if recipe.valid then
			clr['r'], clr['g'], clr['b'] = 0, 0.7, 0
		elseif recipe.known then
			clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
		else
			clr['r'], clr['g'], clr['b'] = 0.7, 0, 0
		end
	end
	if self.shouldDrawMod and item.item.module ~= 'Base' then
		self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font)
		local modY = self.curFontData.pad + getTextManager():getFontHeight(UIFont.Small)
		self:drawText('Mod: ' .. item.item.module, clr.x + self.curFontData.pad, clr.y + modY, 1, 1, 1, 0.8, UIFont
			.Small)
	else
		self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font)
	end
	--endregion

	--region favorite handler
	local favYPos = self.width - 30
	if item.index == self.mouseoverselected then
		if self.mouseX >= favYPos - 20 and self.mouseX <= favYPos + 20 then
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
		self:drawTexture(favoriteStar, favYPos, y + (item.height / 2 - favoriteStar:getHeight() / 2), favoriteAlpha, 1, 1,
			1);
	end
	--endregion

	--region filler
	local sc = { x = 0, y = y, w = self.width, h = item.height - 1, a = 0.2, r = 0.75, g = 0.5, b = 0.5 }
	local bc = { x = sc.x, y = sc.y, w = sc.w, h = sc.h + 1, a = 0.25, r = 1, g = 1, b = 1 }
	-- fill selected entry
	if self.selected == item.index then
		self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b);
	end
	-- border around entry
	self:drawRectBorder(bc.x, bc.y, bc.w, bc.h, bc.a, bc.r, bc.g, bc.b);

	if item.index == self.mouseoverselected then
		self:drawRect(sc.x, sc.y, sc.w, sc.h, 0.2, 0.5, sc.g, sc.b)
	end
	--endregion

	y = y + item.height;
	return y;
end

-- endregion

-- region logic

function CHC_uses_recipelist:onMouseDownObj(x, y)
	local row = self:rowAt(x, y)
	if row == -1 then return end
	if CHC_view._list.isMouseOverFavorite(self, x) then
		self:addToFavorite(row)
	end
end

function CHC_uses_recipelist:onMouseUpOutside(x, y)
	ISScrollingListBox.onMouseUpOutside(self, x, y)
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

	--find 'Favorite' category
	for i, v in ipairs(allr) do
		if v.category == getText('IGUI_CraftCategory_Favorite') then
			fav_idx = i
			break
		end
	end
	if not fav_idx then return end
	local fav_recipes = allr[fav_idx].recipes.items
	selectedItem.item.favorite = not selectedItem.item.favorite
	local favStr = CHC_main.getFavoriteRecipeModDataString(selectedItem.item)
	self.modData[favStr] = selectedItem.item.favorite
	if selectedItem.item.favorite then
		table.insert(fav_recipes, selectedItem)
	else
		if parent.ui_type == 'fav_recipes' then
			self:removeItemByIndex(selectedIndex)
		end
	end
	parent.needUpdateFavorites = true
end

-- endregion


function CHC_uses_recipelist:new(args)
	local o = {}

	o = ISScrollingListBox:new(args.x, args.y, args.w, args.h)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
	o.anchorTop = true
	o.anchorBottom = true
	o.backRef = args.backRef
	o.modData = CHC_main.playerModData

	o.favoriteStar = getTexture('media/textures/CHC_recipe_favorite_star.png')
	o.favCheckedTex = getTexture('media/textures/CHC_recipe_favorite_star_checked.png')
	o.favNotCheckedTex = getTexture('media/textures/CHC_recipe_favorite_star_outline.png')
	o.mouseX = 0
	o.mouseY = 0
	o.yScroll = 0
	o.fontSize = getTextManager():getFontHeight(o.font)


	o.shouldDrawMod = CHC_settings.config.show_recipe_module
	o.shouldShowIcons = CHC_settings.config.show_icons

	o.needUpdateScroll = false
	o.needUpdateMousePos = false
	o.needUpdateRecipeState = false
	return o
end
