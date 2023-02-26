CHC_items_list = ISScrollingListBox:derive('CHC_items_list')

local utils = require('CHC_utils')

-- region create

function CHC_items_list:initialise()
    self.ft = true
    self.fastListReturn = CHC_main.common.fastListReturn
    ISScrollingListBox.initialise(self)
end

-- endregion

-- region update

function CHC_items_list:update()
    if self.needUpdateScroll == true then
        self.yScroll = self:getYScroll()
        self.needUpdateScroll = false
    end

    if self.needUpdateMousePos == true then
        self.mouseX = self:getMouseX()
        self.mouseY = self:getMouseY()
        self.needUpdateMousePos = false
    end

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

function CHC_items_list:rowAtY(y)
    local y0 = 0
    for i = 1, #self.items do
        if y >= y0 and y < y0 + self.itemheight then
            return i
        end
        y0 = y0 + self.itemheight
    end
    return -1
end

function CHC_items_list:prerender()
    local ms = UIManager.getMillisSinceLastRender()
    for i = 1, #self.updRates do
        local val = self.updRates[i]
        if not val.cur then val.cur = 0 end
        val.cur = val.cur + ms
        if val.cur >= val.rate then
            self[val.var] = true
            val.cur = 0
        end
    end

    if not self.items then return end
    if utils.empty(self.items) then return end

    local stencilX = 0
    local stencilY = 0
    local stencilX2 = self.width
    local stencilY2 = self.height

    self:drawRect(0, -self.yScroll, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r,
        self.backgroundColor.g, self.backgroundColor.b);

    if self.drawBorder then
        self:drawRectBorder(0, -self.yScroll, self.width, self.height, self.borderColor.a, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
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
    local i = 1
    for j = 1, #self.items do
        self.items[j].index = i
        self.items[j].height = self.curFontData.icon + 2 * self.curFontData.pad
        local y2 = self:doDrawItem(y, self.items[j], alt)
        self.listHeight = y2
        self.items[j].height = y2 - y
        y = y2
        --alt = not alt
        i = i + 1
    end

    self:setScrollHeight((y));
    self:clearStencilRect();

    if self.doRepaintStencil then
        self:repaintStencilRect(stencilX, stencilY, stencilX2 - stencilX, stencilY2 - stencilY)
    end

    local mouseY = self.mouseY
    self:updateSmoothScrolling()

    if mouseY ~= self.mouseY and self:isMouseOver() then
        self:onMouseMove(0, self.mouseY - mouseY)
    end
    self:updateTooltip()

    if self.ft then
        self.ft = false
    end
end

function CHC_items_list:doDrawItem(y, item, alt)
    if self:fastListReturn(y) then return y + self.itemheight end

    local itemObj = item.item
    local a = 0.9

    local favoriteStar = nil
    local favoriteAlpha = a

    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    local iconsEnabled = CHC_settings.config.show_icons

    -- region icons
    if iconsEnabled then
        local itemIcon = itemObj.texture
        self:drawTextureScaled(itemIcon, 6, y + 6, self.curFontData.icon, self.curFontData.icon, 1)
    end
    --endregion

    --region text
    local clr = {
        txt = item.text,
        x = iconsEnabled and (self.curFontData.icon + 8) or 15,
        y = (y) + itemPadY,
        r = 1,
        g = 1,
        b = 1,
        a = 0.9,
        font = self.font,
    }
    self:drawText(clr.txt, clr.x, clr.y, clr.r, clr.g, clr.b, clr.a, clr.font)
    --endregion

    --region favorite handler
    local isFav = self.modData[CHC_main.getFavItemModDataStr(item.item)] == true
    local favYPos = self.width - 30
    if item.index == self.mouseoverselected and not self:isMouseOverScrollBar() then
        if self:getMouseX() >= favYPos - 20 then
            favoriteStar = isFav and self.favorite.checked or self.favorite.notChecked
            favoriteAlpha = 0.9
        else
            favoriteStar = isFav and self.favorite.star or self.favorite.notChecked
            favoriteAlpha = isFav and a or 0.3
        end
    elseif isFav then
        favoriteStar = self.favorite.star
    end
    if favoriteStar then
        self:drawTexture(
            favoriteStar.tex, favYPos,
            y + (item.height / 2 - favoriteStar.height / 2),
            favoriteAlpha, 1, 1, 1
        )
    end
    --endregion

    --region filler
    local sc = { x = 0, y = y, w = self.width, h = item.height - 1, a = 0.2, r = 0.75, g = 0.5, b = 0.5 }
    local bc = { x = sc.x, y = sc.y, w = sc.w, h = sc.h + 1, a = 0.25, r = 1, g = 1, b = 1 }
    -- fill selected entry
    if self.selected == item.index then
        self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b);
    end
    -- border around entry
    self:drawRectBorder(bc.x, bc.y, bc.w, bc.h, bc.a, bc.r, bc.g, bc.b);

    if item.index == self.mouseoverselected then
        self:drawRect(sc.x, sc.y, sc.w, sc.h, 0.2, 0.5, sc.g, sc.b)
    end
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


function CHC_items_list:onMMBDown()
    if self.onmiddlemousedown then
        self:onmiddlemousedown()
    end
end

function CHC_items_list:onMouseMove(dx, dy)
    ISScrollingListBox.onMouseMove(self, dx, dy)
    if not self.needmmb then self.needmmb = true end
end

function CHC_items_list:onMouseMoveOutside(x, y)
    ISScrollingListBox.onMouseMoveOutside(self, x, y)
    if self.needmmb then self.needmmb = false end
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

function CHC_items_list:new(args, onmiddlemousedown)
    local o = {}

    o = ISScrollingListBox:new(args.x, args.y, args.w, args.h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    o.anchorTop = true
    o.anchorBottom = true

    o.favorite = {
        star = { tex = getTexture('media/textures/itemFavoriteStar.png') },
        checked = { tex = getTexture('media/textures/itemFavoriteStarChecked.png') },
        notChecked = { tex = getTexture('media/textures/itemFavoriteStarOutline.png') }
    }
    o.favorite.star.height = o.favorite.star.tex:getHeight()
    o.favorite.checked.height = o.favorite.checked.tex:getHeight()
    o.favorite.notChecked.height = o.favorite.notChecked.tex:getHeight()
    o.onmiddlemousedown = onmiddlemousedown
    o.needmmb = false
    o.modData = CHC_main.playerModData

    o.updRates = {
        { var = "needUpdateScroll",   rate = 50 },
        { var = "needUpdateMousePos", rate = 100 }
    }
    o.yScroll = 0
    o.needUpdateScroll = true
    o.needUpdateMousePos = true

    o.player = getPlayer()
    return o
end
