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

-- TODO: explore folding for item/recipe list (left side)

-- check out NotlocScrollView for scrollable panel example

CHC_uses_recipepanel = ISPanel:derive('CHC_uses_recipepanel')

-- region create
local blockHiddenStateSelector = {
    "all",
    "av",
    "un"
}

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
    self.mainInfoNameLine = ISPanel:new(0, 0, self.mainInfo.width - 2 * self.margin, fntm + 2 * mainPadY)
    self.mainInfoNameLine.anchorRight = false
    local minlc = 0.45
    self.mainInfoNameLine.backgroundColor = { r = minlc, g = minlc, b = minlc, a = 0.9 }
    self.mainInfoNameLine:initialise()

    self.mainName = ISLabelWithIcon:new(self.margin, mainY, fhMedium, nil, mr, mg, mb, ma, mainPriFont, true)
    self.mainName:initialise()

    local timeText = "100000"
    local timeX = 16 + getTextManager():MeasureStringX(mainSecFont, timeText)
    self.mainTime = ISLabelWithIcon:new(self.width - timeX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainTime.anchorLeft = false
    self.mainTime.anchorRight = true
    self.mainTime:initialise()
    self.mainTime:setIcon(getTexture('media/textures/CHC_recipe_required_time.png'))
    self.mainTime.iconSize = 24
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

    self.mainCat = ISLabelWithIcon:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainCat:initialise()
    self.mainCat:setIcon(getTexture('media/textures/CHC_recipepanel_category.png'))
    self.mainCat.origTooltip = getText("IGUI_invpanel_Category")
    self.mainCat:setTooltip(self.mainCat.origTooltip)
    mainY = mainY + self.mainCat.height + mainPadY

    self.mainRes = ISLabelWithIcon:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainRes:initialise()
    self.mainRes:setIcon(getTexture('media/textures/CHC_recipepanel_output.png'))
    self.mainRes.origTooltip = getText("IGUI_RecipeResult")
    self.mainRes:setTooltip(self.mainRes.origTooltip)
    mainY = mainY + self.mainRes.height + mainPadY

    self.mainMod = ISLabelWithIcon:new(mainX, mainY, fhSmall, nil, mr, mg, mb, ma, mainSecFont, true)
    self.mainMod:initialise()
    self.mainMod:setIcon(getTexture('media/textures/CHC_mod.png'))
    self.mainMod:setTooltip(getText("IGUI_mod_chc"))
    mainY = mainY + self.mainMod.height + mainPadY

    local mainExtraW = 300
    self.mainExtraData = ISPanel:new(self.mainInfo.width - mainExtraW - self.margin, self.mainImg.y, mainExtraW,
        self.mainImg.height)
    self.mainExtraData.borderColor = self.mainImg.borderColor
    -- self.mainExtraData.anchorLeft = false
    -- self.mainExtraData.anchorRight = true
    self.mainExtraData:initialise()
    self.mainExtraData:setVisible(false)

    self.mainName.maxWidth = self.mainInfoNameLine.width - self.mainTime.width - 10

    -- endregion

    self.mainInfo:setHeight(mainY + mainPadY)

    self.mainInfo:addChild(self.mainInfoNameLine)
    self.mainInfo:addChild(self.mainName)
    self.mainInfo:addChild(self.mainTime)
    self.mainInfo:addChild(self.mainImg)
    self.mainInfo:addChild(self.mainCat)
    self.mainInfo:addChild(self.mainRes)
    self.mainInfo:addChild(self.mainMod)
    self.mainInfo:addChild(self.mainExtraData)

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
    self.addRandomButton.title = getText("IGUI_PlayerStats_Add") .. "..."
    self.addRandomButton:setWidth(10 + getTextManager():MeasureStringX(UIFont.Small, self.addRandomButton.title))
    self.addRandomButton:setVisible(false)

    self.selectSpecificButton = ISButton:new(btnInfo.x, btnInfo.y, btnInfo.w, btnInfo.h, nil, btnInfo.clicktgt,
        self.selectSpecificMenu)
    self.selectSpecificButton:initialise()
    self.selectSpecificButton.title = getText("IGUI_Evolved_SelectSpecific") .. "..."
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
        x = self.margin,
        y = y,
        w = self.width - 2 * self.margin,
        h = self.height - self.mainInfo.height - 4 * self.padY,
        backRef = self.backRef,
    }
    stats_args.origH = stats_args.h

    self.statsList = CHC_sectioned_panel:new(stats_args)
    self.statsList:initialise()
    self.statsList:instantiate()
    self.statsList.borderColor.a = 0
    self.statsList:setAnchorRight(true)
    self.statsList:setAnchorBottom(true)
    self.statsList.maintainHeight = false
    self.statsList:setScrollChildren(true)
    self.statsList:addScrollBars()
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
    self.ingredientPanel.drawBorder = false
    self.ingredientPanel.borderColor = listBorderColor
    self.ingredientPanel.vscroll.borderColor = listBorderColor
    self.ingredientPanel:setVisible(false)
    -- endregion

    -- region skills
    self.skillPanel = ISScrollingListBox:new(1, 1, self.width, 1)
    self.skillPanel:initialise()
    self.skillPanel:instantiate()
    self.skillPanel.onRightMouseDown = self.onRMBDownIngrPanel
    self.skillPanel:setOnMouseDownFunction(self, self.onIngredientMouseDown)
    self.skillPanel.itemheight = fhSmall + 2 * self.itemMargin
    self.skillPanel.doDrawItem = self.drawSkill
    self.skillPanel.yScroll = 0
    self.skillPanel.drawBorder = false
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
    self.booksPanel.drawBorder = false
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
    self.equipmentPanel.doDrawItem = self.drawEquipment
    self.equipmentPanel.yScroll = 0
    self.equipmentPanel.drawBorder = false
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
    elseif recipe.isEvolved and self.evolvedSelected then
        res.tooltip = self:getTooltipForEvolvedItem(self.evolvedSelected)
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
    if self.evolvedSelected then
        self.evolvedSelected = nil
        self.evolvedOpt = nil
    end
    self.evolvedSelectedIx = 1
    self.collapsedData = {}
    self.blockStateData = {}
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
        obj.timeToMake = 0 -- FIXME
        obj.howManyCanCraft = 0
        obj.needToBeLearn = false
    elseif recipe.isEvolved then
        obj.available = CHC_main.common.isEvolvedRecipeValid(recipe, self.containerList)
        obj.maxItems = recipe.recipeData.maxItems
        obj.isEvolved = true
        obj.requiredSkillCount = 0
        obj.isKnown = true
        obj.nearItem = nil
        obj.timeToMake = (70 - self.player:getPerkLevel(Perks.Cooking))
        obj.howManyCanCraft = 0
        obj.needToBeLearn = false

        self:getEvolvedChoices(obj, self.containerList)
    else
        obj.available = RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.containerList)
        obj.requiredSkillCount = recipe.recipeData.requiredSkillCount
        obj.isKnown = self.player:isRecipeKnown(recipe.recipe)
        obj.nearItem = recipe.recipeData.nearItem
        obj.timeToMake = recipe.recipe:getTimeToMake()
        obj.howManyCanCraft = RecipeManager.getNumberOfTimesRecipeCanBeDone(
            recipe.recipe, self.player,
            self.containerList, nil
        )
        obj.needToBeLearn = recipe.recipe:needToBeLearn()
    end

    self:updateMainInfo(obj)

    obj.hydrocraftEquipment = recipe.recipeData.hydroFurniture
    obj.cecEquipment = recipe.recipeData.CECFurniture

    obj.sources = self:getSources(recipe)

    self.selectedObj = obj

    if not recipe.isEvolved then
        self.manualsEntries = CHC_main.itemsManuals[recipe.recipeData.originalName]
        if self.manualsEntries ~= nil then
            self.manualsSize = #self.manualsEntries
        end
        self.freeFromTraits = CHC_main.freeRecipesTraits[recipe.recipeData.originalName]
        if self.freeFromTraits then
            self.manualsSize = (self.manualsSize or 0) + #self.freeFromTraits
        end
        self.freeFromProfessions = CHC_main.freeRecipesProfessions[recipe.recipeData.originalName]
        if self.freeFromProfessions then
            self.manualsSize = (self.manualsSize or 0) + #self.freeFromProfessions
        end
    end

    local statsListOpenedSections = self.statsList.expandedSections
    self.statsList:clear()

    self:updateButtons(obj)

    self:refreshIngredientPanel(obj)
    self.statsList:addSection(self.ingredientPanel, getText('IGUI_CraftUI_RequiredItems'))

    if obj.requiredSkillCount > 0 and not utils.empty(obj.recipe.recipeData.requiredSkills) then
        self:refreshSkillPanel(obj)
        self.statsList:addSection(self.skillPanel, getText('IGUI_CraftUI_RequiredSkills'))
    end

    if (self.manualsEntries and obj.needToBeLearn) or self.freeFromTraits or self.freeFromProfessions then
        self:refreshBooksPanel(obj)
        self.statsList:addSection(self.booksPanel, getText('UI_recipe_panel_required_book') .. ':')
    end

    if obj.hydrocraftEquipment or obj.cecEquipment or obj.nearItem then
        self:refreshEquipmentPanel(obj)
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
                            count = round(-item:getHungerChange() * 100, 2)
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
                            count = round(-item:getHungerChange() * 100, 2)
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
    local c4 = self.selectedObj.recipe.isEvolved
    if c1 and c2 and (c3 and not c4) then
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
    local recipeData = self.selectedObj.recipe.recipeData
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
            local evolvedState = true
            if selectedItem.isEvolved and self.evolvedSelected then
                local isSpice = CHC_main.items[item.fullType].propsMap["Spice"]
                data.isSpice = isSpice
                local usedSpice = self.evolvedSelected.extraSpicesMap and
                    self.evolvedSelected.extraSpicesMap[item.fullType]

                local used = self.evolvedSelected.extraItems and #self.evolvedSelected.extraItems
                if not used then used = 0 end
                local max = self.selectedObj.recipe.recipeData.maxItems
                if (used < max and not isSpice) or (used ~= 0 and isSpice and not usedSpice) then
                    evolvedState = true

                    if utils.any({ recipeData.baseItem, recipeData.fullResultItem }, item.fullType) then
                        data.isEvolvedBaseItem = true
                    end
                else
                    evolvedState = false
                end
            end
            local numTypes = selectedItem.typesAvailable[item.fullType]
            if selectedItem.isEvolved and not evolvedState then
                data.available = false
                insert(unavailable, data)
            elseif selectedItem.typesAvailable and (not numTypes or numTypes < item.count) then
                data.available = false
                insert(unavailable, data)
            else
                data.available = true
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
            if not self.collapsedData[i] then
                self.collapsedData[i] = false
            end
            data.collapsed = self.collapsedData[i]
            if not self.blockStateData[i] then
                self.blockStateData[i] = blockHiddenStateSelector[1]
            end
            data.blockHiddenState = self.blockStateData[i]
            data.sourceNum = i
            data.available = #available > 0
            data.totalNum = #available + #unavailable
            data.availableNum = #available
            data.unavailableNum = #unavailable
            local txt = getText('IGUI_CraftUI_OneOf')
            if data.isDestroy then
                txt = txt .. ' (D) '
            end
            if data.isKeep then
                txt = txt .. ' (K) '
            end
            txt = txt .. ' (' .. #available .. '/' .. #available + #unavailable .. ') '
            self.ingredientPanel:addItem(txt, data)

            if data.availableNum == data.totalNum or data.unavailableNum == data.totalNum then
                self.blockStateData[i] = blockHiddenStateSelector[1]
                data.blockHiddenState = self.blockStateData[i]
                data.blockHiddenStateLocked = true
            end
            data.isBlockHidden = data.blockHiddenState ~= blockHiddenStateSelector[1]
        end

        -- handleDismantleWatch(available, unavailable) -- FIXME refactor?

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
        local perkObj = perk and CHC_main.skillsMap[perk:getId()]

        if perkObj then
            local item = copyTable(perkObj)
            item.pLevel = playerLevel
            item.rLevel = skill:getLevel()
            self.skillPanel:addItem(item.name, item)
        end
    end

    self.skillPanel:setHeight(math.min(3, recipe.requiredSkillCount) * self.skillPanel.itemheight)
