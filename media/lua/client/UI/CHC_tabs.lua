require 'ISUI/ISPanel'

local derivative = ISPanel
CHC_tabs = derivative:derive('CHC_tabs');

--create
function CHC_tabs:initialise()
	derivative.initialise(self)
	self:create()
end

function CHC_tabs:create()
	local fontHgtSmall = getTextManager():getFontHeight(UIFont.Small)
	local headerHgt = math.max(fontHgtSmall + 5, self.height)
	-- region list
	local nha = {
		x = 0,
		y = 1,
		w = self.sep_x,
		h = headerHgt,
		title = self.tabName1,
		clicktgt = self,
		onclick = nil
	}
	self.nameHeader = ISResizableButton:new(nha.x, nha.y, nha.w, nha.h,
		nha.title, nha.clicktgt, nha.onclick)
	self.nameHeader:initialise()
	self.nameHeader.borderColor.a = 0.2;
	self.nameHeader.minimumWidth = 100;
	self.nameHeader.onresize = { CHC_tabs.onResizeColumn, self, self.nameHeader }
	self:addChild(self.nameHeader);
	-- endregion

	-- region details
	local tha = {
		x = self.nameHeader.width,
		y = 1,
		w = self.width - self.nameHeader.width,
		h = headerHgt,
		title = self.tabName2,
		clicktgt = self,
		onclick = nil
	}
	self.typeHeader = ISResizableButton:new(tha.x, tha.y, tha.w, tha.h,
		tha.title, tha.clicktgt, tha.onclick)
	self.typeHeader.borderColor.a = 0.2
	self.typeHeader.anchorRight = true
	self.typeHeader.minimumWidth = 100
	self.typeHeader.resizeLeft = true
	self.typeHeader.onresize = { CHC_tabs.onResizeColumn, self, self.typeHeader }
	self.typeHeader:initialise();
	self:addChild(self.typeHeader)
	self.proportion = self.nameHeader.width / self.width
	-- endregion
end

-- render
function CHC_tabs:onResizeColumn(button)
	if button == self.nameHeader then
		self.typeHeader:setX(self.nameHeader.width)
		self.typeHeader:setWidth(self.width - self.nameHeader.width)
	end
	if button == self.typeHeader then
		self.nameHeader:setWidth(self.typeHeader.x)
	end
	if self.onresize then
		self.onresize[1](self.onresize[2], self.onresize[3])
	end
	self.proportion = self.nameHeader.width / self.width
end

function CHC_tabs:prerender()
	self.nameHeader.maximumWidth = self.width - self.typeHeader.minimumWidth
	self.typeHeader.maximumWidth = self.width - self.nameHeader.minimumWidth

	self:setStencilRect(0, 0, self.width - 1, self.height - 1);
end

function CHC_tabs:render()
	self:clearStencilRect();

	local resize = self.nameHeader.resizing or self.nameHeader.mouseOverResize
	if not resize then
		resize = self.typeHeader.resizing or self.typeHeader.mouseOverResize
	end
	if resize then
		self:repaintStencilRect(self.nameHeader:getRight() - 1, self.nameHeader.y, 2, self.height)
		self:drawRectStatic(self.nameHeader:getRight() - 1, self.nameHeader.y, 2, self.parent.height, 0.5, 1, 1, 1)
	end
end

---@param onresize table<number,function|any|any> `table` with 3 values, first is `function`, second and third are arguments
---@return table self
function CHC_tabs:new(x, y, width, height, onresize, sep_x)
	local o = {};
	o = derivative:new(x, y, width, height)

	setmetatable(o, self)
	self.__index = self

	o.onresize = onresize
	o.column2 = 30;
	o.tabName1 = getText('UI_common_left_col_name')
	o.tabName2 = getText('UI_common_right_col_name')
	o.proportion = nil
	o.sep_x = sep_x

	return o
end
