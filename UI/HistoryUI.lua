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
    
    -- Initialize sorting properties
    self.sortColumn = "date"  -- Default sort by date
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
    
    -- Date range filters
    local startTimestamp = self.dateFilterStart and time(self.dateFilterStart) or nil
    local endTimestamp = self.dateFilterEnd and time(self.dateFilterEnd) or nil
    
    -- If we have an end date, move it to the end of that day for inclusive filtering
    if endTimestamp then
        endTimestamp = endTimestamp + (24*60*60) - 1 -- End of the day (23:59:59)
    end

    for _, entry in ipairs(allHistory) do
        local rollType = entry.rollTypeName or "pass"
        local matchesFilter = filter == "all" or filter == rollType
        local matchesSearch = true
        local matchesDateRange = true
        
        -- Apply search filter if we have search text
        if searchText ~= "" then
            local itemName = (entry.itemName or ""):lower()
            matchesSearch = itemName:find(searchText, 1, true) ~= nil
        end
        
        -- Apply date range filter if set
        if startTimestamp and entry.timestamp and entry.timestamp < startTimestamp then
            matchesDateRange = false
        end
        
        if endTimestamp and entry.timestamp and entry.timestamp > endTimestamp then
            matchesDateRange = false
        end
        
        if matchesFilter and matchesSearch and matchesDateRange then
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

    -- Create table entries with consistent styling
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

    -- Simple summary without textures
    local filterText = filter == "all" and L["ALL_TYPES"] or string.format(L["FILTER_SUMMARY"], filter:gsub("^%l", string.upper))
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
    
    -- Create a third row for date filters
    local dateRow = AceGUI:Create("SimpleGroup")
    dateRow:SetFullWidth(true)
    dateRow:SetLayout("Flow")
    controlsGroup:AddChild(dateRow)
    
    -- Date range filters
    local dateFilterLabel = AceGUI:Create("Label")
    dateFilterLabel:SetText(L["DATE_RANGE"] or "Date Range:")
    dateFilterLabel:SetWidth(80)
    dateRow:AddChild(dateFilterLabel)
    
    -- Date format text
    local dateFormatLabel = AceGUI:Create("Label")
    dateFormatLabel:SetText(L["DATE_FORMAT"])
    dateFormatLabel:SetWidth(95)
    dateFormatLabel:SetColor(0.7, 0.7, 0.7)
    dateRow:AddChild(dateFormatLabel)
    
    -- Start date picker
    local startDateLabel = AceGUI:Create("Label")
    startDateLabel:SetText(L["FROM"] or "From:")
    startDateLabel:SetWidth(40)
    dateRow:AddChild(startDateLabel)
    
    local startDateBox = AceGUI:Create("EditBox")
    startDateBox:SetWidth(90)
    startDateBox:DisableButton(true)
    startDateBox:SetCallback("OnTextChanged", function(widget, event, text)
        if text == "" then
            self.dateFilterStart = nil
            self:RefreshHistoryTable()
            return
        end
        
        -- Parse date in YYYY-MM-DD format
        local year, month, day = text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
        if year and month and day then
            self.dateFilterStart = { year = tonumber(year), month = tonumber(month), day = tonumber(day) }
            self:RefreshHistoryTable()
        end
    end)
    dateRow:AddChild(startDateBox)
    
    -- End date picker
    local endDateLabel = AceGUI:Create("Label")
    endDateLabel:SetText(L["TO"] or "To:")
    endDateLabel:SetWidth(30)
    dateRow:AddChild(endDateLabel)
    
    local endDateBox = AceGUI:Create("EditBox")
    endDateBox:SetWidth(90)
    endDateBox:DisableButton(true)
    endDateBox:SetCallback("OnTextChanged", function(widget, event, text)
        if text == "" then
            self.dateFilterEnd = nil
            self:RefreshHistoryTable()
            return
        end
        
        -- Parse date in YYYY-MM-DD format
        local year, month, day = text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
        if year and month and day then
            self.dateFilterEnd = { year = tonumber(year), month = tonumber(month), day = tonumber(day) }
            self:RefreshHistoryTable()
        end
    end)
    dateRow:AddChild(endDateBox)
    
    -- Reset date filter button
    local resetDatesButton = AceGUI:Create("Button")
    resetDatesButton:SetText(L["RESET"] or "Reset")
    resetDatesButton:SetWidth(60)
    resetDatesButton:SetCallback("OnClick", function()
        startDateBox:SetText("")
        endDateBox:SetText("")
        self.dateFilterStart = nil
        self.dateFilterEnd = nil
        self:RefreshHistoryTable()
    end)
    dateRow:AddChild(resetDatesButton)
end

-- Refresh function for external calls
function HistoryUI:RefreshHistory(scrollFrame)
    -- For backward compatibility, but use the new table method
    self:RefreshHistoryTable()
end
