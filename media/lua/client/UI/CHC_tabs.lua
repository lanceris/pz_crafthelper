require "ISUI/ISPanel";
require "ISUI/ISInventoryPane";

CHC_tabs = ISPanel:derive("CHC_tabs");


function CHC_tabs.addTabs(parent)
    local fontHgtSmall = getTextManager():getFontHeight(UIFont.Medium);
    local headerHgt = fontHgtSmall + 1
    -- region list
	local nha = {
		x=parent.column2,
		y=1,
		w=(parent.column3 - parent.column2),
		h=headerHgt,
		title=parent.tabName1,
		clicktgt=parent,
		onclick=nil
	}
    local nameHeader = ISResizableButton:new(nha.x, nha.y, nha.w, nha.h,
											 nha.title, nha.clicktgt, nha.onclick);
	nameHeader:initialise();
	nameHeader.borderColor.a = 0.2;
	nameHeader.minimumWidth = 100;
	nameHeader.onresize = { CHC_tabs.onResizeColumn, parent, nameHeader };
	parent:addChild(nameHeader);
	-- endregion

    -- region details
	local tha = {
		x=parent.column3-2,
		y=1,
		w=(parent.column4 - parent.column3+1),
		h=headerHgt,
		title=parent.tabName2,
		clicktgt=parent,
		onclick=nil
	}
	local typeHeader = ISResizableButton:new(tha.x, tha.y, tha.w, tha.h,
											 tha.title, tha.clicktgt, tha.onclick);
	typeHeader.borderColor.a = 0.2;
	typeHeader.anchorRight = true;
	typeHeader.minimumWidth = 100;
	typeHeader.resizeLeft = true;
	typeHeader.onresize = { CHC_tabs.onResizeColumn, parent, typeHeader };
	typeHeader:initialise();
	parent:addChild(typeHeader)
	-- endregion

    return nameHeader, typeHeader
end

function CHC_tabs.onResizeColumn(parent, button)
	ISInventoryPane.onResizeColumn(parent, button)
	if parent.ui_name and "CHC_uses" then
		parent.recipesList:setWidth(parent.nameHeader.width)
		parent.filterRowContainer:setWidth(parent.nameHeader.width)
		parent.categorySelector:setWidth(parent.nameHeader.width-parent.filterRowContainer.deltaW)
		parent.searchRowContainer:setWidth(parent.nameHeader.width)
		parent.searchBar:setWidth(parent.nameHeader.width-parent.searchRowContainer.deltaW)
		parent.recipePanel:setWidth(parent.typeHeader.width)
		parent.recipePanel:setX(parent.typeHeader.x)
	end
	
end


function CHC_tabs.prerender(parent)
    parent.nameHeader.maximumWidth = parent.width - parent.typeHeader.minimumWidth - parent.column2
    parent.typeHeader.maximumWidth = parent.width - parent.nameHeader.minimumWidth - parent.column2 - 1

    parent:setStencilRect(0,0,parent.width-1, parent.height-1);
end


function CHC_tabs.render(parent)

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