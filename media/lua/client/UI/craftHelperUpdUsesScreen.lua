require "ISUI/ISPanel"
require "UI/craftHelperUpdTabs"
require "UI/craftHelperUpdRecipeList"
require "UI/craftHelperUpdRecipePanel"


craftHelperUpdUsesScreen = ISPanel:derive("craftHelperUpdUsesScreen");


function craftHelperUpdUsesScreen:initialise()
    ISPanel.initialise(self);
    self:create();
end

function craftHelperUpdUsesScreen:create()

    self.allRecipesForItem = craftHelper41.recipesByItem[self.item:getName()];

    -- region draggable headers
    local categoryWid = math.max(100,self.column4-self.column3-1)
    if self.column3 - 1 + categoryWid > self.width then
        self.column3 = self.width - categoryWid + 1
    end
    self.tabName1 = getText("UI_tab_uses_recipe_title")
    self.tabName2 = getText("UI_tab_uses_details_title")
    self.nameHeader, self.typeHeader = craftHelperUpdTabs.addTabs(self);
    self.nameHeader:setAlwaysOnTop(true);
    self.typeHeader:setAlwaysOnTop(true);
    -- endregion

    -- region category selector
    -- We add combobox to select recipe category
    self.categorySelector = ISComboBox:new(self.nameHeader.x, 
                                           self.nameHeader.y+self.nameHeader.height,
                                           self.nameHeader.width, 20)
    self.categorySelector:initialise();
    self.categorySelector.selected = 1;
    self.categorySelector:addOption("All")
    self.categorySelector.onChange = self.onChangeUsesRecipeCategory

    -- Add categories to selector
    local uniqueCategories = {};
    for _,recipe in ipairs(self.allRecipesForItem) do
        local rc = recipe:getCategory() or getText("UI_category_default")
        if uniqueCategories[rc] == nil then
            uniqueCategories[rc] = true
            self.categorySelector:addOption(getTextOrNull("IGUI_CraftCategory_"..rc) or rc)
        end
	end
    --endregion

    -- region recipe list
    self.recipesList = craftHelperUpdRecipeList:new(self.nameHeader.x, 
                                                    self.nameHeader.y+self.nameHeader.height+self.categorySelector.height, 
                                                    self.nameHeader.width, self.height);
	self.recipesList:initialise();
	self.recipesList:instantiate();
	self.recipesList:setAnchorBottom(true)
    self.recipesList:setOnMouseDownFunction(self, craftHelperUpdUsesScreen.onRecipeChange);

    -- Add entries to recipeList
    self:refreshRecipeList(self.allRecipesForItem)
    -- endregion
    
    -- region recipe details windows
    self.recipePanel = craftHelperUpdRecipePanel:new(self.typeHeader.x, 
                        self.typeHeader.y+self.typeHeader.height, 
                        self.typeHeader.width, self.height);
	self.recipePanel:initialise();
	self.recipePanel:instantiate();
	self.recipePanel:setAnchorRight(true)
	self.recipePanel:setAnchorBottom(true)
    -- endregion

    self.categorySelector.target = self

    -- Attach all to the craft helper window
    self:addChild(self.categorySelector)
	self:addChild(self.recipesList)
	self:addChild(self.recipePanel)

end

function craftHelperUpdUsesScreen:onChangeUsesRecipeCategory(_option)
    local sl = _option.options[_option.selected]
    if sl == "All" then
        self:refreshRecipeList(self.allRecipesForItem)
        return
    end

    -- filter recipes by category
    local filteredRecipes = {}
    for _, recipe in ipairs(self.allRecipesForItem) do
        local rc = recipe:getCategory() or getText("UI_category_default")
        local rc_tr = getTextOrNull("IGUI_CraftCategory_"..rc) or rc
        if rc_tr == sl then
            table.insert(filteredRecipes, recipe)
        end
    end
    self:refreshRecipeList(filteredRecipes)
end

function craftHelperUpdUsesScreen:refreshRecipeList(recipes)
    self.recipesList:clear()
    for _,recipe in ipairs(recipes) do
        self.recipesList:addItem(string.trim(recipe:getName()), recipe);
    end
end

function craftHelperUpdUsesScreen:onRecipeChange(recipe)
	self.recipePanel:setRecipe(recipe);
    self.recipesList:onMouseDown_Recipes(self.recipesList:getMouseX(), self.recipesList:getMouseY())
end

function craftHelperUpdUsesScreen:prerender()
    craftHelperUpdTabs.prerender(self)
end

function craftHelperUpdUsesScreen:render()
    craftHelperUpdTabs.render(self)
end


function craftHelperUpdUsesScreen:new(args)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    local item = args.item
    coltab = coltab or {};

    local o = {};
    o = ISPanel:new(x,y,w,h);
    
	setmetatable(o, self);
    self.__index = self;

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};

    o.item = item;

    o.column2 = coltab.column2 or 0;
	o.column3 = coltab.column3 or 140;
	o.column4 = coltab.column4 or o.width - 10;

    return o;
end
