require "ISUI/ISScrollingListBox";

CHC_uses_recipelist = ISScrollingListBox:derive("CHC_uses_recipelist");

function CHC_uses_recipelist:initialise()
	ISScrollingListBox.initialise(self)
end


function CHC_uses_recipelist:getContainers()
	if not self.player then return end
	local playerNum = self.player and self.player:getPlayerNum() or -1
	-- get all the surrounding inventory of the player, gonna check for the item in them too
	self.containerList = ArrayList.new();
	for i,v in ipairs(getPlayerInventory(playerNum).inventoryPane.inventoryPage.backpacks) do
		--        if v.inventory ~= self.character:getInventory() then -- owner inventory already check in RecipeManager
		self.containerList:add(v.inventory);
		--        end
	end
	for i,v in ipairs(getPlayerLoot(playerNum).inventoryPane.inventoryPage.backpacks) do
		self.containerList:add(v.inventory);
	end
end


function CHC_uses_recipelist:prerender()
	ISScrollingListBox.prerender(self)
	self:getContainers();
end


function CHC_uses_recipelist:onMouseDown_Recipes(x, y)
	local row = self:rowAt(x,y)
    if row == -1 then return end
    if self:isMouseOverFavorite(x) then
        self:addToFavorite()
    end
end


function CHC_uses_recipelist:getFavoriteX()
    -- scrollbar width=17 but only 13 pixels wide visually
    -- local scrollBarWid = self.parent:isVScrollBarVisible() and 13 or 0
	return self.width - 40
    -- return self.parent:getWidth() - scrollBarWid - self.favPadX - self.favWidth - self.favPadX
end

function CHC_uses_recipelist:isMouseOverFavorite(x)
    return (x >= self:getFavoriteX()) and not self:isMouseOverScrollBar()
end


function CHC_uses_recipelist:addToFavorite()
    local selectedIndex = self:rowAt(self:getMouseX(), self:getMouseY());

    local selectedItem = self.items[selectedIndex]
	local modData = self.player:getModData();
	local allr = getPlayerCraftingUI(0).categories
	local fav_idx;
	
	--find "Favorite" category
	for i, v in ipairs(allr) do
		if v.category == getText("IGUI_CraftCategory_Favorite") then
			fav_idx = i
			break
		end
	end
	if fav_idx == nil then return end;
	local fav_recipes = allr[fav_idx].recipes.items
	selectedItem.item.favorite = not selectedItem.item.favorite;
	modData[CHC_main.getFavoriteModDataString(selectedItem.item.recipe)] = selectedItem.item.favorite
	if selectedItem.favorite then
		table.insert(fav_recipes, selectedItem)
	end
end

function CHC_uses_recipelist:doDrawItem(y, item, alt)

	local recipe = item.item.recipe
	local recipeList = self.parent
	local a = 0.9
	local favoriteStar = nil
	local favoriteAlpha = a
	local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2

	if y < -self:getYScroll()-1 then return y+item.height; end
	if y > self:getHeight()-self:getYScroll()+1 then return y+item.height; end

	--region text
	local clr = {txt=item.text, x=15, y=(y)+itemPadY,
				 a=0.9, font=self.font}
	if not self.player:isRecipeKnown(recipe) then
		-- unknown recipe, red text
		clr['r'], clr['g'], clr['b'] = 0.7, 0, 0
	elseif RecipeManager.IsRecipeValid(recipe, self.player, nil, self.containerList) then
		-- can craft, green text
		clr['r'], clr['g'], clr['b'] = 0, 0.7, 0
	else
		-- known but cant craft, white text
		clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
	end
	self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font);
	--endregion

	--region favorite handler
	local favYPos = self.width - 30
	if item.index == self.mouseoverselected and not self:isMouseOverScrollBar() then
		if self:getMouseX() >= favYPos-20 then
			favoriteStar = item.item.favorite and self.favCheckedTex or self.favNotCheckedTex
			favoriteAlpha = 0.9
		else
			favoriteStar = item.item.favorite and self.favoriteStar or self.favNotCheckedTex
			favoriteAlpha = item.item.favorite and a or 0.3
		end
	elseif item.item.favorite then
        favoriteStar = recipeList.favoriteStar
	end
	if favoriteStar then
        self:drawTexture(favoriteStar, favYPos, y + (item.height / 2 - favoriteStar:getHeight() / 2), favoriteAlpha,1,1,1);
    end
	--endregion

	--region filler
	local sc = {x=0,y=y,w=self:getWidth(),h=item.height-1,a=0.2,r=0.75,g=0.5,b=0.5}
	local bc = {x=sc.x, y=sc.y,w=sc.w, h=sc.h+1, a=0.25,r=1,g=1,b=1}
	-- fill selected entry
	if self.selected == item.index then
		self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b);
	end
	-- border around entry
	self:drawRectBorder(bc.x, bc.y, bc.w, bc.h, bc.a,bc.r,bc.g,bc.b);
	--endregion

	y = y + item.height;
	return y;
end


function CHC_uses_recipelist:new(x, y, width, height)
	local o = {};

	o = ISScrollingListBox:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;
	o.backgroundColor = {r=0, g=0, b=0, a=0};
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9};
	o.anchorTop = true;
	o.anchorBottom = true;
	o.player = getPlayer();

	o.favoriteStar = getTexture("media/ui/FavoriteStar.png");
    o.favCheckedTex = getTexture("media/ui/FavoriteStarChecked.png");
    o.favNotCheckedTex = getTexture("media/ui/FavoriteStarUnchecked.png");
	o.favPadX = 20;
    o.favWidth = o.favoriteStar and o.favoriteStar:getWidth() or 13
	return o;
end
