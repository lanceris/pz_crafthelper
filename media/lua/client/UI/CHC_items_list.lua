CHC_items_list = ISScrollingListBox:derive("CHC_items_list")

local fontSizeToInternal = {
    { font = UIFont.Small, pad = 4, icon = 10 },
    { font = UIFont.Medium, pad = 4, icon = 18 },
    { font = UIFont.Large, pad = 6, icon = 24 }
}

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

function CHC_items_list:isMouseOverFavorite(x)
    return (x >= self.width - 40) and not self:isMouseOverScrollBar()
end

-- endregion

-- region render

function CHC_items_list:prerender()
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

    local curFontData = fontSizeToInternal[CHC_settings.config.list_font_size]
    if not curFontData then curFontData = fontSizeToInternal[3] end
    if self.font ~= curFontData.font then
        self:setFont(curFontData.font, curFontData.pad)
    end
    item.height = curFontData.icon + 2 * curFontData.pad

    if y + self:getYScroll() >= self.height then return y + item.height end
    if y + item.height + self:getYScroll() <= 0 then return y + item.height end
    if y < -self:getYScroll() - 1 then return y + item.height; end
    if y > self:getHeight() - self:getYScroll() + 1 then return y + item.height; end

    local itemObj = item.item
    local a = 0.9

    local favoriteStar = nil
    local favoriteAlpha = a

    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    local iconsEnabled = CHC_settings.config.show_icons

    -- region icons
    if iconsEnabled then
        local itemIcon = itemObj.texture
        self:drawTextureScaled(itemIcon, 6, y + 6, curFontData.icon, curFontData.icon, 1)
    end
    --endregion

    --region text
    local clr = { txt = item.text, x = iconsEnabled and (curFontData.icon + 8) or 15,
        y = (y) + itemPadY, a = 0.9, font = self.font }
    clr['r'] = 1
    clr['g'] = 1
    clr['b'] = 1
    clr['a'] = a
    self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font)
    --endregion

    --region favorite handler
    local isFav = CHC_main.playerModData[CHC_main.getFavItemModDataStr(item.item)] == true
    local favYPos = self.width - 30
    if item.index == self.mouseoverselected and not self:isMouseOverScrollBar() then
        if self:getMouseX() >= favYPos - 20 then
            favoriteStar = isFav and self.favCheckedTex or self.favNotCheckedTex
            favoriteAlpha = 0.9
        else
            favoriteStar = isFav and self.favoriteStar or self.favNotCheckedTex
            favoriteAlpha = isFav and a or 0.3
        end
    elseif isFav then
        favoriteStar = self.favoriteStar
    end
    if favoriteStar then
        self:drawTexture(favoriteStar, favYPos, y + (item.height / 2 - favoriteStar:getHeight() / 2), favoriteAlpha, 1, 1, 1);
    end
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

-- region logic

-- region event handlers
function CHC_items_list:onMouseDown_Recipes(x, y)
    local row = self:rowAt(x, y)
    if row == -1 then return end
    if self:isMouseOverFavorite(x) then
        self:addToFavorite(row)
    end
end

-- endregion

function CHC_items_list:addToFavorite(selectedIndex, fromKeyboard)
    if fromKeyboard == true then
        selectedIndex = self.selected
    end
    local selectedItem = self.items[selectedIndex]
    if not selectedItem then return end
    local parent = self.parent

    local isFav = self.modData[CHC_main.getFavItemModDataStr(selectedItem.item)] == true
    isFav = not isFav
    self.modData[CHC_main.getFavItemModDataStr(selectedItem.item)] = isFav or nil

    if isFav == true then
    else
        if parent.ui_type == 'fav_items' then
            self:removeItemByIndex(selectedIndex)
        end

    end
    parent.needUpdateTypes = true
    parent.needUpdateFavorites = true
    if parent.ui_type == 'fav_items' then
        parent.needUpdateCategories = true
    end
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

    o.favoriteStar = getTexture("media/textures/itemFavoriteStar.png")
    o.favCheckedTex = getTexture("media/textures/itemFavoriteStarChecked.png")
    o.favNotCheckedTex = getTexture("media/textures/itemFavoriteStarOutline.png")
    o.onmiddlemousedown = onmiddlemousedown
    o.needmmb = false
    o.modData = CHC_main.playerModData

    o.player = getPlayer()
    return o
end
