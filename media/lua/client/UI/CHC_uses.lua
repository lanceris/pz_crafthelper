require 'ISUI/ISPanel'
require 'ISUI/ISContextMenu'
require 'UI/CHC_tabs'
require 'UI/CHC_uses_recipelist'
require 'UI/CHC_uses_recipepanel'

local hh = {
    headers = 20,
    filter_row = 24,
    search_row = 24
}

local fontSizeToInternal = {
    { font = UIFont.Small,  pad = 2, icon = 10, ymin = 2 },
    { font = UIFont.Medium, pad = 4, icon = 18, ymin = -2 },
    { font = UIFont.Large,  pad = 6, icon = 24, ymin = -4 }
}

local derivative = ISPanel
CHC_uses = derivative:derive('CHC_uses')
CHC_uses.sortOrderIconAsc = getTexture('media/textures/sort_order_asc.png')
CHC_uses.sortOrderIconDesc = getTexture('media/textures/sort_order_desc.png')
CHC_uses.typeFiltIconAll = getTexture('media/textures/type_filt_all.png')
CHC_uses.typeFiltIconValid = getTexture('media/textures/type_filt_valid.png')
CHC_uses.typeFiltIconKnown = getTexture('media/textures/type_filt_known.png')
CHC_uses.typeFiltIconInvalid = getTexture('media/textures/type_filt_invalid.png')

local utils = require('CHC_utils')

local insert = table.insert
local sort = table.sort

-- region create
function CHC_uses:initialise()
    derivative.initialise(self)
    self:create()
end

function CHC_uses:create()
    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, hh.headers, { self.onResizeHeaders, self }, self.sep_x)
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
            width = hh.filter_row,
            title = '',
            onclick = self.sortByName,
            defaultTooltip = self:filterOrderSetTooltip(),
            defaultIcon = self:filterOrderSetIcon()
        },
        filterTypeData = {
            width = hh.filter_row,
            title = '',
            onclick = self.onFilterTypeMenu,
            defaultTooltip = self:filterTypeSetTooltip(),
            defaultIcon = self:filterTypeSetIcon()
        },
        filterSelectorData = {
            defaultTooltip = getText('IGUI_invpanel_Category'),
            onChange = self.onChangeCategory
        }
    }

    self.filterRow = CHC_filter_row:new({ x = x, y = y, w = leftW, h = hh.filter_row, backRef = self.backRef },
        filterRowData)
    self.filterRow:initialise()
    local leftY = y + hh.filter_row
    -- endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new({ x = x, y = leftY, w = leftW, h = hh.search_row, backRef = self.backRef }, nil,
        self.onTextChange, self.searchRowHelpText)
    self.searchRow:initialise()
    leftY = leftY + hh.search_row
    -- endregion

    -- region recipe list
    local rlh = self.height - self.headers.height - self.filterRow.height - self.searchRow.height
    self.objList = CHC_uses_recipelist:new({ x = x, y = leftY, w = leftW, h = rlh, backRef = self.backRef })
    self.objList.drawBorder = true
    self.objList.onRightMouseDown = self.onRMBDownObjList
    self.objList:initialise()
    self.objList:instantiate()
    self.objList:setAnchorBottom(true)
    self.objList:setOnMouseDownFunction(self, CHC_uses.onRecipeChange)
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
        self.favrec = self.backRef:getRecipes(true)
    end
    self:updateCategories()
    self:updateTypes()
    self:updateRecipes(self.selectedCategory)
end

-- endregion

-- region update

function CHC_uses:update()
    if self.needUpdateFont then
        self.curFontData = fontSizeToInternal[CHC_settings.config.list_font_size]
        self.objList.curFontData = self.curFontData
        if self.objList.font ~= self.curFontData.font then
            self.objList:setFont(self.curFontData.font, self.curFontData.pad)
        end
        self.needUpdateFont = false
    end

    if self.needUpdateObjects then
        self:updateRecipes(self.selectedCategory)
        self:updateTabNameWithCount()
        self.needUpdateObjects = false
    end
    if self.needUpdateFavorites then
        self:handleFavCategory(self.updFavWithCur)
        if self.favrec then
            self:updateTabNameWithCount(self.favRecNum)
        end
        self.needUpdateFavorites = false
        self.updFavWithCur = false
    end
    if self.needUpdateTypes then
        self:updateTypes()
        self.needUpdateTypes = false
    end
