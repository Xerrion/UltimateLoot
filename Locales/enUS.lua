local E = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB
local L = E.Libs.AceLocale:NewLocale(E._name, "enUS", true)

-- Addon related strings
L["ADDON_LOADED"] = "%s has been loaded."
L["CURRENT_LOCALE"] = "The current locale is: %s"
L["MY_ID"] = "My player ID is: %s"

-- Main UI strings
L["MAIN_FRAME_TITLE"] = "UltimateLoot - Ultimate Loot Management"
L["MAIN_FRAME_STATUS"] = "Track your loot decisions and configure intelligent loot rules"

-- Tab names
L["TAB_HISTORY"] = "History"
L["TAB_STATISTICS"] = "Statistics"
L["TAB_ITEMS"] = "Items"
L["TAB_GRAPH"] = "Graph"
L["TAB_ITEM_RULES"] = "Item Rules"
L["TAB_SETTINGS"] = "Settings"
L["TAB_DEBUG"] = "Debug"

-- Settings related strings
L["DEBUG_MODE"] = "Debug mode: %s"
L["ENABLE_ULTIMATELOOT"] = "Enable UltimateLoot"
L["ENABLE_ULTIMATELOOT_DESC"] = "Enable or disable intelligent loot management system"
L["LOOT_QUALITY_THRESHOLD"] = "Loot Quality Threshold"
L["LOOT_QUALITY_THRESHOLD_TEXT"] = "Auto-decide up to this quality level"
L["LOOT_QUALITY_THRESHOLD_DESC"] =
"Automatically handle items of this quality and below, prompt for higher quality items"

-- Settings groups
L["GENERAL_SETTINGS"] = "General Settings"
L["TRACKER_SETTINGS"] = "Tracker Settings"
L["ACTIONS"] = "Actions"
L["DATA_MANAGEMENT"] = "Data Management"
L["PROFILE_INFORMATION"] = "Profile Information"

-- Settings options
L["PASS_ON_ALL"] = "Pass on All Items"
L["PASS_ON_ALL_DESC"] = "Override all rules and quality thresholds - automatically pass on every item"
L["PASS_ON_ALL_WARNING"] =
string.format("%sWarning:%s Pass on All mode is %sACTIVE%s - ignoring all rules and thresholds", 
    ORANGE_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE, RED_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE)
L["SHOW_NOTIFICATIONS"] = "Show Notifications"
L["SHOW_NOTIFICATIONS_DESC"] = "Display a message when an item is automatically handled"
L["MAX_HISTORY_ENTRIES"] = "Max History Entries"

-- Buttons
L["CLEAR"] = "Clear"
L["REMOVE"] = "Remove"
L["CLEAR_HISTORY"] = "Clear History"
L["CLEAR_ALL_DATA"] = "Clear All Data"
L["RESET_SETTINGS"] = "Reset Settings"
L["EXPORT_DATA"] = "Export Data"
L["REFRESH"] = "Refresh"

-- Confirmations
L["CONFIRM_CLEAR_ALL"] = "Are you sure you want to clear all UltimateLoot data? This cannot be undone."
L["CONFIRM_RESET_SETTINGS"] = "Are you sure you want to reset all settings to defaults?"
L["YES"] = "Yes"
L["NO"] = "No"

-- Messages
L["ALL_DATA_CLEARED"] = "All data cleared."
L["SETTINGS_RESET"] = "Settings reset to defaults."
L["NO_DATA_TO_EXPORT"] = "No data to export."
L["NO_ITEMS_TRACKED"] = "No loot decisions have been tracked yet."
L["NO_DATA_TO_DISPLAY"] = "No data to display"

-- Statistics
L["OVERALL_STATISTICS"] = "Overall Statistics"
L["RECENT_ACTIVITY"] = "Recent Activity"
L["QUALITY_BREAKDOWN"] = "Quality Breakdown"
L["TOTAL_ITEMS_HANDLED"] = "Total Items Handled: |cffffd700%d|r"

L["LAST_HOUR"] = "Last Hour: |cffffd700%d|r"
L["LAST_24_HOURS"] = "Last 24 Hours: |cffffd700%d|r"
L["LAST_7_DAYS"] = "Last 7 Days: |cffffd700%d|r"
L["HANDLED_X_TIMES"] = "Handled |cffffd700%d|r times"
L["LAST_SEEN"] = "Last: %s"

-- Items tab
L["NO_ITEMS_PASSED"] = "No items have been handled yet."
L["ITEMS_PASSED_MOST_OFTEN"] = "Items Handled Most Often"
L["ITEMS_HANDLED_MOST_OFTEN"] = "Items Handled Most Often"
L["PASSED_X_TIMES"] = "Handled %d times"
L["ROLL_TYPE_BREAKDOWN"] = "Roll Type Breakdown"

