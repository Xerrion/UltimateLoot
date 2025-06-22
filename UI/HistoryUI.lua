local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local HistoryUI = E:NewModule("HistoryUI")
E.HistoryUI = HistoryUI
local AceGUI = E.Libs.AceGUI

-- Table column configuration
local COLUMNS = {
    { key = "item",     label = "Item",                      width = 280 },
    { key = "quality",  label = "Quality",                   width = 90 },
    { key = "decision", label = L["DECISION"] or "Decision", width = 80 },
    { key = "date",     label = "Date",                      width = 140 }
}

-- Helper function to get quality color and apply it to a widget
local function SetQualityColor(widget, quality)
    local r, g, b = unpack(E.Tracker:GetQualityColor(quality))
    widget:SetColor(r, g, b)
    return r, g, b
end

-- Helper function to get roll decision color
local function GetRollDecisionColor(rollTypeName)
    if rollTypeName == "need" then
        return 0.12, 1, 0    -- Green (like Uncommon items)
    elseif rollTypeName == "greed" then
        return 0, 0.44, 0.87 -- Blue (like Rare items)
    else                     -- "pass" or nil (legacy)
        return 0.8, 0.8, 0.8 -- Light gray
    end
end

-- Helper function to get roll decision display text
local function GetRollDecisionText(rollTypeName)
    if rollTypeName == "need" then
        return L["NEED_ROLLS"] or "Need"
    elseif rollTypeName == "greed" then
        return L["GREED_ROLLS"] or "Greed"
    else -- "pass" or nil (legacy)
        return L["PASS_ROLLS"] or "Pass"
    end
end

-- Create table header row
local function CreateTableHeader(scrollFrame)
    local headerFrame = AceGUI:Create("SimpleGroup")
    headerFrame:SetFullWidth(true)
    headerFrame:SetLayout("Flow")

    -- Create header background (WoW 3.3.5a compatible)
    local headerBg = headerFrame.frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(headerFrame.frame)
    headerBg:SetTexture(0.2, 0.2, 0.3, 0.8)

    for _, column in ipairs(COLUMNS) do
        local header = AceGUI:Create("Label")
        header:SetText(column.label)
        header:SetWidth(column.width)
        header:SetFontObject(GameFontNormalLarge)
        header:SetColor(1, 1, 1)
        headerFrame:AddChild(header)
    end

    scrollFrame:AddChild(headerFrame)
end

-- Create table row with alternating background
local function CreateTableRow(scrollFrame, rowData, isEven)
    local rowFrame = AceGUI:Create("SimpleGroup")
    rowFrame:SetFullWidth(true)
    rowFrame:SetLayout("Flow")

    -- Add alternating row background (WoW 3.3.5a compatible)
    local rowBg = rowFrame.frame:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints(rowFrame.frame)
    if isEven then
        rowBg:SetTexture(0.1, 0.1, 0.15, 0.3)
    else
        rowBg:SetTexture(0.05, 0.05, 0.1, 0.5)
    end

    -- Item column
    local itemLabel = AceGUI:Create("InteractiveLabel")
    itemLabel:SetText(rowData.itemLink or rowData.itemName)
    itemLabel:SetWidth(COLUMNS[1].width)
    local r, g, b = SetQualityColor(itemLabel, rowData.quality)

    -- Add tooltip for item links
    itemLabel:SetCallback("OnEnter", function(widget)
        if rowData.itemLink and rowData.itemLink:match("|H.-|h") then
            GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
            local success = pcall(GameTooltip.SetHyperlink, GameTooltip, rowData.itemLink)
            if success then
                GameTooltip:Show()
            else
                GameTooltip:Hide()
            end
        end
    end)
    itemLabel:SetCallback("OnLeave", function()
        GameTooltip:Hide()
    end)
    rowFrame:AddChild(itemLabel)

    -- Quality column
    local qualityLabel = AceGUI:Create("Label")
    qualityLabel:SetText(rowData.qualityName or "Unknown")
    qualityLabel:SetWidth(COLUMNS[2].width)
    qualityLabel:SetColor(r, g, b)
    rowFrame:AddChild(qualityLabel)

    -- Decision column
    local decisionLabel = AceGUI:Create("Label")
    local rollTypeName = rowData.rollTypeName or "pass" -- Default to "pass" for legacy entries
    decisionLabel:SetText(GetRollDecisionText(rollTypeName))
    decisionLabel:SetWidth(COLUMNS[3].width)
    local dr, dg, db = GetRollDecisionColor(rollTypeName)
    decisionLabel:SetColor(dr, dg, db)
    rowFrame:AddChild(decisionLabel)

    -- Date column
    local dateLabel = AceGUI:Create("Label")
    dateLabel:SetText(rowData.date or "Unknown")
    dateLabel:SetWidth(COLUMNS[4].width)
    dateLabel:SetColor(0.8, 0.8, 0.8)
    rowFrame:AddChild(dateLabel)

    scrollFrame:AddChild(rowFrame)
