require 'luautils'
require 'ISUI/ISPanel'
require 'ISUI/ISScrollingListBox'
require 'ISUI/ISCraftingUI'
require 'CHC_main'
require 'UI/ISLabelWithIcon'


local utils = require('CHC_utils')
local insert = table.insert
local ssort = string.sort
local tsort = table.sort
local sformat = string.format

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

    local mainPadY = 2

    local mainY = mainPadY
    local mainPriFont = UIFont.Medium
    local mainSecFont = UIFont.Small
    local mr, mg, mb, ma = 1, 1, 1, 1

    self.mainInfo = ISPanel:new(self.margin, y, self.width - 2 * self.margin, 1)
    self.mainInfo.borderColor = { r = 1, g = 0.53, b = 0.53, a = 0 }
    self.mainInfo:initialise()
    self.mainInfo:setVisible(false)

    -- region mainInfo
    self.mainInfoNameLine = ISPanel:new(0, 0, self.mainInfo.width, fntm + 2 * mainPadY)
    self.mainInfoNameLine.anchorRight = true
    local minlc = 0.45
    self.mainInfoNameLine.backgroundColor = { r = minlc, g = minlc, b = minlc, a = 0.9 }
    self.mainInfoNameLine:initialise()

    self.mainName = ISLabelWithIcon:new(self.margin, mainY, fhMedium, nil, mr, mg, mb, ma, mainPriFont, true)
    self.mainName:initialise()

    local timeText = "100000"
    local timeX = 16 + getTextManager():MeasureStringX(mainSecFont, timeText) -- FIXME too close to border
    self.mainTime = ISLabelWithIcon:new(self.width - timeX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainTime.anchorLeft = false
    self.mainTime.anchorRight = true
    self.mainTime:initialise()
    self.mainTime:setIcon(getTexture('media/textures/CHC_recipe_required_time.png'))
    mainY = mainY + self.mainInfoNameLine.height + self.margin

    self.mainImg = ISButton:new(0, mainY, 52, 52, '', self, nil)
    self.mainImg:initialise()
    self.mainImg.backgroundColorMouseOver.a = 0
    self.mainImg.backgroundColor.a = 0
    self.mainImg.origWI = 50
    self.mainImg.origHI = 50
    self.mainImg.forcedWidthImage = self.mainImg.origWI
    self.mainImg.forcedHeightImage = self.mainImg.origHI
    self.mainImg.onRightMouseDown = self.onRMBDownItemIcon
    local mainX = self.mainImg.width + self.margin

    self.mainCat = ISLabel:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainCat:initialise()
    mainY = mainY + self.mainCat.height + mainPadY

    self.mainRes = ISLabel:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainRes:initialise()
    mainY = mainY + self.mainRes.height + mainPadY

    self.mainMod = ISLabel:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainMod:initialise()
    mainY = mainY + self.mainMod.height + mainPadY
    -- endregion

    self.mainInfo:setHeight(mainY + mainPadY)

    self.mainInfo:addChild(self.mainInfoNameLine)
    self.mainInfo:addChild(self.mainName)
    self.mainInfo:addChild(self.mainTime)
    self.mainInfo:addChild(self.mainImg)
    self.mainInfo:addChild(self.mainCat)
    self.mainInfo:addChild(self.mainRes)
    self.mainInfo:addChild(self.mainMod)

    y = y + self.mainInfo:getBottom() + self.padY
    -- endregion

    -- region buttons
    local btnInfo = {
        x = x,
        y = y,
        w = 50,
        h = 25,
        clicktgt = self
    }
    self.craftOneButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt, self.craft);
    self.craftOneButton:initialise()

    -- TODO: change to icon
    self.craftOneButton.title = getText('IGUI_CraftUI_ButtonCraftOne')
    self.craftOneButton:setWidth(10 + getTextManager():MeasureStringX(UIFont.Small, self.craftOneButton.title))
    self.craftOneButton:setVisible(false)

    self.craftAllButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt, self.craftAll);
    self.craftAllButton:initialise()
    self.craftAllButton.title = getText('IGUI_CraftUI_ButtonCraftOne')
    self.craftAllButton:setVisible(false)

    self.addRandomButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt,
        self.addRandomMenu)
    self.addRandomButton:initialise()
    self.addRandomButton.title = "Add Random..." -- FIXME translation
    self.addRandomButton:setWidth(10 + getTextManager():MeasureStringX(UIFont.Small, self.addRandomButton.title))
    self.addRandomButton:setVisible(false)

    self.selectSpecificButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt,
        self.selectSpecificMenu)
    self.selectSpecificButton:initialise()
    self.selectSpecificButton.title = "Select specific..." -- FIXME translation
    self.selectSpecificButton:setWidth(10 +
        getTextManager():MeasureStringX(UIFont.Small, self.selectSpecificButton.title))
    self.selectSpecificButton:setVisible(false)
    y = y + btnInfo.h + self.padY

    -- self.debugGiveIngredientsButton = ISButton:new(0, 0, 50, 25, 'DBG: Give Ingredients', self, ISCraftingUI.debugGiveIngredients);
    -- self.debugGiveIngredientsButton:initialise();
    -- self:addChild(self.debugGiveIngredientsButton);

    -- endregion

    -- region stats list
    local stats_args = {
        x = 0,
        y = y,
        w = self.width - 2 * self.margin,
        h = self.height - self.mainInfo.height - 4 * self.padY,
        backRef = self.backRef,
    }
    stats_args.origH = stats_args.h

    self.statsList = CHC_sectioned_panel:new(stats_args)
    self.statsList:initialise()
    self.statsList:instantiate()
    self.statsList:setAnchorRight(true)
    self.statsList:setAnchorBottom(true)
    self.statsList.maintainHeight = false
    self.statsList:setVisible(false)
    -- endregion


    -- region ingredients
    self.ingredientPanel = ISScrollingListBox:new(1, 1, self.width - 20, 50)
    self.ingredientPanel:initialise()
    self.ingredientPanel:instantiate()
    self.ingredientPanel.onRightMouseDown = self.onRMBDownIngrPanel
    self.ingredientPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.ingredientPanel.prerender = CHC_view._list.prerender
    self.ingredientPanel.doDrawItem = self.drawIngredient
    self.ingredientPanel.itemheight = fhSmall + 2 * self.itemMargin
    self.ingredientPanel.font = UIFont.NewSmall
    self.ingredientPanel.yScroll = 0
    self.ingredientPanel.drawBorder = true
    self.ingredientPanel.borderColor = listBorderColor
    self.ingredientPanel.vscroll.borderColor = listBorderColor
    self.ingredientPanel:setVisible(false)
    -- endregion

    -- region skills
    self.skillPanel = ISScrollingListBox:new(1, 1, self.width, 1)
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
    -- endregion

    -- region books
    self.booksPanel = ISScrollingListBox:new(1, 1, self.width, 1)
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
    -- endregion

    -- region equipment
    self.equipmentPanel = ISScrollingListBox:new(1, 1, self.width, 1)
    self.equipmentPanel:initialise()
    self.equipmentPanel:instantiate()
    self.equipmentPanel.onRightMouseDown = self.onRMBDownIngrPanel
    self.equipmentPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.equipmentPanel.itemheight = fhSmall + 2 * self.itemMargin
    self.equipmentPanel.doDrawItem = self.drawEquipment --FIXME
    self.equipmentPanel.yScroll = 0
    self.equipmentPanel.drawBorder = true
    self.equipmentPanel.borderColor = listBorderColor
    self.equipmentPanel.vscroll.borderColor = listBorderColor
    -- endregion

    self:addChild(self.mainInfo)
    self:addChild(self.craftOneButton)
    self:addChild(self.craftAllButton)
    self:addChild(self.addRandomButton)
    self:addChild(self.selectSpecificButton)
    self:addChild(self.statsList)

    self.statsList:setScrollChildren(true)
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
        self.sourceSpice = sourceSpice
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
        self.sourceSpice = nil
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

