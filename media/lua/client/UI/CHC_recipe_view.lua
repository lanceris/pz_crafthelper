require 'UI/CHC_tabs'
require 'UI/CHC_view'

local derivative = ISPanel
CHC_recipe_view = derivative:derive('CHC_recipe_view')

local utils = require('CHC_utils')

local lower = string.lower
local sub = string.sub
local find = string.find
local tostring = tostring

-- region create
function CHC_recipe_view:initialise()
    derivative.initialise(self)

    self.typeData = {
        all = {
            tooltip = self.defaultCategory,
            icon = self.typeFiltIconAll,
            count = 0
        },
        valid = {
            tooltip = getText('UI_settings_av_valid'),
            icon = self.typeFiltIconValid,
            count = 0
        },
        known = {
            tooltip = getText('UI_settings_av_known'),
            icon = self.typeFiltIconKnown,
            count = 0
        },
        invalid = {
            tooltip = getText('UI_settings_av_invalid'),
            icon = self.typeFiltIconInvalid,
            count = 0
        },
    }
    self.categoryData = {}
    self.categoryData[self.defaultCategory] = { count = 0 }

    self:create()
end

function CHC_recipe_view:create()
    self:getContainers()
    local mainPanelsData = {
        listCls = CHC_recipes_list,
        panelCls = CHC_recipes_panel,
        -- extra_init_params = { }
    }
    CHC_view.create(self, mainPanelsData)
    self.onResizeHeaders = CHC_view.onResizeHeaders
    self.objGetter = "getRecipes"

    if self.ui_type == 'fav_recipes' then
        self.objSource = self.backRef[self.objGetter](self, true)
    end

    self:updateObjects()
    self:updateRecipesState()
    self:updateObjects()
    self.initDone = true
end

-- endregion

-- region update

function CHC_recipe_view:update()
    if self.needUpdateModRender then
        self.objList.shouldDrawMod = CHC_settings.config.show_recipe_module
        self.needUpdateModRender = false
    end
    CHC_view.update(self)
end

function CHC_recipe_view:updateObjects()
    CHC_view.updateObjects(self, '_state')
end

function CHC_recipe_view:updateRecipeState(recipe)
    if recipe.isSynthetic then
        recipe._state = "known"
        recipe.valid = false
        recipe.known = true
        recipe.invalid = false
    elseif recipe.isEvolved then
        if CHC_main.common.isEvolvedRecipeValid(recipe, self.containerList) then
            recipe._state = "valid"
            recipe.valid = true
            recipe.known = false
            recipe.unknown = false
        else
            recipe._state = "known"
            recipe.valid = false
            recipe.known = true
            recipe.unknown = false
        end
    else
        -- if RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.containerList) then
        if CHC_main.common.isRecipeValid(recipe, self.player, self.containerList, self.knownRecipes, self.playerSkills, self.nearbyIsoObjects) then
            recipe._state = "valid"
            recipe.valid = true
            recipe.known = false
            recipe.invalid = false
        elseif (not recipe.recipeData.needToBeLearn) or
            (recipe.recipeData.needToBeLearn and self.knownRecipes[recipe.recipeData.originalName]) then
            recipe._state = "known"
            recipe.valid = false
            recipe.known = true
            recipe.invalid = false
        else
            recipe._state = "invalid"
            recipe.valid = false
            recipe.known = false
            recipe.invalid = true
        end
    end
end

function CHC_recipe_view:updateRecipesState()
    local recipes
    local issuff = false
    if self.typeFilter == 'all' then
        recipes = self.objList.items
        issuff = true
    else
        recipes = self.objSource
    end
    if not recipes or utils.empty(recipes) then return end
    self.knownRecipes = CHC_main.common.getKnownRecipes(self.player)
    self.playerSkills = CHC_main.common.getPlayerSkills(self.player)
    self.nearbyIsoObjects = CHC_main.common.getNearbyIsoObjectNames(self.player)
    for i = 1, #recipes do
        local recipe = issuff and recipes[i].item or recipes[i]
        self:updateRecipeState(recipe)
    end
    if self.typeFilter ~= 'all' then
        self.needUpdateObjects = true
    end
    if not self.filterRow.categorySelector:getSelectedText() then
        self.filterRow.categorySelector:select(self.defaultCategory)
    end
end

-- endregion

-- region render

function CHC_recipe_view:onResize()
    ISPanel.onResize(self)
    CHC_view.onResize(self)
end

function CHC_recipe_view:prerender()
    ISPanel.prerender(self)
    local ms = UIManager.getMillisSinceLastRender()
    if not self.ms then self.ms = 0 end
    self.ms = self.ms + ms
    if self.ms > 1000 and self.initDone then -- FIXME
        self.needUpdateRecipeState = true
        self.ms = 0
    end

    if self.needUpdateRecipeState then
        self.needUpdateRecipeState = false
        self:getContainers()
        local areContainersSame = CHC_main.common.compareContainersHash(
            self.containerListHash,
            self.prevContainerHash)
        if not areContainersSame then
            self:updateRecipesState()
            self.prevContainerHash = self.containerListHash
            self.objPanel.needRefreshIngredientPanel = true
        end
    end
