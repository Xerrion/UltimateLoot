# Copilot Instructions for UltimateLoot
# ===========================

This file provides guidance to GitHub Copilot when working with code in this repository.

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

1. Create a new feature branch from `main`
2. Create an appropriate module in the `Modules/` directory
3. Register it with the Engine using `E:NewModule()`
4. Add UI components in the `UI/` directory if needed
5. Update settings in `Settings/Profile.lua` for any new options
6. Add localization strings in `Locales/*.lua` files

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