function CHC_uses_recipepanel:setResultObj(resultItem, recipe)
    local res = {
        module = resultItem.modname,
        isVanilla = resultItem.isVanilla,
        texture = resultItem.texture,
        forcedWidthImage = nil,
        forcedHeightImage = nil,
        tooltip = nil,
        itemName = nil,
        resultCount = 1
    }

    if resultItem.textureMult then
        res.forcedWidthImage = self.mainImg.origWI * resultItem.textureMult
        res.forcedHeightImage = self.mainImg.origHI * resultItem.textureMult
    else
        res.forcedWidthImage = self.mainImg.origWI
        res.forcedHeightImage = self.mainImg.origHI
    end

    if resultItem.tooltip then
        res.tooltip = getTextOrNull(resultItem.tooltip) --FIXME
    end
    res.itemName = resultItem.displayName

    if not recipe.isSynthetic and not recipe.isEvolved then
        res.resultCount = recipe.recipe:getResult():getCount()
        if res.resultCount > 1 then
            res.itemName = (res.resultCount * resultItem.count) .. 'x ' .. res.itemName
        end
    end

    return res
end

function CHC_uses_recipepanel:setObj(recipe)
    if not self.containerList then
        self.parent.getContainers(self)
    end
    local obj = {
        category = recipe.category,
        _id = recipe._id,
        recipe = recipe,
        recipeObj = recipe.recipe,
    }
    if recipe.isSynthetic then
        obj.available = false
        obj.requiredSkillCount = 0
        obj.isKnown = true
        obj.nearItem = nil
        obj.timeToMake = 100 -- FIXME
        obj.howManyCanCraft = 0
        obj.needToBeLearn = false
    elseif recipe.isEvolved then
        obj.available = CHC_main.common.isEvolvedRecipeValid(recipe, self.containerList)
        obj.maxItems = recipe.recipeData.maxItems
        obj.isEvolved = true
        obj.requiredSkillCount = 0
        obj.isKnown = true
        obj.nearItem = nil
        obj.timeToMake = 0 -- FIXME
        obj.howManyCanCraft = 0
        obj.needToBeLearn = false
    else
        obj.available = RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.containerList) --FIXME
        obj.requiredSkillCount = recipe.recipe:getRequiredSkillCount()
        obj.isKnown = self.player:isRecipeKnown(recipe.recipe)
        obj.nearItem = recipe.recipeData.nearItem
        obj.timeToMake = recipe.recipe:getTimeToMake()
        obj.howManyCanCraft = RecipeManager.getNumberOfTimesRecipeCanBeDone(
            recipe.recipe, self.player,
            self.containerList, nil
        )
        obj.needToBeLearn = recipe.recipe:needToBeLearn()
    end

    -- region main info
    local recipeName
    if recipe.isEvolved then
        recipeName = recipe.recipe:getName() .. ' ' .. getText('IGUI_CHC_Evolved_Max_Ingr', recipe.recipeData.maxItems)
    else
        recipeName = recipe.recipe:getName()
    end
    self.mainName:setName(recipeName)

    self.mainTime:setName(tostring(obj.timeToMake))
    self.mainTime:setX(self.mainInfoNameLine.width - self.mainTime.width - self.margin)
    self.mainTime:setTooltip(luautils.split(getText('IGUI_CraftUI_RequiredTime', 0), ':')[1])
    self.mainName.maxWidth = self.mainInfoNameLine.width - self.mainTime.width

    local resultItem = recipe.recipeData.result
    local resultData
    if resultItem then
        resultData = self:setResultObj(resultItem, recipe)
    end
    if resultData then
        self.mainImg.forcedWidthImage = resultData.forcedWidthImage
        self.mainImg.forcedHeightImage = resultData.forcedHeightImage
        self.mainImg:setImage(resultItem.texture)
        self.mainImg:setTooltip(resultData.tooltip)

        self.mainRes:setName('Result: ' .. resultData.itemName) -- FIXME
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

    local maxY = self.mainMod.y + self.mainMod.height + 2
    self.mainInfo:setHeight(math.max(74, maxY))
    self.mainInfo:setVisible(true)
    -- endregion

    obj.hydrocraftEquipment = recipe.recipeData.hydroFurniture
    obj.cecEquipment = recipe.recipeData.CECFurniture

    obj.sources = self:getSources(recipe)

    self.selectedObj = obj

    if not recipe.isEvolved then
        self.manualsEntries = CHC_main.itemsManuals[recipe.recipe:getOriginalname()]
        if self.manualsEntries ~= nil then
            self.manualsSize = #self.manualsEntries
        end
    end

    local statsListOpenedSections = self.statsList.expandedSections
    self.statsList:clear()

    self:updateButtons(obj)

    self:refreshIngredientPanel(obj)
    self.statsList:addSection(self.ingredientPanel, getText('IGUI_CraftUI_RequiredItems'))

    if obj.requiredSkillCount > 0 then
        self:refreshSkillPanel(obj)
        self.statsList:addSection(self.skillPanel, getText('IGUI_CraftUI_RequiredSkills'))
    end

    if self.manualsEntries and obj.needToBeLearn then
        self:refreshBooksPanel(recipe)
        self.statsList:addSection(self.booksPanel, getText('UI_recipe_panel_required_book') .. ':')
    end

    if obj.hydrocraftEquipment or obj.cecEquipment or obj.nearItem then
        self:refreshEquipmentPanel(recipe)
        self.statsList:addSection(self.equipmentPanel, getText('UI_recipe_panel_near_item') .. ': ')
    end

    for section, _ in pairs(statsListOpenedSections) do
        self.statsList:expandSection(section)
    end

    if not utils.empty(self.statsList.sections) then
        self.needUpdateHeight = true
        self.statsList:setVisible(true)
    else
        self.statsList:setVisible(false)
    end
