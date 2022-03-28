require "ISUI/ISPanel"
require 'ISUI/ISButton'
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

    -- region filter btn
    self.filterBtn = ISButton:new(self.nameHeader.x, self.nameHeader.y+self.nameHeader.height,
                                  15, 20, "", self, self.onFilterMenu)
    self.filterBtn:initialise();
    self.filterBtn.borderColor.a = 0;
    self.filterBtn:setImage(self.filtericon)
    -- endregion

    -- region category selector
    -- We add combobox to select recipe category
    self.categorySelector = ISComboBox:new(self.nameHeader.x+self.filterBtn.width,
                                           self.nameHeader.y+self.nameHeader.height,
                                           self.nameHeader.width-self.filterBtn.width, 20)
    self.categorySelector:initialise();
    self.categorySelector.selected = 1;
    self.categorySelector:addOption(getText("UI_tab_uses_categorySelector_All"))
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

    -- region recipe list
    self.recipesList = CHC_uses_recipelist:new(self.nameHeader.x, 
                        self.nameHeader.y+self.nameHeader.height+self.categorySelector.height, 
                        self.nameHeader.width, 
                        self.height-self.nameHeader.height-self.categorySelector.height-1);

    self.recipesList.drawBorder = true;
	self.recipesList:initialise();
	self.recipesList:instantiate();
	self.recipesList:setAnchorBottom(true)
    self.recipesList:setOnMouseDownFunction(self, CHC_uses.onRecipeChange);

    -- Add entries to recipeList
    self:refreshRecipeList(self.allRecipesForItem)
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
	self:addChild(self.recipesList)
	self:addChild(self.recipePanel)

end

function CHC_uses:onChangeUsesRecipeCategory(_option)
    local sl = _option.options[_option.selected]
    self:updateRecipes(sl)
end


function CHC_uses:updateRecipes(sl)
    if sl == getText("UI_tab_uses_categorySelector_All") then
        self:refreshRecipeList(self.allRecipesForItem)
        return
    end

    -- filter recipes by category
    local filteredRecipes = {}
    for _, recipe in ipairs(self.allRecipesForItem) do
        local rc = recipe.category
        local rc_tr = getTextOrNull("IGUI_CraftCategory_"..rc) or rc
        if sl == "* "..getText("UI_tab_uses_categorySelector_Favorite") and recipe.favorite then
            table.insert(filteredRecipes, recipe)
        end
        if rc_tr == sl then
            table.insert(filteredRecipes, recipe)
        end
    end
    self:refreshRecipeList(filteredRecipes)
end

function CHC_uses:refreshRecipeList(recipes)
    self.recipesList:clear()

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


-- region filter button

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
        self:updateRecipes(sl)
    end
    if not _isAscending and self.itemSortFunc ~= CHC_uses.sortByNameDesc then
        self.itemSortFunc = CHC_uses.sortByNameDesc
        self:updateRecipes(sl)
    end
end

function CHC_uses:onFilterMenu(button)
    local x = button:getAbsoluteX();
    local y = button:getAbsoluteY();
    local context = ISContextMenu.get(0, x, y);

    local name = context:addOption(getText("IGUI_Name"), nil, nil);
    local subMenuName = ISContextMenu:getNew(context);
    context:addSubMenu(name, subMenuName);

    subMenuName:addOption(getText("IGUI_invpanel_ascending"), self, CHC_uses.sortByName, true);
    subMenuName:addOption(getText("IGUI_invpanel_descending"), self, CHC_uses.sortByName, false);
end
-- endregion


function CHC_uses:prerender()
    CHC_tabs.prerender(self)
end

function CHC_uses:render()
    CHC_tabs.render(self)
end


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
    o.itemSortFunc = CHC_uses.sortByNameDesc

    return o;
end
