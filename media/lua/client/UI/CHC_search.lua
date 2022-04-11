require "ISUI/ISPanel"

require "UI/CHC_tabs"
require "UI/CHC_uses_recipelist"


CHC_search = ISPanel:derive("CHC_search")


function CHC_search:initialise()
    ISPanel.initialise(self)
    self:create()
end

function CHC_search:create()
    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, 20, { self.onResizeHeaders, self }, self.sep_x)
    self.headers:initialise()
    -- endregion
end

function CHC_search:onResizeHeaders()
    -- self.filterRow:setWidth(self.headers.nameHeader.width)
    -- self.searchRow:setWidth(self.headers.nameHeader.width)
    -- self.recipesList:setWidth(self.headers.nameHeader.width)
    -- self.recipePanel:setWidth(self.headers.typeHeader.width)
    -- self.recipePanel:setX(self.headers.typeHeader.x)
end

function CHC_search:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }

    o.ui_name = args.ui_name
    o.sep_x = args.sep_x
    o.player = getPlayer()


    o.numRecipesAll = 0
    o.numRecipesValid = 0
    o.numRecipesKnown = 0
    o.numRecipesInvalid = 0
    return o
end
