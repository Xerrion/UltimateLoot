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
"|cffff8000Warning:|r Pass on All mode is |cffff0000ACTIVE|r - ignoring all rules and thresholds"
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

-- Roll decision types
L["PASS_ROLLS"] = "Pass"
L["NEED_ROLLS"] = "Need"
L["GREED_ROLLS"] = "Greed"
L["DECISION"] = "Decision"

-- Date filtering
L["DATE_RANGE"] = "Date Range"
L["FROM"] = "From"
L["TO"] = "To"
L["RESET"] = "Reset"
L["SEARCH"] = "Search"

-- Graph tab
L["HOURLY_ACTIVITY"] = "Hourly Activity (Last 24 Hours)"
L["TOTAL_ROLLS_24H"] = "Total rolls in last 24 hours: %d"

-- Export
L["EXPORT_DATA_TITLE"] = "Export Data"
L["EXPORT_DATA_LABEL"] = "Copy this data to save your UltimateLoot information:"

-- Profile info
L["CURRENT_PROFILE"] = "Current Profile: |cffffd700%s|r"
L["CHARACTER"] = "Character: |cffffd700%s|r"
L["REALM"] = "Realm: |cffffd700%s|r"
L["PROFILE_INFO_FORMAT"] = "Current Profile: |cffffd700%s|r\nCharacter: |cffffd700%s|r\nRealm: |cffffd700%s|r"

-- Quality names with colors
L["QUALITY_POOR"] = "|cff9d9d9dPoor (Gray)|r"
L["QUALITY_COMMON"] = "|cffffffffCommon (White)|r"
L["QUALITY_UNCOMMON"] = "|cff1eff00Uncommon (Green)|r"
L["QUALITY_RARE"] = "|cff0070ddRare (Blue)|r"
L["QUALITY_EPIC"] = "|cffa335eeEpic (Purple)|r"
L["QUALITY_LEGENDARY"] = "|cffff8000Legendary (Orange)|r"

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
L["ADD_RULE"] = "Add Rule"
L["CURRENT_RULES"] = "Current Rules"
L["NO_RULES_CONFIGURED"] = "No item rules configured. Add rules above to customize item behavior."
L["ALWAYS_PASS_RULES"] = "Always Pass Rules"
L["NEVER_PASS_RULES"] = "Never Pass Rules"
L["ALWAYS_NEED_RULES"] = "Always Need Rules"
L["ALWAYS_GREED_RULES"] = "Always Greed Rules"
L["ALWAYS_PASS_RULES_DESC"] = "These items will always be passed on"
L["NEVER_PASS_RULES_DESC"] = "These items will never be passed on"
L["ALWAYS_NEED_RULES_DESC"] = "These items will always be rolled Need"
L["ALWAYS_GREED_RULES_DESC"] = "These items will always be rolled Greed"
L["RULE_MANAGEMENT"] = "Rule Management"
L["TEST_RULES"] = "Test Rules"
L["CLEAR_ALL_RULES"] = "Clear All Rules"
L["CLEAR_ALL_RULES_CONFIRM"] = "Are you sure you want to clear ALL item rules?\n\nThis cannot be undone."
L["CLEAR_RULE_TYPE_CONFIRM"] = "Clear all %s?"
