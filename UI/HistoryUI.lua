local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local HistoryUI = E:NewModule("HistoryUI")
E.HistoryUI = HistoryUI
local AceGUI = E.Libs.AceGUI

-- Table column configuration
local COLUMNS = {
    { key = "item",     label = L["ITEM_COLUMN"],    width = 280 },
    { key = "quality",  label = L["QUALITY_COLUMN"], width = 90 },
    { key = "decision", label = L["DECISION"],       width = 80 },
    { key = "date",     label = L["DATE_COLUMN"],    width = 140 }
}

-- Using UIUtils module for shared functionality

-- Create table header row with sorting support - using UIUtils
local function CreateTableHeader(scrollFrame, sortColumn, sortDirection)
    local sortInfo = {
        column = sortColumn,
        direction = sortDirection,
        callback = function(columnKey)
            -- Toggle sort direction if clicking the same column
            if E.HistoryUI.sortColumn == columnKey then
                E.HistoryUI.sortDirection = E.HistoryUI.sortDirection == "asc" and "desc" or "asc"
            else
                -- New column becomes the sort column with default desc order
                E.HistoryUI.sortColumn = columnKey
                E.HistoryUI.sortDirection = "desc"
            end

            -- Refresh the table with new sorting
            E.HistoryUI:RefreshHistoryTable()
        end
    }

    E.UIUtils:CreateTableHeader(scrollFrame, COLUMNS, sortInfo)
end