end

function HistoryUI:CreateHistoryTab(container)
    -- Main container
    local mainGroup = AceGUI:Create("SimpleGroup")
    mainGroup:SetFullWidth(true)
    mainGroup:SetFullHeight(true)
    mainGroup:SetLayout("Fill")
    container:AddChild(mainGroup)

    -- Controls container
    local controlsGroup = AceGUI:Create("SimpleGroup")
    controlsGroup:SetFullWidth(true)
    controlsGroup:SetHeight(50)
    controlsGroup:SetLayout("Flow")
    mainGroup:AddChild(controlsGroup)

    -- Add table controls
    self:CreateTableControls(controlsGroup)

    -- Table container with scroll
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    mainGroup:AddChild(scrollFrame)

    -- Store references for refreshing
    self.scrollFrame = scrollFrame
    self.currentLimit = 50     -- Default to showing 50 items
    self.currentFilter = "all" -- Default to showing all types

    -- Populate the table
    self:RefreshHistoryTable()
end

function HistoryUI:RefreshHistoryTable()
    if not self.scrollFrame then return end

    -- Clear existing content
    self.scrollFrame:ReleaseChildren()

    -- Debug: Check tracker status
    E:DebugPrint("[DEBUG] HistoryUI: Tracker exists: %s", tostring(E.Tracker ~= nil))
    if E.Tracker and E.Tracker.db then
        E:DebugPrint("[DEBUG] HistoryUI: Tracker enabled: %s", tostring(E.Tracker.db.enabled))
        E:DebugPrint("[DEBUG] HistoryUI: Raw history count: %d", #(E.Tracker.db.history or {}))
    end

    -- Get history data with current limit
    local limit = self.currentLimit or 50
    if limit == 999 then limit = nil end -- "All" option
    local allHistory = E.Tracker:GetHistory(limit)

    -- Debug: Check what we got
    E:DebugPrint("[DEBUG] HistoryUI: Retrieved %d history entries", #allHistory)
    if #allHistory > 0 then
        E:DebugPrint("[DEBUG] HistoryUI: First entry: %s (%s)",
            allHistory[1].itemName or "unknown",
            allHistory[1].rollTypeName or "unknown")
    end

    -- Apply filter
    local history = {}
    local filter = self.currentFilter or "all"

    for _, entry in ipairs(allHistory) do
        local rollType = entry.rollTypeName or "pass"
        if filter == "all" or filter == rollType then
            table.insert(history, entry)
        end
    end

    E:DebugPrint("[DEBUG] HistoryUI: After filtering (%s): %d entries", filter, #history)

    -- Create table header
    CreateTableHeader(self.scrollFrame)

    if #history == 0 then
        -- No data message
        local noDataFrame = AceGUI:Create("SimpleGroup")
        noDataFrame:SetFullWidth(true)
        noDataFrame:SetLayout("Fill")

        local label = AceGUI:Create("Label")
        label:SetText(L["NO_ITEMS_PASSED"] or "No items have been handled yet.")
        label:SetFullWidth(true)
        label:SetJustifyH("CENTER")
        label:SetColor(0.7, 0.7, 0.7)
        noDataFrame:AddChild(label)

        self.scrollFrame:AddChild(noDataFrame)
        return
    end

    -- Create table rows
    for i, entry in ipairs(history) do
        CreateTableRow(self.scrollFrame, entry, i % 2 == 0)
    end

    -- Add summary at the bottom
    self:AddTableSummary()
end

function HistoryUI:AddTableSummary()
    -- Get the currently filtered history
    local limit = self.currentLimit or 50
    if limit == 999 then limit = nil end
    local allHistory = E.Tracker:GetHistory(limit)

    local history = {}
    local filter = self.currentFilter or "all"

    for _, entry in ipairs(allHistory) do
        local rollType = entry.rollTypeName or "pass"
        if filter == "all" or filter == rollType then
            table.insert(history, entry)
        end
    end

    if #history == 0 then return end

    -- Count roll types in current view
    local counts = { pass = 0, need = 0, greed = 0 }
    for _, entry in ipairs(history) do
        local rollType = entry.rollTypeName or "pass"
        counts[rollType] = counts[rollType] + 1
    end

    -- Create summary row
    local summaryFrame = AceGUI:Create("SimpleGroup")
    summaryFrame:SetFullWidth(true)
    summaryFrame:SetLayout("Flow")

    -- Summary background (WoW 3.3.5a compatible)
    local summaryBg = summaryFrame.frame:CreateTexture(nil, "BACKGROUND")
    summaryBg:SetAllPoints(summaryFrame.frame)
    summaryBg:SetTexture(0.3, 0.3, 0.4, 0.6)

    -- Summary text
    local filterText = filter == "all" and "All Types" or (filter:gsub("^%l", string.upper) .. " Only")
    local summaryText = string.format("Showing %d items (%s) | Pass: %d | Need: %d | Greed: %d",
        #history, filterText, counts.pass, counts.need, counts.greed)

    local summaryLabel = AceGUI:Create("Label")
    summaryLabel:SetText(summaryText)
    summaryLabel:SetFullWidth(true)
    summaryLabel:SetJustifyH("CENTER")
    summaryLabel:SetColor(1, 1, 1)
    summaryLabel:SetFontObject(GameFontNormal)
    summaryFrame:AddChild(summaryLabel)

    self.scrollFrame:AddChild(summaryFrame)
end

-- Create table controls (filter, limit, refresh)
function HistoryUI:CreateTableControls(controlsGroup)
    -- Limit dropdown
    local limitLabel = AceGUI:Create("Label")
    limitLabel:SetText("Show:")
    limitLabel:SetWidth(40)
    controlsGroup:AddChild(limitLabel)

    local limitDropdown = AceGUI:Create("Dropdown")
    limitDropdown:SetWidth(80)
    limitDropdown:SetList({
        [25] = "25",
        [50] = "50",
        [100] = "100",
        [200] = "200",
        [999] = "All"
    })
    limitDropdown:SetValue(50)
    limitDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        self.currentLimit = value
        self:RefreshHistoryTable()
    end)
    controlsGroup:AddChild(limitDropdown)

    -- Filter dropdown
    local filterLabel = AceGUI:Create("Label")
    filterLabel:SetText("Filter:")
    filterLabel:SetWidth(40)
    controlsGroup:AddChild(filterLabel)

    local filterDropdown = AceGUI:Create("Dropdown")
    filterDropdown:SetWidth(100)
    filterDropdown:SetList({
        all = "All",
        pass = "Pass Only",
        need = "Need Only",
        greed = "Greed Only"
    })
    filterDropdown:SetValue("all")
    filterDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        self.currentFilter = value
        self:RefreshHistoryTable()
    end)
    controlsGroup:AddChild(filterDropdown)

    -- Refresh button
    local refreshButton = AceGUI:Create("Button")
    refreshButton:SetText("Refresh")
    refreshButton:SetWidth(80)
    refreshButton:SetCallback("OnClick", function()
        self:RefreshHistoryTable()
    end)
    controlsGroup:AddChild(refreshButton)

    -- Test data button
    local testButton = AceGUI:Create("Button")
    testButton:SetText("Add Test Data")
    testButton:SetWidth(100)
    testButton:SetCallback("OnClick", function()
        -- Add some test roll data
        E.Tracker:TrackRoll("|cff9d9d9d|Hitem:2589::::::::1::::::::|h[Linen Cloth]|h|r", "Linen Cloth", 1, 0)           -- Pass
        E.Tracker:TrackRoll("|cff1eff00|Hitem:25:::::::::1::::::::|h[Worn Shortsword]|h|r", "Worn Shortsword", 2, 1)    -- Need
        E.Tracker:TrackRoll("|cff0070dd|Hitem:2567::::::::1::::::::|h[Evocator's Blade]|h|r", "Evocator's Blade", 3, 2) -- Greed
        E.Tracker:TrackRoll(
            "|cffa335ee|Hitem:19019::::::::1::::::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r", "Thunderfury",
            4,
            0)                                                                                                             -- Pass Epic
        E.Tracker:TrackRoll("|cffff8000|Hitem:17182::::::::1::::::::|h[Sulfuras, Hand of Ragnaros]|h|r", "Sulfuras", 5, 1) -- Need Legendary
        E:Print("Added 5 test entries to history")
        self:RefreshHistoryTable()
    end)
    controlsGroup:AddChild(testButton)

    -- Clear history button
    local clearButton = AceGUI:Create("Button")
    clearButton:SetText("Clear History")
    clearButton:SetWidth(100)
    clearButton:SetCallback("OnClick", function()
        StaticPopupDialogs["ULTIMATELOOT_CLEAR_HISTORY"] = {
            text = "Are you sure you want to clear the roll history?\\n\\nThis cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                E.Tracker:ClearHistory()
                self:RefreshHistoryTable()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ULTIMATELOOT_CLEAR_HISTORY")
    end)
    controlsGroup:AddChild(clearButton)
end

-- Refresh function for external calls
function HistoryUI:RefreshHistory(scrollFrame)
    -- For backward compatibility, but use the new table method
    self:RefreshHistoryTable()
end
