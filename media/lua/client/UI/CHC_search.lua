require 'ISUI/ISPanel'

require 'UI/CHC_tabs'
require 'UI/CHC_uses_recipelist'
require 'UI/CHC_uses'

local utils = require('CHC_utils')

CHC_search = ISPanel:derive('CHC_search')

local insert = table.insert
local sort = table.sort
local find = string.find
local sub = string.sub

-- region create
function CHC_search:initialise()
    ISPanel.initialise(self)

    self.typeData = {
        -- .count for each calculated in catSelUpdateOptions
        all = {
            tooltip = getText('UI_All'),
            icon = getTexture('media/textures/type_filt_all.png')
        },
        AlarmClock = {
            tooltip = getText('IGUI_ItemCat_AlarmClock'),
            icon = CHC_main.items['Base.AlarmClock2'].texture
        },
        AlarmClockClothing = {
            tooltip = getText('IGUI_CHC_ItemCat_AlarmClockClothing'),
            icon = CHC_main.items['Base.WristWatch_Right_DigitalRed'].texture
        },
        Clothing = {
            tooltip = getText('IGUI_ItemCat_Clothing'),
            icon = CHC_main.items['Base.Tshirt_Scrubs'].texture
        },
        Container = {
            tooltip = getText('IGUI_ItemCat_Container'),
            icon = CHC_main.items['Base.Purse'].texture
        },
        Drainable = {
            tooltip = getTextOrNull('IGUI_ItemCat_Drainable') or getText('IGUI_CHC_ItemCat_Drainable'),
            icon = CHC_main.items['Base.Thread'].texture
        },
        Food = {
            tooltip = getText('IGUI_ItemCat_Food'),
            icon = CHC_main.items['Base.Steak'].texture
        },
        Key = {
            tooltip = getText('IGUI_CHC_ItemCat_Key'),
            icon = CHC_main.items['Base.Key1'].texture
        },
        Literature = {
            tooltip = getText('IGUI_ItemCat_Literature'),
            icon = CHC_main.items['Base.Book'].texture
        },
        Map = {
            tooltip = getText('IGUI_CHC_ItemCat_Map'),
            icon = CHC_main.items['Base.Map'].texture
        },
        Moveable = {
            tooltip = getText('IGUI_CHC_ItemCat_Moveable'),
            icon = CHC_main.items['Base.Mov_GreyComfyChair'].texture
        },
        Normal = {
            tooltip = getText('IGUI_CHC_ItemCat_Normal'),
            icon = CHC_main.items['Base.Spiffo'].texture
        },
        Radio = {
            tooltip = getText('IGUI_CHC_ItemCat_Radio'),
            icon = CHC_main.items['Radio.RadioRed'].texture
        },
        Weapon = {
            tooltip = getText('IGUI_ItemCat_Weapon'),
            icon = CHC_main.items['Base.Pistol'].texture
        },
        WeaponPart = {
            tooltip = getText('IGUI_ItemCat_WeaponPart'),
            icon = CHC_main.items['Base.GunLight'].texture
        }
    }


    self:create()
end

