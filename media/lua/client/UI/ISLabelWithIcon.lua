require "ISUI/ISLabel"

ISLabelWithIcon = ISLabel:derive("ISLabelWithIcon")

local sub = string.sub

function ISLabelWithIcon:initialise()
    ISLabel.initialise(self)
end

function ISLabelWithIcon:setName(name, setOrig)
    if self.name == name then return end
    self.name = name
    self:setX(self.originalX)

    local width = getTextManager():MeasureStringX(self.font, name)
    if self.icon then
        width = width + self.iconSize + 3
    end
    self:setWidth(width)
    if self.left ~= true and not self.center then
        self:setX(self.x - self.width)
    end
    if setOrig then
        self.origName = name
    end
end

function ISLabelWithIcon:setIcon(icon, size)
    self.icon = icon
    self.iconSize = size and size or getTextManager():getFontHeight(self.font)
end

function ISLabelWithIcon:setWidthToName(minWidth)
    local width = getTextManager():MeasureStringX(self.font, self.name)
    if self.icon then
        width = width + self.iconSize + 3
    end
    width = math.max(width, minWidth or 0)

    if width ~= self.width then
        self:setWidth(width)
    end
end

function ISLabelWithIcon:setColor(r, g, b)
    self.r = r
    self.g = g
    self.b = b
end

---@param r number 0.0 - 1.0 red
---@param g number 0.0 - 1.0 green
---@param b number 0.0 - 1.0 blue
---@param a number? 0.0 - 1.0 alpha
function ISLabelWithIcon:setIconColor(r, g, b, a)
    self.iconR = r
    self.iconG = g
    self.iconB = b
    if a then
        self.iconA = a
    end
end

function ISLabelWithIcon:prerender()
    local txt = self.name
    if self.translation then
        txt = self.translation
    end
    local height = getTextManager():MeasureFont(self.font)

    -- The above call doesn't handle multi-line text
    local height2 = getTextManager():MeasureStringY(self.font, txt)
    height = math.max(height, height2)

    local x = 0
    local y = (self.height / 2) - (height / 2)
    if self.icon then
        self:drawTextureScaled(
            self.icon, x, y, self.iconSize,
            self.iconSize, self.iconA,
            self.iconR, self.iconG,
            self.iconB)

        x = x + self.iconSize
    end

    if not self.center then
        self:drawText(txt, x, y, self.r, self.g, self.b, self.a, self.font)
    else
        self:drawTextCentre(txt, x, y, self.r, self.g, self.b, self.a, self.font)
    end
    if self.joypadFocused and self.joypadTexture then
        local texY = self.height / 2 - 20 / 2
        self:drawTextureScaled(self.joypadTexture, -28, texY, 20, 20, 1, 1, 1, 1);
    end
    self:updateTooltip()
end

function ISLabelWithIcon:onMouseMove(dx, dy)
    self.mouseOver = true
end

function ISLabelWithIcon:onMouseMoveOutside(dx, dy)
    self.mouseOver = false
end

function ISLabelWithIcon:updateTooltip()
    if self.disabled then return; end
    if self:isMouseOver() and self.tooltip then
        local text = self.tooltip
        if not self.tooltipUI then
            self.tooltipUI = ISToolTip:new()
            self.tooltipUI:setOwner(self)
            self.tooltipUI:setVisible(false)
            self.tooltipUI:setAlwaysOnTop(true)
        end
        if not self.tooltipUI:getIsVisible() then
            if string.contains(self.tooltip, "\n") then
                self.tooltipUI.maxLineWidth = 1000 -- don't wrap the lines
            else
                self.tooltipUI.maxLineWidth = 300
            end
            self.tooltipUI:addToUIManager()
            self.tooltipUI:setVisible(true)
        end
        self.tooltipUI.description = text
        self.tooltipUI:setX(self:getAbsoluteX())
        self.tooltipUI:setY(self:getAbsoluteY() + self:getHeight())
    else
        if self.tooltipUI and self.tooltipUI:getIsVisible() then
            self.tooltipUI:setVisible(false)
            self.tooltipUI:removeFromUIManager()
        end
    end
end

function ISLabelWithIcon:setTooltip(tooltip)
    self.tooltip = tooltip
end

function ISLabelWithIcon:setJoypadFocused(focused)
    self.joypadFocused = focused
    self.joypadTexture = Joypad.Texture.AButton
end

function ISLabelWithIcon:setTranslation(translation)
    self.translation = translation
    self.x = self.originalX
    if self.font ~= nil then
        local width = getTextManager():MeasureStringX(self.font, translation)
        if self.icon then
            self.width = width + self.iconSize + 3
        end
        if (self.left ~= true) then
            self.x = self.x - self.width
        end
    else
        self.width = getTextManager():MeasureStringX(UIFont.Small, translation);
        if (self.left ~= true) then
            self.x = self.x - self.width;
        end
        self.font = UIFont.Small;
    end
end

function ISLabelWithIcon:new(x, y, height, name, r, g, b, a, font, bLeft, icon)
    local o = {}

    o = ISLabel:new(x, y, height, name, r, g, b, a, font, bLeft)
    setmetatable(o, self)
    self.__index = self
    o.icon = icon
    o.iconSize = 16
    local width = getTextManager():MeasureStringX(o.font, name)
    if icon then
        width = width + o.iconSize + 3
    end
    o.width = width
    o.iconR = 1
    o.iconG = 1
    o.iconB = 1
    o.iconA = 1
    return o
end