end

-- endregion

-- region update
function CHC_uses_recipepanel:getAvailableItemsType()
    local result = {}
    local recipe = self.selectedObj
    if not recipe or not recipe.recipe then return end
    recipe = recipe.recipe
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
        for i = 2, #self.selectedObj.sources do
            local source = self.selectedObj.sources[i]
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

function CHC_uses_recipepanel:shouldUpdateIngredients(selectedItem)
    if not self.lastSelectedItem then
        self.lastSelectedItem = selectedItem
    end

    if self.selectedObj.recipe.isSynthetic then
        selectedItem.typesAvailable = { true }
    else
        selectedItem.typesAvailable = self:getAvailableItemsType()
    end
    local c1 = not utils.areTablesDifferent(selectedItem.typesAvailable, self.lastAvailableTypes)
    local c2 = #self.ingredientPanel.items > 0
    local c3 = selectedItem._id == self.lastSelectedItem._id
    if c1 and c2 and c3 then
        return false
    end
    self.lastAvailableTypes = selectedItem.typesAvailable
    self.lastSelectedItem = selectedItem
    return true
end

function CHC_uses_recipepanel:refreshIngredientPanel(selectedItem)
    if not self:shouldUpdateIngredients(selectedItem) then
        return
    end

    local function handleDismantleWatch(available, unavailable)
        -- Hack for 'Dismantle Digital Watch' and similar recipes.
        -- Recipe sources include both left-hand and right-hand versions of the same item.
        -- We only want to display one of them.
        local removeExtra = ISCraftingUI.removeExtraClothingItemsFromList
        for j = 1, #available do
            local item = available[j]
            removeExtra(ISCraftingUI, j + 1, item, available)
            removeExtra(ISCraftingUI, 1, item, unavailable)
        end

        for j = 1, #unavailable do
            removeExtra(ISCraftingUI, j + 1, unavailable[j], unavailable)
        end
    end

    self.ingredientPanel:clear()

    -- Display single-item sources before multi-item sources
    local sortedSources = {}
    for i = 1, #selectedItem.sources do
        insert(sortedSources, selectedItem.sources[i])
    end
    tsort(sortedSources, function(a, b) return #a.items == 1 and #b.items > 1 end)

    -- region abc
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
            data.sourceNum = i
            data.recipe = selectedItem.recipe
            data.multiple = #source.items > 1
            local numTypes = selectedItem.typesAvailable[item.fullType]
            if selectedItem.typesAvailable and (not numTypes or numTypes < item.count) then
                insert(unavailable, data)
            else
                insert(available, data)
            end
        end
        tsort(available, function(a, b) return not ssort(a.name, b.name) end)
        tsort(unavailable, function(a, b) return not ssort(a.name, b.name) end)

        if #source.items > 1 then
            local data = {}
            data.multipleHeader = true
            data.isDestroy = source.isDestroy
            data.isKeep = source.isKeep
            data.selectedItem = selectedItem
            data.texture = self.treeexpicon
            data.collapsed = false -- FIXME
            data.sourceNum = i
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

        handleDismantleWatch(available, unavailable)

        for j = 1, #available do
            self.ingredientPanel:addItem(available[j].name, available[j])
        end
        for j = 1, #unavailable do
            self.ingredientPanel:addItem(unavailable[j].name, unavailable[j])
        end
    end
    -- endregion
end

function CHC_uses_recipepanel:refreshSkillPanel(recipe)
    self.skillPanel:clear()

    for i = 1, recipe.requiredSkillCount do
        local skill = recipe.recipeObj:getRequiredSkill(i - 1)
        local perk = PerkFactory.getPerk(skill:getPerk())
        local playerLevel = self.player and self.player:getPerkLevel(skill:getPerk()) or 0
        local perkName = perk and perk:getName() or skill:getPerk():name()

        self.skillPanel:addItem(perkName, { name = perkName, pLevel = playerLevel, rLevel = skill:getLevel() })
    end

    self.skillPanel:setHeight(math.min(3, recipe.requiredSkillCount) * self.skillPanel.itemheight)
end

function CHC_uses_recipepanel:refreshBooksPanel(recipe)
    self.booksPanel:clear()

    for i = 1, #self.manualsEntries do
        local item = self.manualsEntries[i]
        item.isKnown = recipe.isKnown
        self.booksPanel:addItem(item.displayName, item)
    end
    self.booksPanel:setHeight(math.min(3, #self.manualsEntries) * self.booksPanel.itemheight)
end

function CHC_uses_recipepanel:refreshEquipmentPanel(recipe)
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
end

-- endregion

-- region render

function CHC_uses_recipepanel:onResize()
    ISPanel.onResize(self)
    self.mainInfo:setWidth(self.width)
    -- self.statsList:setWidth(self.parent.headers.typeHeader.width - self.margin - self.statsList.x)
    --     self.statsList:setHeight(self.height - self.mainInfo.height - 4 * self.padY)
end

function CHC_uses_recipepanel:drawFavoriteStar(y, item, parent)
    local favoriteStar
    local favoriteAlpha = 0.9
    local favXPos = self.width - 30
    local isFav = CHC_main.playerModData[CHC_main.getFavItemModDataStr(item.item)] == true
    if item.index == self.mouseoverselected then
        local mouseX = self:getMouseX()
        if mouseX >= favXPos - 20 and mouseX <= favXPos + 20 then
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
        self:drawTexture(favoriteStar, favXPos,
            y + (item.height / 2 - favoriteStar:getHeight() / 2),
            favoriteAlpha, 1, 1, 1)
    end
end

function CHC_uses_recipepanel:drawIngredient(y, item, alt)
    if not self.recipepanel then
        self.recipepanel = self.parent.parent.parent
    end
    if self.recipepanel.fastListReturn(self, y) then return y + self.itemheight end
    if item.item.multipleHeader then
        local tex
        local r, g, b = 1, 1, 1
        if not item.item.available then
            r, g, b = 0.54, 0.54, 0.54
        end
        self:drawText(item.text, 12, y + 2, r, g, b, 1, self.font)
        if item.item.collapsed then
            tex = self.recipepanel.treecolicon
        else
            tex = self.recipepanel.treeexpicon
        end
        self:drawTexture(tex, 2, y + 2, 0.8)
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
        self.recipepanel.drawFavoriteStar(self, y, item, self.recipepanel)
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

    return y + self.itemheight
end

function CHC_uses_recipepanel:drawSkill(y, item, alt)
    if not self.recipepanel then
        self.recipepanel = self.parent.parent.parent
    end
    if self.recipepanel.fastListReturn(self, y) then return y + self.itemheight end

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
    if not self.recipepanel then
        self.recipepanel = self.parent.parent.parent
    end
    if self.recipepanel.fastListReturn(self, y) then return y + self.itemheight end
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
    self.recipepanel.drawFavoriteStar(self, y, item, self.recipepanel)
    --endregion

    self:drawRectBorder(0, y, self.width - 2, self.itemheight, ab, rb, gb, bb)

    return y + self.itemheight
end

function CHC_uses_recipepanel:drawEquipment(y, item, alt)
    if not self.recipepanel then
        self.recipepanel = self.parent.parent.parent
    end
    if self.recipepanel.fastListReturn(self, y) then return y + self.itemheight end

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
    self.recipepanel.drawFavoriteStar(self, y, item, self.recipepanel)
    --endregion

    return y + self.itemheight
end

function CHC_uses_recipepanel:render()
    ISPanel.render(self)

    if not self.selectedObj or not self.selectedObj.recipe then return end
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

    if self.needUpdateHeight then
        self.needUpdateHeight = false
        self.statsList.sectionMap[getText('IGUI_CraftUI_RequiredItems')]:calculateHeights()
    end
    local selectedItem = self.selectedObj

    -- region check if available

    if self.needRefreshIngredientPanel then
        self.needRefreshIngredientPanel = false
        self.containerList = self.parent.containerList
        local typesAvailable = self:getAvailableItemsType()
        self.needRefreshRecipeCounts = utils.areTablesDifferent(selectedItem.typesAvailable, typesAvailable)
        selectedItem.typesAvailable = typesAvailable
        if self.selectedObj.recipe.isSynthetic then
            selectedItem.available = false
            selectedItem.howManyCanCraft = 0
        elseif selectedItem.recipe.isEvolved then
            selectedItem.available = CHC_main.common.isEvolvedRecipeValid(selectedItem.recipe, self.containerList)
            selectedItem.howManyCanCraft = 0 -- evolved recipes aren't craftable (as normal recipes are)
        else
            selectedItem.available = RecipeManager.IsRecipeValid(selectedItem.recipe.recipe, self.player, nil,
                self.containerList)
            selectedItem.howManyCanCraft = RecipeManager.getNumberOfTimesRecipeCanBeDone(
                selectedItem.recipe.recipe, self.player,
                self.containerList, nil
            )
        end

        self:updateButtons(selectedItem)

        self:refreshIngredientPanel(selectedItem)
    end

    if self.needRefreshRecipeCounts then
        self.parent.needUpdateCounts = true
        self.needRefreshRecipeCounts = false
    end

    -- endregion
end

function CHC_uses_recipepanel:drawCraftButtons(x, y, item)
    --if not self.selectedObj then return 0 end
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

-- endregion

-- region logic

-- region event handlers


function CHC_uses_recipepanel:onRMBDownIngrPanel(x, y, item)
    local backRef = self.parent.parent.backRef
    local context = backRef.onRMBDownObjList(self, x, y, item)
    local row = self:rowAt(x, y)
    if not item then
        if row == -1 or not row then return end
        item = self.items[row]
        if not item then return end
        item = item.item
    end

    local function getItemsToAdd()
        local itemsToAdd = {}
        local itemsToAddMissing = {}
        for i = row + 1, #self.items do
            local _item = self.items[i].item
            if _item.multipleHeader then
                break
            end
            insert(itemsToAdd, _item.fullType)
            if (self.recipepanel.selectedObj.typesAvailable and
                not self.recipepanel.selectedObj.typesAvailable[_item.fullType]) then
                insert(itemsToAddMissing, _item.fullType)
            end
        end
        return itemsToAdd, itemsToAddMissing
    end

    local function addItems(_, items)
        local pInv = CHC_menu.CHC_window.player:getInventory()
        for i = 1, #items do
            pInv:AddItem(items[i])
        end
    end

    if not item.fullType then
        if item.multipleHeader and getDebug() then
            local itemsToAdd, itemsToAddMissing = getItemsToAdd()

            if not utils.empty(itemsToAdd) then
                context:addOption(sformat("Add all (%d)", #itemsToAdd), self, addItems, itemsToAdd)
            end
            if not utils.empty(itemsToAddMissing) then
                context:addOption(sformat("Add missing (%d)", #itemsToAddMissing), self, addItems, itemsToAddMissing)
            end
        else
            return
        end
    end
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
    if not recipe_panel.selectedObj then return end
    recipe_panel.parent.onRMBDown(recipe_panel, nil, nil, recipe_panel.selectedObj.recipe.recipeData.result)
end

function CHC_uses_recipepanel:onIngredientMouseDown(item)
    if not item then return end
    local x = self:getMouseX()
    local favXPos = self.width - 50

    if not item.multipleHeader and (x >= favXPos) then
        local isFav = self.modData[CHC_main.getFavItemModDataStr(item)] == true
        isFav = not isFav
        self.modData[CHC_main.getFavItemModDataStr(item)] = isFav or nil
        self.backRef.updateQueue:push({
            targetView = 'fav_items',
            actions = { 'needUpdateFavorites', 'needUpdateObjects' }
        })
    end
    if item.multipleHeader then
        item.collapsed = not item.collapsed
        self.needUpdateHeight = true
    end
end

-- endregion

-- region crafting
function CHC_uses_recipepanel:transferItems()
    local result = {}
    local selectedItem = self.selectedObj;
    local items = RecipeManager.getAvailableItemsNeeded(selectedItem.recipeObj, self.player, self.containerList, nil, nil);
    if items:isEmpty() then return result end
    for i = 1, items:size() do
        local item = items:get(i - 1)
        insert(result, item)
        if not selectedItem.recipeObj:isCanBeDoneFromFloor() then
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
    local selectedItem = self.selectedObj;
    -- if selectedItem.evolved then return end
    if not RecipeManager.IsRecipeValid(selectedItem.recipeObj, self.player, nil, self.containerList) then return end
    if not getPlayer() then return end
    local itemsUsed = self:transferItems()
    if #itemsUsed == 0 then
        -- self:refresh()
        return
    end

    local returnToContainer = {}
    local container = itemsUsed[1]:getContainer()
    if not selectedItem.recipeObj:isCanBeDoneFromFloor() then
        container = self.player:getInventory()
        for i = 1, #itemsUsed do
            local item = itemsUsed[i]
            if item:getContainer() ~= self.player:getInventory() then
                insert(returnToContainer, item)
            end
        end
    end

    local action = ISCraftAction:new(self.player, itemsUsed[1],
        selectedItem.recipeObj:getTimeToMake(),
        selectedItem.recipeObj, container, self.containerList)
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

function CHC_uses_recipepanel:addRandomMenu()
    local context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())

    local typesAvailable = self.selectedObj.typesAvailable
    local typesToShow = {}
    local spices = {}

    for fullType, _ in pairs(typesAvailable) do
        local item = CHC_main.items[fullType]
        if item then
            local foodType = item.item:IsFood() and item.item:getFoodType()
            if foodType then
                if foodType == "NoExplicit" then
                    insert(spices, item)
                else
                    if not typesToShow[foodType] then typesToShow[foodType] = {} end
                    insert(typesToShow[foodType], item)
                end
            else
                for i = 1, #self.sourceSpice do
                    if self.sourceSpice[i].fullType == fullType then
                        insert(spices, item)
                    end
                end
            end
        end
    end

    local types = {}
    for foodType, items in pairs(typesToShow) do
        insert(types, { name = foodType, items = items })
    end

    tsort(types, function(a, b) return not ssort(a.name, b.name) end)
    tsort(spices, function(a, b) return not ssort(a.name, b.name) end)

    -- region ingredient
    local ingredientMenu = context:addOption('Ingredient', nil, nil)
    local ingredientSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(ingredientMenu, ingredientSubMenu)
    ingredientSubMenu:addOption('Random (All)', self, CHC_uses_recipepanel.addRandomCategory, types, nil, true)
    ingredientSubMenu:addOption('Random (One)', self, CHC_uses_recipepanel.addRandomCategory, types)
    for i = 1, #types do
        local optName = getText("ContextMenu_FoodType_" .. types[i].name) .. " (" .. #types[i].items .. ")"
        local opt = ingredientSubMenu:addOption(optName, self, CHC_uses_recipepanel.addRandomIngredient, types[i].items)

        if #types[i].items == 1 then
            local item = types[i].items[1]
            local val = item.displayName .. " x " .. round(typesAvailable[item.fullType], 0)
            opt.name = getText("ContextMenu_FoodType_" .. types[i].name) .. " (" .. val .. ")"
        else
            local ingredientCategorySubMenu = ISContextMenu:getNew(ingredientSubMenu)
            ingredientSubMenu:addSubMenu(opt, ingredientCategorySubMenu)
            for j = 1, #types[i].items do
                local item = types[i].items[j]
                ingredientCategorySubMenu:addOption(item.displayName .. " x " .. round(typesAvailable[item.fullType], 0),
                    self, CHC_uses_recipepanel.addItemInEvolvedRecipe, item)
            end
        end
    end

    -- endregion

    -- region condiment
    local condimentMenu = context:addOption('Condiment', nil, nil)
    local condimentSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(condimentMenu, condimentSubMenu)
    condimentSubMenu:addOption('Random (All)', self, CHC_uses_recipepanel.addRandomCategory, spices, nil, true)
    condimentSubMenu:addOption('Random (One)', self, CHC_uses_recipepanel.addRandomIngredient, spices)
    for i = 1, #spices do
        local opt = condimentSubMenu:addOption(
            spices[i].displayName .. " x " .. round(typesAvailable[spices[i].fullType], 0), self,
            CHC_uses_recipepanel.addItemInEvolvedRecipe, spices[i])
    end
    -- endregion
end

function CHC_uses_recipepanel:addRandomCategory(options, func, all)
    -- TODO: ISInventoryPaneContextMenu.getRealEvolvedItemUse
    if all then
        local a = self.selectedObj
        -- selectSpecificMenu
        df:df()
        -- getItemsList
        -- get remaining slots
    end
    local opt = options[ZombRand(1, #options + 1)]
    if opt.items then
        self.addRandomIngredient(self, opt.items, func)
    else
        self.addItemInEvolvedRecipe(opt)
    end
end

function CHC_uses_recipepanel:addRandomIngredient(options, func)
    func = func or self.addItemInEvolvedRecipe
    local opt = options[ZombRand(1, #options + 1)]
    func(self, opt)
end

function CHC_uses_recipepanel:addItemInEvolvedRecipe(item)
    --TODO
    print(item.displayName)
end

function CHC_uses_recipepanel:selectSpecificMenu()
    local context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())

    local max = self.selectedObj.recipe.recipeData.maxItems
    local choices = self.evolvedChoices
    for i = 1, #choices do
        local ch = choices[i]
        local optName = ch.itemObj.displayName
        local optText
        local used = 0
        -- if used == max can only add spices

        if ch.extraItems then
            used = #ch.extraItems
            local contains = { "Contains:" }
            for c = 1, used do
                insert(contains, "- " .. "<IMAGE:" .. ch.extraItems[c].texture:getName() .. ">" .. ch.extraItems[c]
                    .displayName)
            end
            optText = table.concat(contains, '\n')
        end
        optName = optName .. " (" .. used .. "/" .. max .. ")"
        local opt = context:addOption(optName, self, nil)
        opt.iconTexture = ch.itemObj.texture
        if optText then
            CHC_main.common.setTooltipToCtx(opt, optText)
        end
    end
end

-- endregion

function CHC_uses_recipepanel:updateButtons(obj)
    local statsH = self.height - self.mainInfo.height - 3 * self.padY
    if obj.available then
        if obj.recipe.isEvolved then
            -- local items = CHC_main.common.getNearbyItems(self.containerList) -- getExtraItems
            -- getEvolvedRecipe
            local baseItemToCheck = obj.recipe.recipeData.baseItem
            local baseItemToCheck2 = obj.recipe.recipeData.fullResultItem
            local items = CHC_main.common.getNearbyItems(self.containerList, { baseItemToCheck, baseItemToCheck2 })
            self.evolvedChoices = items
            if not utils.empty(items) and #items > 1 then
                self.selectSpecificButton:setX(self.addRandomButton.x + self.addRandomButton.width + 5)
                self.selectSpecificButton:setVisible(true)
            else
                self.selectSpecificButton:setVisible(false)
            end
            self.addRandomButton:setVisible(true)
            self.craftOneButton:setVisible(false)
            self.craftAllButton:setVisible(false)
        else
            self.evolvedChoices = nil
            self.selectSpecificButton:setVisible(false)
            self.addRandomButton:setVisible(false)
            self.craftOneButton:setVisible(true)
            if obj.howManyCanCraft > 1 then
                self.craftAllButton:setTitle(getText("IGUI_CraftUI_ButtonCraftAllCount",
                    obj.howManyCanCraft))
                self.craftAllButton:setX(self.craftOneButton.x + self.craftOneButton.width + 5)
                self.craftAllButton:setWidth(10 +
                    getTextManager():MeasureStringX(UIFont.Small, self.craftAllButton.title))
                self.craftAllButton:setVisible(true)
            else
                self.craftAllButton:setVisible(false)
            end
        end
        -- draw buttons
        self.statsList:setY(self.addRandomButton.y + self.addRandomButton.height + self.padY)
        statsH = statsH - self.addRandomButton.height - self.padY - 2
    else
        self.selectSpecificButton:setVisible(false)
        self.addRandomButton:setVisible(false)
        self.craftOneButton:setVisible(false)
        self.craftAllButton:setVisible(false)
        self.statsList:setY(self.mainInfo.y + self.mainInfo:getBottom() + self.padY)
    end
    self.statsList:setHeight(statsH)
end

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
    o.backRef = args.backRef
    local player = getPlayer()
    o.player = player
    o.character = player
    o.playerNum = player and player:getPlayerNum() or -1

    o.needRefreshIngredientPanel = true
    o.needRefreshRecipeCounts = true
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateHeight = false

    o.recipe = nil
    o.manualsSize = 0
    o.manualsEntries = nil
    o.modData = CHC_main.playerModData
    o.lastAvailableTypes = {}

    o.anchorTop = true
    o.anchorBottom = true
    o.anchorLeft = true
    o.anchorRight = true

    o.bh = nil

    o.itemFavoriteStar = getTexture('media/textures/CHC_item_favorite_star.png')
    o.itemFavCheckedTex = getTexture('media/textures/CHC_item_favorite_star_checked.png')
    o.itemFavNotCheckedTex = getTexture('media/textures/CHC_item_favorite_star_outline.png')
    o.treeexpicon = getTexture("media/ui/TreeExpanded.png")
    o.treecolicon = getTexture("media/ui/TreeCollapsed.png")
    return o;
end
