-- Main window, opened when RMB -> Craft Helper 41 on item
require 'ISUI/ISCollapsableWindow';
require 'ISUI/ISTabPanel';

require 'UI/craftHelperUpdUsesScreen';
require 'UI/craftHelperUpdCraftScreen';
require 'UI/craftHelperUpdSearchScreen';

craftHelperUpdWindow = ISCollapsableWindow:derive("craftHelperUpdWindow");

function craftHelperUpdWindow:initialise()
    ISCollapsableWindow.initialise(self);
end

function craftHelperUpdWindow:refresh()
    local selectedView = self.panel.activeView.name;
    self.panel:activateView(selectedView);
end

function craftHelperUpdWindow:createChildren()
    ISCollapsableWindow.createChildren(self);
    --region main container
    self.panel = ISTabPanel:new(5, self:titleBarHeight(), self.width, self.height-80)
    self.panel:initialise()
    self.panel:setAnchorRight(true)
    self.panel:setAnchorBottom(true)
    self.panel:setEqualTabWidth(true)
    
    -- endregion


    local common_screen_data = {x=0, y=8, w=self.width, h=self.panel.height}

    --region uses screen
    local uses_screen_init = common_screen_data
    uses_screen_init['item'] = self.item

    self.usesScreen = craftHelperUpdUsesScreen:new(uses_screen_init);
    self.usesScreen:initialise();
    self.usesScreen.infoText = getText("UI_infotext_uses")
    --endregion
    
    -- region crafting screen
    self.craftScreen = craftHelperUpdCraftScreen:new(0, 8, self.width, self.panel.height - self.panel.tabHeight)
    self.craftScreen:initialise();
    self.craftScreen.infoText = getText("UI_infotext_craft")
    -- endregion

    -- self.searchScreen = craftHelperUpdSearchScreen:new()

    self:addChild(self.panel)
    self.panel:addView(getText("UI_tab_uses"), self.usesScreen)
    self.panel:addView(getText("UI_tab_craft"), self.craftScreen)

    self:refresh()
end

-- region keyboard controls
function craftHelperUpdWindow:onKeyRelease(key)
    local ui = self
    if not ui.panel or not ui.panel.activeView then return; end
    if key == Keyboard.KEY_ESCAPE then
        self:setVisible(false)
        self:removeFromUIManager()
        return;
    end
end

function craftHelperUpdWindow:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end
-- endregion


function craftHelperUpdWindow:onResize()
    ISPanel.onResize(self)

    self.usesScreen:setWidth(self.width);
    self.usesScreen:setHeight(self.panel.height - self.panel.tabHeight)
    self.usesScreen.recipesList:setWidth(self.usesScreen.nameHeader.width)
    self.usesScreen.categorySelector:setWidth(self.usesScreen.nameHeader.width)

    self.craftScreen:setWidth(self.width)
    self.craftScreen:setHeight(self.panel.height - self.panel.tabHeight)
    

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

    o.title = 'Craft Helper 41 -> ' .. o.item:getName();
    --o:noBackground();
    o.th = o:titleBarHeight()
    o.rh = o:resizeWidgetHeight()
    local fontHgtSmall = getTextManager():getFontHeight(UIFont.Small);
    o.headerHgt = fontHgtSmall + 1

    o:setWantKeyEvents(true);

    return o;


end