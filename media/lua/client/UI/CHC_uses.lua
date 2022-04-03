require "ISUI/ISPanel"
require 'ISUI/ISButton'
require 'ISUI/ISContextMenu'
require 'ISUI/ISTextEntryBox'
require "UI/CHC_tabs"
require "UI/CHC_uses_recipelist"
require "UI/CHC_uses_recipepanel"


CHC_uses = ISPanel:derive("CHC_uses");
CHC_uses.sortOrderIconAsc = getTexture("media/textures/sort_order_asc.png")
CHC_uses.sortOrderIconDesc = getTexture("media/textures/sort_order_desc.png")
CHC_uses.typeFiltIconAll = getTexture("media/textures/type_filt_all.png")
CHC_uses.typeFiltIconValid = getTexture("media/textures/type_filt_valid.png")
CHC_uses.typeFiltIconKnown = getTexture("media/textures/type_filt_known.png")
CHC_uses.typeFiltIconInvalid = getTexture("media/textures/type_filt_invalid.png")
CHC_uses.searchIcon = getTexture("media/textures/search_icon.png")

CHC_uses.localData = {
    typeFilterToNumOfRecipes = {}
}

local function all(t, val, start, stop, step)
    start = start or 1
    stop = stop or #t
    step = step or 1
    for i=start, stop, step do
        if t[i] ~= val then return false end
    end
    return true
end

local function any(t, val, start, stop, step)
    start = start or 1
    stop = stop or #t
    step = step or 1
    for i=start, stop, step do
        if t[i] == val then return true end
    end
    return false
end


local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function startswith(txt, start)
    return string.sub(txt, 1, string.len(start)) == start
end


-- region create
function CHC_uses:initialise()
    ISPanel.initialise(self);
    -- self.localData.typeFilterToNumOfRecipes['all'] = self.numRecipesAll
    -- self.localData.typeFilterToNumOfRecipes['valid'] = self.numRecipesValid
    -- self.localData.typeFilterToNumOfRecipes['known'] = self.numRecipesKnown
    -- self.localData.typeFilterToNumOfRecipes['invalid'] = self.numRecipesInvalid
    self:create();
end

function CHC_uses:createFilterRow(x, y, w, h, defaultCategory)
    local filterRowContainer = ISPanel:new(x, y, w, h)

    self.filterOrderBtn = ISButton:new(x, 0, h, h, "", self, self.onFilterSortMenu)
    self.filterOrderBtn:initialise()
    self.filterOrderBtn.borderColor.a = 0

    x = x + self.filterOrderBtn.width

    self.filterTypeBtn = ISButton:new(x, 0, h, h, "", self, self.onFilterTypeMenu)
    self.filterTypeBtn:initialise()
    self.filterTypeBtn.borderColor.a = 0

    x = x + self.filterTypeBtn.width

    local dw = self.filterOrderBtn.width+self.filterTypeBtn.width
    self.categorySelector = ISComboBox:new(x, 0, w-dw, h)
    self.categorySelector:initialise();
    self.categorySelector.selected = 1;
    self.categorySelector:addOption(defaultCategory)
    self.categorySelector.onChange = self.onChangeUsesRecipeCategory
    self.categorySelector.target = self

    filterRowContainer.deltaW = dw

    return filterRowContainer
end

function CHC_uses:createSearchRow(x,y,w,h)
    local searchRowContainer = ISPanel:new(x, y, w, h)
    self.searchBtn = ISButton:new(x, 0, h, h, "", nil, nil)
    self.searchBtn:initialise()
    self.searchBtn.borderColor.a = 0
    self.searchBtn:setImage(self.searchIcon)

    x = x + self.searchBtn.width

    local dw = self.searchBtn.width
    self.searchBar = ISTextEntryBox:new("", x, 0, w-dw, h)
    self.searchBar:setTooltip(string.sub(getText("IGUI_CraftUI_Name_Filter"), 1, -2))
    self.searchBar:initialise()
    self.searchBar:instantiate()
    self.searchBar:setText("")
    self.searchBar:setClearButton(true)
    self.searchBarLastText = self.searchBar:getInternalText()
    self.searchBarText = self.searchBarLastText
    self.searchBar.onTextChange = self.onTextChange

    searchRowContainer.deltaW = dw
    return searchRowContainer
