require 'UI/CHC_tabs'
require 'UI/CHC_view'

CHC_search = ISPanel:derive('CHC_search')

local utils = require('CHC_utils')
local find = string.find
local sub = string.sub

-- region create
function CHC_search:initialise()
    ISPanel.initialise(self)

    self.typeData = {
        -- .count for each calculated in catSelUpdateOptions
        all = {
            tooltip = self.defaultCategory,
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
    self.categoryData = {}
    self.categoryData[self.defaultCategory] = { count = 0 }

    self:create()
end

function CHC_search:create()
    local filterRowOrderOnClickArgs = { CHC_search.sortByNameAsc, CHC_search.sortByNameDesc }
    local mainPanelsData = {
        listCls = CHC_items_list,
        panelCls = CHC_items_panel,
        extra_init_params = { onmiddlemousedown = self.onMMBDownObjList }
    }
    CHC_view.create(self, filterRowOrderOnClickArgs, mainPanelsData)
    self.onResizeHeaders = CHC_view.onResizeHeaders
    self.objGetter = "getItems"

    if self.ui_type == 'fav_items' then
        self.objSource = self.backRef[self.objGetter](self, true)
    end

    self:updateObjects()

    self.initDone = true
end

--endregion

-- region update
function CHC_search:update()
    if self.needUpdateDelayedSearch then
        local props = self.objPanel.itemProps
        props.delayedSearch = CHC_settings.config.delayed_search
        if props.delayedSearch then
            props.searchRow:setTooltip(props.searchBarDelayedTooltip)
        else
            props.searchRow:setTooltip(props.searchRow.origTooltip)
        end
    end
    CHC_view.update(self)
end

function CHC_search:updateObjects()
    CHC_view.updateObjects(self, 'category')
end

-- endregion

-- region render

function CHC_search:render()
    CHC_view.render(self)
end

--endregion

-- region logic

-- region event handlers
function CHC_search:onTextChange()
    if not self.delayedSearch or self.searchRow.searchBar:getInternalText() == '' then
        CHC_view.onTextChange(self)
    end
end

function CHC_search:onCommandEntered()
    if self.delayedSearch then
        CHC_view.onCommandEntered(self)
    end
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
        opt.iconTexture = getTexture("media/textures/CHC_open_new_tab.png")
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

-- endregion

-- region sorting logic
CHC_search.sortByNameAsc = function(a, b)
    return a.text < b.text
end

CHC_search.sortByNameDesc = function(a, b)
    return a.text > b.text
end

function CHC_search:filterTypeSetTooltip()
    local curtype = self.typeData[self.typeFilter].tooltip
    return getText('IGUI_invpanel_Type') .. ' (' .. curtype .. ')'
end

-- endregion

function CHC_search:searchProcessToken(token, item)
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char
    local items = {}

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token) then
        isSpecialSearch = true
        char = token:sub(1, 1)
        token = string.sub(token, 2)
        if token == '' and char ~= '^' then return true end
    end

    local whatCompare
    if not token then return true end
    if isAllowSpecialSearch and char == '^' then
        if not self.modData[CHC_main.getFavItemModDataStr(item)] then return false end
        whatCompare = string.lower(item.displayName)
    end
    if isSpecialSearch then
        if char == '!' then
            whatCompare = self.typeData[item.category].tooltip or item.category
        end
        if char == '@' then
            whatCompare = item.modname
        end
        if char == '#' then
            whatCompare = item.displayCategory
        end
        if char == '$' then
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
    else
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
    o.delayedSearch = CHC_settings.config.delayed_search
    o.searchBarDelayedTooltip = getText('IGUI_DelayedSearchBarTooltip')
    o.objListSize = 0

    o.needUpdateObjects = false
    o.needUpdateFavorites = false
    o.needUpdateFont = false
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateDelayedSearch = false

    o.isItemView = true
    o.initDone = false
    o.fav_ui_type = 'fav_items'

    o.sortOrderIconAsc = getTexture('media/textures/sort_order_asc.png')
    o.sortOrderIconDesc = getTexture('media/textures/sort_order_desc.png')


    return o
end
