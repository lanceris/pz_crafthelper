require 'ISUI/ISCollapsableWindow';
require 'ISUI/ISLabel';
require 'UI/craftHelper41ScrollingRecipesListBox';
require 'UI/craftHelper41RecipePanel';
require 'crafthelper41';

craftHelper41Window = ISCollapsableWindow:derive("craftHelper41Window");


---
--
--
function craftHelper41Window:onRecipeChange(recipe)
	self.recipePanel:setRecipe(recipe);
end


---
-- Here we create children element conatained in Craft Helper Window 
--
function craftHelper41Window:createChildren()
	ISCollapsableWindow.createChildren(self);

	-- Get list of recipes where the item is used
	local tabRecipes = craftHelper41.recipesByItem[self.item:getName()];

	-- Create a label and attach it to the craft helper window with addChild method
	self.label = ISLabel:new(15, 25, 30, 'With ' .. self.item:getName() .. ', you can :', 1, 1, 1, 1, UIFont.Large, true);
	self.label:initialise();
	self:addChild(self.label);
	
	-- Create an instance of the ISScrollingRecipesListBox object
	self.recipesList = craftHelper41ScrollingRecipesListBox:new(5, 60, 500, self.height - 80);
	self.recipesList:initialise();
	self.recipesList:instantiate();
	self.recipesList:setAnchorBottom(true)
	self.recipesList:setOnMouseDownFunction(self, craftHelper41Window.onRecipeChange);
	
	-- We add recipes in the list
	for _,recipe in ipairs(tabRecipes) do
		self.recipesList:addItem(string.trim(recipe:getName()), recipe);
	end
	
	-- Attach recipes list to the craft helper window
	self:addChild(self.recipesList);

	-- Create an instance of the ISScrollingRecipesListBox object
	self.recipePanel = craftHelper41RecipePanel:new(505, 60, self.width - 500 - 20, self.height - 80);
	self.recipePanel:initialise();
	self.recipePanel:instantiate();
	self.recipePanel:setAnchorRight(true)
	self.recipePanel:setAnchorBottom(true)
	self:addChild(self.recipePanel);
end

---
--
--
function craftHelper41Window:prerender()
	local height = self:getHeight();
	if self.isCollapsed then
		height = 16;
	end
	self:drawRect(0, 0, self:getWidth(), height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);

	self:drawTextureScaled(self.titlebarbkg, 2, 1, self:getWidth() - 4, 14, 1, 1, 1, 1);
	self:drawRectBorder(0, 0, self:getWidth(), 16, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

	if self.title ~= nil then
		self:drawTextCentre(self.title, self:getWidth() / 2, 1, 1, 1, 1, 1, UIFont.Small);
	end
end


---
--
--
function craftHelper41Window:new(x, y, item)
	local o = {};
	
	o = ISCollapsableWindow:new(x, y, 1000, 600);
	setmetatable(o, self);
	self.__index = self;

	o.title = 'Craft Helper 41 for ' .. item:getName() .. ' item';
	
	o.item = item;
	o.minimumHeight = 400;
	o.minimumWidth = 800;
	o.backgroundColor = {r=0, g=0, b=0, a=1};
	o:noBackground();
	return o;
end