-- History UI elements
L["SHOW_LABEL"] = "Show:"
L["FILTER_LABEL"] = "Filter:"
L["LIMIT_25"] = "25"
L["LIMIT_50"] = "50"
L["LIMIT_100"] = "100"
L["LIMIT_200"] = "200"
L["LIMIT_ALL"] = "All"
L["FILTER_ALL"] = "All"
L["FILTER_PASS_ONLY"] = "Pass Only"
L["FILTER_NEED_ONLY"] = "Need Only"
L["FILTER_GREED_ONLY"] = "Greed/Disenchant Only"
L["CLEAR_HISTORY_CONFIRM"] = "Are you sure you want to clear the roll history?\n\nThis cannot be undone."
L["UNKNOWN"] = "Unknown"
L["DATE_FORMAT"] = "(YYYY-MM-DD)"

-- Roll decision types
L["PASS_ROLLS"] = "Pass"
L["NEED_ROLLS"] = "Need"
L["GREED_ROLLS"] = "Greed/Disenchant"
L["DECISION"] = "Decision"

-- Date filtering
L["DATE_RANGE"] = "Date Range"
L["FROM"] = "From"
L["TO"] = "To"
L["RESET"] = "Reset"
L["SEARCH"] = "Search"

-- Table column headers
L["ITEM_COLUMN"] = "Item"
L["QUALITY_COLUMN"] = "Quality"
L["DATE_COLUMN"] = "Date"

-- Summary text
L["ALL_TYPES"] = "All Types"
L["FILTER_SUMMARY"] = "%s Only"
L["SHOWING_ITEMS_SUMMARY"] = "Showing %d items (%s) | Pass: %d | Need: %d | Greed/Disenchant: %d"

-- Graph tab
L["HOURLY_ACTIVITY"] = "Hourly Activity (Last 24 Hours)"
L["HOURLY_ACTIVITY_GRAPH"] = "Activity Graph"
L["TOTAL_ROLLS_24H"] = "Total rolls in last 24 hours: %d"
L["GRAPH_SUMMARY_FORMAT"] = "Total rolls: %d | Average per hour: %.1f | Peak: %d rolls at %dh ago"

-- Statistics breakdown
L["NO_ROLL_DATA"] = "No roll data available"
L["ROLL_BREAKDOWN_FORMAT"] = "|cffff0000Pass:|r %d (%.1f%%)\n|cff0080ffNeed:|r %d (%.1f%%)\n|cffffaa00Greed/Disenchant:|r %d (%.1f%%)"
L["QUALITY_STATS_FORMAT"] = "%s: %d (%.1f%%) - %s"
L["QUALITY_NO_DATA_FORMAT"] = "%s: 0"
L["ROLL_STATS_FORMAT"] = "P:%d N:%d G:%d"
L["TOTAL_WITH_ROLLS_FORMAT"] = "Total: %d (%s)"

-- Export
L["EXPORT_DATA_TITLE"] = "Export Data"
L["EXPORT_DATA_LABEL"] = "Copy this data to save your UltimateLoot information:"

-- Profile info
L["CURRENT_PROFILE"] = "Current Profile: |cffffd700%s|r"
L["CHARACTER"] = "Character: |cffffd700%s|r"
L["REALM"] = "Realm: |cffffd700%s|r"
L["PROFILE_INFO_FORMAT"] = "Current Profile: |cffffd700%s|r\nCharacter: |cffffd700%s|r\nRealm: |cffffd700%s|r"

