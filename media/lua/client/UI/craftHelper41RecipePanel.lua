require 'ISUI/ISPanel';
require 'ISUI/ISLabel';
require 'UI/craftHelper41ScrollingIngredientsListBox';
require 'crafthelper41';

craftHelper41RecipePanel = ISPanel:derive("craftHelper41RecipePanel");

craftHelper41RecipePanel.largeFontHeight = getTextManager():getFontFromEnum(UIFont.Large):getLineHeight()
craftHelper41RecipePanel.mediumFontHeight = getTextManager():getFontHeight(UIFont.Medium)
craftHelper41RecipePanel.smallFontHeight = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()

local function tableSize(table1)
    if not table1 then return 0 end
    local count = 0;
    for _,v in pairs(table1) do
        count = count + 1;
    end
    return count;
end

local function areTablesDifferent(table1, table2)
    local size1 = tableSize(table1)
    local size2 = tableSize(table2)
    if size1 ~= size2 then return true end
    if size1 == 0 then return false end
    for k1,v1 in pairs(table1) do
        if table2[k1] ~= v1 then
            return true
        end
    end
    return false
end

-- Return true if item2's type is in item1's getClothingExtraItem() list.
function craftHelper41RecipePanel:isExtraClothingItemOf(item1, item2)
    local scriptItem = getScriptManager():FindItem(item1.fullType)
    if not scriptItem then
        return false
    end
    local extras = scriptItem:getClothingItemExtra()
    if not extras then
        return false
    end
    local moduleName = scriptItem:getModule():getName()
    for i=1,extras:size() do
        local extra = extras:get(i-1)
        local fullType = moduleDotType(moduleName, extra)
        if item2.fullType == fullType then
            return true
        end
    end
    return false
end

function craftHelper41RecipePanel:removeExtraClothingItemsFromList(index, item, itemList)
    for k=#itemList,index,-1 do
        local item2 = itemList[k]
        if self:isExtraClothingItemOf(item, item2) then
            table.remove(itemList, k)
        end
    end
end

---
--
--
function craftHelper41RecipePanel:createChildren()
    ISPanel.createChildren(self);

    self.ingredientPanel = ISScrollingListBox:new(1, 30, self.width, self.height - 59);
    self.ingredientPanel:initialise()
    self.ingredientPanel:instantiate()
    self.ingredientPanel.itemheight = math.max(craftHelper41RecipePanel.smallFontHeight, 22)
    self.ingredientPanel.font = UIFont.NewSmall
    self.ingredientPanel.doDrawItem = self.drawIngredient
    self.ingredientPanel.drawBorder = true
    self.ingredientPanel:setVisible(false)
    self:addChild(self.ingredientPanel)
end


---
--
--
function craftHelper41RecipePanel:getContainers()
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
function craftHelper41RecipePanel:isWaterSource(item, count)
    -- Fk'n rounding differences between Java and Lua broke simple getUsedDelta()/getUseDelta() here, so I added getDrainableUsesInt()
    return instanceof(item, "DrainableComboItem") and item:isWaterSource() and item:getDrainableUsesInt() >= count
end