end

function CHC_uses:updateRecipes(sl)
    if type(sl) == 'table' then sl = sl.text end
    local categoryAll = self.categorySelectorDefaultOption
    local searchBar = self.searchRow.searchBar
    local recipes = self.ui_type == 'fav_recipes' and self.favrec or self.recipeSource

    if sl == categoryAll and self.typeFilter == 'all' and searchBar:getInternalText() == '' then
        self:refreshObjList(recipes)
        return
    end

    -- get all containers nearby
    self.getContainers(self.objList)

    -- filter recipes
    local filteredRecipes = {}
    for i = 1, #recipes do
        local rc = recipes[i].category
        local rc_tr = getTextOrNull('IGUI_CraftCategory_' .. rc) or rc

        local fav_cat_state = false
        local type_filter_state = false
        local search_state = false
        local condFav1 = sl == '* ' .. getText('IGUI_CraftCategory_Favorite')
        local condFav2 = recipes[i].favorite
        if condFav1 and condFav2 then
            fav_cat_state = true
        end

        if (rc_tr == sl or sl == categoryAll) then
            type_filter_state = self:recipeTypeFilter(recipes[i])
        end
        search_state = CHC_main.common.searchFilter(self, recipes[i], self.searchProcessToken)

        if (type_filter_state or fav_cat_state) and search_state then
            insert(filteredRecipes, recipes[i])
        end
    end
    self:refreshObjList(filteredRecipes)
end

function CHC_uses:updateTypes()
    local recipes = self.ui_type == 'fav_recipes' and self.favrec or self.recipeSource
    local is_valid
    local is_known
    self.getContainers(self.objList)
    self.numRecipesAll, self.numRecipesValid, self.numRecipesKnown, self.numRecipesInvalid = 0, 0, 0, 0
    local c2 = self.selectedCategory == self.categorySelectorDefaultOption
    local c3 = self.selectedCategory == self.favCatName
    for i = 1, #recipes do
        local recipe = recipes[i]
        local c1 = recipe.displayCategory == self.selectedCategory
        if c1 or c2 or (c3 and recipe.favorite) then
            if recipe.isSynthetic then
                is_valid = false
                is_known = true
            elseif recipe.isEvolved then
                is_valid = CHC_main.common.isEvolvedRecipeValid(recipe, self.objList.containerList)
                is_known = true
            else
                is_valid = RecipeManager.IsRecipeValid(recipe.recipe, self.player, nil, self.objList.containerList)
                is_known = self.player:isRecipeKnown(recipe.recipe)
            end
            self.numRecipesAll = self.numRecipesAll + 1
            if is_known and not is_valid then
                self.numRecipesKnown = self.numRecipesKnown + 1
            elseif is_valid then
                self.numRecipesValid = self.numRecipesValid + 1
            else
                self.numRecipesInvalid = self.numRecipesInvalid + 1
            end
        end
    end
    if self.numRecipesValid == 0 and self.typeFilter == 'valid' or
        self.numRecipesKnown == 0 and self.typeFilter == 'known' or
        self.numRecipesInvalid == 0 and self.typeFilter == 'invalid' then
        self:sortByType('all')
    end
end

function CHC_uses:updateCategories(current)
    local selector = self.filterRow.categorySelector
    local uniqueCategories = {}
    local catCounts = {}
    local curCats = nil
    local allrec = self.ui_type == 'fav_recipes' and self.favrec or self.recipeSource
    local c1 = self.typeFilter == 'all'
    local c = 1
    self.favRecNum = 0

    if current and (not c1) then
        --collect current items categories
        local curList = self.objList.items
        for i = 1, #curList do
            local cat = curList[i].item.recipeData.category
            local catT = getTextOrNull('IGUI_CraftCategory_' .. cat) or cat
            if not curCats then curCats = {} end
            curCats[catT] = true
        end
    end


    for i = 1, #allrec do
        if allrec[i].favorite then
            self.favRecNum = self.favRecNum + 1
        end
        local rc = allrec[i].recipeData.category
        rc = getTextOrNull('IGUI_CraftCategory_' .. rc) or rc
        if (not current) or (current and (c1 or curCats[rc])) then
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

    if self.favRecNum > 0 and self.ui_type ~= 'fav_recipes' then
        selector:addOptionWithData(self.favCatName, { count = self.favRecNum })
    end

    sort(uniqueCategories)
    for i = 1, #uniqueCategories do
        selector:addOptionWithData(uniqueCategories[i], { count = catCounts[uniqueCategories[i]] })
    end
