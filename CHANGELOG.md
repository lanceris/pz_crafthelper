# CraftHelper updates

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
