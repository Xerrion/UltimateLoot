# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UltimateLoot is a World of Warcraft addon for WoW 3.3.5a (Wrath of the Lich King) that provides intelligent loot management and comprehensive statistics tracking. It handles loot decisions automatically based on configurable criteria and provides detailed analytics about loot behavior.

## Repository Structure

The codebase is organized into the following main directories:

- `Core/`: Core addon functionality and initialization
- `Modules/`: Feature-specific modules (Events, ItemRules, Tracker, Debug, etc.)
- `Settings/`: Default profile and configuration settings
- `UI/`: User interface components (GraphUI, HistoryUI, ItemsUI, etc.)
- `Lib/`: Third-party libraries (Ace3, LibSharedMedia, LibDBIcon)
- `Locales/`: Localization files (enUS, deDE)

## Architecture

UltimateLoot is built on the Ace3 addon framework, following an event-driven, modular architecture:

1. **Engine (E)**: Central singleton accessible throughout the codebase
2. **Modules**: Self-contained feature components registered with the Engine
3. **Events System**: Custom event bus for internal communication
4. **Settings**: AceDB-3.0 based profile system

## Key Files and Their Purpose

- `Init.lua`: Entry point that creates the Engine and initializes the addon
- `Core/Core.lua`: Core functionality setup (localization, database, events)
- `Modules/UltimateLoot.lua`: Main module handling slash commands and events
- `Modules/Tracker.lua`: Track and analyze loot decisions
- `Modules/ItemRules.lua`: Custom rules for specific items
- `Settings/Profile.lua`: Default settings and configuration
- `UI/*.lua`: Various UI components for different tabs

## Development Guidelines

### Testing

UltimateLoot includes built-in testing functionality:

```lua
-- Test loot roll functionality
/ultimateloot test
/ultimateloot test roll

-- Test item rules functionality
/ultimateloot test rules
```

### Slash Commands

UltimateLoot provides several slash commands for development and testing:

```
/ultimateloot or /ul - Main command help
/ul enable|disable - Toggle addon functionality
/ul show - Open the main interface
/ul threshold <quality> - Set quality threshold
/ul passall - Toggle Pass on All mode
/ul debug - Debug mode toggle
/ul debugtab - Open debug tab
```

### Debugging

Debug mode can be enabled through:

1. Slash command: `/ul debug on`
2. Settings UI: Check "Enable Debug Mode"

While in debug mode:
- Additional logging is shown in chat
- The Debug tab becomes available with test functionality

## Data Structure

The core data structure for statistics:

```lua
stats = {
    totalHandled = 0,
    rollsByType = { pass = 0, need = 0, greed = 0 },
    rollsByQuality = {
        [0] = { pass = 0, need = 0, greed = 0 }, -- Poor
        [1] = { pass = 0, need = 0, greed = 0 }, -- Common
        [2] = { pass = 0, need = 0, greed = 0 }, -- Uncommon
        [3] = { pass = 0, need = 0, greed = 0 }, -- Rare
        [4] = { pass = 0, need = 0, greed = 0 }, -- Epic
        [5] = { pass = 0, need = 0, greed = 0 }  -- Legendary
    }
}
```

## Common Development Tasks

### Adding a New Feature

1. Create an appropriate module in the `Modules/` directory
2. Register it with the Engine using `E:NewModule()`
3. Add UI components in the `UI/` directory if needed
4. Update settings in `Settings/Profile.lua` for any new options
5. Add localization strings in `Locales/*.lua` files

### Adding Localization

Add new localization strings to:
- `Locales/enUS.lua` (required base)
- `Locales/deDE.lua` (optional German translation)

Example:
```lua
L["NEW_STRING_KEY"] = "English text"
```

## Recent Changes

Recent development (v2.1.0) has focused on:
- Adding table headers to History tab
- Improving visual clarity with better font styling
- Fixing issues with empty history display

## AI Development Rules and Guidelines

### Code Style and Standards

