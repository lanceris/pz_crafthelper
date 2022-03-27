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
    --endregion

    -- region recipe list
    local tabRecipes = craftHelper41.recipesByItem[self.item:getName()];
    self.recipesList = craftHelperUpdRecipeList:new(self.nameHeader.x, 
                                                    self.nameHeader.y+self.nameHeader.height+self.categorySelector.height, 
                                                    self.nameHeader.width, self.height);
	self.recipesList:initialise();
	self.recipesList:instantiate();
	self.recipesList:setAnchorBottom(true)
    self.recipesList:setOnMouseDownFunction(self, craftHelperUpdUsesScreen.onRecipeChange);

    
    local uniqueCategories = {};

    -- We add recipes in the list
	for _,recipe in ipairs(tabRecipes) do
        local rc = recipe:getCategory() or getText("UI_category_default")
        print(recipe:getName().." | "..rc)
		self.recipesList:addItem(string.trim(recipe:getName()), recipe);
        if uniqueCategories[rc] == nil then
            uniqueCategories[rc] = true
            self.categorySelector:addOption(getTextOrNull("IGUI_CraftCategory_"..rc) or rc)
        end
	end
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

    -- self.categorySelector.onChange = self.onChangeUsesRecipeCategory
    -- self.categorySelector.target = self.recipesList

    -- Attach all to the craft helper window
    self:addChild(self.categorySelector)
	self:addChild(self.recipesList)
	self:addChild(self.recipePanel)

end

function craftHelperUpdUsesScreen:onChangeUsesRecipeCategory(_option)
    print(_option)
    
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
