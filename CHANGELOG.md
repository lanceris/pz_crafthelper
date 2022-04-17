# CraftHelper updates

## 1.5.6 ()

### New features

- Option to change font size in recipe list (by default 'Large')
- Options to select modifier keys (shift, ctrl) while selecting recipes, cetegories and tabs (by default all 'None')
- Option to show mod name of recipe (if not 'Base', by default 'false')
- Added new special search character (&) - searches by mod name of recipe
- Added new token modifier in search (~) - negates this token

### Improvements

- Config checking: If something new added to config (e.g options), it will autoupdate with default values
- Moved tab closing context menu a bit higher
- Updated search helper info

## 1.5.5 (17.04.2022)

### New features

- Keybind to focus search bar (unfocus on ESC)

### Improvements

- Updated infotext for views
- Cleaned up translations

### Bugfixes

- Fixed settings not applying in main menu

## 1.5.4 (14.04.2022)

### New features

- Ability to close item tab (RMB -> Close)
- Keybind to toggle Craft Helper window
- Keybind for toggling between uses/craft (and items/recipes in search tab)
- Keybinds for changing active tab (left, right)
- Option to close all item tabs on window close (by default OFF)

### Improvements

- Refactored config (from txt to json, will reset all settings)

## 1.5.3 (12.04.2022)

### New features

- Added functionality to search tab (search and category selection for all items/recipes). Lags a lot with large amount of mods.
- Added caching for search tab (first opening of craft helper will take a while, but subsequent ones will be instant)

### Improvements

- Moved java calls (getCategory, getFullType etc) to item/recipe properties, gathered on start (in CHC_main)

## 1.5.2 (11.04.2022)

### New features

- Added new layer of tabs above Uses and Craft, this tab will display all selected items (previously multiple windows were opened)
- Added Favorites tab, showing all favorited recipes
- Added Search tab, showing all recipes and items(WIP)

## 1.5.1 (11.04.2022)

### New features

- Craft screen, shows how to craft selected item

# 1.5 (10.04.2022, workshop release)

## 1.4.6 (10.04.2022)

### New features

- Added option to show/hide hidden recipes

### Bugfixes

- Recipe counts now update correctly (when ingredients panel updates, and when there is new items)

## 1.4.5 (07.04.2022)

### New features

- Added icons to recipes in recipe list
- Added option to control special search (by default ON, need Mod Options to change)
- Added option to control rendering of icons in recipe list (by default OFF, need Mod Options to change)
- Added number of recipes of each type to type filter menu

### Improvements

- Refactored rendering of recipe panel (increased free space for ingredients)
- Refactored filter row (Order, type buttons and category selector) into reusable component
- Optimized recipe panel render a bit

### Bugfixes

- Fixed duplication of search button help window
- Favorite icon now always shows if recipe is favorited

## 1.4.4 (05.04.2022)

### New features

- Added special search modes for search bar
- Added documentation for uses screen
- Added documentation for search (click on magnifier left of search bar)

### Improvements

- Refactored search bar into separate component
- Refactored draggable tabs into proper UI class
- Improved overall performance
- Moved common functions to CHC_utils

## 1.4.3 (03.04.2022)

### New features

- Added Hydrocraft integration (show Hydrocraft furniture in "Required Crafting Equipment")

## 1.4.2 (02.04.2022)

### New features

- Added keybinds for moving through recipes/categories, crafting and favoriting.
  All keys (except window closing one, which is ESC) are not assigned by default, one need to install ModOptions to assign them.

### Improvements

- Changed signature of onChangeUsesRecipeCategory to allow string category option
- Changed signature of addToFavorite to allow selected (row) as argument

### Bugfixes

- Fixed [trello#48](https://trello.com/c/cYpaRrpq/48-type-filter-not-fully-applied-when-creating-recipelist)

# 1.4.1 (02.04.2022, workshop release)

### New features

- Craft buttons (like in crafting UI)
- ES translation (thanks to Dante271)
- Added number of recipes to type filter (WIP)

### Improvements

- Refactored recipepanel
- Added missing (but unused yet) translation to UI_RU

## 1.4 (31.03.2022)

### New features

- New icons for buttons
- Search bar icon
- Added mod name to result item description

### Improvements

- Wrapped search icon + search bar to container
- Refactored recipeList UI

### Bugfixes

- Fixed bug with diplicate recipe names not showing

## 1.3 (29.03.2022)

### New features

- Filter recipes by availability
- Search bar

### Changes

- Refactored config to allow bool and string values
- New config variables for sorting order and type filter
- Wrapped filter row (sort order and type filter buttons + category selector) to container

## 1.2 (28.03.2022)

### New features

- Ability to favorite recipes from craft helper window
  - semi-synchronized with crafting window (need to re-open crafthelper or change category)
- Favorite category (shown only if there are favorited recipes for item)
- Sorting button (like in player inventory, sorts recipes by name)

### Changes

- Changed event used to load all recipes (OnGameBoot -> OnGameStart)
- Handle config creation
- UI adjustments
- Reduced minimum window resolution (800,400 -> 400,350)

## 1.1 (27.03.2022)

### New features

- Added configuration file
- Added saving for various properties on window close

### Changes

- Refactored codebase

## 1.0 (27.03.2022)

### New features

- Added key to close craft helper window (ESC)
- Added category selector for recipes
