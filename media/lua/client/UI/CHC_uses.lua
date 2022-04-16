require "ISUI/ISPanel"
require 'ISUI/ISContextMenu'
require "UI/CHC_tabs"
require "UI/CHC_uses_recipelist"
require "UI/CHC_uses_recipepanel"

local derivative = ISPanel
CHC_uses = derivative:derive("CHC_uses");
CHC_uses.sortOrderIconAsc = getTexture("media/textures/sort_order_asc.png")
CHC_uses.sortOrderIconDesc = getTexture("media/textures/sort_order_desc.png")
CHC_uses.typeFiltIconAll = getTexture("media/textures/type_filt_all.png")
CHC_uses.typeFiltIconValid = getTexture("media/textures/type_filt_valid.png")
CHC_uses.typeFiltIconKnown = getTexture("media/textures/type_filt_known.png")
CHC_uses.typeFiltIconInvalid = getTexture("media/textures/type_filt_invalid.png")
CHC_uses.searchIcon = getTexture("media/textures/search_icon.png")

local utils = require('CHC_utils')

local insert = table.insert
local sort = table.sort
local pairs = pairs
local concat = table.concat


-- region create
function CHC_uses:initialise()
    derivative.initialise(self);
    self:create();
end

function CHC_uses:create()

    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, 20, { self.onResizeHeaders, self }, self.sep_x)
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
            width = 24,
            title = "",
            onclick = self.sortByName,
            defaultTooltip = self:filterRowOrderSetTooltip(),
            defaultIcon = self:filterRowOrderSetIcon()
        },
        filterTypeData = {
            width = 24,
            title = "",
            onclick = self.onFilterTypeMenu,
            defaultTooltip = self:filterRowTypeSetTooltip(),
            defaultIcon = self:filterRowTypeSetIcon()
        },
        filterSelectorData = {
            defaultTooltip = getText("IGUI_invpanel_Category"),
            onChange = self.onChangeCategory
        }
    }

    self.filterRow = CHC_filter_row:new(x, y, leftW, 24, filterRowData)
    self.filterRow:initialise()
    local leftY = y + 24
    -- endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new(x, leftY, leftW, 24, nil, self.onTextChange, getText("UI_searchrow_info"))
    self.searchRow:initialise()
    leftY = leftY + 24
    -- endregion

    -- region recipe list
    local rlh = self.height - self.headers.height - self.filterRow.height - self.searchRow.height
    self.objList = CHC_uses_recipelist:new(x, leftY, leftW, rlh);
    self.objList.drawBorder = true;
    self.objList:initialise();
    self.objList:instantiate();
    self.objList:setAnchorBottom(true)
    self.objList:setOnMouseDownFunction(self, CHC_uses.onRecipeChange);
    -- endregion

    -- region recipe details windows
    local rph = self.height - self.headers.height
    self.objPanel = CHC_uses_recipepanel:new(rightX, y, rightW, rph);
    self.objPanel:initialise();
    self.objPanel:instantiate();
    self.objPanel:setAnchorRight(true)
    self.objPanel:setAnchorBottom(true)
    -- endregion

    -- Attach all to the craft helper window
    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.objList)
    self:addChild(self.objPanel)

    if self.ui_type == 'favorites' then
        self.favrec = self.backRef:getRecipes(true)
    end
    self:catSelUpdateOptions()
    self:cacheRecipeCounts()
    self:updateRecipes(self.selectedCategory)
end

-- endregion

-- region update

function CHC_uses:onTextChange()
    local s = self.parent.parent
    local stateText = s.searchRow.searchBar:getInternalText()
    if stateText ~= s.searchRow.searchBarLastText or stateText == "" then
        s.searchRow.searchBarLastText = stateText
        local option = s.filterRow.categorySelector
        local sl = option.options[option.selected].text
        s.selectedCategory = sl
        s.needUpdateRecipes = true
    end
end

function CHC_uses:onChangeCategory(_option, sl)
    self.parent.selectedCategory = sl or _option.options[_option.selected].text
    self.parent.needUpdateRecipes = true
end

function CHC_uses:cacheRecipeCounts()
    local recipes = self.ui_type == 'favorites' and self.favrec or self.recipeSource
    local is_valid
    local is_known
    ISCraftingUI.getContainers(self.objList)
    self.numRecipesAll, self.numRecipesValid, self.numRecipesKnown, self.numRecipesInvalid = 0, 0, 0, 0
    for i = 1, #recipes do
        is_valid = RecipeManager.IsRecipeValid(recipes[i].recipe, self.player, nil, self.objList.containerList)
        is_known = self.player:isRecipeKnown(recipes[i].recipe)
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

