require 'luautils'
require 'ISUI/ISPanel'
require 'ISUI/ISScrollingListBox'
require 'ISUI/ISCraftingUI'
require 'CHC_main'


local utils = require('CHC_utils')
local insert = table.insert

CHC_uses_recipepanel = ISPanel:derive('CHC_uses_recipepanel')

-- region create
local texMan = getTextManager()
local fhMedium = texMan:getFontHeight(UIFont.Medium) -- mediumFontHeight
local fhSmall = texMan:getFontHeight(UIFont.Small)   -- smallFontHeight

function CHC_uses_recipepanel:initialise()
    ISPanel.initialise(self)
    self.fastListReturn = CHC_main.common.fastListReturn
end

function CHC_uses_recipepanel:createChildren()
    ISPanel.createChildren(self);

    local listBorderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.4 }

    local x, y = 5, 5
    local fntm = getTextManager():getFontHeight(UIFont.Medium)
    local fntl = getTextManager():getFontHeight(UIFont.Large)

    -- region general info
    self.mainInfo = ISPanel:new(self.margin, y, self.width - 2 * self.margin, 1)
    self.mainInfo.borderColor = { r = 1, g = 0.53, b = 0.53, a = 0.2 }
    self.mainInfo:initialise()
    self.mainInfo:setVisible(false)

    self.mainImg = ISButton:new(self.margin, 5, 64, 64, '', self, nil)
    self.mainImg:initialise()
    self.mainImg.backgroundColorMouseOver.a = 0
    self.mainImg.backgroundColor.a = 0
    self.mainImg.origWI = 60
    self.mainImg.origHI = 60
    self.mainImg.forcedWidthImage = self.mainImg.origWI
    self.mainImg.forcedHeightImage = self.mainImg.origHI
    self.mainImg.onRightMouseDown = self.onRMBDownItemIcon

    local mainPadY = 2
    local mainX = self.margin + 64 + 3
    local mainY = mainPadY
    local mainPriFont = UIFont.Medium
    local mainSecFont = UIFont.Small

    local mr, mg, mb, ma = 1, 1, 1, 1
    self.mainCat = ISLabel:new(mainX, mainPadY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainCat:initialise()
    mainY = mainY + mainPadY + self.mainCat.height

    self.mainName = ISLabel:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainName:initialise()
    mainY = mainY + mainPadY + self.mainName.height

    self.mainRes = ISLabel:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainRes:initialise()
    mainY = mainY + mainPadY + self.mainRes.height

    self.mainMod = ISLabel:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainMod:initialise()
    mainY = mainY + mainPadY + self.mainMod.height

    self.mainInfo:setHeight(mainY + mainPadY)

    self.mainInfo:addChild(self.mainImg)
    self.mainInfo:addChild(self.mainCat)
    self.mainInfo:addChild(self.mainName)
    self.mainInfo:addChild(self.mainRes)
    self.mainInfo:addChild(self.mainMod)

    y = y + self.mainInfo:getBottom()
    -- endregion

    -- region ingredients
    self.ingredientPanel = ISScrollingListBox:new(1, 30, self.width, 50)
    self.ingredientPanel:initialise()
    self.ingredientPanel:instantiate()
    self.ingredientPanel.onRightMouseDown = self.onRMBDownIngrPanel
    self.ingredientPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.ingredientPanel.itemheight = fhSmall + 2 * self.itemMargin
    self.ingredientPanel.font = UIFont.NewSmall
    self.ingredientPanel.doDrawItem = self.drawIngredient
    self.ingredientPanel.yScroll = 0
    self.ingredientPanel.drawBorder = true
    self.ingredientPanel.borderColor = listBorderColor
    self.ingredientPanel.vscroll.borderColor = listBorderColor
    self.ingredientPanel:setVisible(false)
    -- endregion

    -- region buttons
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
    self.craftOneButton.title = getText('IGUI_CraftUI_ButtonCraftOne')
    self.craftOneButton:setWidth(5 + getTextManager():MeasureStringX(UIFont.Small, self.craftOneButton.title))
    self.craftOneButton:setVisible(false)

    self.craftAllButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt, self.craftAll);
    self.craftAllButton:initialise()
    self.craftAllButton.title = getText('IGUI_CraftUI_ButtonCraftOne')
    self.craftAllButton:setWidth(5 + getTextManager():MeasureStringX(UIFont.Small, self.craftAllButton.title))
    self.craftAllButton:setVisible(false)

    -- self.debugGiveIngredientsButton = ISButton:new(0, 0, 50, 25, 'DBG: Give Ingredients', self, ISCraftingUI.debugGiveIngredients);
    -- self.debugGiveIngredientsButton:initialise();
    -- self:addChild(self.debugGiveIngredientsButton);

    -- endregion

    -- region skills
    self.skillPanel = ISScrollingListBox:new(1, 1, self.width, 30)
    self.skillPanel:initialise()
    self.skillPanel:instantiate()
    -- self.skillPanel.onRightMouseDown = self.onRMBDownIngrPanel
    -- self.skillPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.skillPanel.itemheight = fhSmall + 2 * self.itemMargin
    self.skillPanel.doDrawItem = self.drawSkill
    self.skillPanel.yScroll = 0
    self.skillPanel.drawBorder = true
    self.skillPanel.borderColor = listBorderColor
    self.skillPanel.vscroll.borderColor = listBorderColor
    self.skillPanel:setVisible(false)
    -- endregion

    -- region books
    self.booksPanel = ISScrollingListBox:new(1, 1, self.width, 30)
    self.booksPanel:initialise()
    self.booksPanel:instantiate()
    self.booksPanel.onRightMouseDown = self.onRMBDownIngrPanel
    self.booksPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.booksPanel.itemheight = fhSmall + 2 * self.itemMargin
    self.booksPanel.doDrawItem = self.drawBook
    self.booksPanel.yScroll = 0
    self.booksPanel.drawBorder = true
    self.booksPanel.borderColor = listBorderColor
    self.booksPanel.vscroll.borderColor = listBorderColor
    self.booksPanel:setVisible(false)
    -- endregion

    -- region equipment
    self.equipmentPanel = ISScrollingListBox:new(1, 1, self.width, 30)
    self.equipmentPanel:initialise()
    self.equipmentPanel:instantiate()
    self.equipmentPanel.onRightMouseDown = self.onRMBDownIngrPanel
    self.equipmentPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.equipmentPanel.itemheight = fhSmall + 2 * self.itemMargin
    self.equipmentPanel.doDrawItem = self.drawBook
    self.equipmentPanel.yScroll = 0
    self.equipmentPanel.drawBorder = true
    self.equipmentPanel.borderColor = listBorderColor
    self.equipmentPanel.vscroll.borderColor = listBorderColor
    self.equipmentPanel:setVisible(false)
    -- endregion

    self:addChild(self.mainInfo)
    self:addChild(self.ingredientPanel)
    self:addChild(self.craftOneButton)
    self:addChild(self.craftAllButton)
    self:addChild(self.skillPanel)
    self:addChild(self.booksPanel)
    self:addChild(self.equipmentPanel)
