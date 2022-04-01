require 'ISUI/ISPanel';
require 'ISUI/ISScrollingListBox';
require 'ISUI/ISCraftingUI'
require 'CHC_main';

CHC_uses_recipepanel = ISPanel:derive("CHC_uses_recipepanel");

CHC_uses_recipepanel.largeFontHeight = getTextManager():getFontFromEnum(UIFont.Large):getLineHeight()
CHC_uses_recipepanel.mediumFontHeight = getTextManager():getFontHeight(UIFont.Medium)
CHC_uses_recipepanel.smallFontHeight = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()

-- region utils (move to CHC_utils)
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
-- endregion

-- region create
function CHC_uses_recipepanel:createChildren()
    ISPanel.createChildren(self);

    self.ingredientPanel = ISScrollingListBox:new(1, 30, self.width, self.height - 40);
    self.ingredientPanel:initialise()
    self.ingredientPanel:instantiate()
    self.ingredientPanel.itemheight = math.max(CHC_uses_recipepanel.smallFontHeight, 22)
    self.ingredientPanel.font = UIFont.NewSmall
    self.ingredientPanel.doDrawItem = self.drawIngredient
    self.ingredientPanel.drawBorder = true
    self.ingredientPanel:setVisible(false)
    self:addChild(self.ingredientPanel)

    local btnInfo = {
        x=0,
        y=self.height/2,
        w=50,
        h=25,
        clicktgt=self
    }
    self.craftOneButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w,btnInfo.h, nil, btnInfo.clicktgt, self.craft);
    self.craftOneButton:initialise()

    -- TODO: change to icon
    self.craftOneButton.title = getText("IGUI_CraftUI_ButtonCraftOne")
    self.craftOneButton:setWidth(5+getTextManager():MeasureStringX(UIFont.Small, self.craftOneButton.title))
    self.craftOneButton:setVisible(false)

    self:addChild(self.craftOneButton);

    self.craftAllButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w,btnInfo.h, nil, btnInfo.clicktgt, self.craftAll);
    self.craftAllButton:initialise()
    self.craftAllButton.title = getText("IGUI_CraftUI_ButtonCraftOne")
    self.craftAllButton:setWidth(5+getTextManager():MeasureStringX(UIFont.Small, self.craftAllButton.title))
    self.craftAllButton:setVisible(false)

    self:addChild(self.craftAllButton);

    -- self.debugGiveIngredientsButton = ISButton:new(0, 0, 50, 25, "DBG: Give Ingredients", self, ISCraftingUI.debugGiveIngredients);
    -- self.debugGiveIngredientsButton:initialise();
    -- self:addChild(self.debugGiveIngredientsButton);
end


-- endregion

-- region update


function CHC_uses_recipepanel:updateTooltip()
    local x = self:getMouseX();
    local y = self:getMouseY();
    local item = nil;
    if (x >= self.hisOfferDatas:getX() and
        x <= self.hisOfferDatas:getX() + self.hisOfferDatas:getWidth() and
        y >= self.hisOfferDatas:getY() and
        y <= self.hisOfferDatas:getY() + self.hisOfferDatas:getHeight()
    ) then
        y = self.hisOfferDatas:rowAt(self.hisOfferDatas:getMouseX(),
                                     self.hisOfferDatas:getMouseY())
        if self.hisOfferDatas.items[y] then
            item = self.hisOfferDatas.items[y];
        end
    end
    if (x >= self.yourOfferDatas:getX() and
        x <= self.yourOfferDatas:getX() + self.yourOfferDatas:getWidth() and
        y >= self.yourOfferDatas:getY() and
        y <= self.yourOfferDatas:getY() + self.yourOfferDatas:getHeight()
    ) then
        y = self.yourOfferDatas:rowAt(self.yourOfferDatas:getMouseX(),
                                      self.yourOfferDatas:getMouseY())
        if self.yourOfferDatas.items[y] then
            item = self.yourOfferDatas.items[y];
        end
    end
    if item then
        if self.toolRender then
            self.toolRender:setItem(item.item);
            if not self:getIsVisible() then
                self.toolRender:setVisible(false);
            else
                self.toolRender:setVisible(true);
                self.toolRender:addToUIManager();
                self.toolRender:bringToTop();
            end
        else
            self.toolRender = ISToolTipInv:new(item.item);
            self.toolRender:initialise();
            self.toolRender:addToUIManager();
            if not self:getIsVisible() then
                self.toolRender:setVisible(true);
            end
            self.toolRender:setOwner(self);
            self.toolRender:setCharacter(self.player);
            self.toolRender:setX(self:getMouseX());
            self.toolRender:setY(self:getMouseY());
            self.toolRender.followMouse = true;
        end
    else
        if self.toolRender then
            self.toolRender:setVisible(false)
        end
    end
