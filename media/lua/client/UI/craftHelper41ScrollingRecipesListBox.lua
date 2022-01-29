require "ISUI/ISScrollingListBox";

craftHelper41ScrollingRecipesListBox = ISScrollingListBox:derive("craftHelper41ScrollingRecipesListBox");


---
--
--
function craftHelper41ScrollingRecipesListBox:getContainers()
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


---
--
--
function craftHelper41ScrollingRecipesListBox:prerender()
	ISScrollingListBox.prerender(self)
	self:getContainers();
end


---
--
--
function craftHelper41ScrollingRecipesListBox:doDrawItem(y, item, alt)
	if not item.height then item.height = self.itemheight end -- compatibility
	if self.selected == item.index then
		self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);

	end
	self:drawRectBorder(0, (y), self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
	if not self.player:isRecipeKnown(item.item) then
		self:drawText(item.text, 35, (y)+itemPadY, 0.7, 0, 0, 0.9, self.font);
	elseif RecipeManager.IsRecipeValid(item.item, self.player, nil, self.containerList) then
		self:drawText(item.text, 35, (y)+itemPadY, 0, 0.7, 0, 0.9, self.font);
	else
		self:drawText(item.text, 35, (y)+itemPadY, 0.9, 0.9, 0.9, 0.9, self.font);
	end
	y = y + item.height;
	return y;
end


---
--
--
function craftHelper41ScrollingRecipesListBox:new(x, y, width, height)
	local o = {};
	o = ISScrollingListBox:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;
	o.backgroundColor = {r=0, g=0, b=0, a=0};
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9};
	o.anchorTop = true;
	o.anchorBottom = true;
	o.player = getPlayer();
	return o;
end
