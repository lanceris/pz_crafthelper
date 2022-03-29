require "ISUI/ISPanel"
require 'ISUI/ISButton'
require 'ISUI/ISContextMenu'
require 'ISUI/ISTextEntryBox'
require "UI/CHC_tabs"
require "UI/CHC_uses_recipelist"
require "UI/CHC_uses_recipepanel"


CHC_uses = ISPanel:derive("CHC_uses");


local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- region create
function CHC_uses:initialise()
    ISPanel.initialise(self);
    self:create();
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

    local y = self.nameHeader.y+self.nameHeader.height
    -- region filter btn
    self.filterBtn = ISButton:new(self.nameHeader.x, y,
                                  15, 20, "", self, self.onFilterMenu)
    self.filterBtn:initialise();
    self.filterBtn.borderColor.a = 0;
    self.filterBtn:setImage(self.filtericon)
    -- endregion

    -- region category selector
    -- We add combobox to select recipe category
    local defaultCategory = getText("UI_tab_uses_categorySelector_All")
    self.categorySelector = ISComboBox:new(self.nameHeader.x+self.filterBtn.width, y,
                                           self.nameHeader.width-self.filterBtn.width, 20)
    y = y + self.categorySelector.height
    self.categorySelector:initialise();
    self.categorySelector.selected = 1;
    self.categorySelector:addOption(defaultCategory)
    self.categorySelector.onChange = self.onChangeUsesRecipeCategory
    self.categorySelector.target = self

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

    self.searchBar = ISTextEntryBox:new("", self.nameHeader.x, y,
                            self.nameHeader.width, self.categorySelector.height)
    self.searchBar:initialise()
    self.searchBar:instantiate()
    self.searchBar:setText("")
    self.searchBar:setClearButton(true)
    self.searchBarLastText = self.searchBar:getInternalText()
    self.searchBarText = self.searchBarLastText
    self.searchBar.onTextChange = self.onTextChange

    y = y + self.searchBar.height
    -- endregion

    
    -- region recipe list
    self.recipesList = CHC_uses_recipelist:new(self.nameHeader.x, y,
                        self.nameHeader.width,
                        self.height-self.nameHeader.height-self.categorySelector.height-self.searchBar.height-1);

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

    -- Attach all to the craft helper window
    self:addChild(self.filterBtn)
    self:addChild(self.categorySelector)
    self:addChild(self.searchBar)
	self:addChild(self.recipesList)
	self:addChild(self.recipePanel)

end

-- endregion

-- region update

function CHC_uses:onTextChange()
    local s = self.parent;
    local stateText = s.searchBar:getInternalText()
    if stateText ~= s.searchBarLastText or stateText == "" then
        s.searchBarLastText = stateText
        local option = s.categorySelector
        local sl = option.options[option.selected]
        s:updateRecipes(sl)
    end
end

function CHC_uses:onChangeUsesRecipeCategory(_option)
    local sl = _option.options[_option.selected]
    self:updateRecipes(sl)
end

function CHC_uses:updateRecipes(sl)
    local categoryAll = getText("UI_tab_uses_categorySelector_All")
    if sl == categoryAll and self.typeFilter == "all" and self.searchBar:getInternalText() == "" then
        self:refreshRecipeList(self.allRecipesForItem)
        return
    end

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
        
        if (type_filter_state and search_state) or (fav_cat_state and search_state) then
            table.insert(filteredRecipes, recipe)
        end
    end
    self:refreshRecipeList(filteredRecipes)
end

function CHC_uses:refreshRecipeList(recipes)
    self.recipesList:clear()
    self.recipesList:setScrollHeight(0)

    -- sort recipes
    local rec = {}
    for _, k in ipairs(recipes) do
        rec[string.trim(k.recipe:getName())] = k
    end
    local modData = getPlayer():getModData()
    for name,recipe in pairs(rec) do
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


-- region filter handlers
function CHC_uses:recipeTypeFilter(recipe)
    local rl = self.recipesList

    local is_valid = RecipeManager.IsRecipeValid(recipe.recipe, rl.player, nil, rl.containerList)
    -- print(#rl.containerList) -- TODO: figure out why items from floor aren't registered here
    local is_known = rl.player:isRecipeKnown(recipe.recipe)

    local state = true
    if self.typeFilter == 'all' then state = true end;
    if self.typeFilter == 'valid' then state = is_valid end
    if self.typeFilter == 'known' then state = is_known and not is_valid end
    if self.typeFilter == 'invalid' then state = not is_known end
    return state
end

function CHC_uses:searchTypeFilter(recipe)
    local state = true
    local stateText = string.trim(self.searchBar:getInternalText())
    if stateText ~= "" then
        if not string.contains(string.lower(recipe.recipe:getName()), string.lower(stateText)) then
            state = false
        end
    end
    return state
end
-- endregion

-- region filter button

-- region sort by name
CHC_uses.sortByNameAsc = function (a,b)
    return a.text<b.text
end

CHC_uses.sortByNameDesc = function (a,b)
    return a.text>b.text
end

function CHC_uses:sortByName(_isAscending)
    local option = self.categorySelector
    local sl = option.options[option.selected]
    if _isAscending and self.itemSortFunc ~= CHC_uses.sortByNameAsc then
        self.itemSortFunc = CHC_uses.sortByNameAsc
        self.itemSortAsc = true
        self:updateRecipes(sl)
    end
    if not _isAscending and self.itemSortFunc ~= CHC_uses.sortByNameDesc then
        self.itemSortFunc = CHC_uses.sortByNameDesc
        self.itemSortAsc = false
        self:updateRecipes(sl)
    end
end

-- endregion

-- region sort by type

function CHC_uses:sortByType(_type)
    local option = self.categorySelector
    local sl = option.options[option.selected]

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

    if stateChanged then self:updateRecipes(sl) end
end
-- endregion


function CHC_uses:onFilterMenu(button)
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x+10, y)

    local name = context:addOption(getText("IGUI_Name"), nil, nil)
    local subMenuName = ISContextMenu:getNew(context)
    context:addSubMenu(name, subMenuName)
    subMenuName:addOption(getText("IGUI_invpanel_ascending"), self, CHC_uses.sortByName, true)
    subMenuName:addOption(getText("IGUI_invpanel_descending"), self, CHC_uses.sortByName, false)

    local av = context:addOption(getText("UI_settings_av_title"), nil, nil)
    local subMenuAv = ISContextMenu:getNew(context)
    context:addSubMenu(av, subMenuAv)
    subMenuAv:addOption(getText("UI_settings_av_all"), self, CHC_uses.sortByType, 'all')
    subMenuAv:addOption(getText("UI_settings_av_valid"), self, CHC_uses.sortByType, 'valid')
    subMenuAv:addOption(getText("UI_settings_av_known"), self, CHC_uses.sortByType, 'known')
    subMenuAv:addOption(getText("UI_settings_av_invalid"), self, CHC_uses.sortByType, 'invalid')

    -- local kb = context:addOption(getText("UI_settings_kb_title"), nil, nil)
    -- local subMenuKb = ISContextMenu:getNew(context)
    -- context:addSubMenu(kb, subMenuKb)
    -- subMenuKb:addOption(getText("UI_Yes"), self, 1)
    -- subMenuKb:addOption(getText("UI_No"), self, 1)
end
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

    return o;
end