1. **Follow WoW 3.3.5a API compatibility** - Only use APIs available in Wrath of the Lich King
2. **Use semantic commit messages** following conventional commits format:
   - `feat(scope): description` for new features
   - `fix(scope): description` for bug fixes
   - `chore(scope): description` for maintenance tasks
   - `style(scope): description` for UI/visual improvements
   - `refactor(scope): description` for code restructuring
3. **Maintain consistent indentation** using 4 spaces (not tabs)
4. **Use descriptive variable names** and add comments for complex logic
5. **Follow Lua best practices** with proper error handling using pcall when appropriate

### File Management Rules

1. **Never modify existing files without reading their current content first**
2. **Use replace_string_in_file for small changes** with 3-5 lines of context
3. **Use insert_edit_into_file for larger additions** with comment placeholders for existing code
4. **Always check file contents before making edits** to avoid conflicts
5. **Preserve existing formatting and spacing** unless specifically asked to change it

### Localization Requirements

1. **All user-facing strings must use localization keys** from L["KEY_NAME"]
2. **Add new strings to both `Locales/enUS.lua` and `Locales/deDE.lua`**
3. **Use descriptive, UPPERCASE_WITH_UNDERSCORES key names**
4. **Provide fallback text in code** using: `L["KEY"] or "Fallback text"`
5. **Group related strings together** with comments indicating their purpose

### Module Development Guidelines

1. **Register new modules with the Engine** using `E:NewModule("ModuleName")`
2. **Use the modular event system** for communication between components
3. **Follow the Engine singleton pattern** - access via `E` throughout codebase
4. **Implement proper OnInitialize/OnEnable methods** for module lifecycle
5. **Use AceDB-3.0 for persistent data** through the profile system

### UI Development Rules

1. **Use AceGUI-3.0 widgets** for all interface elements
2. **Implement proper error handling** for UI operations with pcall
3. **Follow responsive design principles** - use relative sizing when possible
4. **Maintain consistent styling** across all UI components
5. **Handle window position persistence** to avoid resetting user preferences
6. **Add proper tooltips and help text** for user guidance

### Testing and Debugging

1. **Always test changes in-game** before committing
2. **Use the built-in debug system** with `E:DebugPrint()` for logging
3. **Implement slash command tests** for new functionality
4. **Verify error handling** works correctly with invalid inputs
5. **Test with different user configurations** and edge cases

### Git Workflow Rules

1. **Create feature branches** from `main` for all new work
2. **Use descriptive branch names** like `feature/item-rules-ui` or `fix/window-positioning`
3. **Create pull requests** for all changes, no direct commits to main
4. **Use release branches** (`release/vX.Y.Z`) for version preparation
5. **Tag releases** with semantic versioning (vX.Y.Z format)
6. **Merge release branches back to main** after successful release

### Version Management

1. **Follow semantic versioning** (MAJOR.MINOR.PATCH)
2. **Update version in `UltimateLoot.toc`** for all releases
3. **Maintain detailed CHANGELOG.md** with categorized changes
4. **Use conventional commit types** in changelog entries
5. **Include breaking change warnings** when applicable

### Error Handling Standards

1. **Use pcall for potentially failing operations** (file I/O, API calls)
2. **Provide meaningful error messages** to users
3. **Log debug information** for troubleshooting
4. **Gracefully degrade functionality** when components fail
5. **Validate input parameters** before processing

### Performance Guidelines

1. **Minimize memory allocations** in frequently called functions
2. **Cache expensive calculations** when appropriate
3. **Use efficient data structures** for large datasets
4. **Avoid blocking operations** in event handlers
5. **Clean up resources** properly (timers, event handlers, UI elements)

### Documentation Requirements

1. **Document all public functions** with clear parameter descriptions
2. **Explain complex algorithms** with inline comments
3. **Keep README and instruction files updated** with new features
4. **Provide usage examples** for new functionality
5. **Document configuration options** and their effects