end
-- endregion


-- region render
function CHC_uses_recipepanel:render()
    ISPanel.render(self);

    if self.recipe == nil then return end;
    -- self:updateTooltip()
    -- draw recipes infos
    local x = 10;
    local y = 10;
    local selectedItem = self.newItem;

    -- region check if available
    local now = getTimestampMs()
    if not self.refreshTypesAvailableMS or (self.refreshTypesAvailableMS + 500 < now) then
        self.refreshTypesAvailableMS = now
        local typesAvailable = self:getAvailableItemsType();
        self.needRefreshIngredientPanel = self.needRefreshIngredientPanel or areTablesDifferent(selectedItem.typesAvailable, typesAvailable);
        selectedItem.typesAvailable = typesAvailable;
    end
    ISCraftingUI.getContainers(self);
    selectedItem.available = RecipeManager.IsRecipeValid(selectedItem.recipe, self.player, nil, self.containerList);
    -- endregion

    -- region main recipe info + output
    local catName = getTextOrNull("IGUI_CraftCategory_"..selectedItem.category) or selectedItem.category
    self:drawText(getText("UI_category")..": "..catName, x, y, 1,1,1,1, UIFont.Medium);
    y = y + CHC_uses_recipepanel.mediumFontHeight + 3;

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
    self:drawText(selectedItem.recipe:getName() , x + 32 + 15, y, 1,1,1,1, UIFont.Medium);
    self:drawText(selectedItem.itemName, x + 32 + 15, y + CHC_uses_recipepanel.mediumFontHeight, 1,1,1,1, UIFont.Small);
    self:drawText(selectedItem.module, x+32+15, y+CHC_uses_recipepanel.mediumFontHeight+CHC_uses_recipepanel.smallFontHeight, 0.3, 0.3, 0.7, 1, UIFont.Small)
    y = y + math.max(45, CHC_uses_recipepanel.largeFontHeight + CHC_uses_recipepanel.mediumFontHeight+10);
    -- endregion

    -- region required items
    self:drawText(getText("IGUI_CraftUI_RequiredItems"), x, y, 1,1,1,1, UIFont.Small);
    y = y + CHC_uses_recipepanel.smallFontHeight + 5;

    local manualsSize = (self.manualsSize + 1) * CHC_uses_recipepanel.smallFontHeight + 4
    self.ingredientPanel:setX(x + 10)
    self.ingredientPanel:setY(y)
    self.ingredientPanel:setWidth(self.width - 30)
    self.ingredientPanel:setHeight(self.height - 150 - manualsSize - y)
    y = self.ingredientPanel:getBottom()
    y = y + 4;
    -- endregion
    
    -- region craft button(s)
    if selectedItem.available then
        self.craftOneButton:setX(x)
        self.craftOneButton:setY(y)
        self.craftOneButton:setVisible(true)
        self.craftAllButton:setX(self.craftOneButton:getX()+5+self.craftOneButton:getWidth())
        self.craftAllButton:setY(y)
        self.craftAllButton:setVisible(true)
        local title = getText("IGUI_CraftUI_ButtonCraftAll")
        local count = RecipeManager.getNumberOfTimesRecipeCanBeDone(selectedItem.recipe, self.player, self.containerList, nil)
        if count > 1 then
            title = getText("IGUI_CraftUI_ButtonCraftAllCount", count)
        elseif count == 1 then
            self.craftAllButton:setVisible(false)
        end
        if title ~= self.craftAllButton:getTitle() then
            self.craftAllButton:setTitle(title)
            self.craftAllButton:setWidthToTitle()
        end
        y = y + self.craftOneButton.height + 3
    else
        self.craftOneButton:setVisible(false)
        self.craftAllButton:setVisible(false)
    end


    self.craftOneButton.tooltip = nil
    self.craftAllButton.tooltip = nil
    if self.player:isDriving() then
        self.craftOneButton.enable=false
        self.craftOneButton.tooltip = getText("Tooltip_CantCraftDriving")
        self.craftAllButton.enable=false
        self.craftAllButton.tooltip = getText("Tooltip_CantCraftDriving")
    end
    -- endregion

    -- region required skills
    local requiredSkillCount = selectedItem.recipe:getRequiredSkillCount()
    if requiredSkillCount > 0 and self:shouldDrawSkillText(requiredSkillCount, selectedItem) then
        self:drawText(getText("IGUI_CraftUI_RequiredSkills"), x, y, 1,1,1,1, UIFont.Medium);
        y = y + CHC_uses_recipepanel.mediumFontHeight;
        for i=1,requiredSkillCount do
            local skill = selectedItem.recipe:getRequiredSkill(i-1);
            local perk = PerkFactory.getPerk(skill:getPerk());
            local playerLevel = self.player and self.player:getPerkLevel(skill:getPerk()) or 0
            local perkName = perk and perk:getName() or skill:getPerk():name()
            
            local text = " - " .. perkName .. ": " .. tostring(playerLevel) .. " / " .. tostring(skill:getLevel());
            local r,g,b = 1,1,1

            if self.player and (playerLevel < skill:getLevel()) then
                g = 0;
                b = 0;
                self:drawText(text, x + 15, y, r,g,b,1, UIFont.Small);
                y = y + CHC_uses_recipepanel.smallFontHeight;
            end
            
        end
        y = y + 4;
    end
    -- endregion

    -- region required books
    local isKnown = self.player:isRecipeKnown(selectedItem.recipe)
    if self.manualsEntries and not isKnown then
        self:drawText(getText("UI_recipe_panel_required_book")..":", x, y, 1,1,1,1, UIFont.Medium);
        y = y + CHC_uses_recipepanel.mediumFontHeight;
        local r,g,b = 1,1,1
        for _,manual in ipairs(self.manualsEntries) do
            if not isKnown then
                g,b = 0,0
                self:drawText(" - " .. manual, x+15, y, r,g,b,1, UIFont.Small);
                y = y + CHC_uses_recipepanel.smallFontHeight;
            end
            
        end
        y = y + 4;
    end
    -- endregion
    
    -- region nearItem
    if selectedItem.recipe:getNearItem() then
        self:drawText(getText("UI_tab_uses_details_near_item")..": ", x, y, 1,1,1,1, UIFont.Medium);
        y = y + CHC_uses_recipepanel.mediumFontHeight;
        self:drawText(" - "..selectedItem.recipe:getNearItem(), x+15, y, 1,1,1,1, UIFont.Small);
        y = y + CHC_uses_recipepanel.smallFontHeight;
    end
    -- endregion

    self:drawText(getText("IGUI_CraftUI_RequiredTime", selectedItem.recipe:getTimeToMake()), x, y, 1,1,1,1, UIFont.Medium);