---
--
--
function craftHelper41RecipePanel:setRecipe(recipe)
    self:getContainers();
    local newItem = {};

    if recipe:getCategory() then
        newItem.category = recipe:getCategory();
    else
        newItem.category = getText("IGUI_CraftCategory_General");
    end

    newItem.recipe = recipe;
    newItem.available = RecipeManager.IsRecipeValid(recipe, self.player, nil, self.containerList);

    local resultItem = InventoryItemFactory.CreateItem(recipe:getResult():getFullType());
    if resultItem then
        newItem.texture = resultItem:getTex();
        newItem.itemName = resultItem:getDisplayName();
        if recipe:getResult():getCount() > 1 then
            newItem.itemName = (recipe:getResult():getCount() * resultItem:getCount()) .. " " .. newItem.itemName;
        end
    end
    newItem.sources = {};
    for x=0,recipe:getSource():size()-1 do
        local source = recipe:getSource():get(x);
        local sourceInList = {};
        sourceInList.items = {}
        for k=1,source:getItems():size() do
            local sourceFullType = source:getItems():get(k-1)
            local item = nil
            local itemName = nil
            if sourceFullType == "Water" then
                item = InventoryItemFactory.CreateItem("Base.WaterDrop");
            elseif luautils.stringStarts(sourceFullType, "[") then
                -- a Lua test function
                item = InventoryItemFactory.CreateItem("Base.WristWatch_Right_DigitalBlack");
            else
                item = InventoryItemFactory.CreateItem(sourceFullType);
            end
            if item then
                local itemInList = {};
                itemInList.count = source:getCount();
                itemInList.texture = item:getTex();
                if sourceFullType == "Water" then
                    if itemInList.count == 1 then
                        itemInList.name = getText("IGUI_CraftUI_CountOneUnit", getText("ContextMenu_WaterName"))
                    else
                        itemInList.name = getText("IGUI_CraftUI_CountUnits", getText("ContextMenu_WaterName"), itemInList.count)
                    end
                elseif source:getItems():size() > 1 then -- no units
                    itemInList.name = item:getDisplayName()
                elseif not source:isDestroy() and item:IsDrainable() then
                    if itemInList.count == 1 then
                        itemInList.name = getText("IGUI_CraftUI_CountOneUnit", item:getDisplayName())
                    else
                        itemInList.name = getText("IGUI_CraftUI_CountUnits", item:getDisplayName(), itemInList.count)
                    end
                elseif not source:isDestroy() and source:getUse() > 0 then -- food
                    itemInList.count = source:getUse()
                    if itemInList.count == 1 then
                        itemInList.name = getText("IGUI_CraftUI_CountOneUnit", item:getDisplayName())
                    else
                        itemInList.name = getText("IGUI_CraftUI_CountUnits", item:getDisplayName(), itemInList.count)
                    end
                elseif itemInList.count > 1 then
                    itemInList.name = getText("IGUI_CraftUI_CountNumber", item:getDisplayName(), itemInList.count)
                else
                    itemInList.name = item:getDisplayName()
                end
                itemInList.fullType = item:getFullType()
                if sourceFullType == "Water" then
                    itemInList.fullType = "Water"
                end
                table.insert(sourceInList.items, itemInList);
            end
        end
        table.insert(newItem.sources, sourceInList)
    end

    self.recipe = recipe;
    self.newItem = newItem;
    self:refreshIngredientPanel();
end


