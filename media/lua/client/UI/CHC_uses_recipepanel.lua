require 'luautils'
require 'ISUI/ISPanel'
require 'ISUI/ISScrollingListBox'
require 'ISUI/ISCraftingUI'
require 'CHC_main'


local utils = require('CHC_utils')

CHC_uses_recipepanel = ISPanel:derive("CHC_uses_recipepanel")

-- region create
local texMan = getTextManager()
local fhLarge = texMan:getFontHeight(UIFont.Large) -- largeFontHeight
local fhMedium = texMan:getFontHeight(UIFont.Medium) -- mediumFontHeight
local fhSmall = texMan:getFontHeight(UIFont.Small) -- smallFontHeight


function CHC_uses_recipepanel:createChildren()
    ISPanel.createChildren(self);

    self.mainInfoImg = ISButton:new(1, 1, 42, 42, "", self, nil)
    self.mainInfoImg.backgroundColorMouseOver.a = 0
    self.mainInfoImg.backgroundColor.a = 0
    self.mainInfoImg.onRightMouseDown = self.onRMBDownItemIcon
    self.mainInfoImg:initialise()
    self.mainInfoImg:setVisible(false)

    self:addChild(self.mainInfoImg)

    self.ingredientPanel = ISScrollingListBox:new(1, 30, self.width, self.height - 40);
    self.ingredientPanel:initialise()
    self.ingredientPanel:instantiate()
    self.ingredientPanel.onRightMouseDown = self.onRMBDownIngrPanel
    self.ingredientPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.ingredientPanel.itemheight = math.max(fhSmall, 22)
    self.ingredientPanel.font = UIFont.NewSmall
    self.ingredientPanel.doDrawItem = self.drawIngredient
    self.ingredientPanel.drawBorder = true
    self.ingredientPanel:setVisible(false)
    self:addChild(self.ingredientPanel)

    local btnInfo = {
        x = 0,
        y = self.height / 2,
        w = 50,
        h = 25,
        clicktgt = self
    }
    self.craftOneButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt, self.craft);
    self.craftOneButton:initialise()

    -- TODO: change to icon
    self.craftOneButton.title = getText("IGUI_CraftUI_ButtonCraftOne")
    self.craftOneButton:setWidth(5 + getTextManager():MeasureStringX(UIFont.Small, self.craftOneButton.title))
    self.craftOneButton:setVisible(false)

    self:addChild(self.craftOneButton);

    self.craftAllButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt, self.craftAll);
    self.craftAllButton:initialise()
    self.craftAllButton.title = getText("IGUI_CraftUI_ButtonCraftOne")
    self.craftAllButton:setWidth(5 + getTextManager():MeasureStringX(UIFont.Small, self.craftAllButton.title))
    self.craftAllButton:setVisible(false)

    self:addChild(self.craftAllButton);

    -- self.debugGiveIngredientsButton = ISButton:new(0, 0, 50, 25, "DBG: Give Ingredients", self, ISCraftingUI.debugGiveIngredients);
    -- self.debugGiveIngredientsButton:initialise();
    -- self:addChild(self.debugGiveIngredientsButton);
end

function CHC_uses_recipepanel:setItemNameInSource(item, itemInList, isDestroy, uses)
    local onlyOne = itemInList.count == 1
    if itemInList.fullType == "Base.WaterDrop" then
        local one = getText("IGUI_CraftUI_CountOneUnit", getText("ContextMenu_WaterName"))
        local mult = getText("IGUI_CraftUI_CountUnits", getText("ContextMenu_WaterName"), itemInList.count)
        return onlyOne and one or mult
    end
    if not isDestroy and (item.IsDrainable or uses > 0) then
        local one = getText("IGUI_CraftUI_CountOneUnit", item.displayName)
        local mult = getText("IGUI_CraftUI_CountUnits", item.displayName, itemInList.count)
        return onlyOne and one or mult
    end
    if itemInList.count > 1 then
        return getText("IGUI_CraftUI_CountNumber", item.displayName, itemInList.count)
    end
    return item.displayName
end

