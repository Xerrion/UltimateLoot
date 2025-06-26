local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local TrackerUI = E:NewModule("TrackerUI", "AceEvent-3.0", "AceTimer-3.0")
E.TrackerUI = TrackerUI
local AceGUI = E.Libs.AceGUI

local mainFrame = nil
local selectedTab = "history"

-- Helper function to generate title with status
local function GetFrameTitle()
    local enabled = E:GetEnabled()
    local status = enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
    return L["MAIN_FRAME_TITLE"] .. " [" .. status .. "]"
end

-- Helper function to get the tab group safely
local function GetTabGroup()
    return mainFrame and mainFrame.children and mainFrame.children[1]
end

-- Helper function to refresh the current tab
local function RefreshCurrentTab(self)
    local tabGroup = GetTabGroup()
    if tabGroup then
        self:UpdateContent(tabGroup, selectedTab)
    end
end

-- Helper function to build the tab list conditionally
local function BuildTabList()
    local tabs = {
        { text = L["TAB_HISTORY"],    value = "history" },
        { text = L["TAB_STATISTICS"], value = "stats" },
        { text = L["TAB_ITEMS"],      value = "items" },
        { text = L["TAB_GRAPH"],      value = "graph" },
        { text = L["TAB_ITEM_RULES"], value = "itemrules" },
        { text = L["TAB_SETTINGS"],   value = "settings" }
    }

    -- Only add debug tab if debug mode is enabled
    if E.db.debug_mode then
        table.insert(tabs, { text = L["TAB_DEBUG"], value = "debug" })
    end

    return tabs
end

-- Helper function to rebuild tabs when debug mode changes
local function RebuildTabs(self)
    local tabGroup = GetTabGroup()
    if not tabGroup then return end

    -- Check if currently on debug tab when debug mode is being disabled
    local wasOnDebugTab = (selectedTab == "debug" and not E.db.debug_mode)

    -- Rebuild the tab list
    tabGroup:SetTabs(BuildTabList())

    -- If we were on debug tab and it's no longer available, switch to history
    if wasOnDebugTab then
        selectedTab = "history"
        tabGroup:SelectTab("history")
        self:UpdateContent(tabGroup, "history")
    else
        -- Re-select the current tab to ensure it's properly displayed
        tabGroup:SelectTab(selectedTab)
        self:UpdateContent(tabGroup, selectedTab)
    end
end

function TrackerUI:CreateMainFrame()
    if mainFrame then return mainFrame end

    mainFrame = AceGUI:Create("Frame")
    mainFrame:SetTitle(GetFrameTitle())
    mainFrame:SetStatusText(L["MAIN_FRAME_STATUS"])
    mainFrame:SetWidth(800)
    mainFrame:SetHeight(600)
    mainFrame:SetLayout("Fill")

    mainFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        mainFrame = nil
        self.mainFrame = nil -- Clear the exposed reference too
    end)

    -- Create tab group with conditional tabs
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetTabs(BuildTabList())
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
        selectedTab = group
        self:UpdateContent(widget, group)
    end)

    mainFrame:AddChild(tabGroup)

    -- Select the default tab (history)
    tabGroup:SelectTab("history")
    self:UpdateContent(tabGroup, "history")

    -- Expose mainFrame as a property for other modules
    self.mainFrame = mainFrame

    return mainFrame
end

function TrackerUI:UpdateContent(container, tab)
    container:ReleaseChildren()

    -- Delegate tab creation to appropriate modules
    if tab == "history" then
        if E.HistoryUI then
            E.HistoryUI:CreateHistoryTab(container)
        else
            self:ShowModuleError(container, "HistoryUI")
        end
    elseif tab == "stats" then
        if E.StatisticsUI then
            E.StatisticsUI:CreateStatsTab(container)
        else
            self:ShowModuleError(container, "StatisticsUI")
        end
    elseif tab == "items" then
        if E.ItemsUI then
            E.ItemsUI:CreateItemsTab(container)
        else
            self:ShowModuleError(container, "ItemsUI")
        end
    elseif tab == "graph" then
        if E.GraphUI then
            E.GraphUI:CreateGraphTab(container)
        else
            self:ShowModuleError(container, "GraphUI")
        end
    elseif tab == "itemrules" then
        if E.ItemRulesUI then
            E.ItemRulesUI:CreateItemRulesTab(container)
        else
            self:ShowModuleError(container, "ItemRulesUI")
        end
    elseif tab == "settings" then
        if E.SettingsUI then
            -- Pass refresh callback to SettingsUI
            E.SettingsUI:SetRefreshCallback(function()
                RefreshCurrentTab(self)
            end)
            E.SettingsUI:CreateSettingsTab(container)
        else
            self:ShowModuleError(container, "SettingsUI")
        end
    elseif tab == "debug" then
        if E.Debug then
            E.Debug:CreateDebugUI(container)
        else
            self:ShowModuleError(container, "Debug")
        end
    end
end

-- Helper function to show module error
function TrackerUI:ShowModuleError(container, moduleName)
    local errorLabel = AceGUI:Create("Label")
    errorLabel:SetText(string.format("|cffff0000%s module not available|r", moduleName))
    errorLabel:SetFullWidth(true)
    container:AddChild(errorLabel)
end

function TrackerUI:ShowExportFrame(data)
    local exportFrame = AceGUI:Create("Frame")
    exportFrame:SetTitle(L["EXPORT_DATA_TITLE"])
    exportFrame:SetWidth(600)
    exportFrame:SetHeight(400)
    exportFrame:SetLayout("Fill")

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Fill")
    exportFrame:AddChild(scrollFrame)

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel(L["EXPORT_DATA_LABEL"])
    editBox:SetText(data)
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(true)
    editBox:DisableButton(true)
    scrollFrame:AddChild(editBox)

    exportFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
