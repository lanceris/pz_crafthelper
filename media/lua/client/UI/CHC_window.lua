-- Main window, opened when RMB -> Craft Helper 41 on item
require 'ISUI/ISCollapsableWindow';
require 'ISUI/ISTabPanel';

require 'CHC_main'
require 'CHC_config'
require 'UI/CHC_menu'
require 'UI/CHC_uses';
require 'UI/CHC_craft';
-- require 'UI/craftHelperUpdSearchScreen';

CHC_window = ISCollapsableWindow:derive("CHC_window");

function CHC_window:initialise()
    ISCollapsableWindow.initialise(self);
end

function CHC_window:refresh()
    local selectedView = self.panel.activeView.name;
    self.panel:activateView(selectedView);
end

function CHC_window:createChildren()
    ISCollapsableWindow.createChildren(self);
    --region main container
    self.panel = ISTabPanel:new(1, self:titleBarHeight(), self.width, self.height-50)
    self.panel:initialise()
    self.panel:setAnchorRight(true)
    self.panel:setAnchorBottom(true)
    self.panel:setEqualTabWidth(true)
    
    -- endregion


    local common_screen_data = {x=0, y=8, w=self.width, h=self.panel.height, 
                                sep_x=CHC_menu.cfg.uses_tab_sep_x}

    --region uses screen
    local uses_screen_init = common_screen_data
    uses_screen_init['item'] = self.item

    self.usesScreen = CHC_uses:new(uses_screen_init);
    self.usesScreen:initialise();
    self.usesScreen.infoText = getText("UI_infotext_uses")
    --endregion
    
    -- region crafting screen
    -- self.craftScreen = CHC_craft:new(0, 8, self.width, self.panel.height - self.panel.tabHeight)
    -- self.craftScreen:initialise();
    -- self.craftScreen.infoText = getText("UI_infotext_craft")
    -- endregion

    -- self.searchScreen = craftHelperUpdSearchScreen:new()

    self:addChild(self.panel)
    self.panel:addView(getText("UI_tab_uses"), self.usesScreen)
    -- self.panel:addView(getText("UI_tab_craft"), self.craftScreen)

    self:refresh()
end

-- region keyboard controls
function CHC_window:onKeyRelease(key)
    local ui = self
    if not ui.panel or not ui.panel.activeView then return; end
    local view = ui.panel.activeView.view
    local rl = view.recipesList

    -- region close
    if key == CHC_settings.keybinds.close_window.key then
        self:close()
        return
    end
    -- endregion

    -- region select recipe/category

    -- region recipes
    if key == CHC_settings.keybinds.move_up.key then
        rl.selected = rl.selected - 1
        if rl.selected <= 0 then
            rl.selected = #rl.items
        end
    elseif key == CHC_settings.keybinds.move_down.key then
        rl.selected = rl.selected + 1
        if rl.selected > #rl.items then
            rl.selected = 1
        end
    end

    local selectedItem = rl.items[rl.selected]
    if selectedItem then
        view.recipesList:ensureVisible(rl.selected)
        view.recipePanel:setRecipe(selectedItem.item)
    end
    -- endregion

    -- region categories
    local cs = view.categorySelector
    local oldcsSel = cs.selected
    if key == CHC_settings.keybinds.move_left.key then
        cs.selected = cs.selected - 1
        if cs.selected <= 0 then cs.selected = #cs.options end
    elseif key == CHC_settings.keybinds.move_right.key then
        cs.selected = cs.selected + 1
        if cs.selected > #cs.options then cs.selected = 1 end
    end
    if oldcsSel ~= cs.selected then
        view:onChangeUsesRecipeCategory(nil, cs.options[cs.selected])
    end
    -- endregion
    -- endregion

    -- region favorite
    if key == CHC_settings.keybinds.favorite_recipe.key then
        rl:addToFavorite(rl.selected)
    end
    -- endregion
    
    -- region crafting
    if key == CHC_settings.keybinds.craft_one.key then
        if not view.recipePanel.newItem then return end
        view.recipePanel:craft(nil, false)
    elseif key == CHC_settings.keybinds.craft_all.key then
        if not view.recipePanel.newItem then return end
        view.recipePanel:craft(nil, true)
    end
    -- endregion
end

function CHC_window:isKeyConsumed(key)
    local isKeyValid = false
    for _, k in pairs(CHC_settings.keybinds) do
        k = k.key
        if key == k then
            isKeyValid = true
            break
        end
    end

    return isKeyValid
end
-- endregion


function CHC_window:onResize()
    ISPanel.onResize(self)

    self.usesScreen:setWidth(self.width);
    self.usesScreen:setHeight(self.panel.height - self.panel.tabHeight)
    local nhw = self.usesScreen.nameHeader.width;
    self.usesScreen.recipesList:setWidth(nhw)
    self.usesScreen.filterRowContainer:setWidth(nhw)
    self.usesScreen.categorySelector:setWidth(nhw-self.usesScreen.filterRowContainer.deltaW)
    self.usesScreen.searchRowContainer:setWidth(nhw)
    self.usesScreen.searchBar:setWidth(nhw-self.usesScreen.searchRowContainer.deltaW)

    -- self.craftScreen:setWidth(self.width)
    -- self.craftScreen:setHeight(self.panel.height - self.panel.tabHeight)
    

    if self.usesScreen.typeHeader:getWidth() == self.usesScreen.typeHeader.minimumWidth then
		self.usesScreen.column3 = self.usesScreen.width - self.usesScreen.typeHeader:getWidth() + 1
		self.usesScreen.nameHeader:setWidth(self.usesScreen.column3 - self.usesScreen.column2)
		self.usesScreen.typeHeader:setX(self.usesScreen.column3 - 1)
	end
	self.usesScreen.column4 = self.usesScreen.width

    -- if self.craftScreen.typeHeader:getWidth() == self.craftScreen.typeHeader.minimumWidth then
	-- 	self.craftScreen.column3 = self.craftScreen.width - self.craftScreen.typeHeader:getWidth() + 1
	-- 	self.craftScreen.nameHeader:setWidth(self.craftScreen.column3 - self.craftScreen.column2)
	-- 	self.craftScreen.typeHeader:setX(self.craftScreen.column3 - 1)
	-- end
	-- self.craftScreen.column4 = self.craftScreen.width
    
end

function CHC_window:render()
    if self.isCollapsed then return end;
    ISCollapsableWindow.render(self);
end


function CHC_window:close()
    CHC_config.fn.updateSettings()
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
end


function CHC_window:new(args)
    local o = {};
    local x = args.x;
    local y = args.y;
    local width = args.width;
    local height = args.height;

	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;

    for k, v in pairs(args) do
        o[k] = v
    end

    o.title = 'Craft Helper 41 -> ' .. o.item:getName();
    --o:noBackground();
    o.th = o:titleBarHeight()
    o.rh = o:resizeWidgetHeight()
    local fontHgtSmall = getTextManager():getFontHeight(UIFont.Small);
    o.headerHgt = fontHgtSmall + 1

    o:setWantKeyEvents(true);

    return o;
end