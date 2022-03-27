require "ISUI/ISPanel";
require "ISUI/ISInventoryPane";

craftHelperUpdTabs = ISPanel:derive("craftHelperUpdTabs");


function craftHelperUpdTabs:initialise()
    ISPanel.initialise(self);
end

function craftHelperUpdTabs.addTabs(parent)
    local fontHgtSmall = getTextManager():getFontHeight(UIFont.Small);
    local headerHgt = fontHgtSmall + 1
    -- "Recipe"
    local nameHeader = ISResizableButton:new(parent.column2, 1, (parent.column3 - parent.column2), headerHgt, parent.tabName1, parent, nil);
	nameHeader:initialise();
	nameHeader.borderColor.a = 0.2;
	nameHeader.minimumWidth = 100;
	nameHeader.onresize = { craftHelperUpdTabs.onResizeColumn, parent, nameHeader };
	parent:addChild(nameHeader);

    -- "RecipeDetails"
	local typeHeader = ISResizableButton:new(parent.column3-1, 1, parent.column4 - parent.column3 + 1, headerHgt, parent.tabName2, parent, nil);
	typeHeader.borderColor.a = 0.2;
	typeHeader.anchorRight = true;
	typeHeader.minimumWidth = 100;
	typeHeader.resizeLeft = true;
	typeHeader.onresize = { craftHelperUpdTabs.onResizeColumn, parent, typeHeader };
	typeHeader:initialise();
	parent:addChild(typeHeader)

    return nameHeader, typeHeader
end

function craftHelperUpdTabs.onResizeColumn(parent, button)
	ISInventoryPane.onResizeColumn(parent, button)
	parent.recipesList:setWidth(parent.nameHeader.width)
	parent.categorySelector:setWidth(parent.nameHeader.width)
	parent.recipePanel:setWidth(parent.typeHeader.width)
	parent.recipePanel:setX(parent.typeHeader.x)
end


function craftHelperUpdTabs.prerender(parent)
    parent.nameHeader.maximumWidth = parent.width - parent.typeHeader.minimumWidth - parent.column2
    parent.typeHeader.maximumWidth = parent.width - parent.nameHeader.minimumWidth - parent.column2 - 1

    parent:setStencilRect(0,0,parent.width-1, parent.height-1);
end


function craftHelperUpdTabs.render(parent)

	parent:clearStencilRect();

	local resize = parent.nameHeader.resizing or parent.nameHeader.mouseOverResize
	if not resize then
		resize = parent.typeHeader.resizing or parent.typeHeader.mouseOverResize
	end
	if resize then
		parent:repaintStencilRect(parent.nameHeader:getRight() - 1, parent.nameHeader.y, 2, parent.height)
		parent:drawRectStatic(parent.nameHeader:getRight() - 1, parent.nameHeader.y, 2, parent.height, 0.5, 1, 1, 1)
	end
end


function craftHelperUpdTabs:new(args)
    local o = {};
    local x = args.x or 0;
    local y = args.y or 0;
    local width = args.width or 500;
    local height = args.height or 500;

	o = ISPanel:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;

    for k, v in pairs(args) do
        o[k] = v
    end

    --o:noBackground();

    return o;
end