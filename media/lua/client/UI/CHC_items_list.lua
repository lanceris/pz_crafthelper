CHC_items_list = ISScrollingListBox:derive('CHC_items_list')

-- region create

function CHC_items_list:initialise()
    self.fastListReturn = CHC_main.common.fastListReturn
    ISScrollingListBox.initialise(self)
end

-- endregion

-- region update
function CHC_items_list:update()
    if self.needmmb and Mouse.isMiddleDown() then
        self:onMMBDown()
        self.needmmb = false
    end
end

-- endregion

-- region render

function CHC_items_list:prerender()
    CHC_view._list.prerender(self)
end

function CHC_items_list:doDrawItem(y, item, alt)
    if self:fastListReturn(y) then return y + self.itemheight end

    local itemObj = item.item
    local a = 0.9

    local favoriteStar = nil
    local favoriteAlpha = a

    -- region icons
    if self.shouldShowIcons then
        local itemIcon = itemObj.texture
        self:drawTextureScaled(itemIcon, 6, y + 6, self.curFontData.icon, self.curFontData.icon, 1)
    end
    --endregion

    --region text
    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    local clr = {
        txt = item.text,
        x = self.shouldShowIcons and (self.curFontData.icon + 8) or 15,
        y = y + itemPadY,
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
    if item.index == self.mouseoverselected then
        if self.mouseX >= favYPos - 20 and self.mouseX <= favYPos + 20 then
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
function CHC_items_list:onMouseDownObj(x, y)
    local row = self:rowAt(x, y)
    if row == -1 then return end
    if CHC_view._list.isMouseOverFavorite(self, x) then
        self:addToFavorite(row)
    end
end

function CHC_items_list:onMouseWheel(del)
    local yScroll = self.smoothScrollTargetY or self.yScroll
    local topRow = self:rowAt(0, -yScroll)
    if self.items[topRow] then
        if not self.smoothScrollTargetY then self.smoothScrollY = self.yScroll end
        local y = self:topOfItem(topRow)
        if del < 0 then
            if yScroll == -y and topRow > 1 then
                local prev = self:prevVisibleIndex(topRow)
                y = self:topOfItem(prev)
            end
            self.smoothScrollTargetY = -y;
        else
            self.smoothScrollTargetY = -(y + self.items[topRow].height);
        end
    else
        self.yScroll = self.yScroll - (del * 18)
    end
    return true;
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

    local favStr = CHC_main.getFavItemModDataStr(selectedItem.item)
    local isFav = self.modData[favStr] == true
    isFav = not isFav
    self.modData[favStr] = isFav or nil
    if not isFav and parent.ui_type == 'fav_items' then
        self:removeItemByIndex(selectedIndex)
    end
    parent.needUpdateFavorites = true
end

-- endregion

function CHC_items_list:new(args)
    local o = {}

    o = ISScrollingListBox:new(args.x, args.y, args.w, args.h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    o.anchorTop = true
    o.anchorBottom = true

    o.favorite = {
        star = { tex = getTexture('media/textures/CHC_item_favorite_star.png') },
        checked = { tex = getTexture('media/textures/CHC_item_favorite_star_checked.png') },
        notChecked = { tex = getTexture('media/textures/CHC_item_favorite_star_outline.png') }
    }
    o.favorite.star.height = o.favorite.star.tex:getHeight()
    o.favorite.checked.height = o.favorite.checked.tex:getHeight()
    o.favorite.notChecked.height = o.favorite.notChecked.tex:getHeight()
    o.onmiddlemousedown = args.onmiddlemousedown
    o.needmmb = false
    o.modData = CHC_main.playerModData

    o.yScroll = 0
    o.needUpdateScroll = true
    o.needUpdateMousePos = true
    o.shouldShowIcons = CHC_settings.config.show_icons

    o.player = getPlayer()
    return o
end
