require 'UI/CHC_tabs'
require 'UI/CHC_view'

CHC_item_view = ISPanel:derive('CHC_item_view')

local utils = require('CHC_utils')
local find = string.find
local sub = string.sub
local lower = string.lower

-- region create
function CHC_item_view:initialise()
    ISPanel.initialise(self)

    self.typeData = {
        -- .count for each calculated in catSelUpdateOptions
        all = {
            tooltip = self.defaultCategory,
            icon = CHC_window.icons.common.type_all
        },
        AlarmClock = {
            tooltip = getText('IGUI_ItemCat_AlarmClock'),
            item = CHC_main.items['Base.AlarmClock2']
        },
        AlarmClockClothing = {
            tooltip = getText('IGUI_CHC_ItemCat_AlarmClockClothing'),
            item = CHC_main.items['Base.WristWatch_Right_DigitalRed']
        },
        Clothing = {
            tooltip = getText('IGUI_ItemCat_Clothing'),
            item = CHC_main.items['Base.Tshirt_Scrubs']
        },
        Container = {
            tooltip = getText('IGUI_ItemCat_Container'),
            item = CHC_main.items['Base.Purse']
        },
        Drainable = {
            tooltip = getTextOrNull('IGUI_ItemCat_Drainable') or getText('IGUI_CHC_ItemCat_Drainable'),
            item = CHC_main.items['Base.Thread']
        },
        Food = {
            tooltip = getText('IGUI_ItemCat_Food'),
            item = CHC_main.items['Base.Steak']
        },
        Key = {
            tooltip = getText('IGUI_CHC_ItemCat_Key'),
            item = CHC_main.items['Base.Key1']
        },
        Literature = {
            tooltip = getText('IGUI_ItemCat_Literature'),
            item = CHC_main.items['Base.Book']
        },
        Map = {
            tooltip = getText('IGUI_CHC_ItemCat_Map'),
            item = CHC_main.items['Base.Map']
        },
        Moveable = {
            tooltip = getText('IGUI_CHC_ItemCat_Moveable'),
            item = CHC_main.items['Base.Mov_GreyComfyChair']
        },
        Normal = {
            tooltip = getText('IGUI_CHC_ItemCat_Normal'),
            item = CHC_main.items['Base.Spiffo']
        },
        Radio = {
            tooltip = getText('IGUI_CHC_ItemCat_Radio'),
            item = CHC_main.items['Radio.RadioRed']
        },
        Weapon = {
            tooltip = getText('IGUI_ItemCat_Weapon'),
            item = CHC_main.items['Base.Pistol']
        },
        WeaponPart = {
            tooltip = getText('IGUI_ItemCat_WeaponPart'),
            item = CHC_main.items['Base.GunLight']
        }
    }
    self.categoryData = {}
    self.categoryData[self.defaultCategory] = { count = 0 }

    self:create()
end

function CHC_item_view:create()
    local mainPanelsData = {
        listCls = CHC_items_list,
        panelCls = CHC_items_panel,
        extra_init_params = { onmiddlemousedown = self.onMMBDownObjList }
    }
    CHC_view.create(self, mainPanelsData)
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
function CHC_item_view:update()
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

function CHC_item_view:updateObjects()
    CHC_view.updateObjects(self, 'category')
end

-- endregion

-- region render

function CHC_item_view:render()
    CHC_view.render(self)
end

function CHC_item_view:onResize()
    ISPanel.onResize(self)
    CHC_view.onResize(self)
end

--endregion

-- region logic

-- region event handlers
function CHC_item_view:onTextChange()
    if not self.delayedSearch or self.searchRow.searchBar:getInternalText() == '' then
        CHC_view.onTextChange(self)
    end
end

function CHC_item_view:onCommandEntered()
    if self.delayedSearch then
        CHC_view.onCommandEntered(self)
    end
end

function CHC_item_view:onRMBDownObjList(x, y, item)
    local backRef = self.parent.backRef
    local context = backRef.onRMBDownObjList(self, x, y, item)

    if not item then
        local row = self:rowAt(x, y)
        if row == -1 then return end
        item = self.items[row].item
        if not item then return end
    end
    item = CHC_main.items[item.fullType]
    if not item then return end
    local isRecipes = CHC_main.common.areThereRecipesForItem(item)

    if isRecipes then
        local opt = context:addOption(getText('IGUI_new_tab'), backRef, backRef.addItemView, item.item, true, 2)
        opt.iconTexture = CHC_window.icons.common.new_tab
        CHC_main.common.addTooltipNumRecipes(opt, item)
    end
