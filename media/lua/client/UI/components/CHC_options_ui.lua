CHC_options_ui = ISCollapsableWindow:derive('CHC_options_ui')
local insert = table.insert
local sort = table.sort
local find = string.find
local sub = string.sub
local utils = require('CHC_utils')


-- region create
function CHC_options_ui:initialise()
    ISCollapsableWindow.initialise(self)
end

function CHC_options_ui:createChildren()
    ISCollapsableWindow.createChildren(self)

end

-- endregion

-- region update

-- endregion

-- region render
function CHC_options_ui:render()
    ISCollapsableWindow.render(self)
end

function CHC_options_ui:onResize()
    ISCollapsableWindow.onResize(self)
end

function CHC_options_ui:close()
    -- FIXME
end

-- endregion

-- region logic
-- region event handlers

-- endregion

function CHC_options_ui:setPosition()
    local mainX = self.backRef:getX()
    local mainW = self.backRef:getWidth()
    local newX = mainX + mainW
    local newY = self.backRef:getY()

    local val1 = self:getX() + self:getWidth()
    local val2 = getCore():getScreenWidth()
    if val1 >= val2 then
        newX = mainX - self:getWidth()
    end
    if self:getY() + self:getHeight() > getCore():getScreenHeight() then
        newY = getCore():getScreenHeight() - self:getHeight()
    end

    self:setX(newX)
    self:setY(newY)
end

-- endregion



function CHC_options_ui:new(args)
    local o = {}
    o = ISCollapsableWindow:new(args.x, args.y, args.w, args.h);
    setmetatable(o, self)
    self.__index = self

    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.moveWithMouse = false
    o.backRef = args.backRef

    return o
end