function CHC_uses_recipepanel:setObj(recipe)
    CHC_uses_recipelist.getContainers(self)
    local newItem = {};

    if recipe.recipe:getCategory() then
        newItem.category = recipe.recipe:getCategory();
    else
        newItem.category = getText("IGUI_CraftCategory_General");
    end

    newItem.recipe = recipe.recipe;
    newItem.available = RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.containerList);

    if recipe.recipeData.lua then
        -- efg:dfg() -- testing lua parsing
    end

    local resultItem = recipe.recipeData.result
    if resultItem then
        newItem.module = resultItem.modname
        newItem.isVanilla = resultItem.isVanilla
        -- newItem.modname = resultItem:getModID()
        newItem.texture = resultItem.texture
        self.mainInfoImg:setImage(resultItem.texture)
        self.mainInfoImg.item = resultItem
        if resultItem.tooltip then
            newItem.tooltip = getText(resultItem.tooltip)
        end
        newItem.itemName = resultItem.displayName
        local displayCategory = resultItem.displayCategory
        if displayCategory then
            newItem.itemDisplayCategory = getTextOrNull("IGUI_ItemCat_" .. displayCategory)
        end

        local resultCount = recipe.recipe:getResult():getCount()
        if resultCount > 1 then
            newItem.itemName = (resultCount * resultItem.count) .. " " .. newItem.itemName;
        end
    end

    newItem.hydrocraftEquipment = recipe.recipeData.hydroFurniture

    newItem.sources = {}
    local sources = recipe.recipe:getSource()
    for x = 0, sources:size() - 1 do
        local source = sources:get(x);
        local sourceInList = {}
        sourceInList.items = {}
        sourceInList.isKeep = source:isKeep()
        sourceInList.isDestroy = source:isDestroy()
        sourceInList.uses = source:getUse()
        local sourceItems = source:getItems()
        for k = 1, sourceItems:size() do

            local sourceFullType = sourceItems:get(k - 1)
            local item = nil
            if sourceFullType == "Water" then
                item = CHC_main.items["Base.WaterDrop"]
            elseif luautils.stringStarts(sourceFullType, "[") then
                -- a Lua test function
                item = CHC_main.items["Base.WristWatch_Right_DigitalBlack"]
            else
                item = CHC_main.items[sourceFullType]
            end
            if item then
                local itemInList = {}

                itemInList.count = sourceInList.uses > 0 and sourceInList.uses or source:getCount()
                itemInList.texture = item.texture
                itemInList.fullType = item.fullType
                if sourceFullType == "Water" then
                    itemInList.fullType = "Base.WaterDrop"
                end

                itemInList.name = self:setItemNameInSource(item, itemInList, sourceInList.isDestroy, sourceInList.uses)

                table.insert(sourceInList.items, itemInList);
            end
        end
        table.insert(newItem.sources, sourceInList)
    end


    -- extra stuff for render
    newItem.requiredSkillCount = recipe.recipe:getRequiredSkillCount()
    newItem.isKnown = self.player:isRecipeKnown(recipe.recipe)
    newItem.nearItem = recipe.recipeData.nearItem
    newItem.timeToMake = recipe.recipe:getTimeToMake()
    newItem.howManyCanCraft = RecipeManager.getNumberOfTimesRecipeCanBeDone(newItem.recipe, self.player, self.containerList, nil)

    self.recipe = recipe.recipe;
    self.newItem = newItem;

    self.manualsEntries = CHC_main.itemsManuals[newItem.recipe:getOriginalname()]
    if self.manualsEntries ~= nil then
        self.manualsSize = #self.manualsEntries
    end
    self:refreshIngredientPanel()
end

-- endregion

-- region update