end

function CHC_uses_recipepanel:refreshBooksPanel(recipe)
    self.booksPanel:clear()
    local numEntries = 0

    if self.manualsEntries then
        for i = 1, #self.manualsEntries do
            local item = self.manualsEntries[i]
            item.isKnown = recipe.isKnown
            item.drawFavStar = true
            self.booksPanel:addItem(item.displayName, item)
        end
        numEntries = numEntries + #self.manualsEntries
    end
    if self.freeFromTraits then
        for i = 1, #self.freeFromTraits do
            local item = self.freeFromTraits[i]
            item.isTrait = true
            item.isKnown = CHC_menu.player:HasTrait(item.type) -- TODO avoid re-calculation
            item.drawFavStar = true
            self.booksPanel:addItem(item.displayName, item)
        end
        numEntries = numEntries + #self.freeFromTraits
    else
        self.freeFromTraits = nil
    end

    if self.freeFromProfessions then
        for i = 1, #self.freeFromProfessions do
            local item = self.freeFromProfessions[i]
            item.isTrait = true
            item.isKnown = CHC_menu.player:getDescriptor():getProfession() == item.type -- TODO avoid re-calculation
            item.drawFavStar = true
            self.booksPanel:addItem(item.displayName, item)
        end
        numEntries = numEntries + #self.freeFromProfessions
    else
        self.freeFromProfessions = nil
    end

    self.booksPanel:setHeight(math.min(3, numEntries) * self.booksPanel.itemheight)
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