end

function TrackerUI:ShowTracker()
    if not mainFrame then
        self:CreateMainFrame()
    end

    if mainFrame then
        if not mainFrame:IsShown() then
            mainFrame:Show()
        end

        -- Ensure title shows current status
        mainFrame:SetTitle(GetFrameTitle())

        -- Ensure default tab is selected if none is currently active
        local tabGroup = GetTabGroup()
        if tabGroup then
            if not selectedTab or selectedTab == "" then
                selectedTab = "history"
                tabGroup:SelectTab("history")
                self:UpdateContent(tabGroup, "history")
            end
        end
    else
        E:Print(L["TRACKER_UI_CREATION_FAILED"])
    end
end

function TrackerUI:SelectTab(tabName)
    local tabGroup = GetTabGroup()
    if tabGroup then
        tabGroup:SelectTab(tabName)
        selectedTab = tabName
        self:UpdateContent(tabGroup, tabName)
    end
end

function TrackerUI:HideTracker()
    if mainFrame then
        mainFrame:Hide()
    end
end

function TrackerUI:OnEnable()
    E:DebugPrint("[DEBUG] TrackerUI:OnEnable - Registering for events")

    -- OPTIMIZED: Combine tab refresh logic to reduce redundant calls
    local function refreshIfRelevantTab(relevantTabs)
        if not selectedTab then return end
        
        for _, tab in ipairs(relevantTabs) do
            if selectedTab == tab then
                RefreshCurrentTab(self)
                return
            end
        end
    end

    -- Register for updates
    self:RegisterMessage("ULTIMATELOOT_ITEM_TRACKED", function()
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_ITEM_TRACKED event received")
        refreshIfRelevantTab({"history", "items"})
    end)

    self:RegisterMessage("ULTIMATELOOT_HISTORY_CLEARED", function()
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_HISTORY_CLEARED event received")
        RefreshCurrentTab(self)
    end)

    -- Enhanced event handling for new event-driven architecture
    self:RegisterMessage("ULTIMATELOOT_STATS_RESET", function()
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_STATS_RESET event received")
        refreshIfRelevantTab({"stats", "graph"})
    end)

    self:RegisterMessage("ULTIMATELOOT_ALL_DATA_CLEARED", function()
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_ALL_DATA_CLEARED event received")
        RefreshCurrentTab(self)
    end)

    self:RegisterMessage("ULTIMATELOOT_ENABLED_CHANGED", function(_, enabled, oldEnabled)
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_ENABLED_CHANGED event received: %s -> %s", tostring(oldEnabled),
            tostring(enabled))

        -- Update settings tab if visible
        refreshIfRelevantTab({"settings"})

        -- Update main frame title with current status
        if mainFrame then
            mainFrame:SetTitle(GetFrameTitle())
        end
    end)

    self:RegisterMessage("ULTIMATELOOT_THRESHOLD_CHANGED", function(_, newThreshold, oldThreshold)
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_THRESHOLD_CHANGED event received: %s -> %s",
            tostring(oldThreshold), tostring(newThreshold))

        -- Update settings tab if visible
        refreshIfRelevantTab({"settings"})
    end)

    self:RegisterMessage("ULTIMATELOOT_STATE_CHANGED", function(_, changeData)
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_STATE_CHANGED event received: %s (%s -> %s)",
            changeData.type, tostring(changeData.oldValue), tostring(changeData.newValue))

        -- Handle generic state changes - OPTIMIZED: Direct tab check
        if (changeData.type == "enabled" or changeData.type == "threshold") and selectedTab == "settings" then
            RefreshCurrentTab(self)
        end
    end)

    self:RegisterMessage("ULTIMATELOOT_DATA_CHANGED", function(_, changeData)
        E:DebugPrint("[DEBUG] TrackerUI - ULTIMATELOOT_DATA_CHANGED event received: %s", changeData.type)

        -- OPTIMIZED: Use lookup table for performance
        local refreshMap = {
            history_cleared = {"history", "items"},
            stats_cleared = {"stats", "graph"},
            all_data_cleared = true -- Special case - always refresh
        }
        
        local relevantTabs = refreshMap[changeData.type]
        if relevantTabs == true then
            RefreshCurrentTab(self)
        elseif relevantTabs then
            refreshIfRelevantTab(relevantTabs)
        end
    end)

    -- OPTIMIZED: Combine debug event handlers
    local function handleDebugEvents()
        if selectedTab == "debug" and E.Debug then
            E.Debug:RefreshDebugOutput()
        end
    end

    self:RegisterMessage("ULTIMATELOOT_DEBUG_OUTPUT", handleDebugEvents)
    self:RegisterMessage("ULTIMATELOOT_DEBUG_CLEARED", handleDebugEvents)

    E:DebugPrint("[DEBUG] TrackerUI:OnEnable - Event registration complete")
end

-- Method to rebuild tabs (can be called externally when debug mode changes)
function TrackerUI:RebuildTabs()
    RebuildTabs(self)
end

-- Helper methods for other modules to safely check mainFrame status
function TrackerUI:GetMainFrame()
    return mainFrame
end

function TrackerUI:IsMainFrameShown()
    return mainFrame and mainFrame:IsShown() or false
end

function TrackerUI:ToggleMainFrame()
    if self:IsMainFrameShown() then
        self:HideTracker()
    else
        self:ShowTracker()
    end
end