function CHC_uses_recipepanel:refreshIngredientPanel()
    self.ingredientPanel:setVisible(false)

    local selectedItem = self.newItem;
    if not selectedItem then return end

    selectedItem.typesAvailable = self:getAvailableItemsType()

    self.ingredientPanel:setVisible(true)
    self.ingredientPanel:clear()

    -- Display single-item sources before multi-item sources
    local sortedSources = {}
    for _, source in ipairs(selectedItem.sources) do
        table.insert(sortedSources, source)
    end
    table.sort(sortedSources, function(a, b) return #a.items == 1 and #b.items > 1 end)

    for _, source in ipairs(sortedSources) do
        local available = {}
        local unavailable = {}

        for _, item in ipairs(source.items) do
            local data = {}
            data.isDestroy = source.isDestroy
            data.isKeep = source.isKeep
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
        table.sort(available, function(a, b) return not string.sort(a.name, b.name) end)
        table.sort(unavailable, function(a, b) return not string.sort(a.name, b.name) end)

        if #source.items > 1 then
            local data = {}
            data.isDestroy = source.isDestroy
            data.isKeep = source.isKeep
            data.selectedItem = selectedItem
            data.texture = self.TreeExpanded
            data.multipleHeader = true
            data.available = #available > 0
            local txt = getText("IGUI_CraftUI_OneOf")
            if data.isDestroy then
                txt = txt .. " (D) "
            end
            if data.isKeep then
                txt = txt .. " (K) "
            end
            self.ingredientPanel:addItem(txt, data)
        end

        -- Hack for "Dismantle Digital Watch" and similar recipes.
        -- Recipe sources include both left-hand and right-hand versions of the same item.
        -- We only want to display one of them.
        ---[[
        for j = 1, #available do
            local item = available[j]
            ISCraftingUI:removeExtraClothingItemsFromList(j + 1, item, available)
        end

        for j = 1, #available do
            local item = available[j]
            ISCraftingUI:removeExtraClothingItemsFromList(1, item, unavailable)
        end

        for j = 1, #unavailable do
            local item = unavailable[j]
            ISCraftingUI:removeExtraClothingItemsFromList(j + 1, item, unavailable)
        end
        --]]

        for k, item in ipairs(available) do
            self.ingredientPanel:addItem(item.name, item)
        end
        for k, item in ipairs(unavailable) do
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
    for i = 0, recipe:getSource():size() - 1 do
        local source = recipe:getSource():get(i);
        local sourceItemTypes = {};
        for k = 1, source:getItems():size() do
            local sourceFullType = source:getItems():get(k - 1);
            sourceItemTypes[sourceFullType] = true;
        end
        for x = 0, items:size() - 1 do
            local item = items:get(x)
            if sourceItemTypes["Water"] and ISCraftingUI:isWaterSource(item, source:getCount()) then
                result["Base.WaterDrop"] = (result["Base.WaterDrop"] or 0) + item:getDrainableUsesInt()
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

-- endregion

-- region render

function CHC_uses_recipepanel:drawIngredient(y, item, alt)

    if y + self:getYScroll() >= self.height then return y + self.itemheight end
    if y + self.itemheight + self:getYScroll() <= 0 then return y + self.itemheight end

    if item.item.multipleHeader then
        local r, g, b = 1, 1, 1
        if not item.item.available then
            r, g, b = 0.54, 0.54, 0.54
        end
        self:drawText(item.text, 12, y + 2, r, g, b, 1, self.font)
        --self:drawTexture(item.item.texture, 4, y + (item.height - item.item.texture:getHeight()) / 2 - 2, 1,1,1,1)
    else
        local r, g, b
        local r2, g2, b2, a2
        local typesAvailable = item.item.selectedItem.typesAvailable
        local itemNotAvailable = (not typesAvailable[item.item.fullType] or typesAvailable[item.item.fullType] < item.item.count)
        if typesAvailable and itemNotAvailable then
            r, g, b = 0.54, 0.54, 0.54;
            r2, g2, b2, a2 = 1, 1, 1, 1;
        else
            r, g, b = 1, 1, 1;
            r2, g2, b2, a2 = 1, 1, 1, 0.9;
        end

        local imgW = 20
        local imgH = 20
        local dx = 6 + 10 --(item.item.multiple and 10 or 0)
        local txt = ""
        if item.item.isKeep then
            txt = txt .. "K"
        end
        if item.item.isDestroy then
            txt = txt .. "D"
        end
        if txt and not item.item.multiple then
            self:drawText(txt, 5, y + (item.height - fhSmall) / 2, r, g, b, 1, self.font)
        end

        self:drawText(item.text, dx + imgW + 4, y + (item.height - fhSmall) / 2, r, g, b, 1, self.font)

        if item.item.texture then
            self:drawTextureScaledAspect(item.item.texture, dx, y + (self.itemheight - imgH) / 2, 20, 20, a2, r2, g2, b2)
        end

        --region favorite handler
        local favoriteStar = nil
        local favoriteAlpha = 0.9
        local favYPos = self.width - 30
        local parent = self.parent
        local isFav = CHC_main.playerModData[CHC_main.getFavItemModDataStr(item.item)] == true

        if item.index == self.mouseoverselected then
            if self:getMouseX() >= favYPos - 20 then
                favoriteStar = isFav and parent.itemFavCheckedTex or parent.itemFavNotCheckedTex
                favoriteAlpha = 0.9
            else
                favoriteStar = isFav and parent.itemFavoriteStar or parent.itemFavNotCheckedTex
                favoriteAlpha = isFav and 0.9 or 0.3
            end
        elseif isFav then
            favoriteStar = parent.itemFavoriteStar
        end
        if favoriteStar then
            self:drawTexture(favoriteStar, favYPos, y + (item.height / 2 - favoriteStar:getHeight() / 2), favoriteAlpha, 1, 1, 1);
        end
        --endregion

    end
    local ab, rb, gb, bb = 1, 0.1, 0.1, 0.1
    if item.item.multipleHeader then
        self:drawRect(1, y, self:getWidth() - 2, self.itemheight, 0.2, 0.2, gb, bb)
    end
    self:drawRectBorder(0, y, self:getWidth() - 2, self.itemheight, ab, rb, gb, bb)
    -- ISUIElement:drawRectBorder( x, y, w, h, a, r, g, b)

    return y + self.itemheight;
end

function CHC_uses_recipepanel:render()
    ISPanel.render(self);

    if self.recipe == nil then return end
    local x = 10;
    local y = 10;
    local selectedItem = self.newItem

    -- region check if available
    local now = getTimestampMs()

    if not self.refreshTypesAvailableMS then
        self.refreshTypesAvailableMS = now
    end

    if now > self.refreshTypesAvailableMS + 500 and self.needRefreshIngredientPanel == false then
        self.needRefreshIngredientPanel = true
    end

    if self.needRefreshIngredientPanel then
        local typesAvailable = self:getAvailableItemsType()
        self.needRefreshRecipeCounts = utils.areTablesDifferent(selectedItem.typesAvailable, typesAvailable)
        selectedItem.typesAvailable = typesAvailable
        CHC_uses_recipelist.getContainers(self)
        selectedItem.available = RecipeManager.IsRecipeValid(selectedItem.recipe, self.player, nil, self.containerList)
        selectedItem.howManyCanCraft = RecipeManager.getNumberOfTimesRecipeCanBeDone(selectedItem.recipe, self.player, self.containerList, nil)
        self.refreshTypesAvailableMS = now
        self.needRefreshIngredientPanel = false
    end

    if self.needRefreshRecipeCounts then
        self.parent.needUpdateCounts = true
        self.needRefreshRecipeCounts = false
    end

    -- endregion

    y = y + self:drawMainInfo(x, y, selectedItem) + 5

    -- region required items
    self:drawText(getText("IGUI_CraftUI_RequiredItems"), x, y, 1, 1, 1, 1, UIFont.Small);
    y = y + fhSmall + 5


    local bh = self:getBottomHeight(selectedItem) + 25
    self.ingredientPanel:setX(x + 5)
    self.ingredientPanel:setY(y)
    self.ingredientPanel:setWidth(self.width - 25)
    self.ingredientPanel:setHeight(self.height - y - bh)
    y = self.ingredientPanel:getBottom()
    y = y + 4
    -- endregion

    y = y + self:drawCraftButtons(x, y, selectedItem)
    y = y + self:drawRequiredSkills(x, y, selectedItem)
    y = y + self:drawRequiredBooks(x, y, selectedItem)
    y = y + self:drawNearItem(x, y, selectedItem)
    local reqTime = getText("IGUI_CraftUI_RequiredTime", selectedItem.timeToMake)
    self:drawText(reqTime, x, y, 1, 1, 1, 1, UIFont.Medium)
end

function CHC_uses_recipepanel:getBottomHeight(item)
    local bh = 0

    -- craft buttons
    if item.available then
        bh = bh + self.craftOneButton.height + 3
    end

    --skills
    if item.requiredSkillCount > 0 then
        bh = bh + fhMedium
        bh = bh + (item.requiredSkillCount) * fhSmall + 4
    end

    -- books
    if self.manualsEntries then
        bh = bh + (self.manualsSize + 1) * fhSmall + 4
        -- print(self.manualsSize)
    end

    -- near item
    local hydroFurniture = item.hydrocraftEquipment
    local nearItem = item.nearItem
    if hydroFurniture or nearItem then
        bh = bh + fhMedium
        if hydroFurniture then
            bh = bh + 25
        end
        if nearItem then
            bh = bh + fhSmall
        end
    end

    bh = bh + fhMedium
    return bh
end

function CHC_uses_recipepanel:drawMainInfo(x, y, item)
    local sy = y
    -- region main recipe info + output
    local catName = getTextOrNull("IGUI_CraftCategory_" .. item.category) or item.category
    self:drawText(getText("IGUI_invpanel_Category") .. ": " .. catName, x, y, 1, 1, 1, 1, UIFont.Medium);
    y = y + fhMedium + 3;

    -- self:drawRectBorder(x, y, 32 + 10, 32 + 10, 1.0, 1.0, 1.0, 1.0);
    if item.texture then
        self.mainInfoImg:setX(x)
        self.mainInfoImg:setY(y)
        self.mainInfoImg:setVisible(true)
        if item.tooltip then
            self.mainInfoImg:setTooltip(item.tooltip)
        else
            self.mainInfoImg:setTooltip(nil)
        end
    end
    local lx = x + 32 + 15
    local ly = y
    self:drawText(item.recipe:getName(), lx, ly, 1, 1, 1, 1, UIFont.Small)
    ly = ly + fhSmall
    self:drawText(item.itemName, lx, ly, 1, 1, 1, 1, UIFont.Small)
    ly = ly + fhSmall
    if item.itemDisplayCategory then
        self:drawText(getText("IGUI_invpanel_Category") .. ": " .. item.itemDisplayCategory, lx, ly, 0.8, 0.8, 0.8, 0.8, UIFont.Small)
        ly = ly + fhSmall
    end
    if item.isVanilla ~= nil or item.module ~= nil then
        if item.isVanilla == false then
            local clr = { r = 0.392, g = 0.584, b = 0.929 } -- CornFlowerBlue
            self:drawText("Mod: " .. item.module, lx, ly, clr.r, clr.g, clr.b, 1, UIFont.Small)
        end
    end
    y = y + ly - 20
    -- endregion
    return y - sy
end

function CHC_uses_recipepanel:drawCraftButtons(x, y, item)
    --if not self.newItem then return 0 end
    local sy = y
    if not item.available then
        self.craftOneButton:setVisible(false)
        self.craftAllButton:setVisible(false)
        return 0
    end

    if not self.craftOneButton:isVisible() then
        self.craftOneButton:setX(x)
        self.craftOneButton:setY(y)
        self.craftOneButton:setVisible(true)
    end

    --region all
    local title = getText("IGUI_CraftUI_ButtonCraftAll")
    local count = item.howManyCanCraft
    if count > 1 then
        title = getText("IGUI_CraftUI_ButtonCraftAllCount", count)
    elseif count == 1 then
        self.craftAllButton:setVisible(false)
    end
    if title ~= self.craftAllButton:getTitle() then
        self.craftAllButton:setTitle(title)
        self.craftAllButton:setWidthToTitle()
    end

    if not self.craftAllButton:isVisible() and count > 1 then
        self.craftAllButton:setX(self.craftOneButton:getX() + 5 + self.craftOneButton:getWidth())
        self.craftAllButton:setY(y)
        self.craftAllButton:setVisible(true)
    end
    --endregion

    y = y + self.craftOneButton.height + 3

    if self.player:isDriving() then
        self.craftOneButton.enable = false
        self.craftOneButton.tooltip = getText("Tooltip_CantCraftDriving")
        self.craftAllButton.enable = false
        self.craftAllButton.tooltip = getText("Tooltip_CantCraftDriving")
    else
        self.craftOneButton.tooltip = nil
        self.craftAllButton.tooltip = nil
        self.craftOneButton.enable = true
        self.craftAllButton.enable = true
    end
    return y - sy
end

function CHC_uses_recipepanel:drawRequiredSkills(x, y, item)
    local sy = y
    local requiredSkillCount = item.requiredSkillCount
    if requiredSkillCount <= 0 then return 0 end
    self:drawText(getText("IGUI_CraftUI_RequiredSkills"), x, y, 1, 1, 1, 1, UIFont.Medium)
    y = y + fhMedium
    for i = 1, requiredSkillCount do
        local skill = item.recipe:getRequiredSkill(i - 1);
        local perk = PerkFactory.getPerk(skill:getPerk());
        local playerLevel = self.player and self.player:getPerkLevel(skill:getPerk()) or 0
        local perkName = perk and perk:getName() or skill:getPerk():name()

        local text = " - " .. perkName .. ": " .. tostring(playerLevel) .. " / " .. tostring(skill:getLevel());
        local r, g, b = 1, 1, 1

        if playerLevel < skill:getLevel() then
            g, b = 0, 0
        end
        self:drawText(text, x + 15, y, r, g, b, 1, UIFont.Small)
        y = y + fhSmall
    end
    y = y + 4
    return y - sy
end

function CHC_uses_recipepanel:drawRequiredBooks(x, y, item)
    if not self.manualsEntries then return 0 end
    -- if self.manualsEntries and not isKnown then
    local sy = y
    self:drawText(getText("UI_recipe_panel_required_book") .. ":", x, y, 1, 1, 1, 1, UIFont.Medium)
    y = y + fhMedium
    local r, g, b = 1, 1, 1
    for i = 1, #self.manualsEntries do
        if not item.isKnown then
            g, b = 0, 0
        end
        self:drawText(" - " .. self.manualsEntries[i], x + 15, y, r, g, b, 1, UIFont.Small);
        y = y + fhSmall
    end
    y = y + 4
    return y - sy
end

function CHC_uses_recipepanel:drawNearItem(x, y, item)
    local hydroFurniture = item.hydrocraftEquipment
    local nearItem = item.nearItem
    if not nearItem and not hydroFurniture then return 0 end
    local sy = y

    self:drawText(getText("UI_recipe_panel_near_item") .. ": ", x, y, 1, 1, 1, 1, UIFont.Medium);
    y = y + fhMedium

    if hydroFurniture then
        local hydroX = x + 15
        local r, g, b = 1, 1, 1
        local a = 1
        if not hydroFurniture.luaTest(self.player) then
            g, b = 0, 0
            a = 0.75
        end
        self:drawText(" - ", hydroX, y, r, g, b, a, UIFont.Small)
        if hydroFurniture.obj.texture then
            hydroX = hydroX + 15
            self:drawTextureScaledAspect(hydroFurniture.obj.texture, hydroX, y, 20, 20, a, 1, 1, 1)
            hydroX = hydroX + 25
        end
        self:drawText(hydroFurniture.obj.name, hydroX, y, r, g, b, a, UIFont.Small)
        y = y + 25
    end

    if nearItem then
        self:drawText(" - " .. item.nearItem, x + 15, y, 1, 1, 1, 1, UIFont.Small);
        y = y + fhSmall
    end
    return y - sy
end

-- endregion

-- region logic

-- region event handlers


function CHC_uses_recipepanel:onRMBDownIngrPanel(x, y, item)
    if not item then
        local row = self:rowAt(x, y)
        if row == -1 or not row then return end
        item = self.items[row]
        if not item then return end
        item = item.item
    end
    if not item.fullType then return end
    local backref = self.parent.parent.backRef
    -- -- check if there is recipes for item
    local cX = getMouseX()
    local cY = getMouseY()
    local context = ISContextMenu.get(0, cX + 10, cY)

    item = CHC_main.items[item.fullType]
    if not item then return end
    local cond1 = type(CHC_main.recipesByItem[item.fullType]) == 'table'
    local cond2 = type(CHC_main.recipesForItem[item.fullType]) == 'table'

    local function findItem()
        local viewName = getText("UI_search_tab_name")
        backref:refresh(viewName) -- activate top level search view
        backref:refresh(backref.uiTypeToView['search_items'].name,
            backref.panel.activeView.view) -- activate Items subview
        local view = backref:getActiveSubView()
        local txt = string.format("#%s,%s", item.displayCategory, item.displayName)
        txt = string.lower(txt)
        view.searchRow.searchBar:setText(txt) -- set text to Items subview search bar
        view:updateItems(view.selectedCategory)
        -- trigger wont do here because we need to wait until objList actually updated and im too lazy to implement event listener
        -- view.needUpdateObjects = true
        if #view.objList.items ~= 0 then
            local it = view.objList.items
            local c = 1
            for i = 1, #it do
                if string.lower(it[i].text) == string.lower(item.displayName) then c = i break end
            end
            view.objList.selected = c
            view.objList:ensureVisible(c)
            if view.objPanel then
                view.objPanel:setObj(it[c].item)
                -- view.needSyncFilters = true
            end
        end
    end

    local function addToFav()
        -- @@@ TODO
    end

    context:addOption(getText("IGUI_find_item"), backref, findItem)

    local newTabOption = context:addOption(getText("IGUI_new_tab"), backref, backref.addItemView, item.item, true, 2)

    if not (cond1 or cond2) then
        local tooltip = ISToolTip:new()
        tooltip:initialise()
        tooltip:setVisible(false)
        tooltip.description = getText("IGUI_no_recipes")
        newTabOption.notAvailable = true
        newTabOption.toolTip = tooltip
        -- backref:addItemView(item, true)
    end

    -- context:addOption(getText("UI_servers_addToFavorite"), )
end

function CHC_uses_recipepanel:onRMBDownItemIcon(x, y)
    if not self.item then return end
    self.parent.onRMBDownIngrPanel(self, nil, nil, self.item)
end

function CHC_uses_recipepanel:onIngredientMouseDown(item)
    if not item then return end
    local x = self:getMouseX()

    if (x >= self.width - 40) then
        local isFav = self.modData[CHC_main.getFavItemModDataStr(item)] == true
        isFav = not isFav
        self.modData[CHC_main.getFavItemModDataStr(item)] = isFav or nil
        self.parent.backRef.updateQueue:push({
            targetView = 'fav_items',
            actions = { 'needUpdateFavorites', 'needUpdateObjects', 'needUpdateTypes', 'needUpdateCategories' }
        })
    end
end

-- endregion

-- region crafting
function CHC_uses_recipepanel:transferItems()
    local result = {}
    local selectedItem = self.newItem;
    local items = RecipeManager.getAvailableItemsNeeded(selectedItem.recipe, self.player, self.containerList, nil, nil);
    if items:isEmpty() then return result end
    ;for i = 1, items:size() do
        local item = items:get(i - 1)
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
        for i = 1, items:size() do
            local item = items:get(i - 1)
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
        for _, item in ipairs(itemsUsed) do
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

-- endregion

function CHC_uses_recipepanel:new(x, y, width, height)
    local o = {};
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    -- o:noBackground();
    o.anchorTop = true;
    o.anchorBottom = true;
    local player = getPlayer()
    o.player = player
    o.character = player
    o.playerNum = player and player:getPlayerNum() or -1
    o.needRefreshIngredientPanel = true
    o.needRefreshRecipeCounts = true
    o.recipe = nil;
    o.manualsSize = 0
    o.manualsEntries = nil
    o.modData = CHC_main.playerModData

    o.itemFavoriteStar = getTexture("media/textures/itemFavoriteStar.png")
    o.itemFavCheckedTex = getTexture("media/textures/itemFavoriteStarChecked.png")
    o.itemFavNotCheckedTex = getTexture("media/textures/itemFavoriteStarOutline.png")
    return o;
end
