--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************
local MAX_TOTAL = 3
local MAX_BASE = MAX_TOTAL

require "TimedActions/ISBaseTimedAction"

CHC_ISAddItemInRecipe = ISBaseTimedAction:derive("CHC_ISAddItemInRecipe");

function CHC_ISAddItemInRecipe:isValid()
    return self.character:getInventory():contains(self.baseItem) and
        self.recipe:getItemsCanBeUse(self.character, self.baseItem, nil):contains(self.usedItem)
end

function CHC_ISAddItemInRecipe:update()
    self.baseItem:setJobDelta(self:getJobDelta());

    self.character:setMetabolicTarget(Metabolics.LightDomestic);
end

function CHC_ISAddItemInRecipe:start()
    self.baseItem:setJobType(getText("IGUI_JobType_AddingIngredient", self.usedItem:getDisplayName(),
        self.baseItem:getDisplayName()));
    local soundName = self.recipe:getAddIngredientSound() or "AddItemInRecipe"
    self.sound = self.character:getEmitter():playSoundImpl(soundName, nil)
end

function CHC_ISAddItemInRecipe:stop()
    self.baseItem:setJobDelta(0.0);
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self);
end

function CHC_ISAddItemInRecipe:perform()
    self.baseItem:setJobDelta(0.0);
    self.character:removeFromHands(self.baseItem)

    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end

    self.baseItem = self.recipe:addItem(self.baseItem, self.usedItem, self.character);

    ISAddItemInRecipe.checkName(self.baseItem, self.recipe);

    if not self.baseItem:isCustomName() and self.baseItem:getFoodType() == "Beer" then
        baseItem:setName(getText("ContextMenu_FoodType_Beer"))
    end

    ISAddItemInRecipe.checkTemperature(self.baseItem, self.usedItem, self.recipe);

    if self.onCompleteFunc then
        local args = self.onCompleteArgs
        self.onCompleteFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    end

    if self.onCompleteFunc2 then
        local args = self.onCompleteArgs2
        self.onCompleteFunc2(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    end

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function CHC_ISAddItemInRecipe:setOnComplete(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    self.onCompleteFunc = func
    self.onCompleteArgs = { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 }
end

function CHC_ISAddItemInRecipe:setOnComplete2(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    self.onCompleteFunc2 = func
    self.onCompleteArgs2 = { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 }
end

function CHC_ISAddItemInRecipe:new(character, recipe, baseItem, usedItem, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.recipe = recipe;
    o.baseItem = baseItem;
    o.usedItem = usedItem;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = 100 - (character:getPerkLevel(Perks.Cooking) * 2.5);
    if character:isTimedActionInstant() then
        o.maxTime = 1;
    end
    o.jobType = getText("IGUI_JobType_AddingIngredient", usedItem:getDisplayName(), baseItem:getDisplayName());
    return o;
end