-- Create table row with alternating background - using UIUtils with custom row content
local function CreateTableRow(scrollFrame, rowData, isEven)
    local rowFrame = E.UIUtils:CreateTableRow(scrollFrame, isEven)

    -- Item column
    local itemLabel = AceGUI:Create("InteractiveLabel")
    itemLabel:SetText(rowData.itemLink or rowData.itemName)
    itemLabel:SetWidth(COLUMNS[1].width)
    local r, g, b = E.UIUtils:SetQualityColor(itemLabel, rowData.quality)

    -- Add tooltip for item links
    if rowData.itemLink then
        E.UIUtils:AddItemTooltip(itemLabel, rowData.itemLink)
    end
    rowFrame:AddChild(itemLabel)

    -- Quality column
    local qualityLabel = AceGUI:Create("Label")
    qualityLabel:SetText(rowData.qualityName or L["UNKNOWN"])
    qualityLabel:SetWidth(COLUMNS[2].width)
    qualityLabel:SetColor(r, g, b)
    rowFrame:AddChild(qualityLabel)

    -- Decision column
    local decisionLabel = AceGUI:Create("Label")
    local rollTypeName = rowData.rollTypeName or "pass" -- Default to "pass" for legacy entries
    decisionLabel:SetText(E.UIUtils:GetRollDecisionText(rollTypeName))
    decisionLabel:SetWidth(COLUMNS[3].width)
    local dr, dg, db = E.UIUtils:GetRollDecisionColor(rollTypeName)
    decisionLabel:SetColor(dr, dg, db)
    rowFrame:AddChild(decisionLabel)

    -- Date column
    local dateLabel = AceGUI:Create("Label")
    dateLabel:SetText(rowData.date or L["UNKNOWN"])
    dateLabel:SetWidth(COLUMNS[4].width)
    dateLabel:SetColor(0.8, 0.8, 0.8)
    rowFrame:AddChild(dateLabel)
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

    -- History scroll frame - using UIUtils
    local scrollFrame = E.UIUtils:CreateScrollFrame(container)

    -- Store references for refreshing
    self.scrollFrame = scrollFrame
    self.currentLimit = 50     -- Default to showing 50 items
    self.currentFilter = "all" -- Default to showing all types
    self.sortColumn = "date"    -- Default sort by date
    self.sortDirection = "desc" -- Default newest first

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

    -- Apply filters
    local history = {}
    local filter = self.currentFilter or "all"
    local searchText = self.currentSearch or ""
    searchText = searchText:lower()

    -- Apply filters in a single pass for performance
    for _, entry in ipairs(allHistory) do
        local rollType = entry.rollTypeName or "pass"

        -- Check all filter conditions at once to avoid unnecessary operations
        if (filter == "all" or filter == rollType) and
           (searchText == "" or ((entry.itemName or ""):lower():find(searchText, 1, true) ~= nil)) then
            table.insert(history, entry)
        end
    end

    E:DebugPrint("[DEBUG] HistoryUI: After filtering (%s): %d entries", filter, #history)

    -- Apply sorting
    if #history > 0 then
        local sortCol = self.sortColumn or "date"
        local sortDir = self.sortDirection or "desc"

        table.sort(history, function(a, b)
            -- Helper function to compare values based on column type
            local function compareValues(valA, valB)
                if sortDir == "asc" then
                    return valA < valB
                else
                    return valA > valB
                end
            end

            if sortCol == "item" then
                return compareValues((a.itemName or ""):lower(), (b.itemName or ""):lower())
            elseif sortCol == "quality" then
                return compareValues(a.quality or 0, b.quality or 0)
            elseif sortCol == "decision" then
                -- Convert decision names to numeric values for comparison
                local decisionValueA = a.rollTypeName == "need" and 3 or a.rollTypeName == "greed" and 2 or 1
                local decisionValueB = b.rollTypeName == "need" and 3 or b.rollTypeName == "greed" and 2 or 1
                return compareValues(decisionValueA, decisionValueB)
            else -- Default to date
                return compareValues(a.timestamp or 0, b.timestamp or 0)
            end
        end)
    end

    -- Add proper table header with sorting indicators
    CreateTableHeader(self.scrollFrame, self.sortColumn, self.sortDirection)

    if #history == 0 then
        E.UIUtils:ShowEmptyState(self.scrollFrame, L["NO_ITEMS_PASSED"])
        return
    end

    -- Create all rows directly (no virtualization)
    for i, entry in ipairs(history) do
        -- Create a row frame
        local rowFrame = AceGUI:Create("SimpleGroup")
        rowFrame:SetFullWidth(true)
        rowFrame:SetLayout("Flow")
        
        -- Add alternating background
        local rowBg = rowFrame.frame:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints(rowFrame.frame)
        if i % 2 == 0 then
            rowBg:SetTexture(0.1, 0.1, 0.15, 0.3)
        else
            rowBg:SetTexture(0.05, 0.05, 0.1, 0.5)
        end
        
        -- Item column
        local itemLabel = AceGUI:Create("InteractiveLabel")
        itemLabel:SetText(entry.itemLink or entry.itemName)
        itemLabel:SetWidth(COLUMNS[1].width)
        local r, g, b = E.UIUtils:SetQualityColor(itemLabel, entry.quality)
        
        -- Add tooltip for item links
        if entry.itemLink then
            E.UIUtils:AddItemTooltip(itemLabel, entry.itemLink)
        end
        rowFrame:AddChild(itemLabel)
        
        -- Quality column
        local qualityLabel = AceGUI:Create("Label")
        qualityLabel:SetText(entry.qualityName or L["UNKNOWN"])
        qualityLabel:SetWidth(COLUMNS[2].width)
        qualityLabel:SetColor(r, g, b)
        rowFrame:AddChild(qualityLabel)
        
        -- Decision column
        local decisionLabel = AceGUI:Create("Label")
        local rollTypeName = entry.rollTypeName or "pass" -- Default to "pass" for legacy entries
        decisionLabel:SetText(E.UIUtils:GetRollDecisionText(rollTypeName))
        decisionLabel:SetWidth(COLUMNS[3].width)
        local dr, dg, db = E.UIUtils:GetRollDecisionColor(rollTypeName)
        decisionLabel:SetColor(dr, dg, db)
        rowFrame:AddChild(decisionLabel)
        
        -- Date column
        local dateLabel = AceGUI:Create("Label")
        dateLabel:SetText(entry.date or L["UNKNOWN"])
        dateLabel:SetWidth(COLUMNS[4].width)
        dateLabel:SetColor(0.8, 0.8, 0.8)
        rowFrame:AddChild(dateLabel)
        
        -- Add the row to the scroll frame
        self.scrollFrame:AddChild(rowFrame)
    end

    -- Add summary at the bottom
    self:AddTableSummary()
end

-- Update only the currently visible rows for performance
function HistoryUI:UpdateVisibleRows()
    -- Early return checks
    if not self.filteredHistory or #self.filteredHistory == 0 or not self.contentContainer then 
        return 
    end
    
    -- Avoid recursive updating
    if self.updatingRows then
        return
    end
    self.updatingRows = true
    
    -- Clear previous rows but keep spacer
    if self.visibleRowFrames then
        for _, frame in ipairs(self.visibleRowFrames) do
            frame:Release()
        end
    end

    -- Calculate visible range
    local scrollFrame = self.scrollFrame
    local scrollValue = 0

    -- Try different ways to access scrollbar value depending on the AceGUI version
    if scrollFrame.localstatus then
        scrollValue = scrollFrame.localstatus.offset or 0
    elseif scrollFrame.status then
        scrollValue = scrollFrame.status.offset or 0
    end
    local visibleStart = math.floor(scrollValue / self.rowHeight)
    local visibleEnd = visibleStart + self.visibleRows

    -- Clamp to actual data range
    visibleStart = math.max(0, visibleStart)
    visibleEnd = math.min(#self.filteredHistory, visibleEnd)

    -- Create visible row frames
    self.visibleRowFrames = {}
    for i = visibleStart + 1, visibleEnd do
        local entry = self.filteredHistory[i]
        local rowFrame = CreateTableRow(self.contentContainer, entry, i % 2 == 0)

        -- Check if we have the proper frame object
        if rowFrame and rowFrame.frame then
            rowFrame.frame:SetPoint("TOPLEFT", self.contentContainer.frame, "TOPLEFT", 0, -((i - 1) * self.rowHeight))
            rowFrame.frame:SetPoint("TOPRIGHT", self.contentContainer.frame, "TOPRIGHT", 0, -((i - 1) * self.rowHeight))
            rowFrame.frame:SetHeight(self.rowHeight)
        end

        table.insert(self.visibleRowFrames, rowFrame)
    end

    -- Reset the update flag
    self.updatingRows = false
    
    E:DebugPrint("[DEBUG] HistoryUI: Rendered %d visible rows (%d-%d of %d)",
        visibleEnd - visibleStart, visibleStart + 1, visibleEnd, #self.filteredHistory)
end

function HistoryUI:AddTableSummary()
    -- Use already filtered history from cached data
    local history = self.filteredHistory or {}
    local filter = self.currentFilter or "all"

    if #history == 0 then return end

    -- Count roll types in current view
    local counts = { pass = 0, need = 0, greed = 0 }
    for _, entry in ipairs(history) do
        local rollType = entry.rollTypeName or "pass"
        counts[rollType] = counts[rollType] + 1
    end

    -- Simple summary without textures
    local filterText = filter == "all" and L["ALL_TYPES"] or
    string.format(L["FILTER_SUMMARY"], filter:gsub("^%l", string.upper))
    local summaryText = string.format(L["SHOWING_ITEMS_SUMMARY"],
        #history, filterText, counts.pass, counts.need, counts.greed)

    local summaryLabel = AceGUI:Create("Label")
    summaryLabel:SetText(summaryText)
    summaryLabel:SetFullWidth(true)
    summaryLabel:SetColor(0.8, 0.8, 0.8)
    self.scrollFrame:AddChild(summaryLabel)
end

-- Create table controls (filter, limit, refresh)
function HistoryUI:CreateTableControls(controlsGroup)
    -- Create a top row for main controls
    local topRow = AceGUI:Create("SimpleGroup")
    topRow:SetFullWidth(true)
    topRow:SetLayout("Flow")
    controlsGroup:AddChild(topRow)

    -- Limit dropdown
    local limitLabel = AceGUI:Create("Label")
    limitLabel:SetText(L["SHOW_LABEL"])
    limitLabel:SetWidth(40)
    topRow:AddChild(limitLabel)

    local limitDropdown = AceGUI:Create("Dropdown")
    limitDropdown:SetWidth(80)
    limitDropdown:SetList({
        [25] = L["LIMIT_25"],
        [50] = L["LIMIT_50"],
        [100] = L["LIMIT_100"],
        [200] = L["LIMIT_200"],
        [999] = L["LIMIT_ALL"]
    })
    limitDropdown:SetValue(self.currentLimit or 50)
    limitDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        self.currentLimit = value
        self:RefreshHistoryTable()
    end)
    topRow:AddChild(limitDropdown)

    -- Filter dropdown
    local filterLabel = AceGUI:Create("Label")
    filterLabel:SetText(L["FILTER_LABEL"])
    filterLabel:SetWidth(40)
    topRow:AddChild(filterLabel)

    local filterDropdown = AceGUI:Create("Dropdown")
    filterDropdown:SetWidth(100)
    filterDropdown:SetList({
        all = L["FILTER_ALL"],
        pass = L["FILTER_PASS_ONLY"],
        need = L["FILTER_NEED_ONLY"],
        greed = L["FILTER_GREED_ONLY"]
    })
    filterDropdown:SetValue(self.currentFilter or "all")
    filterDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        self.currentFilter = value
        self:RefreshHistoryTable()
    end)
    topRow:AddChild(filterDropdown)

    -- Refresh button
    local refreshButton = AceGUI:Create("Button")
    refreshButton:SetText(L["REFRESH"])
    refreshButton:SetWidth(80)
    refreshButton:SetCallback("OnClick", function()
        self:RefreshHistoryTable()
    end)
    topRow:AddChild(refreshButton)

    -- Clear history button
    local clearButton = AceGUI:Create("Button")
    clearButton:SetText(L["CLEAR_HISTORY"])
    clearButton:SetWidth(100)
    clearButton:SetCallback("OnClick", function()
        E.UIUtils:ShowConfirmDialog("ULTIMATELOOT_CLEAR_HISTORY", L["CLEAR_HISTORY_CONFIRM"], function()
            E.Tracker:ClearHistory()
            self:RefreshHistoryTable()
        end)
    end)
    topRow:AddChild(clearButton)

    -- Create a bottom row for search
    local bottomRow = AceGUI:Create("SimpleGroup")
    bottomRow:SetFullWidth(true)
    bottomRow:SetLayout("Flow")
    controlsGroup:AddChild(bottomRow)

    -- Search box
    local searchLabel = AceGUI:Create("Label")
    searchLabel:SetText(L["SEARCH"] or "Search:")
    searchLabel:SetWidth(60)
    bottomRow:AddChild(searchLabel)

    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetWidth(200)
    searchBox:DisableButton(true)
    searchBox:SetCallback("OnTextChanged", function(widget, event, text)
        self.currentSearch = text
        self:RefreshHistoryTable()
    end)
    bottomRow:AddChild(searchBox)

    -- No date filters
end

-- Refresh function for external calls
function HistoryUI:RefreshHistory(scrollFrame)
    -- For backward compatibility, but use the new table method
    self:RefreshHistoryTable()
end
