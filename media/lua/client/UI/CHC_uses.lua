require 'ISUI/ISPanel'
require 'ISUI/ISContextMenu'
require 'UI/CHC_tabs'
require 'UI/CHC_uses_recipelist'
require 'UI/CHC_uses_recipepanel'

local derivative = ISPanel
CHC_uses = derivative:derive('CHC_uses')
local fhs = getTextManager():getFontHeight(UIFont.Small) -- FIXME

local utils = require('CHC_utils')

local insert = table.insert
local sort = table.sort

-- region create
function CHC_uses:initialise()
    derivative.initialise(self)

    self.typeData = {
        all = {
            tooltip = self.categorySelectorDefaultOption,
            icon = self.typeFiltIconAll,
        },
        valid = {
            tooltip = getText('UI_settings_av_valid'),
            icon = self.typeFiltIconValid
        },
        known = {
            tooltip = getText('UI_settings_av_known'),
            icon = self.typeFiltIconKnown
        },
        invalid = {
            tooltip = getText('UI_settings_av_invalid'),
            icon = self.typeFiltIconInvalid
        },
    }

    self:create()
end

function CHC_uses:create()
    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, CHC_main.common.heights.headers, { self.onResizeHeaders, self },
        self.sep_x)
    self.headers:initialise()
    -- endregion

    local x = self.headers.x
    local y = self.headers.y + self.headers.height
    local leftW = self.headers.nameHeader.width
    local rightX = self.headers.typeHeader.x
    local rightW = self.headers.typeHeader.width
    -- region filters UI

    local filterRowData = {
        filterOrderData = {
            width = CHC_main.common.heights.filter_row,
            title = '',
            onclick = CHC_view.sortByName,
            onclickargs = { CHC_uses.sortByNameAsc, CHC_uses.sortByNameDesc },
            defaultTooltip = CHC_view.filterOrderSetTooltip(self),
            defaultIcon = CHC_view.filterOrderSetIcon(self)
        },
        filterTypeData = {
            width = CHC_main.common.heights.filter_row,
            title = '',
            onclick = self.onFilterTypeMenu,
            defaultTooltip = self:filterTypeSetTooltip(),
            defaultIcon = CHC_view.filterTypeSetIcon(self)
        },
        filterSelectorData = {
            defaultTooltip = getText('IGUI_invpanel_Category'),
            onChange = self.onChangeCategory
        }
    }

    self.filterRow = CHC_filter_row:new(
        { x = x, y = y, w = leftW, h = CHC_main.common.heights.filter_row, backRef = self.backRef },
        filterRowData)
    self.filterRow:initialise()
    local leftY = y + CHC_main.common.heights.filter_row
    -- endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new(
        { x = x, y = leftY, w = leftW, h = CHC_main.common.heights.search_row, backRef = self.backRef }, nil,
        self.onTextChange, self.searchRowHelpText)
    self.searchRow:initialise()
    leftY = leftY + self.searchRow.height
    -- endregion

    -- region recipe list
    local rlh = self.height - self.headers.height - self.filterRow.height - self.searchRow.height
    self.objList = CHC_uses_recipelist:new({ x = x, y = leftY, w = leftW, h = rlh, backRef = self.backRef })

    self.objList.drawBorder = true
    self.objList.onRightMouseDown = self.onRMBDownObjList
    self.objList:initialise()
    self.objList:instantiate()
    self.objList:setAnchorBottom(true)
    self.objList:setOnMouseDownFunction(self, self.onObjectChange)
    self.objList.curFontData = self.curFontData
    -- endregion

    -- region recipe details windows
    local rph = self.height - self.headers.height
    self.objPanel = CHC_uses_recipepanel:new({ x = rightX, y = y, w = rightW, h = rph, backRef = self.backRef })
    self.objPanel.drawBorder = true
    self.objPanel:initialise()
    self.objPanel:instantiate()
    self.objPanel:setAnchorRight(true)
    self.objPanel:setAnchorBottom(true)
    -- endregion

    -- Attach all to the craft helper window
    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.objList)
    self:addChild(self.objPanel)

    if self.ui_type == 'fav_recipes' then
        self.objSource = self.backRef:getRecipes(true)
    end
    self:getContainers()
    self:updateCategories()
    self:updateTypes()
    self:updateObjects(self.selectedCategory)
    self:updateRecipesState()
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