end

-- endregion


-- region logic
function CHC_uses_recipepanel:transferItems()
    local result = {}
    local selectedItem = self.newItem;
    local items = RecipeManager.getAvailableItemsNeeded(selectedItem.recipe, self.player, self.containerList, nil, nil);
    if items:isEmpty() then return result end;
    for i=1,items:size() do
        local item = items:get(i-1)
        table.insert(result, item)
        if not selectedItem.recipe:isCanBeDoneFromFloor() then
            if item:getContainer() ~= self.player:getInventory() then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.player, item, item:getContainer(), self.player:getInventory(), nil));
            end
        end
    end
    return result
end


function CHC_uses_recipepanel:onCraftComplete(completedAction, recipe, container, containers)
    if not RecipeManager.IsRecipeValid(recipe, self.player, nil, containers) then return end
    local items = RecipeManager.getAvailableItemsNeeded(recipe, self.player, containers, nil, nil)
    if items:isEmpty() then return end
    local previousAction = completedAction
    local returnToContainer = {};
    if not recipe:isCanBeDoneFromFloor() then
        for i=1,items:size() do
            local item = items:get(i-1)
            if item:getContainer() ~= self.player:getInventory() then
                local action = ISInventoryTransferAction:new(self.player, item, item:getContainer(), self.player:getInventory(), nil)
                ISTimedActionQueue.addAfter(previousAction, action)
                previousAction = action
                table.insert(returnToContainer, item)
            end
        end
    end
    local action = ISCraftAction:new(self.player, items:get(0), recipe:getTimeToMake(), recipe, container, containers)
    action:setOnComplete(ISCraftingUI.onCraftComplete, self, action, recipe, container, containers)
    ISTimedActionQueue.addAfter(previousAction, action)
    ISCraftingUI.ReturnItemsToOriginalContainer(self.player, returnToContainer)
end


