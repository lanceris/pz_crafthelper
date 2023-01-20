require 'ISUI/ISPanel'

CHC_collapsible_table = ISPanel:derive("CHC_collapsible_table")


function CHC_collapsible_table:initialise()
    ISPanel.initialise(self)
    self:create()
end

function CHC_collapsible_table:create()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self.testBtn = ISButton:new(x, y, w, h, "test", self)
    self.testBtn:initialise()

    self:addChild(self.testBtn)
end

function CHC_collapsible_table:new(x, y, width, height)
    local o = {};
    o = ISPanel:new(x, y, width, height)

    setmetatable(o, self)
    self.__index = self

    o.x = x
    o.y = y
    o.w = width
    o.h = height

    return o
end