function CHC_uses:updateRecipes(sl)
    if type(sl) == "table" then sl = sl.text end
    local categoryAll = self.categorySelectorDefaultOption
    local searchBar = self.searchRow.searchBar
    local recipes = self.ui_type == 'favorites' and self.favrec or self.recipeSource

    if sl == categoryAll and self.typeFilter == "all" and searchBar:getInternalText() == "" then
        self:refreshRecipeList(recipes)
        return
    end

    -- get all containers nearby
    ISCraftingUI.getContainers(self.objList)

    -- filter recipes
    local filteredRecipes = {}
    for i = 1, #recipes do
        local rc = recipes[i].category
        local rc_tr = getTextOrNull("IGUI_CraftCategory_" .. rc) or rc

        local fav_cat_state = false
        local type_filter_state = false
        local search_state = false
        local condFav1 = sl == "* " .. getText("IGUI_CraftCategory_Favorite")
        local condFav2 = recipes[i].favorite
        if condFav1 and condFav2 then
            fav_cat_state = true
        end

        if (rc_tr == sl or sl == categoryAll) then
            type_filter_state = self:recipeTypeFilter(recipes[i])
        end
        search_state = self:searchTypeFilter(recipes[i])

        if (type_filter_state or fav_cat_state) and search_state then
            insert(filteredRecipes, recipes[i])
        end
    end
    self:refreshRecipeList(filteredRecipes)
end

function CHC_uses:processAddRecipeToRecipeList(recipe, modData)
    if not self.showHidden and recipe.recipe:isHidden() then return end
    local name = recipe.recipeData.name
    recipe.favorite = modData[CHC_main.getFavoriteModDataString(recipe.recipe)] or false

    self.objList:addItem(name, recipe)
end

function CHC_uses:refreshRecipeList(recipes)
    self.objList:clear()
    self.objList:setScrollHeight(0)

    local modData = getPlayer():getModData()

    for i = 1, #recipes do
        self:processAddRecipeToRecipeList(recipes[i], modData)
    end
    sort(self.objList.items, self.itemSortFunc)
end

function CHC_uses:onRecipeChange(recipe)
    self.objPanel:setRecipe(recipe);
    self.objList:onMouseDown_Recipes(self.objList:getMouseX(), self.objList:getMouseY())
end

function CHC_uses:update()
    if self.filterRow then
        if self.needUpdateFavorites == true then
            print('triggered upd favorites for: ' .. self.ui_type)
            -- self.backRef.updateQueue:push({action='updfav', })
            self:handleFavCategory()
            self.needUpdateFavorites = false
        end
        if self.needUpdateCounts == true then
            -- print('triggered upd counts for: ' .. self.ui_type)
            self:cacheRecipeCounts()
            self.needUpdateCounts = false
        end
    end
    if self.needUpdateRecipes == true then
        -- print('triggered upd recipes for: ' .. self.ui_type)
        self:updateRecipes(self.selectedCategory)
        self.needUpdateRecipes = false
    end
end

function CHC_uses:handleFavCategory()
    local cs = self.filterRow.categorySelector
    local csSel = cs.options[cs.selected]
    local cond3 = self.ui_type == 'favorites'

    if cond3 then
        self.favrec = self.backRef:getRecipes(true)
    end

    --if cond1 or cond2 or cond3 then
    self:catSelUpdateOptions()
    --end
    if csSel.text == self.favCatName then
        if csSel.data.count == 0 then
            self.selectedCategory = self.categorySelectorDefaultOption
        end
    end
    if self.favRecNum == 0 then
        if self.selectedCategory == self.favCatName then
            self.selectedCategory = self.categorySelectorDefaultOption
            self.needUpdateRecipes = true
        end
    end

    cs:select(self.selectedCategory)
    --update favorites in favorites view
    if not cond3 then
        self.backRef.updateQueue:push({
            targetView = 'favorites',
            actions = { 'needUpdateFavorites', 'needUpdateRecipes', 'needUpdateCounts' }
        })
    end
end

-- region filterRow setters
function CHC_uses:filterRowOrderSetTooltip()
    local cursort = self.itemSortAsc and getText("IGUI_invpanel_ascending") or getText("IGUI_invpanel_descending")
    return getText("UI_settings_st_title") .. " (" .. cursort .. ")"
end

function CHC_uses:filterRowOrderSetIcon()
    return self.itemSortAsc and self.sortOrderIconAsc or self.sortOrderIconDesc
end

