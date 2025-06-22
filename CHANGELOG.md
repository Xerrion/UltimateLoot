# Changelog

All notable changes to UltimateLoot will be documented in this file.

## [2.0.0] - 2024-01-XX

### 🚀 Major Release - Complete Rewrite

**Breaking Changes**
- Evolved from AutoPass addon with complete terminology overhaul
- Replaced simple pass tracking with comprehensive roll analytics
- No backward compatibility with AutoPass data

### ✨ New Features

#### Individual Roll Tracking System
- **Roll Type Analytics**: Track Pass, Need, and Greed decisions separately
- **Quality Breakdowns**: See roll patterns across all item qualities (Poor→Legendary)
- **Enhanced Statistics**: Comprehensive roll data with percentages and trends
- **Smart Tracking**: `TrackRoll(itemLink, itemName, quality, rollType)` replaces basic pass counting

#### Pass on All Mode
- **Emergency Override**: Bypass all rules and thresholds to pass on everything
- **Safety Warnings**: Clear UI indicators when active
- **Slash Commands**: Quick toggle via `/ul passall`
- **Status Integration**: Shows in tooltips and status displays

#### Modern User Interface
- **Tabbed Interface**: Statistics, Items, History, Settings, and Debug tabs
- **Visual Analytics**: Roll type breakdowns with percentages
- **Quality Insights**: "P:X N:Y G:Z" format showing roll distribution
- **Enhanced Tooltips**: Comprehensive status information

#### Professional Framework Integration
- **Ace3 Architecture**: Built on industry-standard addon framework
- **Localization**: English and German translations included
- **Profile Management**: Character-specific settings with export/import
- **Event System**: Efficient, event-driven architecture

### 🔧 Technical Improvements

#### Data Structure Overhaul
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

#### API Modernization
- **Updated Functions**: `GetRollsByTimeframe()` replaces `GetHandledByTimeframe()`
- **Enhanced Returns**: Functions now return `{total, pass, need, greed}` objects
- **Error Handling**: Comprehensive nil checks and fallback values
- **Debug System**: Advanced testing with realistic scenarios

### 🗑️ Removed Features
- **Legacy Compatibility**: All AutoPass-specific code removed
- **Dead Code Cleanup**: Removed unused `track_all` setting
- **Useless Logging**: Eliminated meaningless party composition debug messages

### 🐛 Bug Fixes
- **Locale Errors**: Fixed missing translation keys throughout UI
- **Nil Comparisons**: Added proper null checks in MinimapIcon
- **String Formatting**: Fixed format errors in debug statements
- **Data Validation**: Enhanced input validation for roll tracking

### 🎨 UI/UX Improvements
- **Terminology Update**: "Auto-pass" → "Automatically handle" throughout
- **Professional Language**: Improved all user-facing text
- **Clear Warnings**: Prominent alerts for Pass on All mode
- **Intuitive Layout**: Reorganized settings for better user flow

### 🔍 Debug & Testing
- **Comprehensive Test Suite**: `RunComprehensiveRollTest()` with realistic scenarios
- **Pass on All Testing**: Specific validation for override functionality
- **Edge Case Coverage**: Tests for invalid inputs and large datasets
- **Performance Testing**: Volume testing with thousands of entries

### 📊 Analytics Enhancements
- **Roll Percentages**: "45.2% Pass, 32.1% Need, 22.7% Greed" displays
- **Quality Insights**: Per-quality roll distribution analysis
- **Time-based Filtering**: Statistics by day, week, month, all-time
- **Top Items**: Most frequently rolled items with detailed breakdowns

---

## [1.x.x] - AutoPass Era

*Previous versions were released as "AutoPass" addon with basic pass-only functionality.*

---

**Note**: Version 2.0.0 represents a complete rewrite and rebranding. Users upgrading from AutoPass should treat this as a new addon installation. 