end

function CHC_uses:create()

    self.allRecipesForItem = CHC_main.recipesByItem[self.item:getName()];

    -- region draggable headers
    local categoryWid = math.max(100,self.column4-self.column3-1)
    if self.column3 - 1 + categoryWid > self.width then
        self.column3 = self.width - categoryWid + 1
    end
    self.tabName1 = getText("UI_tab_uses_recipe_title")
    self.tabName2 = getText("UI_tab_uses_details_title")
    self.nameHeader, self.typeHeader = CHC_tabs.addTabs(self);
    self.nameHeader:setAlwaysOnTop(true);
    self.typeHeader:setAlwaysOnTop(true);
    -- endregion

    local x = self.nameHeader.x
    local y = self.nameHeader.y+self.nameHeader.height

    -- region filters UI
    local defaultCategory = getText("UI_tab_uses_categorySelector_All")
    self.filterRowContainer = self:createFilterRow(x, y, self.nameHeader.width, 24, defaultCategory)
    y = y + 24
    
    -- endregion

    -- region category selector data
    -- We add combobox to select recipe category
    -- Add categories to selector
    local uniqueCategories = {};
    local is_fav_recipes = false
    for _,recipe in ipairs(self.allRecipesForItem) do
        if not is_fav_recipes and recipe.favorite then
            is_fav_recipes = true
        end
        local rc = recipe.recipe:getCategory() or getText("UI_category_default")
        rc = getTextOrNull("IGUI_CraftCategory_"..rc) or rc
        if not has_value(uniqueCategories, rc) then
            table.insert(uniqueCategories, rc)
        end
	end

    if is_fav_recipes then self.categorySelector:addOption("* "..getText("UI_tab_uses_categorySelector_Favorite")) end;

    table.sort(uniqueCategories)
    for _, rc in pairs(uniqueCategories) do
        self.categorySelector:addOption(rc)
    end
    --endregion

    -- region search bar
    self.searchRowContainer = self:createSearchRow(self.nameHeader.x, y, self.nameHeader.width, 24)
    y = y + 24
    -- endregion

    -- region recipe list
    local rlh = self.height-self.nameHeader.height-self.filterRowContainer.height-self.searchRowContainer.height-1
    self.recipesList = CHC_uses_recipelist:new(self.nameHeader.x, y, self.nameHeader.width, rlh);

    self.recipesList.drawBorder = true;
	self.recipesList:initialise();
	self.recipesList:instantiate();
	self.recipesList:setAnchorBottom(true)
    self.recipesList:setOnMouseDownFunction(self, CHC_uses.onRecipeChange);

    -- Add entries to recipeList
    self:updateRecipes(defaultCategory)
    -- endregion

    -- region recipe details windows
    self.recipePanel = CHC_uses_recipepanel:new(self.typeHeader.x, 
                        self.typeHeader.y+self.typeHeader.height, 
                        self.typeHeader.width, self.height);
	self.recipePanel:initialise();
	self.recipePanel:instantiate();
	self.recipePanel:setAnchorRight(true)
	self.recipePanel:setAnchorBottom(true)
    -- endregion

    -- region set initial icons
    local foi, fti = nil, nil
    if self.itemSortAsc then
        foi = self.sortOrderIconAsc
    elseif not self.itemSortAsc then
        foi = self.sortOrderIconDesc
    end
    

    if self.typeFilter == 'all' then
        fti = self.typeFiltIconAll
    elseif self.typeFilter == 'valid' then
        fti = self.typeFiltIconValid
    elseif self.typeFilter == 'known' then
        fti = self.typeFiltIconKnown
    elseif self.typeFilter == 'invalid' then
        fti = self.typeFiltIconInvalid
    end

    self.filterOrderBtn:setImage(foi)
    self.filterTypeBtn:setImage(fti)
    -- endregion

    -- Attach all to the craft helper window
    self.filterRowContainer:addChild(self.filterOrderBtn)
    self.filterRowContainer:addChild(self.filterTypeBtn)
    self.filterRowContainer:addChild(self.categorySelector)
    self:addChild(self.filterRowContainer)
    self.searchRowContainer:addChild(self.searchBtn)
    self.searchRowContainer:addChild(self.searchBar)
    self:addChild(self.searchRowContainer)
	self:addChild(self.recipesList)
	self:addChild(self.recipePanel)