---
--
--
function craftHelper41RecipePanel:refreshIngredientPanel()
    self.ingredientPanel:setVisible(false)

    local selectedItem = self.newItem;
    if not selectedItem then return end

    selectedItem.typesAvailable = self:getAvailableItemsType()

    self.ingredientPanel:setVisible(true)
    self.ingredientPanel:clear()

    -- Display single-item sources before multi-item sources
    local sortedSources = {}
    for _,source in ipairs(selectedItem.sources) do
        table.insert(sortedSources, source)
    end
    table.sort(sortedSources, function(a,b) return #a.items == 1 and #b.items > 1 end)

    for _,source in ipairs(sortedSources) do
        local available = {}
        local unavailable = {}

        for _,item in ipairs(source.items) do
            local data = {}
            data.selectedItem = selectedItem
            data.name = item.name
            data.texture = item.texture
            data.fullType = item.fullType
            data.count = item.count
            data.recipe = selectedItem.recipe
            data.multiple = #source.items > 1
            if selectedItem.typesAvailable and (not selectedItem.typesAvailable[item.fullType] or selectedItem.typesAvailable[item.fullType] < item.count) then
                table.insert(unavailable, data)
            else
                table.insert(available, data)
            end
        end
        table.sort(available, function(a,b) return not string.sort(a.name, b.name) end)
        table.sort(unavailable, function(a,b) return not string.sort(a.name, b.name) end)

        if #source.items > 1 then
            local data = {}
            data.selectedItem = selectedItem
            data.texture = self.TreeExpanded
            data.multipleHeader = true
            data.available = #available > 0
            self.ingredientPanel:addItem(getText("IGUI_CraftUI_OneOf"), data)
        end

        -- Hack for "Dismantle Digital Watch" and similar recipes.
        -- Recipe sources include both left-hand and right-hand versions of the same item.
        -- We only want to display one of them.
        ---[[
        for j=1,#available do
            local item = available[j]
            self:removeExtraClothingItemsFromList(j+1, item, available)
        end

        for j=1,#available do
            local item = available[j]
            self:removeExtraClothingItemsFromList(1, item, unavailable)
        end

        for j=1,#unavailable do
            local item = unavailable[j]
            self:removeExtraClothingItemsFromList(j+1, item, unavailable)
        end
        --]]

        for k,item in ipairs(available) do
            self.ingredientPanel:addItem(item.name, item)
        end
        for k,item in ipairs(unavailable) do
            self.ingredientPanel:addItem(item.name, item)
        end
    end

    self.refreshTypesAvailableMS = getTimestampMs()

    self.ingredientPanel.doDrawItem = craftHelper41RecipePanel.drawIngredient
end


---
--
--
function craftHelper41RecipePanel:getAvailableItemsType()
    local result = {};
    local recipe = self.recipe;
    local items = RecipeManager.getAvailableItemsAll(recipe, self.player, self.containerList, nil, nil);
    for i=0, recipe:getSource():size()-1 do
        local source = recipe:getSource():get(i);
        local sourceItemTypes = {};
        for k=1,source:getItems():size() do
            local sourceFullType = source:getItems():get(k-1);
            sourceItemTypes[sourceFullType] = true;
        end
        for x=0,items:size()-1 do
            local item = items:get(x)
            if sourceItemTypes["Water"] and self:isWaterSource(item, source:getCount()) then
                result["Water"] = (result["Water"] or 0) + item:getDrainableUsesInt()
            elseif sourceItemTypes[item:getFullType()] then
                local count = 1
                if not source:isDestroy() and item:IsDrainable() then
                    count = item:getDrainableUsesInt()
                end
                if not source:isDestroy() and instanceof(item, "Food") then
                    if source:getUse() > 0 then
                        count = -item:getHungerChange() * 100
                    end
                end
                result[item:getFullType()] = (result[item:getFullType()] or 0) + count;
            end
        end
    end
    return result;
end


---
--
--
function craftHelper41RecipePanel:render()
    ISPanel.render(self);

    if self.recipe == nil then
        return
    end;

    -- draw recipes infos
    local x = 10;
    local y = 10;
    local selectedItem = self.newItem;

    local now = getTimestampMs()
    if not self.refreshTypesAvailableMS or (self.refreshTypesAvailableMS + 500 < now) then
        self.refreshTypesAvailableMS = now
        local typesAvailable = self:getAvailableItemsType();
        self.needRefreshIngredientPanel = self.needRefreshIngredientPanel or areTablesDifferent(selectedItem.typesAvailable, typesAvailable);
        selectedItem.typesAvailable = typesAvailable;
    end
    self:getContainers();
    selectedItem.available = RecipeManager.IsRecipeValid(selectedItem.recipe, self.player, nil, self.containerList);

    -- render the right part, the craft information
    local catName = getTextOrNull("IGUI_CraftCategory_"..selectedItem.category) or selectedItem.category
    self:drawText(catName, x, y, 1,1,1,1, UIFont.Large);
    y = y + craftHelper41RecipePanel.largeFontHeight + 5;

    self:drawRectBorder(x, y, 32 + 10, 32 + 10, 1.0, 1.0, 1.0, 1.0);
    if selectedItem.texture then
        if selectedItem.texture:getWidth() <= 32 and selectedItem.texture:getHeight() <= 32 then
            local newX = (32 - selectedItem.texture:getWidthOrig()) / 2;
            local newY = (32 - selectedItem.texture:getHeightOrig()) / 2;
            self:drawTexture(selectedItem.texture,x+5 + newX,y+5 + newY,1,1,1,1);
        else
            self:drawTextureScaledAspect(selectedItem.texture,x+5,y+5,32,32,1,1,1,1);
        end
    end
    self:drawText(selectedItem.recipe:getName() , x + 32 + 15, y, 1,1,1,1, UIFont.Large);
    self:drawText(selectedItem.itemName, x + 32 + 15, y + craftHelper41RecipePanel.largeFontHeight, 1,1,1,1, UIFont.Small);
    y = y + math.max(45, craftHelper41RecipePanel.largeFontHeight + craftHelper41RecipePanel.smallFontHeight);

    self:drawText(getText("IGUI_CraftUI_RequiredItems"), x, y, 1,1,1,1, UIFont.Medium);

    y = y + craftHelper41RecipePanel.mediumFontHeight + 7;

    local manualsSize = 0;
    if not self.player:isRecipeKnown(selectedItem.recipe) and craftHelper41.itemsManuals[selectedItem.recipe:getOriginalname()] ~= nil then
        manualsSize = (#craftHelper41.itemsManuals[selectedItem.recipe:getOriginalname()] + 1) * craftHelper41RecipePanel.smallFontHeight + 4;
    end

    self.ingredientPanel:setX(x + 15)
    self.ingredientPanel:setY(y)
    self.ingredientPanel:setWidth(self.width - 30)
    self.ingredientPanel:setHeight(self.height - 75 - manualsSize - y)
    y = self.ingredientPanel:getBottom()

    y = y + 4;
    if selectedItem.recipe:getRequiredSkills() then
        self:drawText(getText("IGUI_CraftUI_RequiredSkills"), x, y, 1,1,1,1, UIFont.Medium);
        y = y + craftHelper41RecipePanel.mediumFontHeight;
        for i=0,selectedItem.recipe:getRequiredSkills():size()-1 do
            self:drawText(" - " .. selectedItem.recipe:getRequiredSkills():get(i), x + 15, y, 1,1,1,1, UIFont.Small);
            y = y + craftHelper41RecipePanel.smallFontHeight;
        end
        y = y + 4;
    end
    if not self.player:isRecipeKnown(selectedItem.recipe) and craftHelper41.itemsManuals[selectedItem.recipe:getOriginalname()] ~= nil then
        self:drawText("Required book:", x, y, 1,1,1,1, UIFont.Medium);
        y = y + craftHelper41RecipePanel.mediumFontHeight;
        for _,manual in ipairs(craftHelper41.itemsManuals[selectedItem.recipe:getOriginalname()]) do
            self:drawText(manual, x+15, y, 0.9,0,0,1, UIFont.Small);
            y = y + craftHelper41RecipePanel.smallFontHeight;
        end
        y = y + 4;
    end
    if selectedItem.recipe:getNearItem() then
        self:drawText(getText("IGUI_CraftUI_NearItem", selectedItem.recipe:getNearItem()), x, y, 1,1,1,1, UIFont.Medium);
        y = y + craftHelper41RecipePanel.mediumFontHeight;
    end
    self:drawText(getText("IGUI_CraftUI_RequiredTime", selectedItem.recipe:getTimeToMake()), x, y, 1,1,1,1, UIFont.Medium);
end


---
--
--
function craftHelper41RecipePanel:drawIngredient(y, item, alt)

    if y + self:getYScroll() >= self.height then return y + self.itemheight end
    if y + self.itemheight + self:getYScroll() <= 0 then return y + self.itemheight end

    --if not self.parent.recipeListHasFocus and self.selected == item.index then
    --    self:drawRectBorder(1, y, self:getWidth()-2, self.itemheight, 1.0, 0.5, 0.5, 0.5);
    --end

    if item.item.multipleHeader then
        local r,g,b = 1,1,1
        if not item.item.available then
            r,g,b = 0.54,0.54,0.54
        end
        self:drawText(item.text, 12, y + 2, r, g, b, 1, self.font)
        --self:drawTexture(item.item.texture, 4, y + (item.height - item.item.texture:getHeight()) / 2 - 2, 1,1,1,1)
    else
        local r,g,b
        local r2,g2,b2,a2
        local typesAvailable = item.item.selectedItem.typesAvailable
        if typesAvailable and (not typesAvailable[item.item.fullType] or typesAvailable[item.item.fullType] < item.item.count) then
            r,g,b = 0.54,0.54,0.54;
            r2,g2,b2,a2 = 1,1,1,0.3;
        else
            r,g,b = 1,1,1;
            r2,g2,b2,a2 = 1,1,1,0.9;
        end

        local imgW = 20
        local imgH = 20
        local dx = 6 + (item.item.multiple and 10 or 0)

        self:drawText(item.text, dx + imgW + 4, y + (item.height - ISCraftingUI.smallFontHeight) / 2, r, g, b, 1, self.font)

        if item.item.texture then
            local texWidth = item.item.texture:getWidth()
            local texHeight = item.item.texture:getHeight()
            self:drawTextureScaledAspect(item.item.texture, dx, y + (self.itemheight - imgH) / 2, 20, 20, a2,r2,g2,b2)
        end
    end

    return y + self.itemheight;
end


---
--
--
function craftHelper41RecipePanel:update()
    if self.needRefreshIngredientPanel then
        self.needRefreshIngredientPanel = false
        self:refreshIngredientPanel()
    end
end



---
--
--
function craftHelper41RecipePanel:new(x, y, width, height)
    local o = {};
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = {r=0, g=0, b=0, a=1};
    o:noBackground();
    o.anchorTop = true;
    o.anchorBottom = true;
    o.player = getPlayer();
    o.needRefreshIngredientPanel = true;
    o.recipe = nil;
    return o;
end