function CHC_search:create()
    -- region draggable headers
    self.headers = CHC_tabs:new(0, 0, self.width, CHC_main.common.heights.headers, { self.onResizeHeaders, self },
        self.sep_x)
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
            width = CHC_main.common.heights.filter_row,
            title = '',
            onclick = CHC_view.sortByName,
            onclickargs = { CHC_search.sortByNameAsc, CHC_search.sortByNameDesc },
            defaultTooltip = CHC_view.filterOrderSetTooltip(self),
            defaultIcon = CHC_view.filterOrderSetIcon(self)
        },
        filterTypeData = {
            width = CHC_main.common.heights.filter_row,
            title = '',
            onclick = self.onFilterTypeMenu,
            defaultTooltip = self:filterTypeSetTooltip(),
            defaultIcon = CHC_view.filterTypeSetIcon(self)
        },
        filterSelectorData = {
            defaultCategory = getText('UI_All'),
            defaultTooltip = getText('IGUI_invpanel_Category'),
            onChange = self.onChangeCategory
        }
    }

    self.filterRow = CHC_filter_row:new(
        { x = x, y = y, w = leftW, h = CHC_main.common.heights.filter_row, backRef = self.backRef }, filterRowData)
    self.filterRow:initialise()
    local leftY = y + CHC_main.common.heights.filter_row
    --endregion

    -- region search bar
    self.searchRow = CHC_search_bar:new(
        { x = x, y = leftY, w = leftW, h = CHC_main.common.heights.search_row, backRef = self.backRef }, nil,
        self.onTextChange, self.searchRowHelpText)
    self.searchRow:initialise()
    leftY = leftY + self.searchRow.height
    -- endregion

    -- region recipe list
    local rlh = self.height - self.headers.height - self.filterRow.height - self.searchRow.height
    self.objList = CHC_items_list:new({ x = x, y = leftY, w = leftW, h = rlh, backRef = self.backRef },
        self.onMMBDownObjList)

    self.objList.drawBorder = true
    self.objList.onRightMouseDown = self.onRMBDownObjList
    self.objList:initialise()
    self.objList:instantiate()
    self.objList:setAnchorBottom(true)
    self.objList:setOnMouseDownFunction(self, self.onObjectChange)
    self.objList.curFontData = self.curFontData

    -- Add entries to recipeList
    local iph = self.height - self.headers.height
    self.objPanel = CHC_items_panel:new({ x = rightX, y = y, w = rightW, h = iph, backRef = self.backRef })
    self.objPanel:initialise()
    self.objPanel:instantiate()
    self.objPanel:setAnchorLeft(true)

    -- endregion

    self:addChild(self.headers)
    self:addChild(self.filterRow)
    self:addChild(self.searchRow)
    self:addChild(self.objList)
    self:addChild(self.objPanel)

    if self.ui_type == 'fav_items' then
        self.favrec = self.backRef:getItems(CHC_main.itemsForSearch, nil, true)
    end

    self:updateTypesCategoriesInitial()
    self:updateObjects(self.selectedCategory)
end

--endregion

-- region update