function CHC_uses:updateObjects(sl)
    -- get all containers nearby
    self:getContainers()

    if type(sl) == 'table' then sl = sl.text end
    local categoryAll = self.categorySelectorDefaultOption
    local searchBar = self.searchRow.searchBar
    local recipes = self.objSource

    if sl == categoryAll and self.typeFilter == 'all' and searchBar:getInternalText() == '' then
        CHC_view.refreshObjList(self, recipes)
        return
    end

    -- filter recipes
    local filteredRecipes = {}
    for i = 1, #recipes do
        local rc = recipes[i].category
        local rc_tr = getTextOrNull('IGUI_CraftCategory_' .. rc) or rc

        local type_filter_state = false
        local search_state = false

        if (rc_tr == sl or sl == categoryAll) then
            type_filter_state = CHC_view.objTypeFilter(self, recipes[i]._state)
        end
        search_state = CHC_main.common.searchFilter(self, recipes[i], self.searchProcessToken)

        if type_filter_state and search_state then
            insert(filteredRecipes, recipes[i])
        end
    end
    CHC_view.refreshObjList(self, filteredRecipes)
end

function CHC_uses:updateTypes()
    local recipes
    local suff = false
    if self.searchRow.searchBar:getInternalText() == "" then
        recipes = self.objSource
    else
        recipes = self.objList.items
        suff = true
        if not recipes or utils.empty(recipes) then
            recipes = self.objSource
            suff = false
        end
    end
    self:getContainers()
    self.numRecipes = { all = 0, valid = 0, known = 0, invalid = 0 }
    for i = 1, #recipes do
        local recipe = suff and recipes[i].item or recipes[i]
        local category = recipe.category
        category = getTextOrNull('IGUI_CraftCategory_' .. category) or category
        if self.selectedCategory == self.categorySelectorDefaultOption or self.selectedCategory == category then
            self.numRecipes.all = self.numRecipes.all + 1
            if recipe.valid then
                self.numRecipes.valid = self.numRecipes.valid + 1
            elseif recipe.known then
                self.numRecipes.known = self.numRecipes.known + 1
            else
                self.numRecipes.invalid = self.numRecipes.invalid + 1
            end
        end
    end
    if self.numRecipes.valid == 0 and self.typeFilter == 'valid' or
        self.numRecipes.known == 0 and self.typeFilter == 'known' or
        self.numRecipes.invalid == 0 and self.typeFilter == 'invalid' then
        CHC_view.sortByType(self, 'all')
    end
    if self.numRecipesPrev ~= self.numRecipes then
        self.needUpdateObjects = true
    end
    self.numRecipesPrev = self.numRecipes
    -- print(self.numRecipes.all .. "|" .. self.numRecipes.valid .. "|" ..
    -- self.numRecipes.known .. "|" .. self.numRecipes.invalid)
end