-- Quality names with colors (using WoW's built-in item quality colors)
L["QUALITY_POOR"] = function() return E.ColorConstants:FormatQualityText("Poor (Gray)", 0) end
L["QUALITY_COMMON"] = function() return E.ColorConstants:FormatQualityText("Common (White)", 1) end
L["QUALITY_UNCOMMON"] = function() return E.ColorConstants:FormatQualityText("Uncommon (Green)", 2) end
L["QUALITY_RARE"] = function() return E.ColorConstants:FormatQualityText("Rare (Blue)", 3) end
L["QUALITY_EPIC"] = function() return E.ColorConstants:FormatQualityText("Epic (Purple)", 4) end
L["QUALITY_LEGENDARY"] = function() return E.ColorConstants:FormatQualityText("Legendary (Orange)", 5) end

-- Frame related strings
L["FRAME_TITLE"] = "%s Frame"
L["FRAME_STATUS"] = "%s example frame created."

-- Event related strings
L["PLAYER_HEALTH_CHANGED"] = "Player health changed."

-- Error messages
L["TRACKER_UI_CREATION_FAILED"] = "Tracker UI could not be created"

-- Debug Settings
L["ENABLE_DEBUG_MODE"] = "Enable Debug Mode"
L["ENABLE_DEBUG_MODE_DESC"] = "Enable debug mode to show the Debug tab and debug output in chat"

-- Minimap Settings
L["SHOW_MINIMAP_ICON"] = "Show Minimap Icon"
L["SHOW_MINIMAP_ICON_DESC"] = "Show or hide the UltimateLoot minimap icon"

-- Item Rules UI
L["ITEM_RULES_SYSTEM"] = "Item Rules System"
L["ENABLE_ITEM_RULES"] = "Enable Item Rules"
L["ENABLE_ITEM_RULES_DESC"] = "Enable custom item-specific rules that override quality thresholds"
L["ITEM_RULES_DISABLED"] = "Item Rules are disabled. Enable them above to manage custom item behaviors."
L["ADD_NEW_RULE"] = "Add New Rule"
L["ITEM_NAME_OR_LINK"] = "Item Name or Link"
L["RULE_TYPE"] = "Rule Type"
L["ALWAYS_PASS"] = "Always Pass"
L["ALWAYS_PASS_DESC"] = "Override threshold, always pass"
L["NEVER_PASS"] = "Never Pass"
L["NEVER_PASS_DESC"] = "Override threshold, never pass"
L["ALWAYS_NEED"] = "Always Need"
L["ALWAYS_NEED_DESC"] = "Always roll Need on this item"
L["ALWAYS_GREED"] = "Always Greed"
L["ALWAYS_GREED_DESC"] = "Always roll Greed on this item"
L["ALWAYS_GREED_DISENCHANT"] = "Always Greed/Disenchant"
L["ALWAYS_GREED_DISENCHANT_DESC"] = "Always roll Greed/Disenchant on this item (disenchant if possible)"
L["ADD_RULE"] = "Add Rule"
L["CURRENT_RULES"] = "Current Rules"
L["USE_PATTERN"] = "Use Pattern Matching"
L["USE_PATTERN_DESC"] = "Use Lua pattern matching for flexible name rules (e.g. \"Potion.*Strength\" matches all Strength Potions)"
L["RULE_NOTE"] = "Rule Note"
L["NO_NOTE"] = "No note"
L["ADD_NOTE"] = "Add note..."
L["NOTE_PREFIX"] = "Note: "
L["EDIT_NOTE_FOR"] = "Edit note for "
L["UNKNOWN_ITEM"] = "item"
L["PATTERN_INVALID"] = "The pattern is not valid. Please check your syntax."
L["OKAY"] = "Okay"
L["CANCEL"] = "Cancel"
L["NO_RULES_CONFIGURED"] = "No item rules configured. Add rules above to customize item behavior."
L["ALWAYS_PASS_RULES"] = "Always Pass Rules"
L["NEVER_PASS_RULES"] = "Never Pass Rules"
L["ALWAYS_NEED_RULES"] = "Always Need Rules"
L["ALWAYS_GREED_RULES"] = "Always Greed Rules"
L["ALWAYS_GREED_DISENCHANT_RULES"] = "Always Greed/Disenchant Rules"
L["ALWAYS_PASS_RULES_DESC"] = "These items will always be passed on"
L["NEVER_PASS_RULES_DESC"] = "These items will never be passed on"
L["ALWAYS_NEED_RULES_DESC"] = "These items will always be rolled Need"
L["ALWAYS_GREED_RULES_DESC"] = "These items will always be rolled Greed"
L["ALWAYS_GREED_DISENCHANT_RULES_DESC"] = "These items will always be rolled Greed/Disenchant"
L["RULE_MANAGEMENT"] = "Rule Management"
L["TEST_RULES"] = "Test Rules"
L["CLEAR_ALL_RULES"] = "Clear All Rules"
L["CLEAR_ALL_RULES_CONFIRM"] = "Are you sure you want to clear ALL item rules?\n\nThis cannot be undone."
L["CLEAR_RULE_TYPE_CONFIRM"] = "Clear all %s?"

-- Item Rules UI strings
L["ITEM_RULES_DESC"] = "Configure automatic rules for handling specific items when loot rolls appear"
L["RULES_SUMMARY"] = "Rules Summary"
L["TOTAL_RULES"] = "Total Rules"
L["MANAGE_RULES"] = "Manage Rules"
L["ITEM_RULES_MANAGER"] = "Item Rules Manager"
L["CLEAR_RULES_OF_TYPE"] = "Clear All Rules of This Type"
L["NO_RULES_OF_TYPE"] = "No rules of this type configured"

-- Manager window strings
L["RULES_OVERVIEW"] = "Rules Overview"
L["STATUS"] = "Status"
L["ENABLED"] = "Enabled"
L["DISABLED"] = "Disabled"
L["IMPORT_EXPORT"] = "Import/Export"
L["EDIT"] = "Edit"
L["SELECT_ALL"] = "Select All"
L["CLEAR_ALL"] = "Clear All"
L["CONFIGURED_RULES"] = "Configured Rules"
L["RULE"] = "rule"
L["RULES"] = "rules"
L["NO_RULES_OF_TYPE_DETAILED"] = "No %s rules configured.\n\nClick 'Add Rule' below or use the main tab to create your first rule."
L["YES"] = "Yes"
L["NO"] = "No"