end

-- endregion

-- region update

function CHC_uses:onTextChange()
    local s = self.parent.parent;
    local stateText = s.searchBar:getInternalText()
    if stateText ~= s.searchBarLastText or stateText == "" then
        s.searchBarLastText = stateText
        local option = s.categorySelector
        local sl = option.options[option.selected]
        s:updateRecipes(sl)
    end
end

function CHC_uses:onChangeUsesRecipeCategory(_option, sl)
    if not sl then
        sl = _option.options[_option.selected]
    end
    self:updateRecipes(sl)
end

function CHC_uses:updateRecipes(sl)
    local categoryAll = getText("UI_tab_uses_categorySelector_All")
    if sl == categoryAll and self.typeFilter == "all" and self.searchBar:getInternalText() == "" then
        self:refreshRecipeList(self.allRecipesForItem)
        return
    end

    -- get all containers nearby
    ISCraftingUI.getContainers(self.recipesList)

    -- filter recipes
    local filteredRecipes = {}
    for _, recipe in ipairs(self.allRecipesForItem) do
        local rc = recipe.category
        local rc_tr = getTextOrNull("IGUI_CraftCategory_"..rc) or rc

        local fav_cat_state = false
        local type_filter_state = false
        local search_state = false
        if sl == "* "..getText("UI_tab_uses_categorySelector_Favorite") and recipe.favorite then
            fav_cat_state = true
        end

        if (rc_tr == sl or sl == categoryAll) then
            type_filter_state = self:recipeTypeFilter(recipe)
        end
        search_state = self:searchTypeFilter(recipe)
        
        if (type_filter_state or fav_cat_state) and search_state then
            table.insert(filteredRecipes, recipe)
        end
    end
    self:refreshRecipeList(filteredRecipes)
end

function CHC_uses:refreshRecipeList(recipes)
    self.recipesList:clear()
    self.recipesList:setScrollHeight(0)

    local modData = getPlayer():getModData()
    for _, recipe in ipairs(recipes) do
        local name = recipe.recipe:getName()
        recipe.favorite = modData[CHC_main.getFavoriteModDataString(recipe.recipe)] or false
        self.recipesList:addItem(name, recipe);
    end
    table.sort(self.recipesList.items, self.itemSortFunc)
end

function CHC_uses:onRecipeChange(recipe)
	self.recipePanel:setRecipe(recipe);
    self.recipesList:onMouseDown_Recipes(self.recipesList:getMouseX(), self.recipesList:getMouseY())
end

-- endregion

-- region filters

-- region filter handlers
function CHC_uses:recipeTypeFilter(recipe)
    local rl = self.recipesList

    local is_valid = RecipeManager.IsRecipeValid(recipe.recipe, rl.player, nil, rl.containerList)
    local is_known = rl.player:isRecipeKnown(recipe.recipe)

    local state = true
    if self.typeFilter == 'all' then state = true end;
    if self.typeFilter == 'valid' then state = is_valid end
    if self.typeFilter == 'known' then state = is_known and not is_valid end
    if self.typeFilter == 'invalid' then state = not is_known end
    return state
end


function CHC_uses:searchIsSpecialCommand(txt)
    -- !: search by recipe category
    -- @: search by mod name of resulting item
    -- #: search by recipe ingredients
    -- $: search by DisplayCategory of resulting item
    -- %: search by name of resulting item
    -- ^: show favorited recipes only
    local validSpecialChars = {"!", "@", "#", "$", "%", "^"} -- @@@
    for _, char in ipairs(validSpecialChars) do
        if startswith(txt, char) then return true end
    end
    return false