function CHC_uses_recipepanel:updateMainInfo(obj)
    local recipe = obj.recipe
    self.evolvedSelected = nil
    self.mainExtraData:setVisible(false)
    self.mainExtraData:clearChildren()

    local recipeName = recipe.recipe:getName()
    if recipe.isEvolved then
        local used = 0
        local max = recipe.recipeData.maxItems
        local ch
        if self.evolvedOpt then
            ch = self.evolvedOpt
        elseif not utils.empty(self.evolvedChoices) then
            ch = self.evolvedChoices[1]
        else
            self:getEvolvedChoices(obj, self.containerList)
            ch = self.evolvedChoices[1]
        end
        if ch then
            self.evolvedSelected = ch
            if ch.extraItems then
                used = #ch.extraItems
                recipeName = ch.displayNameExtra
            end
            recipeName = recipeName .. " (" .. used .. "/" .. max .. ")"


            -- region food data
            -- self.origFoodData = nil
            local foodData = self:getFoodData(ch)
            self:updateExtraData(foodData)
            -- self.origFoodData = copyTable(ch.foodData)
            if not utils.empty(self.mainExtraData.children) then
                self.mainExtraData:setVisible(true)
            end
            -- endregion
        end
    end

    self.mainName:setName(recipeName, true)
    self.mainName:setTooltip(nil)

    self.mainTime:setName(tostring(obj.timeToMake), true)
    self.mainTime:setX(self.mainInfoNameLine.width - self.mainTime.width - self.margin)
    self.mainTime:setTooltip(luautils.split(getText('IGUI_CraftUI_RequiredTime', 0), ':')[1])
    self.mainImg:setTooltip(nil)

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

        self.mainRes:setName(resultData.itemName, true)
        self.mainRes:setTooltip(self.mainRes.origTooltip)

        if resultItem.modname and not resultItem.isVanilla then
            local c = { r = 0.392, g = 0.584, b = 0.929 } -- CornFlowerBlue
            self.mainMod:setName(resultItem.modname, true)
            self.mainMod:setColor(c.r, c.g, c.b)
        else
            self.mainMod:setName(nil)
        end
        self.mainMod:setVisible(self.mainMod.name ~= nil)
    end

    local catName = getTextOrNull('IGUI_CraftCategory_' .. recipe.category) or recipe.category
    self.mainCat:setName(catName, true)
    self.mainCat:setTooltip(self.mainCat.origTooltip)


    local maxY = self.mainMod.y + self.mainMod.height + 2
    self.mainInfo:setHeight(math.max(74, maxY))

    self:handleOverflow(self.mainName, self.mainInfoNameLine.width - self.mainTime.width - 10)
    if recipe.isEvolved and self.mainExtraData:isVisible() then
        local maxW = self.mainInfo.width - self.mainImg.width - self.mainExtraData.width - 2 * self.margin
        self:handleOverflow(self.mainCat, maxW)
        self:handleOverflow(self.mainRes, maxW)
        if self.mainMod.name then
            self:handleOverflow(self.mainMod, maxW)
        end
    end
    self.mainInfo:setVisible(true)
end

function CHC_uses_recipepanel:updateExtraData(foodData)
    local function btnRender(s)
        s:drawTextureScaledAspect(s.image,
            (s.width / 2) - (s.iconSize / 2),
            2, s.iconSize, s.iconSize, 1)
        s:drawText(s.title, s.width / 2 - s.textW / 2,
            s.iconSize - 3,
            s.textColor.r, s.textColor.g,
            s.textColor.b, s.textColor.a, s.font)
    end

    if not foodData then return end
    local margin = 5
    local innerMar = 3
    local padding = 2
    local x = margin
    local y = margin
    local w = 24 + 2 * padding
    local h = self.mainExtraData.height - 2 * margin

    local numBtn = 0
    for i = 1, #foodData do
        local item = foodData[i]
        if not item.isCal then
            local btn = ISButton:new(x, y, w, h, item.value)
            x = x + w + innerMar
            btn.borderColor = { r = 0.18, g = 0.18, b = 0.18, a = 1 }
            btn.textColor = item.color
            btn.iconSize = 24
            btn.margin = margin
            btn:initialise()
            btn.width = w
            btn.textW = getTextManager():MeasureStringX(btn.font, btn.title)
            btn:setImage(item.icon)
            local tooltip = item.title
            if item.valPrecise then tooltip = tooltip .. " <SPACE> (" .. item.valPrecise .. ")" end
            btn:setTooltip(tooltip)
            btn.render = btnRender

            self.mainExtraData:addChild(btn)
            numBtn = numBtn + 1
        end
    end

    local mainExtraW = 2 * margin + math.min(8, numBtn) * (w + innerMar) - innerMar
    self.mainExtraData:setWidth(mainExtraW)
    self.mainExtraData:setX(self.mainInfo.width - mainExtraW - 2 * self.margin)