function CHC_search:updateTypesCategoriesInitial()
    local selector = self.filterRow.categorySelector
    local uniqueCategories = {}
    local dcatCounts = {}
    local catCounts = {}
    local allItems = self.ui_type == 'fav_items' and self.favrec or self.objSource -- CHC_items.itemsForSearch
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
    selector:addOptionWithData(self.defaultCategory, { count = #allItems, initCount = #allItems })

    sort(uniqueCategories)
    for i = 1, #uniqueCategories do
        local val = dcatCounts[uniqueCategories[i]]
        selector:addOptionWithData(uniqueCategories[i], { count = val, initCount = val })
    end

    self.typeData.all.selectorOptions = selector.options
    self.typeData.all.count = #allItems
    self.typeData.all.initCount = #allItems
    for cat, cnt in pairs(catCounts) do
        self.typeData[cat].initCount = cnt
        self.typeData[cat].count = cnt
    end
end

function CHC_search:update()
    CHC_view.update(self)
end

function CHC_search:updateObjects(sl)
    if type(sl) == 'table' then sl = sl.text end
    local categoryAll = self.defaultCategory
    local searchBar = self.searchRow.searchBar
    local sBText = searchBar:getInternalText()

    local items
    items = self.ui_type == 'fav_items' and self.favrec or self.objSource

    if sl == categoryAll and self.typeFilter == 'all' and sBText == '' then
        CHC_view.refreshObjList(self, items)
        return
    end

    -- filter items
    local filteredItems = {}
    for i = 1, #items do
        local rc = items[i].displayCategory

        local type_filter_state = false
        local search_state = false

        if (rc == sl or sl == categoryAll) then
            type_filter_state = CHC_view.objTypeFilter(self, items[i].category)
        end
        search_state = CHC_main.common.searchFilter(self, items[i], self.searchProcessToken)

        if type_filter_state and search_state then
            insert(filteredItems, items[i])
        end
    end
    CHC_view.refreshObjList(self, filteredItems)
end

function CHC_search:updateTypes()
    local typCounts = {}
    local allItems = self.ui_type == 'fav_items' and self.favrec or self.objSource -- CHC_items.itemsForSearch
    local currentCategory = self.selectedCategory
    local isSelectorSetToAll = self.selectedCategory == self.defaultCategory

    for i = 1, #allItems do
        local ic = allItems[i].category
        local idc = allItems[i].displayCategory
        if idc == currentCategory or isSelectorSetToAll then
            if not typCounts[ic] then
                typCounts[ic] = 1
            else
                typCounts[ic] = typCounts[ic] + 1
            end
        end
    end
    for typ, _ in pairs(self.typeData) do
        self.typeData[typ].count = 0
    end
    local allcnt = 0
    for typ, cnt in pairs(typCounts) do
        self.typeData[typ].count = cnt
        allcnt = allcnt + cnt
    end
    self.typeData.all.count = allcnt
end

function CHC_search:updateCategories()
    local catCounts = {}
    local allItems = self.ui_type == 'fav_items' and self.favrec or self.objSource -- CHC_items.itemsForSearch
    local currentType = self.typeFilter
    local isTypeSetToAll = self.typeFilter == 'all'
    local selector = self.filterRow.categorySelector
    local newCats = {}

    for i = 1, #allItems do
        local ic = allItems[i].category
        local idc = allItems[i].displayCategory
        if ic == currentType or isTypeSetToAll then
            if not catCounts[idc] then
                insert(newCats, idc)
                catCounts[idc] = 1
            else
                catCounts[idc] = catCounts[idc] + 1
            end
        end
    end
    selector:clear()
    selector:addOptionWithData(self.defaultCategory, { count = self.typeData.all.count })
    sort(newCats)
    for i = 1, #newCats do
        local val = newCats[i]
        selector:addOptionWithData(val, { count = catCounts[val] })
    end

    selector:select(self.selectedCategory)
end

function CHC_search:handleFavorites()
    if self.ui_type == 'fav_items' then
        self.favrec = self.backRef:getItems(CHC_main.itemsForSearch, nil, true)
    else
        self.backRef.updateQueue:push({
            targetView = 'fav_items',
            actions = { 'needUpdateFavorites', 'needUpdateObjects', 'needUpdateTypes', 'needUpdateCategories' }
        })
    end
end

-- endregion

-- region render

function CHC_search:render()
    CHC_view.render(self)
end

function CHC_search:onResizeHeaders()
    CHC_view.onResizeHeaders(self)
end

--endregion

-- region logic

-- region event handlers
function CHC_search:onTextChange()
    CHC_view.onTextChange(self)
end

function CHC_search:onRMBDownObjList(x, y, item)
    local backRef = self.parent.backRef
    local context = backRef.onRMBDownObjList(self, x, y, item)

    if not item then
        local row = self:rowAt(x, y)
        if row == -1 then return end
        item = self.items[row].item
        if not item then return end
    end
    item = CHC_main.items[item.fullType]
    local isRecipes = CHC_main.common.areThereRecipesForItem(item)

    if isRecipes then
        local opt = context:addOption(getText('IGUI_new_tab'), backRef, backRef.addItemView, item.item, true, 2)
        CHC_main.common.addTooltipNumRecipes(opt, item)
    end
end

function CHC_search:onMMBDownObjList()
    local x = self:getMouseX()
    local y = self:getMouseY()
    local row = self:rowAt(x, y)
    if row == -1 then return end
    local item = self.items[row].item
    local isRecipes = CHC_main.common.areThereRecipesForItem(item)
    if isRecipes then
        self.parent.backRef:addItemView(item.item, false)
    end
end

function CHC_search:onChangeCategory(_option, sl)
    CHC_view.onChangeCategory(self, _option, sl)
end

function CHC_search:onObjectChange(obj)
    CHC_view.onObjectChange(self, obj)
end

function CHC_search:onFilterTypeMenu(button)
    local data = {}
    for cat, d in pairs(self.parent.typeData) do
        insert(data, { txt = d.tooltip, num = d.count, arg = cat })
    end
    CHC_view.onFilterTypeMenu(self.parent, button, data, CHC_view.sortByType)
end

-- endregion

-- region sorting logic
CHC_search.sortByNameAsc = function(a, b)
    return a.text < b.text
end

CHC_search.sortByNameDesc = function(a, b)
    return a.text > b.text
end

-- endregion

function CHC_search:searchProcessToken(token, item)
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
        if token == '' and char ~= '^' then return true end
    end


    local whatCompare
    if isAllowSpecialSearch and char == '^' then
        if not self.modData[CHC_main.getFavItemModDataStr(item)] then return false end
        whatCompare = string.lower(item.displayName)
    end
    if token and isSpecialSearch then
        if char == '!' then
            -- search by item category
            whatCompare = self.typeData[item.category].tooltip or item.category
        end
        if char == '@' then
            -- search by mod name of item
            whatCompare = item.modname
        end
        if char == '#' then
            -- search by display category of item
            whatCompare = item.displayCategory
        end
        if char == '$' then
            -- search by attributes (props)
            whatCompare = CHC_main.common.getItemProps(item)
            if not whatCompare then return false end
            local opIx = find(token, '[><=]')
            if opIx then
                opIx = find(token, '[~><=]')
                for i = 1, #whatCompare do
                    local prop = whatCompare[i]
                    local whatCompName = prop.name
                    local toCompName = sub(token, 1, opIx - 1)
                    local stateName = utils.compare(whatCompName, toCompName)

                    local whatCompVal = prop.value
                    local toCompVal = sub(token, opIx, #token)
                    local stateVal = utils.compare(whatCompVal, toCompVal)

                    if stateName and stateVal then return true end
                end
                return false
            else
                for i = 1, #whatCompare do
                    local prop = whatCompare[i]
                    if utils.compare(prop.name, token) then return true end
                end
                return false
            end
        end
        -- if char == "%" then
        --     whatCompare = item.fullType
        -- end
    end
    if token and not isSpecialSearch then
        whatCompare = string.lower(item.displayName)
    end
    state = utils.compare(whatCompare, token)
    return state
end

function CHC_search:processAddObjToObjList(item, modData)
    local name = item.displayName
    if name then
        self.objList:addItem(name, item)
    end
end

-- region filterRow setters

function CHC_search:filterTypeSetTooltip()
    local curtype = self.typeData[self.typeFilter].tooltip
    return getText('IGUI_invpanel_Type') .. ' (' .. curtype .. ')'
end

-- endregion
-- endregion


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
    o.modData = CHC_main.playerModData

    o.defaultCategory = getText('UI_All')
    o.searchRowHelpText = getText('UI_searchrow_info',
        getText('UI_searchrow_info_items_special'),
        getText('UI_searchrow_info_items_examples')
    )

    o.selectedCategory = o.defaultCategory
    o.backRef = args.backRef

    o.objSource = args.objSource
    o.itemSortAsc = args.itemSortAsc
    o.itemSortFunc = o.itemSortAsc == true and CHC_search.sortByNameAsc or CHC_search.sortByNameDesc
    o.typeFilter = args.typeFilter
    o.showHidden = args.showHidden

    o.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
    o.objListSize = 0

    o.needUpdateObjects = false
    o.needUpdateTypes = false
    o.needUpdateCategories = false
    o.needUpdateFavorites = false
    o.needUpdateFont = false
    o.needUpdateScroll = false
    o.needUpdateMousePos = false

    o.isItemView = true

    o.sortOrderIconAsc = getTexture('media/textures/sort_order_asc.png')
    o.sortOrderIconDesc = getTexture('media/textures/sort_order_desc.png')


    return o
end
