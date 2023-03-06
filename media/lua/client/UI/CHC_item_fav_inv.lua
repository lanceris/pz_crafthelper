require 'ISUI/ISInventoryPane'
require 'CHC_main'

local favTexOutline = getTexture('media/textures/CHC_item_favorite_star_outline.png')

local function renderdetailsCHC(self, doDragged)
    local y = 0
    local MOUSEX = self:getMouseX()
    local MOUSEY = self:getMouseY()
    local YSCROLL = self:getYScroll()
    local HEIGHT = self:getHeight()
    for k, v in ipairs(self.itemslist) do
        local count = 1
        for k2, v2 in ipairs(v.items) do
            local item = v2
            local chcItem = CHC_main.items[item:getFullType()]
            if not chcItem or not CHC_main.playerModData then return end
            local isFav = CHC_main.playerModData[CHC_main.getFavItemModDataStr(item)] == true
            if chcItem and isFav then
                local doIt = true
                local xoff = 0
                local yoff = 0

                local isDragging = false
                if self.dragging ~= nil and self.selected[y + 1] ~= nil and self.dragStarted then
                    xoff = MOUSEX - self.draggingX
                    yoff = MOUSEY - self.draggingY
                    if not doDragged then
                        doIt = false
                    else
                        isDragging = true
                    end
                else
                    if doDragged then doIt = false end
                end
                local topOfItem = y * self.itemHgt + YSCROLL
                if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
                    doIt = false
                end

                local tex = item:getTex()
                local auxDXY = math.ceil(20 * self.texScale)
                if doIt == true and tex ~= nil and count == 1 then
                    local tx = (13 + auxDXY + xoff)
                    local ty = (y * self.itemHgt) + self.headerHgt + yoff
                    self:drawTexture(favTexOutline, tx, ty, 1, 1, 1, 1)
                end
            end
            y = y + 1
            if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
                break
            end
            count = count + 1
        end
    end
end

local old_render_details = ISInventoryPane.renderdetails
function ISInventoryPane:renderdetails(doDragged)
    old_render_details(self, doDragged)
    if CHC_settings.config and CHC_settings.config.show_fav_items_inventory == true then
        pcall(renderdetailsCHC, self, doDragged)
    end
end
