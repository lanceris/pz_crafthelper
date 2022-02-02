require 'ISUI/ISCollapsableWindow';
require 'ISUI/ISTabPanel';

require 'UI/craftHelperUpdUsesScreen';
require 'UI/craftHelperUpdCraftScreen';


craftHelperUpdWindow = ISCollapsableWindow:derive("craftHelperUpdWindow");
craftHelperUpdWindow.bottomInfoHeight = getTextManager():getFontHeight(UIFont.Small) * 2;

function craftHelperUpdWindow:initialise()
    ISCollapsableWindow.initialise(self);
end

function craftHelperUpdWindow:createChildren()
    ISCollapsableWindow.createChildren(self);
    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    self.panel = ISTabPanel:new(5, th, self.width, self.height-th-rh-16);
    self.panel:initialise();
    self.panel:setAnchorRight(true);
    self.panel:setEqualTabWidth(true);

    self:addChild(self.panel);

    self.usesScreen = craftHelperUpdUsesScreen:new(0, 8, self.width, self.height-th-rh-16);
    self.usesScreen:initialise();
    self.panel:addView('Uses', self.usesScreen);
    self.usesScreen.infoText = "Test info for Uses Screen"

    self.craftScreen = craftHelperUpdCraftScreen:new(0, 8, self.width, self.height-th-rh-16)
    self.craftScreen:initialise();
    self.panel:addView('Craft', self.craftScreen);
    self.craftScreen.infoText = "Test info for Craft Screen"
end


function craftHelperUpdWindow:onResize()
    ISPanel.onResize(self)
    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    print(self.height..";"..self.panel.height..';'..self.usesScreen.height)
    self.usesScreen:setWidth(self.width-self.usesScreen.x*2);
    self.usesScreen:setHeight(self.height-th-rh)

    self.craftScreen:setWidth(self.width-self.craftScreen.x*2)
    self.craftScreen:setHeight(self.height-th-rh)

    if self.usesScreen.typeHeader:getWidth() == self.usesScreen.typeHeader.minimumWidth then
		self.usesScreen.column3 = self.usesScreen.width - self.usesScreen.typeHeader:getWidth() + 1
		self.usesScreen.nameHeader:setWidth(self.usesScreen.column3 - self.usesScreen.column2)
		self.usesScreen.typeHeader:setX(self.usesScreen.column3 - 1)
	end
	self.usesScreen.column4 = self.usesScreen.width

    if self.craftScreen.typeHeader:getWidth() == self.craftScreen.typeHeader.minimumWidth then
		self.craftScreen.column3 = self.craftScreen.width - self.craftScreen.typeHeader:getWidth() + 1
		self.craftScreen.nameHeader:setWidth(self.craftScreen.column3 - self.craftScreen.column2)
		self.craftScreen.typeHeader:setX(self.craftScreen.column3 - 1)
	end
	self.craftScreen.column4 = self.craftScreen.width
    
end

-- function craftHelperUpdWindow:prerender()

-- end

function craftHelperUpdWindow:render()
    ISCollapsableWindow.render(self);
end


function craftHelperUpdWindow:new(args)
    local o = {};
    local x = args.x or 100;
    local y = args.y or 100;
    local width = args.width or 1000;
    local height = args.height or 600;

	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;

    for k, v in pairs(args) do
        o[k] = v
    end

    o.title = 'Craft Helper 41 for ' .. o.item:getName();
    --o:noBackground();

    return o;


end