end

function CHC_recipe_view:render()
    CHC_view.render(self)
end

-- endregion

-- region logic

-- region event handlers
function CHC_recipe_view:onTextChange()
    if not self.delayedSearch or self.searchRow.searchBar:getInternalText() == '' then
        CHC_view.onTextChange(self)
    end
end

function CHC_recipe_view:onCommandEntered()
    if self.delayedSearch then
        CHC_view.onCommandEntered(self)
    end
end

function CHC_recipe_view:onRMBDown(x, y, item, showNameInFindCtx)
    local backRef = self.parent.backRef
    local context = backRef.onRMBDownObjList(self, x, y, item)
    item = CHC_main.items[item.fullType]
    if not item then return end

    local ctxText = getText('IGUI_find_item')
    if showNameInFindCtx then
        ctxText = ctxText .. " (" .. item.displayName .. ")"
    end
    local findOpt = context:addOption(ctxText, backRef, CHC_menu.onCraftHelperItem, item)
    findOpt.iconTexture = CHC_window.icons.common.search

    local newTabOption = context:addOption(getText('IGUI_new_tab'), backRef, backRef.addItemView, item.item,
        true, 2)

    newTabOption.iconTexture = CHC_window.icons.common.new_tab
    local isRecipes = CHC_main.common.areThereRecipesForItem(item)

    if not isRecipes then
        CHC_main.common.setTooltipToCtx(
            newTabOption,
            getText('IGUI_no_recipes'),
            false
        )
    else
        CHC_main.common.addTooltipNumRecipes(newTabOption, item)
    end
end

function CHC_recipe_view:onRMBDownObjList(x, y, item)
    if not item then
        local row = self:rowAt(x, y)
        if row == -1 then return end
        item = self.items[row].item.recipeData.result
        if not item then return end
    end

    self.parent.onRMBDown(self, x, y, item, true)
end

function CHC_recipe_view:onRemoveAllFavBtnClick()
    for key, value in pairs(self.modData) do
        if utils.startswith(key, "craftingFavorite:") and value == true then
            self.modData[key] = nil
        end
    end
    self.needUpdateFavorites = true
    self.needUpdateLayout = true
end

-- endregion

-- region sorting logic

function CHC_recipe_view:filterTypeSetTooltip()
    local curtype = self.typeData[self.typeFilter].tooltip
    return getText('UI_settings_av_title') .. ' (' .. curtype .. ')'
end

-- endregion