end

local function compare(what, to, isList, passAll)
    if passAll then return true end
    isList = type(what) == "table"
    to = string.lower(tostring(to))
    local state = false
    if not isList then
        what = string.lower(tostring(what))
        if string.contains(what, to) then
            state = true
        end
    else
        for i=1, #what do
            local wh = string.lower(tostring(what[i]))
            if string.contains(wh, to) then
                state = true
                break
            end
        end
    end
    return state
end

function CHC_uses:searchParseTokens(txt)

    local delim = {",", "|"}
    local regex = "[^"..table.concat(delim).."]+"
    local queryType

    txt = string.trim(txt)
    if not string.contains(txt, ',') and not string.contains(txt, "|") then
        return {txt}, false, nil
    end
    if string.contains(txt,",") then queryType = 'AND'
    elseif string.contains(txt,'|') then queryType = "OR" end

    local tokens = {}
    for token in txt:gmatch(regex) do
        table.insert(tokens, token)
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
    local isAllowSpecialSearch = true -- @@@ to settings
    local isSpecialSearch = false
    local char
    local items = {}

    if self:searchIsSpecialCommand(token) then
        isSpecialSearch = true
        char = token:sub(1, 1)
        token = string.sub(token, 2)
        if token == "" then token = nil end
    end

    local whatCompare
    if char == "^" then
        -- show favorited reciped and search by them
        if not recipe.favorite then return false end
        whatCompare = string.lower(recipe.recipe:getName())
    end
    if token and isSpecialSearch then
        if char == "!" then
            -- search by recipe category
            whatCompare = recipe.recipe:getCategory() or getText("UI_category_default")
        end
        local resultItem = CHC_main.items[recipe.recipe:getResult():getFullType()]
        if resultItem then
            if char == "@" then
                -- search by mod name of resulting item
                whatCompare = resultItem:getModName()
            elseif char == "$" then
                -- search by DisplayCategory of resulting item
                local displayCat = resultItem:getDisplayCategory() or ""
                whatCompare = getText("IGUI_ItemCat_" .. displayCat) or "None"
            elseif char == "%" then
                -- search by name of resulting item
                whatCompare = resultItem:getDisplayName()
            end
        end
        if char == "#" then
            -- search by ingredients
            local rSources = recipe.recipe:getSource()
            
            -- Go through items needed by the recipe
            for n=0, rSources:size() - 1 do
                -- Get the item name (not the display name)
                local rSource = rSources:get(n)
                local sItems = rSource:getItems()
                for k=0, sItems:size() - 1 do
                    local itemString = sItems:get(k)
                    local item = CHC_main.items[itemString]:getDisplayName()
                    if item then table.insert(items, item) end
                end
            end
            whatCompare = items
        end
    end
    if token and not isSpecialSearch then
        whatCompare = string.lower(recipe.recipe:getName())
    end
    state = compare(whatCompare, token, items)
    if not token then state = true end
    return state
end


