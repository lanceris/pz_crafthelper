---@class ISToolTip
---@class PresetTooltip : ISToolTip
---@field font UIFont
---@field imageSize number
---@field margins? {left:number,top:number,right:number,bottom:number}
PresetTooltip = ISToolTip:derive("PresetTooltip")
PresetTooltip.tooltipPool = {}
PresetTooltip.tooltipsUsed = {}
PresetTooltip.tooltipsUsedNum = 0

local utils = require('CHC_utils')

local insert = table.insert

---Get font height in pixels
---@param font UIFont
---@return number fontHgt
local function getFontHgt(font)
    return getTextManager():getFontHeight(font)
end

---Add text to specific position in tooltip
---@param x number X position of text top-left corner
---@param y number Y position of text top-left corner
---@param text string text
---@param r? number text red color (0-1), 1
---@param g? number text green color (0-1), 1
---@param b? number text blue color (0-1), 1
---@param a? number text opacity (0-1), 0.9
---@param font? UIFont font to use, `self.font` by default
function PresetTooltip:addText(x, y, text, r, g, b, a, font)
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 0.9
    local fontHgt = self.fontHgt
    if font and font ~= self.font then
        fontHgt = getFontHgt(font)
    end
    font = font or self.font


    local numLines = 1
    local p = string.find(text, "\n")
    while p do
        numLines = numLines + 1
        p = string.find(text, "\n", p + 4)
    end

    local width = utils.strWidth(font, text)
    insert(self.contents,
        {
            type = "text",
            x = x,
            y = y,
            width = width,
            height = fontHgt * numLines,
            text = text,
            r = r,
            g = g,
            b = b,
            a = a
        })
    self.newItemAdded = true
end

---Add image to specific position in tooltip
---@param x number X position of top-left image corner
---@param y number Y position of top-left image corner
---@param textureName string? name of texture to load by `getTexture(...)`
---@param size number? force this image size in pixels, `self.imageSize` by default
---@param texture Texture? actual texture
function PresetTooltip:addImage(x, y, size, textureName, texture)
    size = size or self.imageSize
    local tex = textureName and getTexture(textureName) or texture
    insert(self.contents,
        {
            type = "image",
            x = x,
            y = y,
            width = size,
            height = size,
            texture = tex,
        })
    self.newItemAdded = true
end

function PresetTooltip:layoutContents()
    -- if not self.newItemAdded then return end
    -- self.newItemAdded = false
    local width = 0
    local height = 0
    for i = 1, #self.contents do
        local v = self.contents[i]
        width = math.max(width, v.x + v.width)
        height = math.max(height, v.y + v.height + self.margins.bottom)
    end
    return width, height
end

function PresetTooltip:renderContents()
    for i = 1, #self.contents do
        local v = self.contents[i]
        local width = 0
        if v.type == "image" then
            self:drawTextureScaledAspect(v.texture, v.x, v.y, v.width, v.height, 1, 1, 1, 1)
            width = width + v.width
        elseif v.type == "text" then
            self:drawText(v.text, v.x, v.y, v.r, v.g, v.b, v.a, v.font)
            width = width + v.width
        end
        if width > self.width then
            self.width = width
        end
        self:drawRect(0, v.y - 2, self.width, 1, 0.05, 1, 1, 1)
    end
end

---reset tooltip and remove all contents
function PresetTooltip:reset()
    self:setVisible(false)
    -- ISToolTip.reset(self)
    table.wipe(self.contents)
end

function PresetTooltip:prerender()
    if self.owner and not self.owner:isReallyVisible() then
        self:removeFromUIManager()
        self:setVisible(false)
    end
    self:doLayout()
    self:drawRect(0,
        0,
        self.width,
        self.height,
        self.backgroundColor.a,
        self.backgroundColor.r,
        self.backgroundColor.g,
        self.backgroundColor.b)
end

---create new PresetTooltip
---@class PresetTooltip
---@param font? UIFont font to use, `UIFont.Small` by default
---@param imageSize? number image size, `24` by default
---@param margins? {left:number,top:number,right:number,bottom:number} margins to use, by default all 10
function PresetTooltip:new(font, imageSize, margins)
    ---@class PresetTooltip
    local o = ISToolTip.new(self)
    o.background = true
    o.contents = {}
    o.font = font or UIFont.Small
    o.fontHgt = getTextManager():getFontHeight(o.font)
    o.imageSize = imageSize or 24
    o.margins = margins or { left = 10, top = 120, right = 10, bottom = 10 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.6 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.9 };
    return o
end

---@param font? UIFont font to use, `UIFont.Small` by default
---@param imageSize? number image size, `24` by default
---@param margins? {left:number,top:number,right:number,bottom:number} margins to use, by default all 10
---@return PresetTooltip
function PresetTooltip.addToolTip(font, imageSize, margins)
    local pool = PresetTooltip.tooltipPool
    if #pool == 0 then
        table.insert(pool, PresetTooltip:new(font, imageSize, margins))
    end
    ---@type PresetTooltip
    local tooltip = table.remove(pool, #pool)
    tooltip:reset()
    table.insert(PresetTooltip.tooltipsUsed, tooltip)
    PresetTooltip.tooltipsUsedNum = PresetTooltip.tooltipsUsedNum + 1
    return tooltip
end

function PresetTooltip.releaseAll()
    for i = 1, PresetTooltip.tooltipsUsedNum do
        insert(PresetTooltip.tooltipPool, PresetTooltip.tooltipsUsed[i])
    end
    table.wipe(PresetTooltip.tooltipsUsed)
    PresetTooltip.tooltipsUsedNum = 0
end