function CHC_recipe_view:searchProcessToken(token, recipe)
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char
    local items = {}

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token) then
        isSpecialSearch = true
        char = sub(token, 1, 1)
        token = sub(token, 2)
        if token == '' and char ~= '^' then return true end
    end

    local whatCompare
    if not token then return true end
    if isSpecialSearch then
        if char == '^' then
            if not recipe.favorite then return false end
            whatCompare = lower(recipe.recipeData.name)
        end
        if char == '!' then
            local catName = recipe.displayCategory or recipe.category
            whatCompare = catName
        end
        if char == '#' then
            -- search by ingredients
            if recipe.isSynthetic then
                local sources = recipe.recipeData.ingredients
                for i = 1, #sources do
                    local source = sources[i]
                    local item = CHC_main.items[source.type]
                    if item then items[#items + 1] = item.displayName end
                end
            elseif recipe.isEvolved then
                local item = CHC_main.items[recipe.recipeData.baseItem]
                if item then items[#items + 1] = item.displayName end
                local sources = recipe.recipeData.possibleItems
                for i = 1, #sources do
                    local source = sources[i]
                    local _item = CHC_main.items[source.fullType]
                    if _item then items[#items + 1] = _item.displayName end
                end
            else
                local rSources = recipe.recipe:getSource()
                -- Go through items needed by the recipe
                for n = 0, rSources:size() - 1 do
                    -- Get the item name (not the display name)
                    local rSource = rSources:get(n)
                    local sItems = rSource:getItems()
                    for k = 0, sItems:size() - 1 do
                        local itemString = sItems:get(k)
                        local item = CHC_main.items[itemString]
                        if item then items[#items + 1] = item.displayName end
                    end
                end
            end

            -- add books
            local books = CHC_main.itemsManuals[recipe.recipeData.name] or {}
            if not utils.empty(books) then
                for i = 1, #books do
                    items[#items + 1] = books[i].displayName
                end
            end

            -- add traits
            local traits = CHC_main.freeRecipesTraits[recipe.recipeData.name] or {}
            if not utils.empty(traits) then
                for i = 1, #traits do
                    items[#items + 1] = traits[i].displayName
                end
            end

            -- add professions
            local professions = CHC_main.freeRecipesProfessions[recipe.recipeData.name] or {}
            if not utils.empty(professions) then
                for i = 1, #professions do
                    items[#items + 1] = professions[i].displayName
                end
            end

            -- add skills
            local skillCount = recipe.recipeData.requiredSkillCount
            if skillCount and skillCount > 0 then
                local skills = recipe.recipeData.requiredSkills
                local opIx = find(token, '[><=]')
                if opIx then
                    opIx = find(token, '[~><=]')
                    for i = 1, #skills do
                        local skill = skills[i]
                        local whatCompName = skill.skill
                        local toCompName = sub(token, 1, opIx - 1)
                        local stateName = utils.compare(whatCompName, toCompName)

                        local whatCompVal = skill.level
                        local toCompVal = sub(token, opIx, #token)
                        local stateVal = utils.compare(whatCompVal, toCompVal)

                        if stateName and stateVal then return true end
                    end
                else
                    for i = 1, #skills do
                        local prop = skills[i]
                        items[#items + 1] = prop.skill
                    end
                end
            end


            if recipe.recipeData.hydroFurniture then
                items[#items + 1] = recipe.recipeData.hydroFurniture.obj.displayName
            end

            if recipe.recipeData.nearItem then
                local nearItem = CHC_main.items[recipe.recipeData.nearItem]
                if nearItem then
                    items[#items + 1] = nearItem.displayName
                else
                    items[#items + 1] = recipe.recipeData.nearItem
                end
            end

            whatCompare = items
        end
        if char == '&' then
            whatCompare = lower(tostring(recipe.module))
        end
        local resultItem = recipe.recipeData.result
        if resultItem and resultItem.fullType then
            if char == '@' then
                whatCompare = resultItem.modname
            elseif char == '$' then
                local displayCat = resultItem.displayCategory or ''
                whatCompare = getText('IGUI_ItemCat_' .. displayCat) or 'None'
            elseif char == '%' then
                whatCompare = resultItem.displayName
            end
        end
    else
        whatCompare = lower(recipe.recipeData.name)
    end
    state = utils.compare(whatCompare, token)
    return state
end

function CHC_recipe_view:processAddObjToObjList(recipe, modData) --FIXME
    local name = recipe.recipeData.name
    recipe.favorite = modData[recipe.favStr] or false
    recipe.drawMod = self.shouldDrawMod and recipe.module and recipe.module ~= 'Base'
    if name then
        if recipe.drawMod then
            name = name .. " (" .. tostring(recipe.module) .. ")"
        end
        local w = utils.strWidth(self.curFontData.font, name) + 50
        local addedItem = self.objList:addItem(name, recipe)
        if w > self.objList.width then
            addedItem.tooltip = name
        else
            addedItem.tooltip = nil
        end
    end
end

function CHC_recipe_view:getContainers()
    self.playerNum = CHC_menu.playerNum
    ISCraftingUI.getContainers(self)
    self.containerListHash = CHC_main.common.getContainersHash(self.containerList)
end

--endregion


function CHC_recipe_view:new(args)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    -- local item = args.item

    local o = {}
    o = derivative:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }

    o.item = args.item or nil
    o.objSource = args.objSource
    o.itemSortAsc = args.itemSortAsc
    o.typeFilter = args.typeFilter
    o.showHidden = args.showHidden
    o.sep_x = args.sep_x
    o.player = CHC_menu.player
    o.defaultCategory = getText('UI_All')
    o.searchRowHelpText = getText('UI_searchrow_info',
        getText('UI_searchrow_info_recipes_special'),
        getText('UI_searchrow_info_recipes_examples')
    )
    o.objListSize = 0

    o.needUpdateFavorites = true
    o.needUpdateObjects = false
    o.needUpdateFont = true
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateModRender = false
    o.needUpdateShowIcons = false
    o.needUpdateDelayedSearch = false
    o.needUpdateRecipeState = false
    o.needUpdateInfoTooltip = false
    o.needUpdateLayout = false

    o.anchorTop = true
    o.anchorBottom = true
    o.anchorLeft = true
    o.anchorRight = true

    o.selectedCategory = o.defaultCategory
    o.initDone = false
    o.fav_ui_type = "fav_recipes"
    o.backRef = args.backRef
    o.ui_type = args.ui_type
    o.isItemView = false
    o.modData = CHC_menu.playerModData
    o.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
    o.fontSize = getTextManager():getFontHeight(o.curFontData.font)
    o.delayedSearch = CHC_settings.config.delayed_search
    o.shouldDrawMod = CHC_settings.config.show_recipe_module
    o.searchBarDelayedTooltip = getText('IGUI_DelayedSearchBarTooltip')
    o.player = CHC_menu.player
    o.character = o.player

    o.typeFiltIconAll = CHC_window.icons.common.type_all
    o.typeFiltIconValid = CHC_window.icons.recipe.type_valid
    o.typeFiltIconKnown = CHC_window.icons.recipe.type_known
    o.typeFiltIconInvalid = CHC_window.icons.recipe.type_invalid
    o.removeAllFavBtnIcon = CHC_window.icons.recipe.favorite.remove_all

    return o
end