end

-- endregion

-- region render

function CHC_uses_recipepanel:onResize()
    ISPanel.onResize(self)
    self.mainInfo:setWidth(self.parent.headers.typeHeader.width)

    self.mainInfoNameLine:setWidth(self.mainInfo.width - 2 * self.margin)
    self.mainExtraData:setX(self.mainInfo.width - self.mainExtraData.width - 2 * self.margin)
    self.statsList:setWidth(self.parent.headers.typeHeader.width - self.margin - self.statsList.x)
    local statsH = self.height - self.mainInfo.height - 5 * self.padY
    if self.buttonVisible then
        statsH = statsH - self.craftOneButton.height - self.padY
    end
    self.statsList:setHeight(statsH)

    self:handleOverflow(self.mainName, self.mainInfoNameLine.width - self.mainTime.width - 10)
    if not self.selectedObj then return end
    if self.selectedObj.recipe.isEvolved and self.mainExtraData:isVisible() then
        local maxW = self.mainInfo.width - self.mainImg.width - self.mainExtraData.width - 2 * self.margin
        self:handleOverflow(self.mainCat, maxW)
        self:handleOverflow(self.mainRes, maxW)
        if self.mainMod.name then
            self:handleOverflow(self.mainMod, maxW)
        end
    end
end

function CHC_uses_recipepanel:drawFavoriteStar(y, item, parent)
    local favoriteStar
    local favoriteAlpha = 0.9
    local favXPos = self.width - 30
    local itemObj = CHC_main.items[item.item.fullType]
    if not itemObj then return end
    local isFav = itemObj.favorite
    if item.index == self.mouseoverselected then
        local mouseX = self:getMouseX()
        if mouseX >= favXPos - 5 and mouseX <= favXPos + 16 then
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

function CHC_uses_recipepanel:drawAddToEvolved(y, item, parent, dx)
    local addXPos = 2
    local addW = dx - 2
    local icon
    if item.index == self.mouseoverselected then
        local mouseX = self:getMouseX()
        if mouseX >= addXPos and mouseX <= addW then -- hovered over
            icon = parent.addEvolvedHoveredTex
        else
            icon = parent.addEvolvedTex
        end
    end
    if icon then
        self:drawTextureScaledAspect(icon, addXPos, y + (item.height - 16) / 2, 16, 16, 1)
    end
end

function CHC_uses_recipepanel:drawIngredient(y, item, alt)
    if not self.recipepanel then
        self.recipepanel = self.parent.parent.parent
    end
    if self.recipepanel.fastListReturn(self, y) then return y + self.itemheight end
    if item.item.multipleHeader then
        --region One of: text
        local r, g, b = 1, 1, 1
        if not item.item.available then
            r, g, b = 0.54, 0.54, 0.54
        end
        self:drawText(item.text, 12, y + 2, r, g, b, 1, self.font)
        --endregion

        -- region fold icon
        local tex
        if item.item.collapsed then
            tex = self.recipepanel.treecolicon
        else
            tex = self.recipepanel.treeexpicon
        end
        self:drawTexture(tex, 2, y + 2, 0.8)
        -- endregion

        --region show/hide unavailable icon
        local hideTex
        if item.item.blockHiddenState == "av" then
            hideTex = self.recipepanel.blockAVIcon
        elseif item.item.blockHiddenState == "un" then
            hideTex = self.recipepanel.blockUNIcon
        elseif item.item.blockHiddenState == "all" then
            hideTex = self.recipepanel.blockAllIcon
        else
            error("Unknown blockHiddenState")
        end
        if not item.item.blockHiddenStateLocked then
            local hoveredX = item.index == self.mouseoverselected
            local a = 0.5
            local x = self.width - 17 - 16
            local mouseX = self:getMouseX()
            if hoveredX and mouseX >= x then
                a = 1
            end

            if hoveredX or item.item.blockHiddenState ~= "all" then
                self:drawTextureScaledAspect(hideTex, x, y, item.height - 2,
                    item.height - 2, a)
            end
        end
        -- endregion
    else
        local r, g, b
        local r2, g2, b2, a2
        local typesAvailable = item.item.selectedItem.typesAvailable
        local numTypes = typesAvailable[item.item.fullType]
        local lowAmount = (
            not numTypes or numTypes < item.item.count)
        if (typesAvailable and lowAmount) or not item.item.available then
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

        if self.recipepanel.evolvedSelected and item.item.available and not item.item.isEvolvedBaseItem then
            self.recipepanel.drawAddToEvolved(self, y, item, self.recipepanel, dx)
        end

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

    local text = item.text .. ': ' .. tostring(item.item.pLevel) .. ' / ' .. tostring(item.item.rLevel);
    local r, g, b, a = 1, 1, 1, 0.9
    local rb, gb, bb, ab = 0.1, 0.1, 0.1, 1

    if item.item.pLevel < item.item.rLevel then
        g, b = 0, 0
    else
        a = 0.7
    end
    self:drawText(text, 15, y, r, g, b, a, UIFont.Small)
    self.recipepanel.drawFavoriteStar(self, y, item, self.recipepanel)
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
    if item.item.isTrait then
        self:drawText(item.item.displayName, tX, tY, r, g, b, a,
            UIFont.Small)
    else
        self:drawText(item.item.displayName, tX, tY, r, g, b, a, UIFont.Small)
    end

    --region favorite handler
    if item.item.drawFavStar then
        self.recipepanel.drawFavoriteStar(self, y, item, self.recipepanel)
    end
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
                self:drawTextureScaled(item.item.texture, tX, ttY, tW, tH, 1)
            else
                self:drawTextureScaledAspect(item.item.texture, tX, ttY, tW, tH, a, 1, 1, 1)
            end
            tX = tX + tW + 5
        end
        self:drawText(item.item.name, tX, tY, r, g, b, a, UIFont.Small)
    end

    if not isComplex then
        self:drawText(' - ' .. item.item, x + 15, y, 1, 1, 1, a, UIFont.Small)
    end

    --region favorite handler
    if isComplex then
        self.recipepanel.drawFavoriteStar(self, y, item, self.recipepanel)
    end
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

        self:getEvolvedChoices(selectedItem, self.containerList)
        self:updateMainInfo(selectedItem)
        self:updateButtons(selectedItem)

        self:refreshIngredientPanel(selectedItem)
    end

    if self.needRefreshRecipeCounts then
        self.parent.needUpdateCounts = true
        self.needRefreshRecipeCounts = false
    end

    -- endregion