function CHC_uses:filterRowTypeSetTooltip()
    local typeFilterToTxt = {
        all = self.categorySelectorDefaultOption,
        valid = getText("UI_settings_av_valid"),
        known = getText("UI_settings_av_known"),
        invalid = getText("UI_settings_av_invalid")
    }
    local curtype = typeFilterToTxt[self.typeFilter]
    return getText("UI_settings_av_title") .. " (" .. curtype .. ")"
end

function CHC_uses:filterRowTypeSetIcon()
    local typeFilterToIcon = {
        all = self.typeFiltIconAll,
        valid = self.typeFiltIconValid,
        known = self.typeFiltIconKnown,
        invalid = self.typeFiltIconInvalid
    }
    return typeFilterToIcon[self.typeFilter]
end

-- endregion


function CHC_uses:catSelUpdateOptions()

    local selector = self.filterRow.categorySelector
    local uniqueCategories = {}
    local catCounts = {}
    local allrec = self.ui_type == 'favorites' and self.favrec or self.recipeSource
    local c = 1
    self.favRecNum = 0
    for i = 1, #allrec do
        if allrec[i].favorite then
            self.favRecNum = self.favRecNum + 1
        end
        local rc = allrec[i].recipeData.category
        rc = getTextOrNull("IGUI_CraftCategory_" .. rc) or rc
        if not utils.any(uniqueCategories, rc) then
            uniqueCategories[c] = rc
            catCounts[rc] = 1
            c = c + 1
        else
            catCounts[rc] = catCounts[rc] + 1
        end
    end

    selector:clear()
    selector:addOptionWithData(self.categorySelectorDefaultOption, { count = #allrec })

    if self.favRecNum > 0 and self.ui_type ~= 'favorites' then
        selector:addOptionWithData(self.favCatName, { count = self.favRecNum })
    end

    sort(uniqueCategories)
    for _, rc in pairs(uniqueCategories) do
        selector:addOptionWithData(rc, { count = catCounts[rc] })
    end
end

-- endregion

-- region filters

-- region filter handlers
function CHC_uses:recipeTypeFilter(recipe)
    local rl = self.objList

    local is_valid = RecipeManager.IsRecipeValid(recipe.recipe, rl.player, nil, rl.containerList)
    local is_known = rl.player:isRecipeKnown(recipe.recipe)

    local state = true
    if self.typeFilter == 'all' then state = true end
    ;if self.typeFilter == 'valid' then state = is_valid end
    if self.typeFilter == 'known' then state = is_known and not is_valid end
    if self.typeFilter == 'invalid' then state = not is_known end
    return state
end

function CHC_uses:searchParseTokens(txt)

    local delim = { ",", "|" }
    local regex = "[^" .. concat(delim) .. "]+"
    local queryType

    txt = string.trim(txt)
    if not string.contains(txt, ',') and not string.contains(txt, "|") then
        return { txt }, false, nil
    end
    if string.contains(txt, ",") then queryType = 'AND'
    elseif string.contains(txt, '|') then queryType = "OR" end

    local tokens = {}
    for token in txt:gmatch(regex) do
        insert(tokens, token)
    end
    if #tokens == 1 then
        return tokens, false, nil
    elseif not tokens then -- just sep (e.g txt=",")
        return nil, false, nil
    end
    -- tokens = table.unpack(tokens, 1, #tokens-1)
    return tokens, true, queryType
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
        if token == "" then token = nil end
    end

    local whatCompare
    if isAllowSpecialSearch and char == "^" then
        -- show favorited reciped and search by them
        if not recipe.favorite then return false end
        whatCompare = string.lower(recipe.recipeData.name)
    end
    if token and isSpecialSearch then
        if char == "!" then
            -- search by recipe category
            local catName = getTextOrNull("IGUI_CraftCategory_" .. recipe.category) or recipe.category
            whatCompare = catName
        end
        local resultItem = CHC_main.items[recipe.recipeData.result.fullType]
        if resultItem then
            if char == "@" then
                -- search by mod name of resulting item
                whatCompare = resultItem.modname
            elseif char == "$" then
                -- search by DisplayCategory of resulting item
                local displayCat = resultItem.displayCategory or ""
                whatCompare = getText("IGUI_ItemCat_" .. displayCat) or "None"
            elseif char == "%" then
                -- search by name of resulting item
                whatCompare = resultItem.displayName
            end
        end
        if char == "#" then
            -- search by ingredients
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

function CHC_uses:searchTypeFilter(recipe)
    local stateText = string.trim(self.searchRow.searchBar:getInternalText())
    local tokens, isMultiSearch, queryType = CHC_search_bar:parseTokens(stateText)
    local tokenStates = {}
    local state = false

    if not tokens then return true end

    if isMultiSearch then
        for i = 1, #tokens do
            insert(tokenStates, self:searchProcessToken(tokens[i], recipe))
        end
        for i = 1, #tokenStates do
            if queryType == 'OR' then
                if tokenStates[i] then
                    state = true
                    break
                end
            end
            if queryType == 'AND' and i > #tokenStates - 1 then
                local allPrev = utils.all(tokenStates, true, 1, #tokenStates)
                if allPrev and tokenStates[i] then
                    state = true
                    break
                end
            end
        end
    else -- one token
        state = self:searchProcessToken(tokens[1], recipe)
    end
    return state
end

-- endregion

-- region filter logic handlers
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

    local newIcon = self:filterRowOrderSetIcon()
    self.filterRow.filterOrderBtn:setImage(newIcon)
    local newTooltip = self:filterRowOrderSetTooltip()
    self.filterRow.filterOrderBtn:setTooltip(newTooltip)
    self.selectedCategory = sl
    self.needUpdateRecipes = true
end

function CHC_uses:sortByType(_type)
    local option = self.filterRow.categorySelector
    local sl = option.options[option.selected].text

    local stateChanged = false
    if _type == "all" and self.typeFilter ~= 'all' then
        self.typeFilter = 'all'
        stateChanged = true
    end
    if _type == "valid" and self.typeFilter ~= 'valid' then
        self.typeFilter = 'valid'
        stateChanged = true
    end
    if _type == "known" and self.typeFilter ~= 'known' then
        self.typeFilter = 'known'
        stateChanged = true
    end
    if _type == "invalid" and self.typeFilter ~= 'invalid' then
        self.typeFilter = 'invalid'
        stateChanged = true
    end

    if stateChanged then
        self.filterRow.filterTypeBtn:setTooltip(self:filterRowTypeSetTooltip())
        self.filterRow.filterTypeBtn:setImage(self:filterRowTypeSetIcon())
        self.selectedCategory = sl
        self.needUpdateRecipes = true
    end
end

-- endregion

-- region filter onClick handlers

function CHC_uses:filterSortMenuGetText(textStr, value)
    local txt = getText(textStr)
    if value then
        txt = txt .. " (" .. tostring(value) .. ")"
    end
    return txt
end

function CHC_uses:onFilterTypeMenu(button)
    local self = self.parent
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 10, y)

    local data = {
        { txt = "UI_All", num = self.numRecipesAll, arg = 'all' },
        { txt = "UI_settings_av_valid", num = self.numRecipesValid, arg = 'valid' },
        { txt = "UI_settings_av_known", num = self.numRecipesKnown, arg = 'known' },
        { txt = "UI_settings_av_invalid", num = self.numRecipesInvalid, arg = 'invalid' }
    }

    local txt = nil
    for i = 1, #data do
        txt = self:filterSortMenuGetText(data[i].txt, data[i].num)
        context:addOption(txt, self, CHC_uses.sortByType, data[i].arg)
    end
end

-- endregion
-- endregion

-- region render
function CHC_uses:prerender()
end

function CHC_uses:render()
    -- CHC_tabs.render(self)
end

function CHC_uses:onResizeHeaders()
    self.filterRow:setWidth(self.headers.nameHeader.width)
    self.searchRow:setWidth(self.headers.nameHeader.width)
    self.objList:setWidth(self.headers.nameHeader.width)
    self.objPanel:setWidth(self.headers.typeHeader.width)
    self.objPanel:setX(self.headers.typeHeader.x)
end

-- endregion


function CHC_uses:new(args)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    -- local item = args.item

    local o = {};
    o = derivative:new(x, y, w, h);

    setmetatable(o, self);
    self.__index = self;

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 };
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 };

    o.item = args.item or nil
    o.recipeSource = args.recipeSource
    o.itemSortAsc = args.itemSortAsc
    o.typeFilter = args.typeFilter
    o.showHidden = args.showHidden
    o.sep_x = args.sep_x
    o.itemSortFunc = o.itemSortAsc == true and CHC_uses.sortByNameAsc or CHC_uses.sortByNameDesc
    o.player = getPlayer()
    o.favCatName = "* " .. getText("IGUI_CraftCategory_Favorite")
    o.categorySelectorDefaultOption = getText("UI_All")

    o.needUpdateFavorites = true
    o.needUpdateCounts = false
    o.needUpdateRecipes = false
    o.selectedCategory = o.categorySelectorDefaultOption
    o.backRef = args.backRef
    o.ui_type = args.ui_type
    o.favRecNum = 0


    o.numRecipesAll = 0
    o.numRecipesValid = 0
    o.numRecipesKnown = 0
    o.numRecipesInvalid = 0
    return o;
end