end

function CHC_uses:refreshObjList(recipes)
    local objL = self.objList
    objL:clear()

    for i = 1, #recipes do
        self:processAddObjToObjList(recipes[i], self.modData)
    end
    sort(objL.items, self.itemSortFunc)
    if objL.items and #objL.items > 0 then
        local ix = 1
        objL.selected = ix
        objL:ensureVisible(ix)
        self.objPanel:setObj(objL.items[ix].item)
    end

    self.objListSize = #objL.items
end

function CHC_uses:handleFavCategory(current)
    local cs = self.filterRow.categorySelector
    local csSel = cs.options[cs.selected]
    local cond3 = self.ui_type == 'fav_recipes'

    if cond3 then
        self.favrec = self.backRef:getRecipes(true)
    end

    --if cond1 or cond2 or cond3 then
    self:updateCategories(current)
    --end
    if self.favRecNum == 0 and
        self.selectedCategory == self.favCatName or
        csSel.data.count == 1 then
        self.selectedCategory = self.categorySelectorDefaultOption
        self.needUpdateObjects = true
    end

    cs:select(self.selectedCategory)
    --update favorites in favorites view
    if not cond3 then
        self.backRef.updateQueue:push({
            targetView = 'fav_recipes',
            actions = { 'needUpdateFavorites', 'needUpdateObjects', 'needUpdateTypes' }
        })
    end
end

function CHC_uses:updateTabNameWithCount(listSize)
    listSize = listSize and listSize or self.objListSize
    self.backRef.updateQueue:push({
        targetView = self.ui_type,
        actions = { 'needUpdateSubViewName' },
        data = { needUpdateSubViewName = listSize }
    })
end

-- endregion

-- region render

function CHC_uses:render()
    ISPanel.render(self)
    if self.needUpdateScroll then
        self.objList.needUpdateScroll = true
        self.objPanel.needUpdateScroll = true
        self.needUpdateScroll = false
    end
    if self.needUpdateMousePos then
        self.objList.needUpdateMousePos = true
        self.objPanel.needUpdateMousePos = true
        self.needUpdateMousePos = false
    end
end

function CHC_uses:onResizeHeaders()
    self.filterRow:setWidth(self.headers.nameHeader.width)
    self.searchRow:setWidth(self.headers.nameHeader.width)
    self.objList:setWidth(self.headers.nameHeader.width)
    self.objPanel:setWidth(self.headers.typeHeader.width)
    self.objPanel:setX(self.headers.typeHeader.x)
end

-- endregion

-- region logic

-- region event handlers
function CHC_uses:onTextChange()
    self.needUpdateObjects = true
end

function CHC_uses:onChangeCategory(_option, sl)
    self.parent.selectedCategory = sl or _option.options[_option.selected].text
    self.parent.needUpdateObjects = true
    self.parent.needUpdateTypes = true
end

function CHC_uses:onRecipeChange(recipe)
    self.objPanel:setObj(recipe)
    self.objList:onMouseDown_Recipes(self.objList:getMouseX(), self.objList:getMouseY())
end

function CHC_uses:onFilterTypeMenu(button)
    local self = self.parent
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 10, y)

    local data = {
        { txt = 'UI_All',                 num = self.numRecipesAll,     arg = 'all' },
        { txt = 'UI_settings_av_valid',   num = self.numRecipesValid,   arg = 'valid' },
        { txt = 'UI_settings_av_known',   num = self.numRecipesKnown,   arg = 'known' },
        { txt = 'UI_settings_av_invalid', num = self.numRecipesInvalid, arg = 'invalid' }
    }

    local txt = nil
    for i = 1, #data do
        if data[i].num > 0 then
            txt = self:filterSortMenuGetText(data[i].txt, data[i].num)
            context:addOption(txt, self, CHC_uses.sortByType, data[i].arg)
        end
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