end

function CHC_uses_recipepanel:setItemNameInSource(item, itemInList, isDestroy, uses)
    local onlyOne = itemInList.count == 1
    if itemInList.displayCount then
        if onlyOne or itemInList.displayCount == 1 then
            return item.displayName
        end
        return getText('IGUI_CraftUI_CountNumber', item.displayName, itemInList.displayCount)
    end
    if itemInList.fullType == 'Base.WaterDrop' then
        local one = getText('IGUI_CraftUI_CountOneUnit', getText('ContextMenu_WaterName'))
        local mult = getText('IGUI_CraftUI_CountUnits', getText('ContextMenu_WaterName'), itemInList.count)
        return onlyOne and one or mult
    end
    if not isDestroy and (item.IsDrainable or uses > 0) then
        local one = getText('IGUI_CraftUI_CountOneUnit', item.displayName)
        local mult = getText('IGUI_CraftUI_CountUnits', item.displayName, itemInList.count)
        return onlyOne and one or mult
    end
    if itemInList.count > 1 then
        return getText('IGUI_CraftUI_CountNumber', item.displayName, itemInList.count)
    end
    return item.displayName
end

function CHC_uses_recipepanel:getSources(recipe)
    local function getCount(item, sourceObj)
        local param
        local result
        local displayCount
        if item.propsMap then
            if instanceof(item.item, "Food") then
                param = item.propsMap["HungChange"].value
            elseif instanceof(item.item, "Drainable") then
                param = item.propsMap["UseDeltaTotal*"].value
            else
                param = item.propsMap["Count"].value
            end
        else
            return 1, 1
        end
        result = math.abs(sourceObj.use / param)
        if math.floor(result) == 1 then
            displayCount = 1
        else
            local rev = math.floor(1 / result)
            if rev > 1 then
                displayCount = '(1/' .. rev .. ')'
            elseif rev < 1 then
                displayCount = round(result, 2)
            else
                displayCount = 1
            end
        end
        --return result, displayCount
        return sourceObj.use, displayCount
    end

    local result = {}
    if recipe.isSynthetic then
        local sources = recipe.recipeData.ingredients
        for i = 1, #sources do
            local source = sources[i]
            local sourceInList = {}
            sourceInList.items = {}
            sourceInList.isKeep = source.isKeep and true or false
            sourceInList.isDestroy = false
            sourceInList.uses = 0
            local item = CHC_main.items[source.type]
            local itemInList = {}

            itemInList.count = source.amount
            itemInList.texture = item.texture
            itemInList.fullType = item.fullType
            itemInList.name = self:setItemNameInSource(item, itemInList, sourceInList.isDestroy,
                sourceInList.uses)
            insert(sourceInList.items, itemInList)
            insert(result, sourceInList)
        end
    elseif recipe.isEvolved then
        local sourceBase = {
            { fullType = recipe.recipeData.baseItem, isSpice = false, name = recipe.recipeData.baseItem, use = 1 } }
        local sourceMain = {}
        local sourceSpice = {}
        for i = 1, #recipe.recipeData.possibleItems do
            local item = recipe.recipeData.possibleItems[i]
            if item.isSpice then
                insert(sourceSpice, item)
            else
                insert(sourceMain, item)
            end
        end
        local types = { sourceBase, sourceMain, sourceSpice }
        for order = 1, #types do
            local source = types[order]
            local sourceInList = {}
            sourceInList.items = {}

            sourceInList.isKeep = order == 1 and true or false -- keep baseItem
            sourceInList.isDestroy = false
            sourceInList.uses = 1

            local sourceItems = source
            for i = 1, #sourceItems do
                local sourceObj = sourceItems[i]
                local item
                if sourceObj.fullType == 'Water' then
                    item = CHC_main.items['Base.WaterDrop']
                else
                    item = CHC_main.items[sourceObj.fullType]
                end

                if item then
                    local itemInList = {}
                    if order == 1 then
                        itemInList.count, itemInList.displayCount = 1, 1
                    else
                        itemInList.count, itemInList.displayCount = getCount(item, sourceObj)
                    end
                    itemInList.texture = item.texture
                    itemInList.fullType = item.fullType
                    if sourceObj.fullType == 'Water' then
                        itemInList.fullType = 'Base.WaterDrop'
                    end
                    itemInList.name = self:setItemNameInSource(item, itemInList, sourceInList.isDestroy,
                        itemInList.count)

                    insert(sourceInList.items, itemInList)
                end
            end
            insert(result, sourceInList)
        end
    else
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
                local item
                if sourceFullType == 'Water' then
                    item = CHC_main.items['Base.WaterDrop']
                elseif utils.startswith(sourceFullType, '[') then
                    -- a Lua test function
                    item = CHC_main.items['Base.WristWatch_Right_DigitalBlack']
                else
                    item = CHC_main.items[sourceFullType]
                end
                if item then
                    local itemInList = {}

                    itemInList.count = sourceInList.uses > 0 and sourceInList.uses or source:getCount()
                    itemInList.texture = item.texture
                    itemInList.fullType = item.fullType
                    if sourceFullType == 'Water' then
                        itemInList.fullType = 'Base.WaterDrop'
                    end

                    itemInList.name = self:setItemNameInSource(item, itemInList, sourceInList.isDestroy,
                        sourceInList.uses)

                    insert(sourceInList.items, itemInList);
                end
            end
            insert(result, sourceInList)
        end
    end
    return result
