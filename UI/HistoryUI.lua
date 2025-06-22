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
    -- Controls container at top
    local controlsGroup = AceGUI:Create("SimpleGroup")
    controlsGroup:SetFullWidth(true)
    controlsGroup:SetHeight(50)
    controlsGroup:SetLayout("Flow")
    container:AddChild(controlsGroup)

    -- Add table controls
    self:CreateTableControls(controlsGroup)

    -- History scroll frame - use Flow layout like original
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    container:AddChild(scrollFrame)

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

    -- Add simple table header
    local headerGroup = AceGUI:Create("InlineGroup")
    headerGroup:SetTitle("")
    headerGroup:SetFullWidth(true)
    headerGroup:SetLayout("Flow")

    local itemHeader = AceGUI:Create("Label")
    itemHeader:SetText("Item")
    itemHeader:SetWidth(250)
    itemHeader:SetFontObject(GameFontNormalLarge)
    itemHeader:SetColor(1, 1, 1)
    headerGroup:AddChild(itemHeader)

    local qualityHeader = AceGUI:Create("Label")
    qualityHeader:SetText("Quality")
    qualityHeader:SetWidth(80)
    qualityHeader:SetFontObject(GameFontNormalLarge)
    qualityHeader:SetColor(1, 1, 1)
    headerGroup:AddChild(qualityHeader)

    local decisionHeader = AceGUI:Create("Label")
    decisionHeader:SetText(L["DECISION"] or "Decision")
    decisionHeader:SetWidth(60)
    decisionHeader:SetFontObject(GameFontNormalLarge)
    decisionHeader:SetColor(1, 1, 1)
    headerGroup:AddChild(decisionHeader)

    local dateHeader = AceGUI:Create("Label")
    dateHeader:SetText("Date")
    dateHeader:SetWidth(130)
    dateHeader:SetFontObject(GameFontNormalLarge)
    dateHeader:SetColor(1, 1, 1)
    headerGroup:AddChild(dateHeader)

    self.scrollFrame:AddChild(headerGroup)

    if #history == 0 then
        local label = AceGUI:Create("Label")
        label:SetText(L["NO_ITEMS_PASSED"] or "No items have been handled yet.")
        label:SetFullWidth(true)
        self.scrollFrame:AddChild(label)
        return
    end

    -- Create simple table entries (like original, but with decision info)
    for i, entry in ipairs(history) do
        local itemGroup = AceGUI:Create("InlineGroup")
        itemGroup:SetTitle("")
        itemGroup:SetFullWidth(true)
        itemGroup:SetLayout("Flow")

        -- Item link
        local itemLabel = AceGUI:Create("InteractiveLabel")
        itemLabel:SetText(entry.itemLink or entry.itemName)
        itemLabel:SetWidth(250)
        local r, g, b = SetQualityColor(itemLabel, entry.quality)
        itemLabel:SetCallback("OnEnter", function(widget)
            if entry.itemLink and entry.itemLink:match("|H.-|h") then
                GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
                local success = pcall(GameTooltip.SetHyperlink, GameTooltip, entry.itemLink)
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
        itemGroup:AddChild(itemLabel)

        -- Quality
        local qualityLabel = AceGUI:Create("Label")
        qualityLabel:SetText(entry.qualityName)
        qualityLabel:SetWidth(80)
        qualityLabel:SetColor(r, g, b)
        itemGroup:AddChild(qualityLabel)

        -- Roll Decision
        local decisionLabel = AceGUI:Create("Label")
        local rollTypeName = entry.rollTypeName or "pass"
        decisionLabel:SetText(GetRollDecisionText(rollTypeName))
        decisionLabel:SetWidth(60)
        local dr, dg, db = GetRollDecisionColor(rollTypeName)
        decisionLabel:SetColor(dr, dg, db)
        itemGroup:AddChild(decisionLabel)

        -- Date
        local dateLabel = AceGUI:Create("Label")
        dateLabel:SetText(entry.date)
        dateLabel:SetWidth(130)
        itemGroup:AddChild(dateLabel)

        self.scrollFrame:AddChild(itemGroup)
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

    -- Simple summary without textures
    local filterText = filter == "all" and "All Types" or (filter:gsub("^%l", string.upper) .. " Only")
    local summaryText = string.format("Showing %d items (%s) | Pass: %d | Need: %d | Greed: %d",
        #history, filterText, counts.pass, counts.need, counts.greed)

    local summaryLabel = AceGUI:Create("Label")
    summaryLabel:SetText(summaryText)
    summaryLabel:SetFullWidth(true)
    summaryLabel:SetColor(0.8, 0.8, 0.8)
    self.scrollFrame:AddChild(summaryLabel)
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
    refreshButton:SetText(L["REFRESH"])
    refreshButton:SetWidth(80)
    refreshButton:SetCallback("OnClick", function()
        self:RefreshHistoryTable()
    end)
    controlsGroup:AddChild(refreshButton)


    -- Clear history button
    local clearButton = AceGUI:Create("Button")
    clearButton:SetText(L["CLEAR_HISTORY"])
    clearButton:SetWidth(100)
    clearButton:SetCallback("OnClick", function()
        StaticPopupDialogs["ULTIMATELOOT_CLEAR_HISTORY"] = {
            text = "Are you sure you want to clear the roll history?\n\nThis cannot be undone.",
            button1 = L["YES"],
            button2 = L["NO"],
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