function CHC_uses_recipepanel:craft(button, all)
    self.craftInProgress = false
    local selectedItem = self.newItem;
    -- if selectedItem.evolved then return end -- add in #2
    if not RecipeManager.IsRecipeValid(selectedItem.recipe, self.player, nil, self.containerList) then return end
    if not getPlayer() then return end
    local itemsUsed = self:transferItems()
    if #itemsUsed == 0 then
        -- self:refresh()
        return
    end

    local returnToContainer = {}
    local container = itemsUsed[1]:getContainer()
    if not selectedItem.recipe:isCanBeDoneFromFloor() then
        container = self.player:getInventory()
        for _,item in ipairs(itemsUsed) do
            if item:getContainer() ~= self.player:getInventory() then
                table.insert(returnToContainer, item)
            end
        end
    end

    local action = ISCraftAction:new(self.player, itemsUsed[1],
                                     selectedItem.recipe:getTimeToMake(),
                                     selectedItem.recipe, container, self.containerList)
    if all then
        action:setOnComplete(self.onCraftComplete, self, action, selectedItem.recipe, container, self.containerList)
    end
    ISTimedActionQueue.add(action)
    self.craftInProgress = true

    ISCraftingUI.ReturnItemsToOriginalContainer(self.player, returnToContainer)
end

function CHC_uses_recipepanel:craftAll()
    self:craft(nil, true);
end
-- endregion

function CHC_uses_recipepanel:setRecipe(recipe)
    ISCraftingUI.getContainers(self);
    local newItem = {};

    if recipe.recipe:getCategory() then
        newItem.category = recipe.recipe:getCategory();
    else
        newItem.category = getText("IGUI_CraftCategory_General");
    end

    newItem.recipe = recipe.recipe;
    newItem.available = RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.containerList);

    local recipeResult = recipe.recipe:getResult()
    local resultItem = InventoryItemFactory.CreateItem(recipeResult:getFullType());
    if resultItem then
        newItem.module = resultItem:getModName()
        newItem.texture = resultItem:getTex();
        newItem.itemName = resultItem:getDisplayName();
        if recipe.recipe:getResult():getCount() > 1 then
            newItem.itemName = (recipe.recipe:getResult():getCount() * resultItem:getCount()) .. " " .. newItem.itemName;
        end
    end
    newItem.sources = {};
    for x=0,recipe.recipe:getSource():size()-1 do
        local source = recipe.recipe:getSource():get(x);
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

    self.recipe = recipe.recipe;
    self.newItem = newItem;

    self.manualsEntries = CHC_main.itemsManuals[newItem.recipe:getOriginalname()]
    if not self.player:isRecipeKnown(newItem.recipe) and self.manualsEntries ~= nil then
       self.manualsSize = #self.manualsEntries
    end
    self:refreshIngredientPanel();
end


function CHC_uses_recipepanel:refreshIngredientPanel()
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
            ISCraftingUI:removeExtraClothingItemsFromList(j+1, item, available)
        end

        for j=1,#available do
            local item = available[j]
            ISCraftingUI:removeExtraClothingItemsFromList(1, item, unavailable)
        end

        for j=1,#unavailable do
            local item = unavailable[j]
            ISCraftingUI:removeExtraClothingItemsFromList(j+1, item, unavailable)
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

    self.ingredientPanel.doDrawItem = CHC_uses_recipepanel.drawIngredient
end


function CHC_uses_recipepanel:getAvailableItemsType()
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
            if sourceItemTypes["Water"] and ISCraftingUI:isWaterSource(item, source:getCount()) then
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


function CHC_uses_recipepanel:shouldDrawSkillText(requiredSkillCount, selectedItem)
    for i=1, requiredSkillCount do
        local skill = selectedItem.recipe:getRequiredSkill(i-1);
        local playerLevel = self.player and self.player:getPerkLevel(skill:getPerk()) or 0
        if (playerLevel < skill:getLevel()) then
            return true
        end
    end
    return false
end


function CHC_uses_recipepanel:drawIngredient(y, item, alt)

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



function CHC_uses_recipepanel:new(x, y, width, height)
    local o = {};
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = {r=0, g=0, b=0, a=1};
    o:noBackground();
    o.anchorTop = true;
    o.anchorBottom = true;
    local player = getPlayer()
    o.player = player
    o.character = player
    o.playerNum = player and player:getPlayerNum() or -1
    o.needRefreshIngredientPanel = true;
    o.recipe = nil;
    o.manualsSize = 0
    o.manualsEntries = nil
    return o;
end



