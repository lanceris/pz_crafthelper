CHC_items_list = ISScrollingListBox:derive("CHC_items_list")

-- region create

function CHC_items_list:initialise()
    self.ft = true
    ISScrollingListBox.initialise(self)
end

-- endregion

-- region update

function CHC_items_list:onMMBDown()
    if self.onmiddlemousedown then
        self:onmiddlemousedown()
    end
end

function CHC_items_list:onMouseMove(dx, dy)
    ISScrollingListBox.onMouseMove(self, dx, dy)
    self.needmmb = true
end

function CHC_items_list:onMouseMoveOutside(x, y)
    ISScrollingListBox.onMouseMoveOutside(self, x, y)
    self.needmmb = false
end

function CHC_items_list:update()
    if self.needmmb and Mouse.isMiddleDown() then
        self:onMMBDown()
        self.needmmb = false
    end
end

-- endregion

-- region render

function CHC_items_list:prerender()
    local now
    if self.ft then
        now = getTimestampMs()
    end
    if not self.items then return end

    local stencilX = 0
    local stencilY = 0
    local stencilX2 = self.width
    local stencilY2 = self.height

    self:drawRect(0, -self:getYScroll(), self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);

    if self.drawBorder then
        self:drawRectBorder(0, -self:getYScroll(), self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
        stencilX = 1
        stencilY = 1
        stencilX2 = self.width - 1
        stencilY2 = self.height - 1
    end

    if self:isVScrollBarVisible() then
        stencilX2 = self.vscroll.x + 3 -- +3 because the scrollbar texture is narrower than the scrollbar width
    end

    self:setStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)

    local y = 0;
    local alt = false;

    --	if self.selected ~= -1 and self.selected < 1 then
    --		self.selected = 1
    if self.selected ~= -1 and self.selected > #self.items then
        self.selected = #self.items
    end


    self.listHeight = 0;
    local i = 1;  --@@@
    for j = 1, #self.items do
        self.items[j].index = i;
        local y2 = self:doDrawItem(y, self.items[j], alt);
        self.listHeight = y2;
        self.items[j].height = y2 - y
        y = y2

        alt = not alt;
        i = i + 1;

    end

    self:setScrollHeight((y));
    self:clearStencilRect();

    if self.doRepaintStencil then
        self:repaintStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)
    end

    local mouseY = self:getMouseY()
    self:updateSmoothScrolling()

    if mouseY ~= self:getMouseY() and self:isMouseOver() then
        self:onMouseMove(0, self:getMouseY() - mouseY)
    end
    self:updateTooltip()

    if self.ft then
        self.ft = false
    end
end

function CHC_items_list:doDrawItem(y, item, alt)

    if y + self:getYScroll() >= self.height then return y + item.height end
    if y + item.height + self:getYScroll() <= 0 then return y + item.height end
    if y < -self:getYScroll() - 1 then return y + item.height; end
    if y > self:getHeight() - self:getYScroll() + 1 then return y + item.height; end

    local itemObj = item.item
    local a = 0.9

    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    local iconsEnabled = CHC_settings.config.show_icons

    -- region icons
    if iconsEnabled then
        local itemIcon = itemObj.texture
        self:drawTextureScaled(itemIcon, 6, y + 6, item.height - 12, item.height - 12, 1)
    end
    --endregion

    --region text
    local clr = { txt = item.text, x = iconsEnabled and item.height or 15,
        y = (y) + itemPadY, a = 0.9, font = self.font }
    clr['r'] = 1
    clr['g'] = 1
    clr['b'] = 1
    clr['a'] = a
    self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font)
    --endregion


    --region filler
    local sc = { x = 0, y = y, w = self:getWidth(), h = item.height - 1, a = 0.2, r = 0.75, g = 0.5, b = 0.5 }
    local bc = { x = sc.x, y = sc.y, w = sc.w, h = sc.h + 1, a = 0.25, r = 1, g = 1, b = 1 }
    -- fill selected entry
    if self.selected == item.index then
        self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b);
    end
    -- border around entry
    self:drawRectBorder(bc.x, bc.y, bc.w, bc.h, bc.a, bc.r, bc.g, bc.b);
    --endregion

    y = y + item.height;
    return y;
end

-- endregion


function CHC_items_list:new(x, y, width, height, onmiddlemousedown)
    local o = {}

    o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    o.anchorTop = true
    o.anchorBottom = true

    o.favoriteStar = getTexture("media/ui/FavoriteStar.png")
    o.favCheckedTex = getTexture("media/ui/FavoriteStarChecked.png")
    o.favNotCheckedTex = getTexture("media/ui/FavoriteStarUnchecked.png")
    o.onmiddlemousedown = onmiddlemousedown
    o.needmmb = false
    return o
end
