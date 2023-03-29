require 'UI/CHC_tabs'
require 'UI/CHC_view'

local derivative = ISPanel
CHC_uses = derivative:derive('CHC_uses')
local fhs = getTextManager():getFontHeight(UIFont.Small) -- FIXME

local utils = require('CHC_utils')

local insert = table.insert

-- region create
function CHC_uses:initialise()
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

function CHC_uses:create()
    self:getContainers()
    local filterRowOrderOnClickArgs = { CHC_uses.sortByNameAsc, CHC_uses.sortByNameDesc }
    local mainPanelsData = {
        listCls = CHC_uses_recipelist,
        panelCls = CHC_uses_recipepanel,
        -- extra_init_params = { }
    }
    CHC_view.create(self, filterRowOrderOnClickArgs, mainPanelsData)
    self.onResizeHeaders = CHC_view.onResizeHeaders
    self.objGetter = "getRecipes"

    if self.ui_type == 'fav_recipes' then
        self.objSource = self.backRef[self.objGetter](self, true)
    end

    self:updateObjects()
    self:updateRecipesState()
    self.initDone = true
end

-- endregion

-- region update

function CHC_uses:update()
    if self.needUpdateModRender then
        self.objList.shouldDrawMod = CHC_settings.config.show_recipe_module
        self.needUpdateModRender = false
    end
    CHC_view.update(self)
end

function CHC_uses:updateObjects()
    CHC_view.updateObjects(self, '_state')
end

function CHC_uses:updateRecipeState(recipe)
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

function CHC_uses:updateRecipesState()
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

function CHC_uses:prerender()
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

function CHC_uses:render()
    CHC_view.render(self)
end

-- endregion

-- region logic

-- region event handlers
function CHC_uses:onTextChange()
    if not self.delayedSearch or self.searchRow.searchBar:getInternalText() == '' then
        CHC_view.onTextChange(self)
    end
end

function CHC_uses:onCommandEntered()
    if self.delayedSearch then
        CHC_view.onCommandEntered(self)
    end
end

function CHC_uses:onRMBDown(x, y, item, showNameInFindCtx)
    local backRef = self.parent.backRef
    local context = backRef.onRMBDownObjList(self, x, y, item)
    item = CHC_main.items[item.fullType]
    if not item then return end

    local ctxText = getText('IGUI_find_item')
    if showNameInFindCtx then
        ctxText = ctxText .. " (" .. item.displayName .. ")"
    end
    local findOpt = context:addOption(ctxText, backRef, CHC_menu.onCraftHelperItem, item)
    findOpt.iconTexture = getTexture("media/textures/search_icon.png")

    local newTabOption = context:addOption(getText('IGUI_new_tab'), backRef, backRef.addItemView, item.item,
        true, 2)

    newTabOption.iconTexture = getTexture("media/textures/CHC_open_new_tab.png")
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

function CHC_uses:onRMBDownObjList(x, y, item)
    if not item then
        local row = self:rowAt(x, y)
        if row == -1 then return end
        item = self.items[row].item.recipeData.result
        if not item then return end
    end

    self.parent.onRMBDown(self, x, y, item, true)
end

-- endregion

-- region sorting logic
CHC_uses.sortByNameAsc = function(a, b)
    return a.item.recipeData.name < b.item.recipeData.name
end

CHC_uses.sortByNameDesc = function(a, b)
    return a.item.recipeData.name > b.item.recipeData.name
end

function CHC_uses:filterTypeSetTooltip()
    local curtype = self.typeData[self.typeFilter].tooltip
    return getText('UI_settings_av_title') .. ' (' .. curtype .. ')'
end

-- endregion

