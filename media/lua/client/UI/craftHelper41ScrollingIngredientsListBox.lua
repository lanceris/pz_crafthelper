require "ISUI/ISScrollingListBox";

craftHelper41ScrollingIngredientsListBox = ISScrollingListBox:derive("craftHelper41ScrollingIngredientsListBox");


---
--
--
function craftHelper41ScrollingIngredientsListBox:isCraftable(recipe)
	local craftable = true;

	local playerInventory = getSpecificPlayer(self.player):getInventory();
	-- Go through the items list needed to craft the recipe
	--for i=0, recipe.item:getNumberOfNeededItem() - 1 do
	for n=0, recipe.item:getSource():size() - 1 do
		local neededItem = recipe.item:getSource():get(n);
		if neededItem then


			for k=0, neededItem:getItems():size() - 1 do
				--i = i + 1;

				local invItem = InventoryItemFactory.CreateItem(neededItem:getItems():get(k));


				if invItem == nil then
					invItem = InventoryItemFactory.CreateItem(recipe.item:getModule():getName() .. "." .. neededItem:getItems():get(k));

				end

				if invItem then
					if not playerInventory:contains(neededItem:getItems():get(k)) or playerInventory:getNumberOfItem(neededItem:getItems():get(k)) < neededItem:getCount() then
						craftable = false;
					end
				else
					local tabNeededItems = luautils.split(neededItem:getItems():get(k), '/');
					local ownedItems = 0;
					for _,item in ipairs(tabNeededItems) do
						local objItem = InventoryItemFactory.CreateItem(item);

						if objItem == nil then
							objItem = InventoryItemFactory.CreateItem(recipe.item:getModule():getName() .. "." .. item);
						end
						if objItem and playerInventory:contains(objItem:getOnlyItem()) and playerInventory:getNumberOfItem(objItem:getOnlyItem()) >= neededItem:getCount() then
							ownedItems = ownedItems + 1;
						end
					end

					if ownedItems == 0 then
						craftable = false;
					end
				end
			end
		end
	end

	return craftable;
end

---
--
--
function craftHelper41ScrollingIngredientsListBox:createItem(sourceItemString)
	local sourceItem;
	-- todo find out what's wrong with the radio and digital watch (it's not related with recent update @see DismantleDigitalWatch_GetItemTypes)
	if(string.find(sourceItemString, "Radio%.")) then
		sourceItem = InventoryItemFactory.CreateItem(self.recipe:getModule():getName() .. "." .. sourceItemString);
	else
		sourceItem = InventoryItemFactory.CreateItem(sourceItemString);
	end

	return sourceItem;
end

---
--
--
function craftHelper41ScrollingIngredientsListBox:setRecipe(recipe)
    self.recipe = recipe;
	self:clear();
end


---
--
--
function craftHelper41ScrollingIngredientsListBox:new(x, y, width, height, player)
	local o = {};
	o = ISScrollingListBox:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;
	o.backgroundColor = {r=0, g=0, b=0, a=0};
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9};
	o.anchorTop = true;
	o.anchorBottom = true;
	o.player = player;
	o.recipe = nil;
	return o;
end
