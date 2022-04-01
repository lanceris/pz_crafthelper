# CraftHelper updates

# 1.4.1 (02.04.2022)

### New features

- Craft buttons (like in crafting UI)
- ES translation (thanks to Dante271)
- Added number of recipes to type filter (WIP)

### Improvements

- Refactored recipepanel
- Added missing (but unused yet) translation to UI_RU

# 1.4 (31.03.2022)

### New features

- New icons for buttons
- Search bar icon
- Added mod name to result item description

### Improvements

- Wrapped search icon + search bar to container
- Refactored recipeList UI

### Bugfixes

- Fixed bug with diplicate recipe names not showing

# 1.3 (29.03.2022)

### New features

- Filter recipes by availability
- Search bar

### Changes

- Refactored config to allow bool and string values
- New config variables for sorting order and type filter
- Wrapped filter row (sort order and type filter buttons + category selector) to container

# 1.2 (28.03.2022)

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

# 1.1 (27.03.2022)

### New features

- Added configuration file
- Added saving for various properties on window close

### Changes

- Refactored codebase

# 1.0 (27.03.2022)

### New features

- Added key to close craft helper window (ESC)
- Added category selector for recipes