end

-- endregion

-- region logic

-- region event handlers

-- function CHC_uses_recipepanel:onIngredientMouseMove(x, y)
--     local ix = self.mouseoverselected
--     local panel = self.recipepanel

--     ISScrollingListBox.onMouseMove(self, x, y)
--     if not panel.evolvedSelected then return end
--     if not panel.evolvedSelected.foodData then return end
--     if ix == self.mouseoverselected then return end

--     local item = self.items[self.mouseoverselected]
--     local recipeData = item.item and item.item.recipe and item.item.recipe.recipeData
--     local origFoodData = panel.origFoodData
--     if ix == -1 or
--         item.item.multipleHeader or
--         not item.item.available or
--         (item.item.fullType and
--             utils.any({ recipeData.baseItem, recipeData.fullResultItem }, item.item.fullType)) then
--         local foodData = CHC_uses_recipepanel.getFoodData(panel,
--             { item = panel.evolvedSelected.item, foodData = origFoodData })
--         panel.mainExtraData:setVisible(false)
--         panel.mainExtraData:clearChildren()
--         CHC_uses_recipepanel.updateExtraData(panel, foodData)
--         panel.mainExtraData:setVisible(true)
--         return
--     end
--     local concreteItem = CHC_main.common.getConcreteItem(panel.containerList, item.item.fullType)
--     if not concreteItem then return end
--     local concreteBaseItem = CHC_main.common.getConcreteItem(panel.containerList, panel.evolvedSelected.itemObj.fullType)
--     local addedFoodData
--     if item.item.isSpice then
--         addedFoodData = CHC_main.common.getFoodDataSpice(
--             concreteBaseItem,
--             concreteItem,
--             item.item.selectedItem.recipeObj,
--             panel.player:getPerkLevel(Perks.Cooking)
--         )
--     else
--         addedFoodData = CHC_main.common.getFoodData(concreteItem)
--     end

--     local newFoodData = {}
--     for key, value in pairs(addedFoodData.foodData) do
--         newFoodData[key] = copyTable(origFoodData[key])
--         newFoodData[key].val = origFoodData[key].val + value.val
--         if value.valPrecise then
--             newFoodData[key].valPrecise = origFoodData[key].valPrecise + value.valPrecise
--         end
--     end
--     local foodData = CHC_uses_recipepanel.getFoodData(panel,
--         { item = panel.evolvedSelected.item, foodData = newFoodData })
--     panel.mainExtraData:setVisible(false)
--     panel.mainExtraData:clearChildren()
--     CHC_uses_recipepanel.updateExtraData(panel, foodData)
--     panel.mainExtraData:setVisible(true)
-- end

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
    local favXPos = self.width - 50 - self.statsList.x
    local addW = 16 + self.statsList.x

    if not item.multipleHeader then
        -- favorite handler
        if (x >= favXPos) then
            local _item = CHC_main.items[item.fullType]
            local isFav = _item.favorite == true
            isFav = not isFav
            _item.favorite = isFav
            self.modData[CHC_main.common.getFavItemModDataStr(item)] = isFav or nil
            self.backRef.updateQueue:push({
                targetViews = { 'fav_items' },
                actions = { 'needUpdateFavorites', 'needUpdateObjects' }
            })
        end
        if x <= addW then
            if self.evolvedSelected and item.available and not item.isEvolvedBaseItem then
                self:addItemInEvolvedRecipe({ item = CHC_main.items[item.fullType] })
            end
        end
    end
    if item.multipleHeader then
        if (x >= favXPos) then
            item.blockHiddenState = CHC_main.common.getNextState(blockHiddenStateSelector, item.blockHiddenState)
            if item.availableNum == item.totalNum or item.unavailableNum == item.totalNum then
                item.blockHiddenState = blockHiddenStateSelector[1]
                item.blockHiddenStateLocked = true
            end
            if item.blockHiddenState == blockHiddenStateSelector[1] then
                item.isBlockHidden = false
            else
                item.isBlockHidden = true
            end
            self.blockStateData[item.sourceNum] = item.blockHiddenState
        else
            item.collapsed = not item.collapsed
            self.collapsedData[item.sourceNum] = item.collapsed
            self.needUpdateHeight = true
        end
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
    if not self.player then return end
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
        action:setOnComplete(self.onCraftComplete, self, action, selectedItem.recipeObj, container, self.containerList)
    end
    ISTimedActionQueue.add(action)
    self.craftInProgress = true

    ISCraftingUI.ReturnItemsToOriginalContainer(self.player, returnToContainer)
end

function CHC_uses_recipepanel:craftAll()
    self:craft(nil, true);
end

