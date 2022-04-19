local utils = require('CHC_utils')

CHC_item_panel = ISPanel:derive("CHC_item_panel")

-- region create
function CHC_item_panel:initialise()
    ISPanel.initialise(self)
    self:create()
end

function CHC_item_panel:create()
    -- common item properties
    -- - fullType
    -- - name
    -- - category
    -- - display category
    -- - modname
    -- - count (?)
    -- - texture
    -- - tooltip (?)
end

-- endregion

-- region render

-- endregion

-- region logic

-- endregion

function CHC_item_panel:new(x, y, w, h)
    local o = {}
    o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o:noBackground()
    o.anchorTop = true
    o.anchorBottom = true

    o.item = nil

    return o
end