end

function CHC_uses_recipepanel:setObj(recipe)
    if not self.containerList then
        self.parent.getContainers(self)
    end
    local obj = {}

    obj.category = recipe.category
    obj._id = recipe._id

    obj.recipe = recipe.recipe
    if recipe.isSynthetic then
        obj.available = false
    elseif recipe.isEvolved then
        obj.available = CHC_main.common.isEvolvedRecipeValid(recipe, self.containerList)
        obj.maxItems = recipe.recipeData.maxItems
    else
        obj.available = RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.containerList)
    end

    -- if recipe.recipeData.lua then
    --     -- efg:dfg() -- testing lua parsing
    -- end

    local resultItem = recipe.recipeData.result
    if resultItem then
        obj.module = resultItem.modname
        obj.isVanilla = resultItem.isVanilla
        -- newItem.modname = resultItem:getModID()
        obj.texture = resultItem.texture
        if resultItem.textureMult then
            if not self.itemImgTextureMultApplied then
                self.mainImg.forcedWidthImage = self.mainImg.forcedWidthImage * resultItem.textureMult
                self.mainImg.forcedHeightImage = self.mainImg.forcedHeightImage * resultItem.textureMult
                self.itemImgTextureMultApplied = true
            end
        else
            self.mainImg.forcedWidthImage = self.mainImg.origWI
            self.mainImg.forcedHeightImage = self.mainImg.origHI
            self.itemImgTextureMultApplied = false
        end
        self.mainImg:setImage(resultItem.texture)
        --self.mainImg.item = resultItem
        if resultItem.tooltip then
            obj.tooltip = getText(resultItem.tooltip) --FIXME
            self.mainImg:setTooltip(getText(resultItem.tooltip))
        else
            self.mainImg:setTooltip(nil)
        end
        obj.itemName = resultItem.displayName
        local displayCategory = resultItem.displayCategory
        if displayCategory then
            obj.itemDisplayCategory = getTextOrNull('IGUI_ItemCat_' .. displayCategory)
        end

        local resultCount
        if recipe.isSynthetic then
            resultCount = 1
        elseif recipe.isEvolved then
            resultCount = 1
        else
            resultCount = recipe.recipe:getResult():getCount()
        end
        if resultCount > 1 then
            obj.itemName = (resultCount * resultItem.count) .. ' ' .. obj.itemName
        end

        self.mainRes:setName(obj.itemName)
        self.mainRes:setTooltip(string.format('%s <LINE>%s', resultItem.name, resultItem.fullType))

        if resultItem.modname and not resultItem.isVanilla then
            local c = { r = 0.392, g = 0.584, b = 0.929 } -- CornFlowerBlue
            self.mainMod:setName('Mod: ' .. resultItem.modname)
            self.mainMod:setColor(c.r, c.g, c.b)
        else
            self.mainMod:setName(nil)
        end
    end

    local catName = getTextOrNull('IGUI_CraftCategory_' .. recipe.category) or recipe.category
    self.mainCat:setName(getText('IGUI_invpanel_Category') .. ': ' .. catName)

    local recipeName
    if recipe.isEvolved then
        recipeName = recipe.recipe:getName() .. ' ' .. getText('IGUI_CHC_Evolved_Max_Ingr', recipe.recipeData.maxItems)
    else
        recipeName = recipe.recipe:getName()
    end
    self.mainName:setName(recipeName)

    local maxY = self.mainMod.y + self.mainMod.height + 2
    self.mainInfo:setHeight(math.max(74, maxY))
    self.mainInfo:setVisible(true)


    obj.hydrocraftEquipment = recipe.recipeData.hydroFurniture
    obj.cecEquipment = recipe.recipeData.CECFurniture

    obj.sources = self:getSources(recipe)


    -- extra stuff for render
    if recipe.isSynthetic then
        obj.requiredSkillCount = 0
        obj.isKnown = true
        obj.nearItem = nil
        obj.timeToMake = 100 -- FIXME
        obj.howManyCanCraft = 1
        obj.needToBeLearn = false
    elseif recipe.isEvolved then
        obj.isEvolved = true
        obj.requiredSkillCount = 0
        obj.isKnown = true
        obj.nearItem = nil
        obj.timeToMake = 0 -- FIXME
        obj.howManyCanCraft = 0
        obj.needToBeLearn = false
    else
        obj.requiredSkillCount = recipe.recipe:getRequiredSkillCount()
        obj.isKnown = self.player:isRecipeKnown(recipe.recipe)
        obj.nearItem = recipe.recipeData.nearItem
        obj.timeToMake = recipe.recipe:getTimeToMake()
        obj.howManyCanCraft = RecipeManager.getNumberOfTimesRecipeCanBeDone(
            obj.recipe, self.player,
            self.containerList, nil
        )
        obj.needToBeLearn = recipe.recipe:needToBeLearn()
    end

    self.recipe = recipe
    self.newItem = obj

    if not recipe.isEvolved then
        self.manualsEntries = CHC_main.itemsManuals[obj.recipe:getOriginalname()]
        if self.manualsEntries ~= nil then
            self.manualsSize = #self.manualsEntries
        end
    end
    self:refreshIngredientPanel()
    self:refreshSkillPanel()
    self:refreshBooksPanel()
    self:refreshEquipmentPanel()

    self.bh = self:getBottomHeight(obj)