function CHC_uses:searchProcessToken(token, recipe)
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char
    local items = {}

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token) then
        isSpecialSearch = true
        char = token:sub(1, 1)
        token = string.sub(token, 2)
        if token == '' and char ~= '^' then return true end
    end

    local whatCompare
    if not token then return true end
    if isSpecialSearch then
        if char == '^' then
            if not recipe.favorite then return false end
            whatCompare = string.lower(recipe.recipeData.name)
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
                    if item then insert(items, item.displayName) end
                end
            elseif recipe.isEvolved then
                local item = CHC_main.items[recipe.recipeData.baseItem]
                if item then insert(items, item.displayName) end
                local sources = recipe.recipeData.possibleItems
                for i = 1, #sources do
                    local source = sources[i]
                    local _item = CHC_main.items[source.fullType]
                    if _item then insert(items, _item.displayName) end
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
                        if item then insert(items, item.displayName) end
                    end
                end
            end


            if recipe.recipeData.hydroFurniture then
                insert(items, recipe.recipeData.hydroFurniture.obj.displayName)
            end

            if recipe.recipeData.nearItem then
                local nearItem = CHC_main.items[recipe.recipeData.nearItem]
                if nearItem then
                    insert(items, nearItem.displayName)
                else
                    insert(items, recipe.recipeData.nearItem)
                end
            end

            whatCompare = items
        end
        if char == '&' then
            whatCompare = string.lower(recipe.module)
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
        whatCompare = string.lower(recipe.recipeData.name)
    end
    state = utils.compare(whatCompare, token)
    return state
end

function CHC_uses:processAddObjToObjList(recipe, modData) --FIXME
    local name = recipe.recipeData.name
    recipe.favorite = modData[CHC_main.getFavoriteRecipeModDataString(recipe)] or false
    if self.shouldDrawMod and recipe.module ~= 'Base' then
        recipe.height = recipe.height + 2 + fhs
    else
        recipe.height = self.curFontData.icon + 2 * self.curFontData.pad
    end

    self.objList:addItem(name, recipe)
end

function CHC_uses:getContainers()
    ISCraftingUI.getContainers(self)
    self.containerListHash = CHC_main.common.getContainersHash(self.containerList)
end

--endregion


function CHC_uses:new(args)
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
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }

    o.item = args.item or nil
    o.objSource = args.objSource
    o.itemSortAsc = args.itemSortAsc
    o.typeFilter = args.typeFilter
    o.showHidden = args.showHidden
    o.sep_x = args.sep_x
    o.itemSortFunc = o.itemSortAsc == true and CHC_uses.sortByNameAsc or CHC_uses.sortByNameDesc
    o.player = getPlayer()
    o.defaultCategory = getText('UI_All')
    o.searchRowHelpText = getText('UI_searchrow_info',
        getText('UI_searchrow_info_recipes_special'),
        getText('UI_searchrow_info_recipes_examples')
    )
    o.objListSize = 0

    o.needUpdateFavorites = true
    o.needUpdateObjects = false
    o.needUpdateFont = false
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateModRender = false
    o.needUpdateShowIcons = false
    o.needUpdateDelayedSearch = false
    o.needUpdateRecipeState = false

    o.selectedCategory = o.defaultCategory
    o.initDone = false
    o.fav_ui_type = "fav_recipes"
    o.backRef = args.backRef
    o.ui_type = args.ui_type
    o.isItemView = false
    o.modData = CHC_main.playerModData
    o.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
    o.delayedSearch = CHC_settings.config.delayed_search
    o.searchBarDelayedTooltip = getText('IGUI_DelayedSearchBarTooltip')
    local player = getPlayer()
    o.player = player
    o.character = player
    o.playerNum = player and player:getPlayerNum() or -1

    o.sortOrderIconAsc = getTexture('media/textures/sort_order_asc.png')
    o.sortOrderIconDesc = getTexture('media/textures/sort_order_desc.png')
    o.typeFiltIconAll = getTexture('media/textures/type_filt_all.png')
    o.typeFiltIconValid = getTexture('media/textures/type_filt_valid.png')
    o.typeFiltIconKnown = getTexture('media/textures/type_filt_known.png')
    o.typeFiltIconInvalid = getTexture('media/textures/type_filt_invalid.png')

    return o
end