-- region evolved
function CHC_uses_recipepanel:addRandomMenu()
    local context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())

    local typesAvailable = self.selectedObj.typesAvailable
    local used = self.evolvedSelected.extraItems and #self.evolvedSelected.extraItems or 0
    local max = self.selectedObj.recipe.recipeData.maxItems

    self.evolvedValidTypes, self.evolvedValidSpices = self:getValidEvolvedIngredients(typesAvailable)
    local types = self.evolvedValidTypes
    local spices = self.evolvedValidSpices

    -- region ingredient
    if used < max and types and not utils.empty(types) then
        tsort(types, function(a, b) return not ssort(a.name, b.name) end)
        local ingredientMenu = context:addOption(getText("IGUI_Evolved_Ingredient"), nil, nil)
        local ingredientSubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(ingredientMenu, ingredientSubMenu)
        if #types > 1 then
            -- TODO: add random (all w/o dupes)
            ingredientSubMenu:addOption(sformat("%s (%s)", getText("IGUI_Evolved_Random"), getText("UI_All")), self,
                CHC_uses_recipepanel.addRandomCategory, types, true, false)
            ingredientSubMenu:addOption(sformat("%s (%s)", getText("IGUI_Evolved_Random"), getText("ContextMenu_One")),
                self, CHC_uses_recipepanel.addRandomCategory, types, false, false)
        end
        for i = 1, #types do
            local _type = types[i]
            local optName = getText("ContextMenu_FoodType_" .. _type.name) .. " (" .. #_type.items .. ")"
            local opt = ingredientSubMenu:addOption(optName, self, CHC_uses_recipepanel.addRandomIngredient, _type.items,
                false, false)

            if #_type.items == 1 then
                local item = _type.items[1]
                local val = item.item.displayName .. " x " .. item.uses
                opt.name = getText("ContextMenu_FoodType_" .. _type.name) .. " (" .. val .. ")"
            else
                local ingredientCategorySubMenu = ISContextMenu:getNew(ingredientSubMenu)
                ingredientSubMenu:addSubMenu(opt, ingredientCategorySubMenu)
                for j = 1, #types[i].items do
                    local item = types[i].items[j]
                    ingredientCategorySubMenu:addOption(
                        item.item.displayName .. " x " .. item.uses,
                        self, CHC_uses_recipepanel.addItemInEvolvedRecipe, item, false, false)
                end
            end
        end
    end
    -- endregion

    -- region condiment
    if used > 0 and spices and not utils.empty(spices) then
        tsort(spices, function(a, b) return not ssort(a.item.name, b.item.name) end)
        local condimentMenu = context:addOption(getText("ContextMenu_FoodType_NoExplicit"), nil, nil)
        local condimentSubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(condimentMenu, condimentSubMenu)
        if #spices > 1 then
            condimentSubMenu:addOption(sformat("%s (%s)", getText("IGUI_Evolved_Random"), getText("UI_All")), self,
                CHC_uses_recipepanel.addRandomCategory, spices, true, true)
            condimentSubMenu:addOption(sformat("%s (%s)", getText("IGUI_Evolved_Random"), getText("ContextMenu_One")),
                self, CHC_uses_recipepanel.addRandomIngredient, spices, false, true)
        end
        for i = 1, #spices do
            local _spice = spices[i]
            local opt = condimentSubMenu:addOption(
                _spice.item.displayName .. " x " .. _spice.uses, self,
                CHC_uses_recipepanel.addItemInEvolvedRecipe, _spice, false, true)
        end
    end
    -- endregion
end

function CHC_uses_recipepanel:addRandomCategory(options, all, isSpice)
    local opt = CHC_main.common.getRandom(options)
    if opt.items then
        self.addRandomIngredient(self, opt.items, all, isSpice)
    else
        self.addItemInEvolvedRecipe(self, opt, all, isSpice)
    end
end

function CHC_uses_recipepanel:addRandomIngredient(options, all, isSpice)
    local opt = CHC_main.common.getRandom(options)
    self.addItemInEvolvedRecipe(self, opt, all, isSpice)
end

function CHC_uses_recipepanel:addItemInEvolvedRecipe(item, all, isSpice)
    local function updateSelected(self)
        self.parent.getContainers(self)
        CHC_uses_recipepanel.getEvolvedChoices(self, self.selectedObj, self.containerList)
        CHC_uses_recipepanel.setSpecificEvolvedItem(self, self.evolvedChoices[self.evolvedSelectedIx])
    end

    local function onComplete(self, completedAction, isSpice)
        local used = self.evolvedSelected.extraItems and #self.evolvedSelected.extraItems or 0
        local max = self.selectedObj.recipe.recipeData.maxItems
        if used >= max and not isSpice then return end

        self.evolvedValidTypes, self.evolvedValidSpices = CHC_uses_recipepanel.getValidEvolvedIngredients(self,
            self.selectedObj.typesAvailable)

        local options = isSpice and self.evolvedValidSpices or self.evolvedValidTypes
        if utils.empty(options) then return end
        local item = CHC_main.common.getRandom(options)
        if item.items then
            item = CHC_main.common.getRandom(item.items)
        end

        local previousAction = completedAction
        local returnToContainer = {}
        local itemObj = CHC_main.common.getConcreteItem(self.containerList, item.item.fullType)
        local baseItem = self.evolvedSelected.item
        local ch = self.player
        local action = CHC_ISAddItemInRecipe:new(ch,
            self.selectedObj.recipeObj, baseItem,
            itemObj, self.selectedObj.timeToMake
        )
        action:setOnComplete(updateSelected, self)
        action:setOnComplete2(onComplete, self, action, isSpice)
        ISTimedActionQueue.addAfter(previousAction, action)
        ISCraftingUI.ReturnItemsToOriginalContainer(ch, returnToContainer)
    end

    -- Adapted from ISCraftingUI:addItemInEvolvedRecipe
    local returnToContainer = {}
    local ch = self.player
    local inv = ch:getInventory()
    local itemObj = CHC_main.common.getConcreteItem(self.containerList, item.item.fullType)
    local baseItem = self.evolvedSelected.item
    if not itemObj or not baseItem then error("Item not found") end

    if not inv:contains(itemObj) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(ch, itemObj, itemObj:getContainer(), inv, nil))
        table.insert(returnToContainer, itemObj)
    end
    if not inv:contains(baseItem) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(ch, baseItem, baseItem:getContainer(), inv, nil))
        table.insert(returnToContainer, baseItem)
    end
    local action = CHC_ISAddItemInRecipe:new(ch, self.selectedObj.recipeObj, baseItem, itemObj,
        self.selectedObj.timeToMake)
    action:setOnComplete(updateSelected, self)
    if all then
        action:setOnComplete2(onComplete, self, action, isSpice)
    end
    ISTimedActionQueue.add(action)
    self.craftInProgress = true
    ISCraftingUI.ReturnItemsToOriginalContainer(ch, returnToContainer)