end

-- endregion

-- region update

function CHC_uses_recipepanel:refreshIngredientPanel()
    local selectedItem = self.newItem
    if not selectedItem then return end
    if not self.lastSelectedItem then
        self.lastSelectedItem = selectedItem
    end

    if self.recipe.isSynthetic then
        selectedItem.typesAvailable = { true }
    elseif self.recipe.isEvolved then
        selectedItem.typesAvailable = self:getAvailableItemsType()
    else
        selectedItem.typesAvailable = self:getAvailableItemsType()
    end
    local c1 = not utils.areTablesDifferent(selectedItem.typesAvailable, self.lastAvailableTypes)
    local c2 = self.ingredientPanel.origH
    local c3 = selectedItem._id == self.lastSelectedItem._id
    if c1 and c2 and c3 then
        return
    end
    self.lastAvailableTypes = selectedItem.typesAvailable
    self.lastSelectedItem = selectedItem
    self.ingredientPanel:setVisible(false)
    self.ingredientPanel:clear()

    -- Display single-item sources before multi-item sources
    local sortedSources = {}
    for i = 1, #selectedItem.sources do
        insert(sortedSources, selectedItem.sources[i])
    end
    table.sort(sortedSources, function(a, b) return #a.items == 1 and #b.items > 1 end)

    for i = 1, #sortedSources do
        local source = sortedSources[i]
        local available = {}
        local unavailable = {}

        for j = 1, #source.items do
            local item = source.items[j]
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
            local numTypes = selectedItem.typesAvailable[item.fullType]
            if selectedItem.typesAvailable and (not numTypes or numTypes < item.count) then
                insert(unavailable, data)
            else
                insert(available, data)
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
            local txt = getText('IGUI_CraftUI_OneOf')
            if data.isDestroy then
                txt = txt .. ' (D) '
            end
            if data.isKeep then
                txt = txt .. ' (K) '
            end
            txt = txt .. ' (' .. #available .. '/' .. #available + #unavailable .. ') '
            self.ingredientPanel:addItem(txt, data)
        end

        -- Hack for 'Dismantle Digital Watch' and similar recipes.
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

        for j = 1, #available do
            self.ingredientPanel:addItem(available[j].name, available[j])
        end
        for j = 1, #unavailable do
            self.ingredientPanel:addItem(unavailable[j].name, unavailable[j])
        end
    end

    local h = math.min(10, #self.ingredientPanel.items) * self.ingredientPanel.itemheight
    self.ingredientPanel.origH = h
    --self.ingredientPanel:setHeight(h)
    self.ingredientPanel:setVisible(true)
end

function CHC_uses_recipepanel:getAvailableItemsType()
    local result = {}
    local recipe = self.recipe
    if not recipe then return end
    if recipe.isSynthetic then
        -- TODO
    elseif recipe.isEvolved then
        local baseItem = CHC_main.items[recipe.recipeData.baseItem]
        local resultItem = recipe.recipeData.result
        if not baseItem or not resultItem then return result end
        -- check if player has baseitem/resultitem nearby
        if CHC_main.common.playerHasItemNearby(baseItem, self.containerList) or
            CHC_main.common.playerHasItemNearby(resultItem, self.containerList) then
            result[baseItem.fullType] = 1
        end
        -- i = 1 is baseItem (handled above)
        local items = recipe.recipe:getItemsCanBeUse(self.player, recipe.recipeData.result.item, self.containerList)
        for i = 2, #self.newItem.sources do
            local source = self.newItem.sources[i]
            local sourceItemTypes = {}
            for k = 1, #source.items do
                sourceItemTypes[source.items[k].fullType] = true
            end
            for x = 0, items:size() - 1 do
                local item = items:get(x)
                local itemFT = item:getFullType()
                if sourceItemTypes['Water'] and ISCraftingUI:isWaterSource(item, source:getCount()) then
                    result['Base.WaterDrop'] = (result['Base.WaterDrop'] or 0) + item:getDrainableUsesInt()
                elseif sourceItemTypes[itemFT] then
                    local count = 1
                    if not source.isDestroy and item:IsDrainable() then
                        count = item:getDrainableUsesInt()
                    end
                    if not source.isDestroy and instanceof(item, 'Food') then
                        if source.uses > 0 then
                            count = -item:getHungerChange() * 100
                        end
                    end
                    result[itemFT] = (result[itemFT] or 0) + count
                end
            end
        end
    else
        recipe = recipe.recipe
        for i = 0, recipe:getSource():size() - 1 do
            local items = RecipeManager.getSourceItemsAll(recipe, i, self.player, self.containerList, nil, nil)
            local source = recipe:getSource():get(i);
            local sourceItemTypes = {};
            for k = 1, source:getItems():size() do
                local sourceFullType = source:getItems():get(k - 1);
                sourceItemTypes[sourceFullType] = true;
            end
            for x = 0, items:size() - 1 do
                local item = items:get(x)
                local itemFT = item:getFullType()
                if sourceItemTypes['Water'] and ISCraftingUI:isWaterSource(item, source:getCount()) then
                    result['Base.WaterDrop'] = (result['Base.WaterDrop'] or 0) + item:getDrainableUsesInt()
                elseif sourceItemTypes[itemFT] then
                    local count = 1
                    if not source:isDestroy() and item:IsDrainable() then
                        count = item:getDrainableUsesInt()
                    end
                    if not source:isDestroy() and instanceof(item, 'Food') then
                        if source:getUse() > 0 then
                            count = -item:getHungerChange() * 100
                        end
                    end
                    result[itemFT] = (result[itemFT] or 0) + count
                end
            end
        end
    end
    return result
end

function CHC_uses_recipepanel:refreshSkillPanel()
    self.skillPanel:setVisible(false)

    local recipe = self.newItem
    if not recipe then return end
    if recipe.requiredSkillCount <= 0 then return end

    self.skillPanel:clear()

    for i = 1, recipe.requiredSkillCount do
        local skill = recipe.recipe:getRequiredSkill(i - 1)
        local perk = PerkFactory.getPerk(skill:getPerk())
        local playerLevel = self.player and self.player:getPerkLevel(skill:getPerk()) or 0
        local perkName = perk and perk:getName() or skill:getPerk():name()

        self.skillPanel:addItem(perkName, { name = perkName, pLevel = playerLevel, rLevel = skill:getLevel() })
    end

    self.skillPanel:setHeight(math.min(3, recipe.requiredSkillCount) * self.skillPanel.itemheight)
    self.skillPanel.doDrawItem = self.drawSkill
    self.skillPanel:setVisible(true)
end

function CHC_uses_recipepanel:refreshBooksPanel()
    self.booksPanel:setVisible(false)

    local recipe = self.newItem
    if not recipe then return end
    if not self.manualsEntries then return end
    if not recipe.needToBeLearn then return end

    self.booksPanel:clear()

    for i = 1, #self.manualsEntries do
        local item = self.manualsEntries[i]
        item.isKnown = recipe.isKnown
        self.booksPanel:addItem(item.displayName, item)
    end
    self.booksPanel:setHeight(math.min(3, #self.manualsEntries) * self.booksPanel.itemheight)
    self.booksPanel.doDrawItem = self.drawBook
    self.booksPanel:setVisible(true)
end

function CHC_uses_recipepanel:refreshEquipmentPanel()
    self.equipmentPanel:setVisible(false)

    local recipe = self.newItem
    if not recipe then return end

    local hydro = recipe.hydrocraftEquipment
    local cec = recipe.cecEquipment
    local near = recipe.nearItem
    if not hydro and not near and not cec then return end

    self.equipmentPanel:clear()

    if hydro then
        local obj = hydro.obj
        obj.luaTest = hydro.luaTest
        self.equipmentPanel:addItem(obj.name, obj)
    end

    if cec then
        local obj = cec.obj
        obj.luaTest = cec.luaTest
        obj.luaTestParam = cec.luaTestParam
        self.equipmentPanel:addItem(obj.name, obj)
        near = nil
    end

    if near then
        self.equipmentPanel:addItem(near, near)
    end

    self.equipmentPanel:setHeight(math.min(1, #self.equipmentPanel.items) * self.equipmentPanel.itemheight)
    self.equipmentPanel.doDrawItem = self.drawEquipment
    self.equipmentPanel:setVisible(true)
end

-- endregion

-- region render
function CHC_uses_recipepanel:onResize()
    ISPanel.onResize(self)
    self.mainInfo:setWidth(self.parent.headers.typeHeader.width - self.margin - self.mainInfo.x)
end

function CHC_uses_recipepanel:drawFavoriteStar(y, item)
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
            favoriteAlpha = isFav and 0.9 or 0.5
        end
    elseif isFav then
        favoriteStar = parent.itemFavoriteStar
    end
    if favoriteStar then
        self:drawTexture(favoriteStar, favYPos,
            y + (item.height / 2 - favoriteStar:getHeight() / 2),
            favoriteAlpha, 1, 1, 1)
    end
end

-- region doDrawItem

function CHC_uses_recipepanel:drawIngredient(y, item, alt)
    if self.parent.fastListReturn(self, y) then return y + self.itemheight end
    if item.item.multipleHeader then
        local r, g, b = 1, 1, 1
        if not item.item.available then
            r, g, b = 0.54, 0.54, 0.54
        end
        self:drawText(item.text, 12, y + 2, r, g, b, 1, self.font)
    else
        local r, g, b
        local r2, g2, b2, a2
        local typesAvailable = item.item.selectedItem.typesAvailable
        local numTypes = typesAvailable[item.item.fullType]
        local itemNotAvailable = (
            not numTypes or numTypes < item.item.count)
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
        local txt = ''
        if item.item.isKeep then
            txt = txt .. 'K'
        end
        if item.item.isDestroy then
            txt = txt .. 'D'
        end
        if txt and not item.item.multiple then
            self:drawText(txt, 5, y + (item.height - fhSmall) / 2, r, g, b, 1, self.font)
        end

        self:drawText(item.text, dx + imgW + 4, y + (item.height - fhSmall) / 2, r, g, b, 1, self.font)

        if item.item.texture then
            self:drawTextureScaledAspect(item.item.texture, dx, y + (self.itemheight - imgH) / 2, 20, 20, a2, r2, g2, b2)
        end

        --region favorite handler
        self.parent.drawFavoriteStar(self, y, item)
        --endregion

        if item.index == self.mouseoverselected then
            local fr, fg, fb, fa = 0.1, 0.1, 0.5, 0.2
            if item.item.multiple then
                fr, fb = 0.5, 0.1
            end
            self:drawRect(1, y, self.width - 2, self.itemheight, fa, fr, fg, fb)
        end
    end
    local ab, rb, gb, bb = 1, 0.1, 0.1, 0.1
    if item.item.multipleHeader then
        self:drawRect(1, y, self.width - 2, self.itemheight, 0.2, 0.25, gb, bb)
    end
    self:drawRectBorder(0, y, self.width - 2, self.itemheight, ab, rb, gb, bb)
    -- ISUIElement:drawRectBorder( x, y, w, h, a, r, g, b)

    return y + self.itemheight;
end

function CHC_uses_recipepanel:drawSkill(y, item, alt)
    if self.parent.fastListReturn(self, y) then return y + self.itemheight end

    local text = ' - ' .. item.text .. ': ' .. tostring(item.item.pLevel) .. ' / ' .. tostring(item.item.rLevel);
    local r, g, b, a = 1, 1, 1, 0.9
    local rb, gb, bb, ab = 0.1, 0.1, 0.1, 1

    if item.item.pLevel < item.item.rLevel then
        g, b = 0, 0
    else
        a = 0.7
    end
    self:drawText(text, 15, y, r, g, b, a, UIFont.Small)
    self:drawRectBorder(0, y, self.width - 2, self.itemheight, ab, rb, gb, bb)
    return y + self.itemheight
end

function CHC_uses_recipepanel:drawBook(y, item, alt)
    if self.parent.fastListReturn(self, y) then return y + self.itemheight end
    local x = 0

    local r, g, b, a = 1, 1, 1, 1
    local rb, gb, bb, ab = 0.1, 0.1, 0.1, 1
    if not item.item.isKnown then
        g, b, a = 0, 0, 0.9
    end
    local tX = x
    local tY = y + 2
    -- self:drawText(' - ', tX, tY, r, g, b, a, UIFont.Small)
    if item.item.texture then
        tX = tX + 15
        self:drawTextureScaledAspect(item.item.texture, tX, tY, 16, 16, 1, 1, 1, 1)
        tX = tX + 20
    end
    self:drawText(item.item.displayName, tX, tY, r, g, b, a, UIFont.Small)

    --region favorite handler
    self.parent.drawFavoriteStar(self, y, item)
    --endregion

    self:drawRectBorder(0, y, self.width - 2, self.itemheight, ab, rb, gb, bb)

    return y + self.itemheight
end

function CHC_uses_recipepanel:drawEquipment(y, item, alt)
    if self.parent.fastListReturn(self, y) then return y + self.itemheight end

    local isComplex = item.item.luaTest and true or false

    local x = 0
    local a = 0.9
    if isComplex then
        local r, g, b = 1, 1, 1
        local tX = x
        local tY = y + 2
        local luaTestResult
        if type(item.item.luaTest) == "function" then
            if item.item.luaTestParam then
                luaTestResult = item.item.luaTest(self.player, item.item.luaTestParam)
            else
                luaTestResult = item.item.luaTest(self.player)
            end
        else
            luaTestResult = true
        end
        if not luaTestResult then
            g, b = 0, 0
            a = 0.75
        end
        if item.item.texture then
            local tW = 20
            local tH = 20
            local ttY = tY
            if item.item.textureMult then
                tW = tW * item.item.textureMult
                tH = tH * item.item.textureMult
                ttY = tY - tH / 4
                tX = tX + tW / 2
            end
            self:drawTextureScaledAspect(item.item.texture, tX, ttY, tW, tH, a, 1, 1, 1)
            tX = tX + tW + 5
        end
        self:drawText(item.item.name, tX, tY, r, g, b, a, UIFont.Small)
    end

    if not isComplex then
        self:drawText(' - ' .. item.item, x + 15, y, 1, 1, 1, a, UIFont.Small)
    end

    --region favorite handler
    self.parent.drawFavoriteStar(self, y, item)
    --endregion

    return y + self.itemheight
end

-- endregion

function CHC_uses_recipepanel:render()
    ISPanel.render(self)

    if not self.recipe then return end
    if self.needUpdateScroll then
        self.ingredientPanel.yScroll = self.ingredientPanel:getYScroll()
        self.skillPanel.yScroll = self.skillPanel:getYScroll()
        self.booksPanel.yScroll = self.booksPanel:getYScroll()
        self.equipmentPanel.yScroll = self.equipmentPanel:getYScroll()
        self.needUpdateScroll = false
    end

    if self.needUpdateMousePos then
        self.ingredientPanel.mouseX = self.ingredientPanel:getMouseX()
        self.skillPanel.mouseX = self.skillPanel:getMouseX()
        self.booksPanel.mouseX = self.booksPanel:getMouseX()
        self.equipmentPanel.mouseX = self.equipmentPanel:getMouseX()
        self.ingredientPanel.mouseY = self.ingredientPanel:getMouseY()
        self.skillPanel.mouseY = self.skillPanel:getMouseY()
        self.booksPanel.mouseY = self.booksPanel:getMouseY()
        self.equipmentPanel.mouseY = self.equipmentPanel:getMouseY()
        self.needUpdateMousePos = false
    end
    local x = 10;
    local y = 10;
    local selectedItem = self.newItem

    -- region check if available

    if self.needRefreshIngredientPanel then
        self.needRefreshIngredientPanel = false
        self.containerList = self.parent.containerList
        local typesAvailable = self:getAvailableItemsType()
        self.needRefreshRecipeCounts = utils.areTablesDifferent(selectedItem.typesAvailable, typesAvailable)
        selectedItem.typesAvailable = typesAvailable
        if self.recipe.isSynthetic then
            selectedItem.available = false
            selectedItem.howManyCanCraft = 0
        elseif self.recipe.isEvolved then
            selectedItem.available = CHC_main.common.isEvolvedRecipeValid(self.recipe, self.containerList)
            selectedItem.howManyCanCraft = 0 -- evolved recipes aren't craftable
        else
            selectedItem.available = RecipeManager.IsRecipeValid(selectedItem.recipe, self.player, nil,
                self.containerList)
            selectedItem.howManyCanCraft = RecipeManager.getNumberOfTimesRecipeCanBeDone(
                selectedItem.recipe, self.player,
                self.containerList, nil
            )
        end
        self:refreshIngredientPanel()
    end

    if self.needRefreshRecipeCounts then
        self.parent.needUpdateCounts = true
        self.needRefreshRecipeCounts = false
    end

    -- endregion

    --y = y + self:drawMainInfo(x, y, selectedItem) + 5
    y = y + self.mainInfo.height
    y = y + self:drawIngredients(x, y, selectedItem)
    y = y + self:drawCraftButtons(x, y, selectedItem)
    y = y + self:drawRequiredSkills(x, y, selectedItem)
    y = y + self:drawRequiredBooks(x, y, selectedItem)
    y = y + self:drawNearItem(x, y, selectedItem)
    local reqTime = getText('IGUI_CraftUI_RequiredTime', selectedItem.timeToMake)
    self:drawText(reqTime, x, y, 1, 1, 1, 0.9, UIFont.Medium)
end

function CHC_uses_recipepanel:getBottomHeight(item)
    local bh = 0

    -- craft buttons
    if item.available then
        bh = bh + self.craftOneButton.height + 3
    end

    --skills
    if item.requiredSkillCount > 0 then
        bh = bh + fhMedium + self.margin
        bh = bh + self.skillPanel.height
    end

    -- books
    if self.manualsEntries then
        bh = bh + fhMedium + self.margin
        bh = bh + self.booksPanel.height
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

    bh = bh + fhMedium + self.margin
    return bh
end

function CHC_uses_recipepanel:drawIngredients(x, y, item)
    local sy = y
    local a = 0.9
    self:drawText(getText('IGUI_CraftUI_RequiredItems'), x, y, 1, 1, 1, a, UIFont.Medium)
    y = y + fhMedium + 5


    self.ingredientPanel:setX(x + 5)
    self.ingredientPanel:setY(y)
    self.ingredientPanel:setWidth(self.width - 25)
    local m1 = self.height - y - self.bh
    local ipH = math.min(m1, self.ingredientPanel.origH)

    self.ingredientPanel:setHeight(ipH)
    y = y + self.ingredientPanel.height + self.margin

    return y - sy
end

function CHC_uses_recipepanel:drawCraftButtons(x, y, item)
    --if not self.newItem then return 0 end
    local sy = y
    if not item.available or item.isEvolved then
        self.craftOneButton:setVisible(false)
        self.craftAllButton:setVisible(false)
        return 0
    end

    self.craftOneButton:setY(y)
    self.craftAllButton:setY(y)
    if not self.craftOneButton:isVisible() then
        self.craftOneButton:setX(x)

        self.craftOneButton:setVisible(true)
    end

    --region all
    local title = getText('IGUI_CraftUI_ButtonCraftAll')
    local count = item.howManyCanCraft
    if count > 1 then
        title = getText('IGUI_CraftUI_ButtonCraftAllCount', count)
    elseif count == 1 then
        self.craftAllButton:setVisible(false)
    end
    if title ~= self.craftAllButton:getTitle() then
        self.craftAllButton:setTitle(title)
        self.craftAllButton:setWidthToTitle()
    end

    if not self.craftAllButton:isVisible() and count > 1 then
        self.craftAllButton:setX(self.craftOneButton.x + 5 + self.craftOneButton.width)
        self.craftAllButton:setVisible(true)
    end
    --endregion

    y = y + self.craftOneButton.height + 3

    if self.player:isDriving() then
        self.craftOneButton.enable = false
        self.craftOneButton.tooltip = getText('Tooltip_CantCraftDriving')
        self.craftAllButton.enable = false
        self.craftAllButton.tooltip = getText('Tooltip_CantCraftDriving')
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
    local a = 0.9
    local requiredSkillCount = item.requiredSkillCount
    if requiredSkillCount <= 0 then return 0 end
    self:drawText(getText('IGUI_CraftUI_RequiredSkills'), x, y, 1, 1, 1, a, UIFont.Medium)
    y = y + fhMedium
    self.skillPanel:setX(x + 5)
    self.skillPanel:setY(y)
    self.skillPanel:setWidth(self.width - 25)
    y = y + self.skillPanel.height
    return y - sy
end

function CHC_uses_recipepanel:drawRequiredBooks(x, y, item)
    if not self.manualsEntries then return 0 end
    -- if self.manualsEntries and not isKnown then
    if not item.needToBeLearn then return 0 end
    local sy = y
    local a = 0.9
    self:drawText(getText('UI_recipe_panel_required_book') .. ':', x, y, 1, 1, 1, a, UIFont.Medium)
    y = y + fhMedium
    self.booksPanel:setX(x + 5)
    self.booksPanel:setY(y)
    self.booksPanel:setWidth(self.width - 25)

    y = y + self.booksPanel.height
    return y - sy
end

function CHC_uses_recipepanel:drawNearItem(x, y, item)
    local hydroFurniture = item.hydrocraftEquipment
    local nearItem = item.nearItem
    if not nearItem and not hydroFurniture then return 0 end
    local sy = y
    local a = 0.9

    self:drawText(getText('UI_recipe_panel_near_item') .. ': ', x, y, 1, 1, 1, a, UIFont.Medium);
    y = y + fhMedium

    self.equipmentPanel:setX(x + 5)
    self.equipmentPanel:setY(y)
    self.equipmentPanel:setWidth(self.width - 25)
    y = y + self.equipmentPanel.height
    return y - sy
end

-- endregion

-- region logic

-- region event handlers


function CHC_uses_recipepanel:onRMBDownIngrPanel(x, y, item)
    local backRef = self.parent.backRef
    local context = backRef.onRMBDownObjList(self, x, y, item)
    if not item then
        local row = self:rowAt(x, y)
        if row == -1 or not row then return end
        item = self.items[row]
        if not item then return end
        item = item.item
    end
    if not item.fullType then return end
    -- -- check if there is recipes for item

    item = CHC_main.items[item.fullType]
    if not item then return end
    local isRecipes = CHC_main.common.areThereRecipesForItem(item)

    local findOpt = context:addOption(getText('IGUI_find_item'), backRef, CHC_menu.onCraftHelperItem, item)
    findOpt.iconTexture = getTexture("media/textures/search_icon.png")

    local newTabOption = context:addOption(getText('IGUI_new_tab'), backRef, backRef.addItemView, item.item,
        true, 2)

    newTabOption.iconTexture = getTexture("media/textures/CHC_open_new_tab.png")

    if not isRecipes then
        CHC_main.common.setTooltipToCtx(
            newTabOption,
            getText('IGUI_no_recipes'),
            false
        )
    else
        CHC_main.common.addTooltipNumRecipes(newTabOption, item)
    end

    -- context:addOption(getText('UI_servers_addToFavorite'), )
end

function CHC_uses_recipepanel:onRMBDownItemIcon(x, y)
    local recipe_panel = self.parent.parent
    if not recipe_panel.recipe then return end
    recipe_panel.parent.onRMBDown(recipe_panel, nil, nil, recipe_panel.recipe.recipeData.result)
end

function CHC_uses_recipepanel:onIngredientMouseDown(item)
    if not item then return end
    local x = self:getMouseX()

    if (x >= self.width - 40) then
        local isFav = self.modData[CHC_main.getFavItemModDataStr(item)] == true
        isFav = not isFav
        self.modData[CHC_main.getFavItemModDataStr(item)] = isFav or nil
        self.backRef.updateQueue:push({
            targetView = 'fav_items',
            actions = { 'needUpdateFavorites', 'needUpdateObjects' }
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
    for i = 1, items:size() do
        local item = items:get(i - 1)
        insert(result, item)
        if not selectedItem.recipe:isCanBeDoneFromFloor() then
            if item:getContainer() ~= self.player:getInventory() then
                ISTimedActionQueue.add(
                    ISInventoryTransferAction:new(
                        self.player, item,
                        item:getContainer(),
                        self.player:getInventory(), nil
                    )
                )
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
                local action = ISInventoryTransferAction:new(
                    self.player, item,
                    item:getContainer(),
                    self.player:getInventory(), nil)
                ISTimedActionQueue.addAfter(previousAction, action)
                previousAction = action
                insert(returnToContainer, item)
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
        for i = 1, #itemsUsed do
            local item = itemsUsed[i]
            if item:getContainer() ~= self.player:getInventory() then
                insert(returnToContainer, item)
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

function CHC_uses_recipepanel:new(args)
    local o = {};
    o = ISPanel:new(args.x, args.y, args.w, args.h);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    o.itemMargin = 2
    o.padY = 5
    o.margin = 5
    o.anchorTop = true;
    o.anchorBottom = true;
    o.backRef = args.backRef
    local player = getPlayer()
    o.player = player
    o.character = player
    o.playerNum = player and player:getPlayerNum() or -1
    o.needRefreshIngredientPanel = true
    o.needRefreshRecipeCounts = true
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.recipe = nil;
    o.manualsSize = 0
    o.manualsEntries = nil
    o.modData = CHC_main.playerModData
    o.lastAvailableTypes = {}

    o.bh = nil

    o.itemFavoriteStar = getTexture('media/textures/CHC_item_favorite_star.png')
    o.itemFavCheckedTex = getTexture('media/textures/CHC_item_favorite_star_checked.png')
    o.itemFavNotCheckedTex = getTexture('media/textures/CHC_item_favorite_star_outline.png')
    return o;
end