function CHC_uses:sortByName()
    local self = self.parent
    local option = self.filterRow.categorySelector
    local sl = option.options[option.selected].text
    self.itemSortAsc = not self.itemSortAsc
    self.itemSortFunc = self.itemSortAsc and CHC_uses.sortByNameAsc or CHC_uses.sortByNameDesc

    local newIcon = self:filterOrderSetIcon()
    self.filterRow.filterOrderBtn:setImage(newIcon)
    local newTooltip = self:filterOrderSetTooltip()
    self.filterRow.filterOrderBtn:setTooltip(newTooltip)
    self.selectedCategory = sl
    self.needUpdateObjects = true
end

function CHC_uses:sortByType(_type)
    if _type ~= self.typeFilter then
        self.typeFilter = _type
        self.filterRow.filterTypeBtn:setTooltip(self:filterTypeSetTooltip())
        self.filterRow.filterTypeBtn:setImage(self:filterTypeSetIcon())
        self.needUpdateObjects = true
        self.updFavWithCur = true
        self.needUpdateFavorites = true
    end
end

-- endregion

-- region filterRow setters
function CHC_uses:filterOrderSetTooltip()
    local cursort = self.itemSortAsc and getText('IGUI_invpanel_ascending') or getText('IGUI_invpanel_descending')
    return getText('UI_settings_st_title') .. ' (' .. cursort .. ')'
end

function CHC_uses:filterOrderSetIcon()
    return self.itemSortAsc and self.sortOrderIconAsc or self.sortOrderIconDesc
end

function CHC_uses:filterTypeSetTooltip()
    local typeFilterToTxt = {
        all = self.categorySelectorDefaultOption,
        valid = getText('UI_settings_av_valid'),
        known = getText('UI_settings_av_known'),
        invalid = getText('UI_settings_av_invalid')
    }
    local curtype = typeFilterToTxt[self.typeFilter]
    return getText('UI_settings_av_title') .. ' (' .. curtype .. ')'
end

function CHC_uses:filterTypeSetIcon()
    local typeFilterToIcon = {
        all = self.typeFiltIconAll,
        valid = self.typeFiltIconValid,
        known = self.typeFiltIconKnown,
        invalid = self.typeFiltIconInvalid
    }
    return typeFilterToIcon[self.typeFilter]
end

-- endregion


function CHC_uses:filterSortMenuGetText(textStr, value)
    local txt = getTextOrNull(textStr) or textStr
    if value then
        txt = txt .. ' (' .. tostring(value) .. ')'
    end
    return txt
end

function CHC_uses:recipeTypeFilter(recipe)
    local rl = self.objList
    local is_valid
    local is_known
    if recipe.isSynthetic then
        is_valid = false
        is_known = true
    elseif recipe.isEvolved then
        is_valid = CHC_main.common.isEvolvedRecipeValid(recipe, rl.containerList)
        is_known = true
    else
        is_valid = RecipeManager.IsRecipeValid(recipe.recipe, rl.player, nil, rl.containerList)
        is_known = rl.player:isRecipeKnown(recipe.recipe)
    end

    local state = true
    if self.typeFilter == 'all' then state = true end
    if self.typeFilter == 'valid' then state = is_valid end
    if self.typeFilter == 'known' then state = is_known and not is_valid end
    if self.typeFilter == 'invalid' then state = not is_known end
    return state
end

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
                    local item = CHC_main.items[source.fullType]
                    if item then insert(items, item.displayName) end
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

function CHC_uses:processAddObjToObjList(recipe, modData)
    if not self.showHidden and recipe.hidden then return end
    local name = recipe.recipeData.name
    recipe.favorite = modData[CHC_main.getFavoriteRecipeModDataString(recipe)] or false

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
    o.recipeSource = args.recipeSource
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

    o.selectedCategory = o.categorySelectorDefaultOption
    o.backRef = args.backRef
    o.ui_type = args.ui_type
    o.favRecNum = 0
    o.updFavWithCur = false
    o.isItemView = false
    o.modData = CHC_main.playerModData
    o.curFontData = fontSizeToInternal[CHC_settings.config.list_font_size]


    o.numRecipesAll = 0
    o.numRecipesValid = 0
    o.numRecipesKnown = 0
    o.numRecipesInvalid = 0

    -- o.ms = 0
    return o
end
