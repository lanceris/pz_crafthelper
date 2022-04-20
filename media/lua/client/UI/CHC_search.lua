require "ISUI/ISPanel"

require "UI/CHC_tabs"
require "UI/CHC_uses_recipelist"
require "UI/CHC_uses"

local utils = require('CHC_utils')

CHC_search = ISPanel:derive("CHC_search")

CHC_search.sortOrderIconAsc = getTexture("media/textures/sort_order_asc.png")
CHC_search.sortOrderIconDesc = getTexture("media/textures/sort_order_desc.png")
CHC_search.typeFiltIconAll = getTexture("media/textures/type_filt_all.png")
CHC_search.typeFiltIconValid = getTexture("media/textures/type_filt_valid.png")
CHC_search.typeFiltIconKnown = getTexture("media/textures/type_filt_known.png")
CHC_search.typeFiltIconInvalid = getTexture("media/textures/type_filt_invalid.png")
CHC_search.searchIcon = getTexture("media/textures/search_icon.png")

local insert = table.insert
local sort = table.sort

-- region create
function CHC_search:initialise()
    ISPanel.initialise(self)

    self.categoryData = { -- .count for each calculated in catSelUpdateOptions
        all = {
            tooltip = getText("UI_All"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        AlarmClock = {
            tooltip = getText("IGUI_ItemCat_AlarmClock"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        AlarmClockClothing = {
            tooltip = getText("IGUI_CHC_ItemCat_AlarmClockClothing"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Clothing = {
            tooltip = getText("IGUI_ItemCat_Clothing"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Container = {
            tooltip = getText("IGUI_ItemCat_Container"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Drainable = {
            tooltip = getText("IGUI_CHC_ItemCat_Drainable"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Food = {
            tooltip = getText("IGUI_ItemCat_Food"),
            icon = getTexture("media/textures/type_filt_valid.png")
        },
        Key = {
            tooltip = getText("IGUI_CHC_ItemCat_Key"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Literature = {
            tooltip = getText("IGUI_ItemCat_Literature"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Map = {
            tooltip = getText("IGUI_CHC_ItemCat_Map"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Moveable = {
            tooltip = getText("IGUI_CHC_ItemCat_Moveable"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Normal = {
            tooltip = getText("IGUI_CHC_ItemCat_Normal"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Radio = {
            tooltip = getText("IGUI_CHC_ItemCat_Radio"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        Weapon = {
            tooltip = getText("IGUI_ItemCat_Weapon"),
            icon = getTexture("media/textures/type_filt_all.png")
        },
        WeaponPart = {
            tooltip = getText("IGUI_ItemCat_WeaponPart"),
            icon = getTexture("media/textures/type_filt_all.png")
        }
    }


    self:create()
end

function CHC_search:create()

    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, 20, { self.onResizeHeaders, self }, self.sep_x)
    self.headers:initialise()
    -- endregion

    local x = self.headers.x
    local y = self.headers.y + self.headers.height
    local leftW = self.headers.nameHeader.width
    local rightX = self.headers.typeHeader.x
    local rightW = self.headers.typeHeader.width

    -- region filters UI
    local filterRowData = {
        filterOrderData = {
            width = 24,
            title = "",
            onclick = self.sortByName,
            defaultTooltip = self:filterRowOrderSetTooltip(),
            defaultIcon = self:filterRowOrderSetIcon()
        },
        filterTypeData = {
            width = 24,
            title = "",
            onclick = self.onFilterTypeMenu,
            defaultTooltip = self:filterRowTypeSetTooltip(),
            defaultIcon = self:filterRowTypeSetIcon()
        },
        filterSelectorData = {
            defaultCategory = getText("UI_All"),
            defaultTooltip = getText("IGUI_invpanel_Category"),
            onChange = self.onChangeCategory
        }
    }

    self.filterRow = CHC_filter_row:new(x, y, leftW, 24, filterRowData)
    self.filterRow:initialise()
    local leftY = y + 24
    --endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new(x, leftY, leftW, 24, nil, self.onTextChange, self.searchRowHelpText)
    self.searchRow:initialise()
    leftY = leftY + 24
    -- endregion

    -- region recipe list
    local rlh = self.height - self.headers.height - self.filterRow.height - self.searchRow.height
    self.objList = CHC_items_list:new(x, leftY, leftW, rlh, self.onMMBDownObjList)

    self.objList.drawBorder = true
    self.objList.onRightMouseDown = self.onRMBDownObjList
    self.objList:initialise()
    self.objList:instantiate()
    self.objList:setAnchorBottom(true)
    self.objList:setOnMouseDownFunction(self, self.onItemChange)

    -- Add entries to recipeList
    -- self:cacheFullRecipeCount(self.itemSource)
    local iph = self.height - self.headers.height
    self.objPanel = CHC_items_panel:new(rightX, y, rightW, iph)
    self.objPanel:initialise()
    self.objPanel:instantiate()
    self.objPanel:setAnchorLeft(true)

    -- endregion

    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.objList)
    self:addChild(self.objPanel)

    self:catSelUpdateOptions()
    -- self:cacheCategoryCounts()
    self:updateItems(self.selectedCategory)
end

--endregion

--region update

function CHC_search:update()
    if self.needUpdateFavorites == true then
        self.needUpdateFavorites = false
    end
    if self.needUpdateObjects == true then
        self:updateItems(self.selectedCategory)
        self.needUpdateObjects = false
    end
end

function CHC_search:onTextChange()
    self.needUpdateObjects = true
end

function CHC_search:onRMBDownObjList(x, y)
    local row = self:rowAt(x, y)
    if row == -1 then return end
    local backref = self.parent.backRef
    local item = self.items[row].item
    -- check if there is recipes for item
    local cond1 = type(CHC_main.recipesByItem[item.item:getName()]) == 'table'
    local cond2 = type(CHC_main.recipesForItem[item.item:getName()]) == 'table'
    local cX = getMouseX()
    local cY = getMouseY()
    local context = ISContextMenu.get(0, cX + 10, cY)

    local function chccopy()
        if item.name then
            Clipboard.setClipboard(item.name)
        end
    end

    -- context:addOption("Copy name to clipboard", self, chccopy)
    if cond1 or cond2 then
        context:addOption(getText("IGUI_new_tab"), backref, backref.addItemView, item.item, true)
        -- backref:addItemView(item, true)
    end
end

function CHC_search:onMMBDownObjList()
    local x = self:getMouseX()
    local y = self:getMouseY()
    local row = self:rowAt(x, y)
    if row == -1 then return end
    local backref = self.parent.backRef
    local item = self.items[row].item.item
    -- check if there is recipes for item
    local cond1 = type(CHC_main.recipesByItem[item:getName()]) == 'table'
    local cond2 = type(CHC_main.recipesForItem[item:getName()]) == 'table'
    if cond1 or cond2 then
        backref:addItemView(item, false)
    end
end

function CHC_search:onChangeCategory(_option, sl)
    self.parent.selectedCategory = sl or _option.options[_option.selected].text
    self.parent.needUpdateObjects = true
end

function CHC_search:cacheItemCounts()

end

function CHC_search:updateItems(sl)
    -- print(sl)
    if type(sl) == 'table' then sl = sl.text end
    local categoryAll = self.categorySelectorDefaultOption
    local searchBar = self.searchRow.searchBar
    local items = self.ui_type == 'fav_items' and self.favrec or self.itemSource

    if sl == categoryAll and self.typeFilter == "all" and searchBar:getInternalText() == "" then
        CHC_uses.refreshObjList(self, items)
        return
    end

    -- filter items
    local filteredItems = {}
    for i = 1, #items do
        local rc = items[i].displayCategory

        local fav_cat_state = false
        local type_filter_state = false
        local search_state = false
        -- local condFav1 = sl == "* " .. getText("IGUI_CraftCategory_Favorite")
        -- local condFav2 = items[i].favorite
        -- if condFav1 and condFav2 then
        --     fav_cat_state = true
        -- end

        if (rc == sl or sl == categoryAll) then
            type_filter_state = self:itemTypeFilter(items[i])
        end
        search_state = CHC_uses.searchTypeFilter(self, items[i])

        if type_filter_state and search_state then
            insert(filteredItems, items[i])
        end
    end
    CHC_uses.refreshObjList(self, filteredItems)
end

function CHC_search:searchProcessToken(token, item)
    -- check if token is special search
    -- if so
    -- remove special char from token
    -- process special chars
    -- if not, compare token with recipe name
    --return state
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char
    local items = {}
    if not token then return true end

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token) then
        isSpecialSearch = true
        char = token:sub(1, 1)
        token = string.sub(token, 2)
        if token == "" then return true end
    end


    local whatCompare
    if isAllowSpecialSearch and char == "^" then
        -- print('fav items(?) here')
        --     -- show favorited reciped and search by them
        --     if not recipe.favorite then return false end
        --     whatCompare = string.lower(recipe.recipe:getName())
    end
    if token and isSpecialSearch then
        if char == "!" then
            -- search by item category
            whatCompare = self.categoryData[item.category].tooltip or item.category
        end
        if char == "@" then
            -- search by mod name of item
            whatCompare = item.modname
        end
        if char == "#" then
            -- search by display category of item
            whatCompare = item.displayCategory
        end
    end
    if token and not isSpecialSearch then
        whatCompare = string.lower(item.displayName)
    end
    state = utils.compare(whatCompare, token)
    return state
end

function CHC_search:processAddObjToObjList(item, modData)
    -- item.favorite = modData[CHC_main.getFavoriteModDataString(item.recipe)] or false
    local name = item.displayName
    if name then
        self.objList:addItem(name, item)
    end
end

function CHC_search:onItemChange(item)
    self.objPanel:setObj(item)
    -- self.recipesList:onMouseDown_Recipes(self.recipesList:getMouseX(), self.recipesList:getMouseY())
end

function CHC_search:catSelUpdateOptions()

    local selector = self.filterRow.categorySelector
    local uniqueCategories = {}
    local dcatCounts = {}
    local catCounts = {}
    local allItems = self.ui_type == 'fav_items' and self.favrec or self.itemSource
    local c = 1

    for i = 1, #allItems do

        local ic = allItems[i].category
        if not catCounts[ic] then
            catCounts[ic] = 1
        else
            catCounts[ic] = catCounts[ic] + 1
        end

        local idc = allItems[i].displayCategory
        if not utils.any(uniqueCategories, idc) then
            uniqueCategories[c] = idc
            dcatCounts[idc] = 1
            c = c + 1
        else
            dcatCounts[idc] = dcatCounts[idc] + 1
        end
    end

    selector:clear()
    selector:addOptionWithData(self.categorySelectorDefaultOption, { count = #allItems })

    -- WIP favorite category

    sort(uniqueCategories)
    for i = 1, #uniqueCategories do
        selector:addOptionWithData(uniqueCategories[i], { count = dcatCounts[uniqueCategories[i]] })
    end

    self.categoryData.all.count = #allItems
    for cat, cnt in pairs(catCounts) do
        self.categoryData[cat].count = cnt
    end
end

function CHC_search:handleFavorites()

end

-- endregion

--region filters

-- region filter onClick handlers
function CHC_search:onFilterTypeMenu(button)
    local self = self.parent
    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(0, x + 10, y)

    local data = {}
    for cat, d in pairs(self.categoryData) do
        insert(data, { txt = d.tooltip, num = d.count, arg = cat })
    end

    local txt
    for i = 1, #data do
        txt = CHC_uses.filterSortMenuGetText(self, data[i].txt, data[i].num)
        context:addOption(txt, self, CHC_search.sortByType, data[i].arg)
    end

end

function CHC_search:itemTypeFilter(item)
    local state = true
    if self.typeFilter == 'all' then
        state = true
    elseif self.typeFilter ~= item.category then
        state = false
    end
    return state
end

-- region filterRow setters
function CHC_search:filterRowOrderSetTooltip()
    local cursort = self.itemSortAsc and getText("IGUI_invpanel_ascending") or getText("IGUI_invpanel_descending")
    return getText("UI_settings_st_title") .. " (" .. cursort .. ")"
end

function CHC_search:filterRowOrderSetIcon()
    return self.itemSortAsc and self.sortOrderIconAsc or self.sortOrderIconDesc
end

function CHC_search:filterRowTypeSetTooltip()
    local curtype = self.categoryData[self.typeFilter].tooltip
    return getText("UI_settings_av_title") .. " (" .. curtype .. ")"
end

function CHC_search:filterRowTypeSetIcon()
    return self.categoryData[self.typeFilter].icon
end

-- endregion

CHC_search.sortByNameAsc = function(a, b)
    return a.text < b.text
end

CHC_search.sortByNameDesc = function(a, b)
    return a.text > b.text
end

function CHC_search:sortByName()
    local self = self.parent
    local option = self.filterRow.categorySelector
    local sl = option.options[option.selected].text
    self.itemSortAsc = not self.itemSortAsc
    self.itemSortFunc = self.itemSortAsc and CHC_search.sortByNameAsc or CHC_search.sortByNameDesc

    local newIcon = self:filterRowOrderSetIcon()
    self.filterRow.filterOrderBtn:setImage(newIcon)
    local newTooltip = self:filterRowOrderSetTooltip()
    self.filterRow.filterOrderBtn:setTooltip(newTooltip)
    self.selectedCategory = sl
    self.needUpdateObjects = true
end

function CHC_search:sortByType(_type)
    if _type ~= self.typeFilter then
        self.typeFilter = _type
        self.filterRow.filterTypeBtn:setTooltip(self:filterRowTypeSetTooltip())
        self.filterRow.filterTypeBtn:setImage(self:filterRowTypeSetIcon())
        self.needUpdateObjects = true
    end
end

-- endregion

--region render

function CHC_search:onResizeHeaders()
    self.filterRow:setWidth(self.headers.nameHeader.width)
    self.searchRow:setWidth(self.headers.nameHeader.width)
    self.objList:setWidth(self.headers.nameHeader.width)
    self.objPanel:setWidth(self.headers.typeHeader.width)
    self.objPanel:setX(self.headers.typeHeader.x)
end

--endregion


function CHC_search:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }

    o.ui_type = args.ui_type
    o.sep_x = args.sep_x
    o.player = getPlayer()

    o.favCatName = "* " .. getText("IGUI_CraftCategory_Favorite")
    o.categorySelectorDefaultOption = getText("UI_All")
    o.searchRowHelpText = getText("UI_searchrow_info",
        getText("UI_searchrow_info_items_special"),
        getText("UI_searchrow_info_items_examples")
    )


    o.selectedCategory = o.categorySelectorDefaultOption
    o.backRef = args.backRef

    o.itemSource = args.recipeSource
    o.itemSortAsc = args.itemSortAsc
    o.itemSortFunc = o.itemSortAsc == true and CHC_search.sortByNameAsc or CHC_search.sortByNameDesc
    o.typeFilter = args.typeFilter
    o.showHidden = args.showHidden
    o.favNum = 0 -- WIP favorite items

    o.needUpdateFavorites = false
    o.needUpdateCounts = false
    o.needUpdateObjects = false
    o.updCountsWithCur = false

    return o
end