end

function CHC_item_view:onMMBDownObjList()
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

function CHC_item_view:onRemoveAllFavBtnClick()
    self.modData.CHC_item_favorites = {}
    self.needUpdateFavorites = true
    self.needUpdateLayout = true
end

-- endregion

-- region sorting logic

function CHC_item_view:filterTypeSetTooltip()
    local curtype = self.typeData[self.typeFilter].tooltip
    return getText('IGUI_invpanel_Type') .. ' (' .. curtype .. ')'
end

-- endregion

function CHC_item_view:searchProcessToken(token, item)
    local state = false
    local isAllowSpecialSearch = CHC_settings.config.allow_special_search
    local isSpecialSearch = false
    local char

    if isAllowSpecialSearch and CHC_search_bar:isSpecialCommand(token) then
        isSpecialSearch = true
        char = sub(token, 1, 1)
        token = sub(token, 2)
        if token == '' and char ~= '^' then return true end
    end

    local whatCompare
    if not token then return true end
    if isAllowSpecialSearch and char == '^' then
        if not item.favorite then return false end
        whatCompare = lower(item.displayName)
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
                local toCompName = sub(token, 1, opIx - 1)
                local toCompVal = sub(token, opIx, #token)
                -- whatCompare = CHC_main.getPropItems(toCompName)
                for i = 1, #whatCompare do
                    local prop = whatCompare[i]
                    local whatCompName = prop.name
                    local stateName = utils.compare(whatCompName, toCompName)

                    local whatCompVal = prop.value
                    local stateVal = utils.compare(whatCompVal, toCompVal)

                    if stateName and stateVal then return true end
                end
                return false
            else
                -- local toCompName = token
                -- opIx = find(token, '~')
                -- if opIx then toCompName = sub(token, 1, opIx - 1) end
                -- whatCompare = CHC_main.getPropItems(toCompName)
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
        whatCompare = lower(item.displayName)
    end
    state = utils.compare(whatCompare, token)
    return state
end

function CHC_item_view:processAddObjToObjList(item, modData)
    local name = item.displayName
    local w = utils.strWidth(self.curFontData.font, name) + 50
    if name then
        local addedItem = self.objList:addItem(name, item)
        if w > self.objList.width then
            addedItem.tooltip = name
        else
            addedItem.tooltip = nil
        end
    end
end

-- endregion


function CHC_item_view:new(args)
    local o = {}
    o = ISPanel:new(args.x, args.y, args.w, args.h)

    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }

    o.ui_type = args.ui_type
    o.sep_x = args.sep_x

    o.defaultCategory = getText('UI_All')
    o.searchRowHelpText = getText('UI_searchrow_info',
        getText('UI_searchrow_info_items_special'),
        getText('UI_searchrow_info_items_examples')
    )

    o.selectedCategory = o.defaultCategory
    o.backRef = args.backRef
    o.player = CHC_menu.player
    o.modData = CHC_menu.playerModData

    o.objSource = args.objSource
    o.itemSortAsc = args.itemSortAsc
    o.typeFilter = args.typeFilter
    o.showHidden = args.showHidden

    o.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
    o.delayedSearch = CHC_settings.config.delayed_search
    o.searchBarDelayedTooltip = getText('IGUI_DelayedSearchBarTooltip')
    o.objListSize = 0

    o.needUpdateObjects = false
    o.needUpdateFavorites = false
    o.needUpdateFont = true
    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateDelayedSearch = false
    o.needUpdateInfoTooltip = false
    o.needUpdateLayout = false

    o.anchorTop = true
    o.anchorBottom = true
    o.anchorLeft = true
    o.anchorRight = true

    o.isItemView = true
    o.initDone = false
    o.fav_ui_type = 'fav_items'

    o.removeAllFavBtnIcon = CHC_window.icons.item.favorite.remove_all


    return o
end
