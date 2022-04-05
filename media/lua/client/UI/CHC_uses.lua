require "ISUI/ISPanel"
require 'ISUI/ISButton'
require 'ISUI/ISContextMenu'
require 'ISUI/ISTextEntryBox'
require "UI/CHC_tabs"
require "UI/CHC_uses_recipelist"
require "UI/CHC_uses_recipepanel"
require "ISUI/ISModalRichText"

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

CHC_uses.localData = {
    typeFilterToNumOfRecipes = {}
}



-- region create
function CHC_uses:initialise()
    derivative.initialise(self);
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

function CHC_uses:searchBtnOnClick()
    local w,h = 600, 350
    local x, y = getCore():getScreenWidth() / 2 - w/2,getCore():getScreenHeight() / 2 - h/2
    local modal = ISModalRichText:new(x,y,w,h,getText("UI_search_info"),false, self)
    modal:initialise()
    modal:addToUIManager()
end


function CHC_uses:onResizeHeaders()
    self.filterRowContainer:setWidth(self.headers.nameHeader.width)
    self.categorySelector:setWidth(self.headers.nameHeader.width-self.filterOrderBtn.width-self.filterTypeBtn.width) --@@@ refactor
    self.searchRow:setWidth(self.headers.nameHeader.width)
    self.recipesList:setWidth(self.headers.nameHeader.width)
    self.recipePanel:setWidth(self.headers.typeHeader.width)
    self.recipePanel:setX(self.headers.typeHeader.x)
end

function CHC_uses:create()

    self.allRecipesForItem = CHC_main.recipesByItem[self.item:getName()];

    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, 20, {self.onResizeHeaders, self})
    self.headers:initialise()
    -- endregion

    local x = self.headers.x
    local y = self.headers.y+self.headers.height
    local leftW = self.headers.nameHeader.width
    local rightX = self.headers.typeHeader.x
    local rightW = self.headers.typeHeader.width

    -- region filters UI
    local defaultCategory = getText("UI_tab_uses_categorySelector_All")
    self.filterRowContainer = self:createFilterRow(x, y, leftW, 24, defaultCategory)
    local leftY = y + 24
    
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
        if not utils.any(uniqueCategories, rc) then
            table.insert(uniqueCategories, rc)
        end
	end

    if is_fav_recipes then
        self.categorySelector:addOption("* "..getText("UI_tab_uses_categorySelector_Favorite")) 
    end

    table.sort(uniqueCategories)
    for _, rc in pairs(uniqueCategories) do
        self.categorySelector:addOption(rc)
    end
    --endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new(x, leftY, leftW, 24, self.searchBtnOnClick, nil, self.onTextChange)
    self.searchRow:initialise()
    leftY = leftY + 24
    -- endregion

    -- region recipe list
    local rlh = self.height-self.headers.height-self.filterRowContainer.height-self.searchRow.height-1
    self.recipesList = CHC_uses_recipelist:new(x, leftY, leftW, rlh);

    self.recipesList.drawBorder = true;
	self.recipesList:initialise();
	self.recipesList:instantiate();
	self.recipesList:setAnchorBottom(true)
    self.recipesList:setOnMouseDownFunction(self, CHC_uses.onRecipeChange);

    -- Add entries to recipeList
    self:updateRecipes(defaultCategory)
    -- endregion

    -- region recipe details windows
    self.recipePanel = CHC_uses_recipepanel:new(rightX, y, rightW, self.height);
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
    self:addChild(self.headers)
    self.filterRowContainer:addChild(self.filterOrderBtn)
    self.filterRowContainer:addChild(self.filterTypeBtn)
    self.filterRowContainer:addChild(self.categorySelector)
    self:addChild(self.filterRowContainer)
    self:addChild(self.searchRow)
	self:addChild(self.recipesList)
	self:addChild(self.recipePanel)
end

-- endregion

-- region update

function CHC_uses:onTextChange()
    local s = self.parent.parent
    local stateText = s.searchRow.searchBar:getInternalText()
    if stateText ~= s.searchRow.searchBarLastText or stateText == "" then
        s.searchRow.searchBarLastText = stateText
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
    local searchBar = self.searchRow.searchBar
    if sl == categoryAll and self.typeFilter == "all" and searchBar:getInternalText() == "" then
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


-- function CHC_uses:searchIsSpecialCommand(txt)
--     -- !: search by recipe category
--     -- @: search by mod name of resulting item
--     -- #: search by recipe ingredients
--     -- $: search by DisplayCategory of resulting item
--     -- %: search by name of resulting item
--     -- ^: show favorited recipes only
--     local validSpecialChars = {"!", "@", "#", "$", "%", "^"} -- @@@
--     for _, char in ipairs(validSpecialChars) do
--         if utils.startswith(txt, char) then return true end
--     end
--     return false
-- end


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

    if CHC_search_bar:isSpecialCommand(token) then
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
            local catName = getTextOrNull("IGUI_CraftCategory_"..recipe.category) or recipe.category
            whatCompare = catName
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
                    local item = CHC_main.items[itemString]
                    if item then table.insert(items, item:getDisplayName()) end
                end
            end
            whatCompare = items
        end
    end
    if token and not isSpecialSearch then
        whatCompare = string.lower(recipe.recipe:getName())
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
                local allPrev = utils.all(tokenStates, true, 1,#tokenStates)
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
end

function CHC_uses:render()
    -- CHC_tabs.render(self)
end
-- endregion


function CHC_uses:new(args)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    local item = args.item

    local o = {};
    o = derivative:new(x,y,w,h);
    
	setmetatable(o, self);
    self.__index = self;

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};

    o.item = item;

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