end

function CHC_uses_recipepanel:setSpecificEvolvedItem(evolvedOpt)
    if not evolvedOpt then return end
    self.evolvedOpt = evolvedOpt
    -- TODO: might be inconsistent, need to test
    self.evolvedSelectedIx = evolvedOpt.index
    self.selectedObj.typesAvailable = self:getAvailableItemsType()
    self:updateMainInfo(self.selectedObj)
    self:updateButtons(self.selectedObj)

    self:refreshIngredientPanel(self.selectedObj)
end

function CHC_uses_recipepanel:getFoodData(ch)
    if not ch.foodData then return end
    local res = {}
    local immersive = false
    local playerTraits = CHC_menu.CHC_window.player:getTraits()
    local canShowNutriData = not immersive or
        ch.item:isPackaged() or
        playerTraits:contains("Nutritionist") or
        playerTraits:contains("Nutritionist2")

    for name, data in pairs(ch.foodData) do
        local isNutri = utils.startswith(name, "nutr_")
        local isCal = utils.startswith(name, "nutr_cal_")
        local title = data.text
        local value = tostring(data.val)
        local rgb = { r = 1, g = 1, b = 1 }

        if not isNutri then
            if (data.val >= 0 or data.posGood == false) and
                (data.val <= 0 or data.posGood == true) then
                rgb = { r = 0.3, g = 1, b = 0.2 }
            else
                rgb = { r = 0.8, g = 0.3, b = 0.2 }
            end
        end

        if data.val == 0 then rgb = { r = 1, g = 1, b = 1 } end

        if data.val > 0 and not isNutri then
            value = "+" .. value
        end

        rgb.a = 1
        if not isNutri or canShowNutriData then
            local item = { title = title, color = rgb, value = value, isCal = isCal, valPrecise = data.valPrecise }
            if not isCal then
                item.icon = data.icon
            end
            insert(res, item)
        end
    end
    return res
end

function CHC_uses_recipepanel:getTooltipForEvolvedItem(ch)
    local function collectOptions(options, contains)
        local itemCounts = {}
        local counts = {}
        for c = 1, #options do
            local item = options[c]
            if not itemCounts[item.fullType] then
                itemCounts[item.fullType] = { item = item, count = 1 }
            else
                itemCounts[item.fullType].count = itemCounts[item.fullType].count + 1
            end
        end

        for _, value in pairs(itemCounts) do
            insert(counts, value)
        end
        tsort(counts, function(a, b) return a.item.displayName < b.item.displayName end)

        for i = 1, #counts do
            local value = counts[i]
            local label = "- " .. "<IMAGE:" .. value.item.texture:getName() .. ",32,32>" .. value.item.displayName
            if value.count > 1 then
                label = label .. " x " .. value.count
            end
            insert(contains, label)
        end
    end

    local contains = {}
    insert(contains, ch.displayNameExtra)

    if ch.extraItems then
        insert(contains, "<RGB:0.5,0.5,0.5>_______________ <RGB:1,1,1>")
        insert(contains, sformat("<RGB:0.8,0.8,0.8> %s <RGB:1,1,1>", getText("Tooltip_item_Contains")))
        collectOptions(ch.extraItems, contains)

        if ch.extraSpices then
            insert(contains, sformat("<RGB:0.8,0.8,0.8> %s <RGB:1,1,1>", getText("Tooltip_item_Spices")))
            collectOptions(ch.extraSpices, contains)
        end
    end
    insert(contains, "")
    return table.concat(contains, '\n')
end

function CHC_uses_recipepanel:selectSpecificMenu()
    local context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())

    local max = self.selectedObj.recipe.recipeData.maxItems
    local choices = self.evolvedChoices
    for i = 1, #choices do
        local ch = choices[i]
        local optName = ch.itemObj.displayName
        local used = ch.extraItems and #ch.extraItems or 0
        local optText = self:getTooltipForEvolvedItem(ch)
        optName = optName .. " (" .. used .. "/" .. max .. ")"
        local opt = context:addOption(optName, self, self.setSpecificEvolvedItem, ch)
        opt.iconTexture = ch.itemObj.texture
        if optText then
            CHC_main.common.setTooltipToCtx(opt, optText)
        end
    end
end

-- endregion

-- endregion