function CHC_uses:updateCategories()
    local selector = self.filterRow.categorySelector
    local uniqueCategories = {}
    local catCounts = {}
    local allrec
    local suff = false
    if self.searchRow.searchBar:getInternalText() == "" then
        allrec = self.objSource
    else
        allrec = self.objList.items
        suff = true
        if not allrec or utils.empty(allrec) then
            allrec = self.objSource
            suff = false
        end
    end
    local c = 1
    self.favRecNum = 0


    for i = 1, #allrec do
        local recipe = suff and allrec[i].item or allrec[i]
        if recipe.favorite then
            self.favRecNum = self.favRecNum + 1
        end
        local state = recipe._state
        local rc = recipe.recipeData.category
        rc = getTextOrNull('IGUI_CraftCategory_' .. rc) or rc
        if self.typeFilter == 'all' or self.typeFilter == state then
            if not utils.any(uniqueCategories, rc) then
                uniqueCategories[c] = rc
                catCounts[rc] = 1
                c = c + 1
            else
                catCounts[rc] = catCounts[rc] + 1
            end
        end
    end

    selector:clear()
    selector:addOptionWithData(self.categorySelectorDefaultOption, { count = #allrec })

    sort(uniqueCategories)
    for i = 1, #uniqueCategories do
        selector:addOptionWithData(uniqueCategories[i], { count = catCounts[uniqueCategories[i]] })
    end
end

function CHC_uses:handleFavorites()
    if self.ui_type == 'fav_recipes' then
        self.objSource = self.backRef:getRecipes(true)
    else
        self.backRef.updateQueue:push({
            targetView = 'fav_recipes',
            actions = { 'needUpdateFavorites', 'needUpdateObjects', 'needUpdateTypes' }
        })
    end
    self:updateCategories()
    self.filterRow.categorySelector:select(self.selectedCategory)
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
        recipe._state = "invalid"
        recipe.valid = false
        recipe.known = false
        recipe.invalid = true
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
            recipe._state = "unknown"
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
    self.needUpdateTypes = true
    if not self.filterRow.categorySelector:getSelectedText() then
        self.filterRow.categorySelector:select(self.categorySelectorDefaultOption)
    end
end

-- endregion

-- region render

function CHC_uses:prerender()
    local ms = UIManager.getMillisSinceLastRender()
    if not self.ms then self.ms = 0 end
    self.ms = self.ms + ms
    if self.ms > 1000 then -- FIXME
        self.needUpdateRecipeState = true
        self.ms = 0
    end

    if self.needUpdateRecipeState then
        self:updateRecipesState()
        self.needUpdateRecipeState = false
    end
end

function CHC_uses:render()
    CHC_view.render(self)
end

function CHC_uses:onResizeHeaders()
    CHC_view.onResizeHeaders(self)
end

-- endregion

-- region logic

-- region event handlers
function CHC_uses:onTextChange()
    CHC_view.onTextChange(self)
end

function CHC_uses:onChangeCategory(_option, sl)
    CHC_view.onChangeCategory(self, _option, sl)
end

function CHC_uses:onObjectChange(obj)
    CHC_view.onObjectChange(self, obj)
end

function CHC_uses:onFilterTypeMenu(button)
    local data = {
        { txt = 'UI_All',                 num = self.parent.numRecipes.all,     arg = 'all' },
        { txt = 'UI_settings_av_valid',   num = self.parent.numRecipes.valid,   arg = 'valid' },
        { txt = 'UI_settings_av_known',   num = self.parent.numRecipes.known,   arg = 'known' },
        { txt = 'UI_settings_av_invalid', num = self.parent.numRecipes.invalid, arg = 'invalid' }
    }

    CHC_view.onFilterTypeMenu(self.parent, button, data, CHC_view.sortByType)
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
    context:addOption(ctxText, backRef, CHC_menu.onCraftHelperItem, item)

    local newTabOption = context:addOption(getText('IGUI_new_tab'), backRef, backRef.addItemView, item.item,
        true, 2)

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

-- endregion

-- region filterRow setters

function CHC_uses:filterTypeSetTooltip()
    local curtype = self.typeData[self.typeFilter].tooltip
    return getText('UI_settings_av_title') .. ' (' .. curtype .. ')'
end

-- endregion


function CHC_uses:searchProcessToken(token, recipe)
    -- check if token is special search
    -- if so
    -- remove special char from token
    -- process special chars
    -- if not, compare token with recipe name
    --return state
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
    if isAllowSpecialSearch and char == '^' then
        -- show favorited reciped and search by them
        if not recipe.favorite then return false end
        whatCompare = string.lower(recipe.recipeData.name)
    end
    if isAllowSpecialSearch and char == '&' then
        -- search by mod(ule) name of recipe
        whatCompare = string.lower(recipe.module)
    end
    if token and isSpecialSearch then
        if char == '!' then
            -- search by recipe category
            local catName = getTextOrNull('IGUI_CraftCategory_' .. recipe.category) or recipe.category
            whatCompare = catName
        end
        local resultItem = recipe.recipeData.result
        if resultItem and resultItem.fullType then
            if char == '@' then
                -- search by mod name of resulting item
                whatCompare = resultItem.modname
            elseif char == '$' then
                -- search by DisplayCategory of resulting item
                local displayCat = resultItem.displayCategory or ''
                whatCompare = getText('IGUI_ItemCat_' .. displayCat) or 'None'
            elseif char == '%' then
                -- search by name of resulting item
                whatCompare = resultItem.displayName
            end
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
    end
    if token and not isSpecialSearch then
        whatCompare = string.lower(recipe.recipeData.name)
    end
    state = utils.compare(whatCompare, token)
    if not token then state = true end
    return state
end

function CHC_uses:processAddObjToObjList(recipe, modData) --FIXME
    if not self.showHidden and recipe.hidden then return end
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
    o.favCatName = '* ' .. getText('IGUI_CraftCategory_Favorite')
    o.categorySelectorDefaultOption = getText('UI_All')
    o.searchRowHelpText = getText('UI_searchrow_info',
        getText('UI_searchrow_info_recipes_special'),
        getText('UI_searchrow_info_recipes_examples')
    )
    o.objListSize = 0

    o.needUpdateFavorites = true
    o.needUpdateTypes = false
    o.needUpdateObjects = false
    o.needUpdateFont = false
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateModRender = false
    o.needUpdateShowIcons = false
    o.needUpdateRecipeState = false

    o.selectedCategory = o.categorySelectorDefaultOption
    o.backRef = args.backRef
    o.ui_type = args.ui_type
    o.favRecNum = 0
    o.isItemView = false
    o.modData = CHC_main.playerModData
    o.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
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

    o.numRecipes = { all = 0, valid = 0, known = 0, invalid = 0 }

    -- o.ms = 0
    return o
end
