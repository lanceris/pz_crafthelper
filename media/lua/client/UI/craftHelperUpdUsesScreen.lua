require "ISUI/ISPanel";
require "UI/craftHelperUpdTabs";


craftHelperUpdUsesScreen = ISPanel:derive("craftHelperUpdUsesScreen");


function craftHelperUpdUsesScreen:initialise()
    ISPanel.initialise(self);
    self:create();
end

function craftHelperUpdUsesScreen:create()

    local categoryWid = math.max(100,self.column4-self.column3-1)
    if self.column3 - 1 + categoryWid > self.width then
        self.column3 = self.width - categoryWid + 1
    end

    self.tabName1 = "Recipe"
    self.tabName2 = "RecipeDetails"
    self.nameHeader, self.typeHeader = craftHelperUpdTabs.addTabs(self);
end

function craftHelperUpdUsesScreen:prerender()
    craftHelperUpdTabs.prerender(self)
end

function craftHelperUpdUsesScreen:render()
    craftHelperUpdTabs.render(self)
end


function craftHelperUpdUsesScreen:new(x, y, width, height, coltab)
    coltab = coltab or {};

    local o = {};
    o = ISPanel:new(x,y,width, height);
    
	setmetatable(o, self);
    self.__index = self;

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};

    o.column2 = coltab.column2 or 0;
	o.column3 = coltab.column3 or 140;
	o.column4 = coltab.column4 or o.width - 10;

    return o;
end