function CHC_uses_recipepanel:getValidEvolvedIngredients(typesAvailable)
    local typesToShow = {}
    local spices = {}
    local containsSpices = {}
    local baseItem = self.selectedObj.recipe.recipeData.baseItem

    if self.evolvedSelected then
        containsSpices = self.evolvedSelected.extraSpicesMap or {}
    end

    for fullType, count in pairs(typesAvailable) do
        local item = CHC_main.items[fullType]
        if item and item.fullType ~= baseItem then
            local foodType = item.item:IsFood() and item.item:getFoodType()
            if foodType then
                local uses = 0
                local isValidUses = false
                local isValidCooked = false
                local isInvalidFrozen = true
                local concreteItems = CHC_main.common.getNearbyItems(self.containerList, { item.fullType })
                local evoRecipe = self.selectedObj.recipeObj
                local concreteItem = concreteItems[1]
                if concreteItem and concreteItem.item then
                    concreteItem = concreteItem.item
                    local use = evoRecipe:getItemRecipe(concreteItem):getUse()
                    local hungChange = concreteItem:getHungerChange()
                    if use > math.abs(hungChange * 100) then
                        use = math.floor(math.abs(hungChange * 100));
                    end
                    uses = math.floor(count / use)
                    isValidUses = uses > 0
                    -- source: ISInventoryPaneContextMenu.addItemInEvoRecipe
                    isValidCooked = evoRecipe:needToBeCooked(concreteItem)
                    isInvalidFrozen = concreteItem:getFreezingTime() > 0 and (not evoRecipe:isAllowFrozenItem())
                end
                local isSpice = item.propsMap and item.propsMap["Spice"] and
                    tostring(item.propsMap["Spice"].value) == "true"

                if isValidUses and isValidCooked and not isInvalidFrozen then -- TODO add tooltip
                    if (foodType == "NoExplicit" or isSpice) then
                        if not containsSpices[item.fullType] then
                            insert(spices, { item = item, uses = #concreteItems })
                        end
                    else
                        if not typesToShow[foodType] then typesToShow[foodType] = {} end
                        insert(typesToShow[foodType], { item = item, uses = uses })
                    end
                end
            else
                local sourceSpice = self.sourceSpice or {}
                for i = 1, #sourceSpice do
                    if sourceSpice[i].fullType == fullType and not containsSpices[item.fullType] then
                        insert(spices, { item = item, uses = 1 })
                    end
                end
            end
        end
    end

    local types = {}
    for foodType, items in pairs(typesToShow) do
        insert(types, { name = foodType, items = items })
    end
    return types, spices
end

function CHC_uses_recipepanel:updateButtons(obj)
    self.buttonVisible = false
    local statsY = self.mainInfo.y + self.mainInfo:getBottom() + self.padY
    local statsH = self.height - self.mainInfo.height - 5 * self.padY

    local buttonStates = {
        craftOne = false,
        craftAll = false,
        evoSpecific = false,
        evoIngr = false
    }

    if obj.available then
        if obj.recipe.isEvolved then
            if not obj.typesAvailable then
                obj.typesAvailable = self:getAvailableItemsType()
            end
            if not utils.empty(self.evolvedChoices) and #self.evolvedChoices > 1 then
                buttonStates.evoSpecific = true
            end
            if not utils.empty(obj.typesAvailable) then
                if self.evolvedSelected then
                    self.evolvedValidTypes, self.evolvedValidSpices = self:getValidEvolvedIngredients(obj.typesAvailable)
                    local isIngr = not utils.empty(self.evolvedValidTypes)
                    local isSpices = not utils.empty(self.evolvedValidSpices)
                    local isExtra = self.evolvedSelected.extraItems
                    local c1 = isExtra and #self.evolvedSelected.extraItems == obj.maxItems and isSpices
                    local c2 = isExtra and #self.evolvedSelected.extraItems < obj.maxItems and (isIngr or isSpices)
                    local c3 = not isExtra and isIngr
                    if c1 or c2 or c3 then
                        local rndButX = 5
                        if buttonStates.evoSpecific then
                            rndButX = rndButX + self.selectSpecificButton.x + self.selectSpecificButton.width
                        end
                        self.addRandomButton:setX(rndButX)
                        buttonStates.evoIngr = true
                    end
                end
            end
        else
            buttonStates.craftOne = true
            if obj.howManyCanCraft > 1 then
                self.craftAllButton:setTitle(getText("IGUI_CraftUI_ButtonCraftAllCount",
                    obj.howManyCanCraft))
                self.craftAllButton:setX(self.craftOneButton.x + self.craftOneButton.width + 5)
                self.craftAllButton:setWidth(10 +
                    getTextManager():MeasureStringX(UIFont.Small, self.craftAllButton.title))

                buttonStates.craftAll = true
            end
        end
        -- draw buttons
        if utils.any({
                buttonStates.craftOne,
                buttonStates.craftAll,
                buttonStates.evoSpecific,
                buttonStates.evoIngr
            }, true) then
            self.buttonVisible = true
            statsY = statsY + self.addRandomButton.height + self.padY
            statsH = statsH - self.addRandomButton.height - self.padY - 2
        end
    end

    self.craftOneButton:setVisible(buttonStates.craftOne)
    self.craftAllButton:setVisible(buttonStates.craftAll)
    self.selectSpecificButton:setVisible(buttonStates.evoSpecific)
    self.addRandomButton:setVisible(buttonStates.evoIngr)

    self.statsList:setY(statsY)
    self.statsList:setHeight(statsH)
end

function CHC_uses_recipepanel:handleOverflow(label, maxWidth)
    if label.name ~= label.origName or label.width > maxWidth then
        local newName = CHC_main.common.handleTextOverflow(label, maxWidth)
        label:setName(newName)
        if not label.origTooltip then
            label:setTooltip(label.origName)
        else
            label:setTooltip(label.origTooltip .. "\n" .. label.origName)
        end
    end
    if label.name == label.origName then
        label:setTooltip(label.origTooltip)
    end
end

function CHC_uses_recipepanel:getEvolvedChoices(obj, containerList)
    local recipeData = obj.recipe.recipeData
    self.evolvedChoices = CHC_main.common.getNearbyItems(containerList,
        { recipeData.baseItem, recipeData.fullResultItem })
    for i = 1, #self.evolvedChoices do
        self.evolvedChoices[i].index = i
    end
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
    o.player = CHC_menu.player
    o.character = o.player

    o.needRefreshIngredientPanel = true
    o.needRefreshRecipeCounts = true
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateHeight = false

    o.recipe = nil
    o.manualsSize = 0
    o.manualsEntries = nil
    o.modData = CHC_menu.playerModData
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
    o.blockAVIcon = getTexture("media/textures/CHC_blockAV.png")
    o.blockUNIcon = getTexture("media/textures/CHC_blockUN.png")
    o.blockAllIcon = getTexture("media/textures/type_filt_all.png")
    o.addEvolvedHoveredTex = getTexture("media/textures/CHC_evolved_add_hovered.png")
    o.addEvolvedTex = getTexture("media/textures/CHC_evolved_add.png")
    return o;
end