function CHC_uses:searchTypeFilter(recipe)
    local stateText = string.trim(self.searchBar:getInternalText())
    local tokens, isMultiSearch, queryType = self:searchParseTokens(stateText)
    local tokenStates = {}
    local state = false

    if not tokens then return true end
    
    if isMultiSearch then
        for i=1, #tokens do
            table.insert(tokenStates, self:searchProcessToken(tokens[i], recipe))
        end
        for i=1, #tokenStates do
            if queryType == 'OR' then
                if tokenStates[i] then
                    state = true
                    break
                end
            end
            if queryType == 'AND' and i>#tokenStates-1 then
                local allPrev = all(tokenStates, true, nil,#tokenStates,nil)
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
CHC_uses.sortByNameAsc = function (a,b)
    return a.item.recipe:getName()<b.item.recipe:getName()
end

CHC_uses.sortByNameDesc = function (a,b)
    return a.item.recipe:getName()>b.item.recipe:getName()
end


function CHC_uses:sortByName(_isAscending)
    local option = self.categorySelector
    local sl = option.options[option.selected]
    if _isAscending and self.itemSortFunc ~= CHC_uses.sortByNameAsc then
        self.itemSortFunc = CHC_uses.sortByNameAsc
        self.itemSortAsc = true
        self.filterOrderBtn:setImage(self.sortOrderIconAsc)
        self:updateRecipes(sl)
    end
    if not _isAscending and self.itemSortFunc ~= CHC_uses.sortByNameDesc then
        self.itemSortFunc = CHC_uses.sortByNameDesc
        self.itemSortAsc = false
        self.filterOrderBtn:setImage(self.sortOrderIconDesc)
        self:updateRecipes(sl)
    end
end


function CHC_uses:sortByType(_type)
    local option = self.categorySelector
    local sl = option.options[option.selected]

    local stateChanged = false
    if _type == "all" and self.typeFilter ~= 'all' then
        self.typeFilter = 'all'
        self.filterTypeBtn:setImage(self.typeFiltIconAll)
        stateChanged = true
    end
    if _type == "valid" and self.typeFilter ~= 'valid' then
        self.typeFilter = 'valid'
        self.filterTypeBtn:setImage(self.typeFiltIconValid)
        stateChanged = true
    end
    if _type == "known" and self.typeFilter ~= 'known' then
        self.typeFilter = 'known'
        self.filterTypeBtn:setImage(self.typeFiltIconKnown)
        stateChanged = true
    end
    if _type == "invalid" and self.typeFilter ~= 'invalid' then
        self.typeFilter = 'invalid'
        self.filterTypeBtn:setImage(self.typeFiltIconInvalid)
        stateChanged = true
    end

    if stateChanged then self:updateRecipes(sl) end
end
-- endregion

-- region filter onClick handlers
function CHC_uses:onFilterSortMenu(button)
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x+10, y)

    context:addOption(getText("IGUI_invpanel_ascending"), self, CHC_uses.sortByName, true)
    context:addOption(getText("IGUI_invpanel_descending"), self, CHC_uses.sortByName, false)
end

function CHC_uses:filterSortMenuGetText(textStr, value)
    local txt = getText(textStr)
    -- if value then
    --     txt = txt.." ("..tostring(value)..")"
    -- end
    return txt
end

function CHC_uses:onFilterTypeMenu(button)
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x+10, y)

    local data = {
        {txt="UI_settings_av_all", num=self.numRecipesAll, arg='all'},
        {txt="UI_settings_av_valid", num=self.numRecipesValid, arg='valid'},
        {txt="UI_settings_av_known", num=self.numRecipesKnown, arg='known'},
        {txt="UI_settings_av_invalid", num=self.numRecipesInvalid, arg='invalid'}
    }

    local txt = nil
    for _, k in ipairs(data) do
        txt = self:filterSortMenuGetText(k.txt, k.num)
        context:addOption(txt, self, CHC_uses.sortByType, k.arg)
    end
end
-- endregion
-- endregion

-- region render
function CHC_uses:prerender()
    CHC_tabs.prerender(self)
end

function CHC_uses:render()
    CHC_tabs.render(self)
end
-- endregion


function CHC_uses:new(args)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    local sep_x = args.sep_x
    local item = args.item

    local o = {};
    o = ISPanel:new(x,y,w,h);
    
	setmetatable(o, self);
    self.__index = self;

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};

    o.item = item;

    o.column2 = 0;
	o.column3 = sep_x;
	o.column4 = o.width - 1;

    o.filtericon = getTexture("media/ui/TreeFilter.png");
    o.ui_name = "CHC_uses"
    o.itemSortAsc = CHC_menu.cfg.uses_filter_name_asc
    o.typeFilter = CHC_menu.cfg.uses_filter_type
    o.itemSortFunc = o.itemSortAsc == true and CHC_uses.sortByNameAsc or CHC_uses.sortByNameDesc


    o.numRecipesAll = nil
    o.numRecipesValid = nil
    o.numRecipesKnown = nil
    o.numRecipesInvalid = nil
    return o;
end
