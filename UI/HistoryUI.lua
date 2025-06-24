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

-- Create table header row with sorting support
local function CreateTableHeader(scrollFrame, sortColumn, sortDirection)
    local headerFrame = AceGUI:Create("SimpleGroup")
    headerFrame:SetFullWidth(true)
    headerFrame:SetLayout("Flow")

    -- Create header background (WoW 3.3.5a compatible)
    local headerBg = headerFrame.frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(headerFrame.frame)
    headerBg:SetTexture(0.2, 0.2, 0.3, 0.8)

    for _, column in ipairs(COLUMNS) do
        -- Create an interactive label for headers to support clicking
        local header = AceGUI:Create("InteractiveLabel")
        
        -- Add sort indicators if this is the currently sorted column
        local headerText = column.label
        if sortColumn == column.key then
            headerText = headerText .. (sortDirection == "asc" and " \226\134\145" or " \226\134\147")
        end
        
        header:SetText(headerText)
        header:SetWidth(column.width)
        header:SetFontObject(GameFontNormalLarge)
        header:SetColor(1, 1, 1)
        
        -- Make headers clickable for sorting
        header:SetCallback("OnClick", function()
            -- Toggle sort direction if clicking the same column
            if E.HistoryUI.sortColumn == column.key then
                E.HistoryUI.sortDirection = E.HistoryUI.sortDirection == "asc" and "desc" or "asc"
            else
                -- New column becomes the sort column with default desc order
                E.HistoryUI.sortColumn = column.key
                E.HistoryUI.sortDirection = "desc"
            end
            
            -- Refresh the table with new sorting
            E.HistoryUI:RefreshHistoryTable()
        end)
        
        -- Add hover effect to indicate clickable headers
        header:SetCallback("OnEnter", function(widget)
            widget:SetColor(1, 1, 0) -- Yellow on hover
        end)
        
        header:SetCallback("OnLeave", function(widget)
            widget:SetColor(1, 1, 1) -- White when not hovering
        end)
        
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
        local label = AceGUI:Create("Label")
        label:SetText(L["NO_ITEMS_PASSED"] or "No items have been handled yet.")
        label:SetFullWidth(true)
        self.scrollFrame:AddChild(label)
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
    -- Create a top row for main controls
    local topRow = AceGUI:Create("SimpleGroup")
    topRow:SetFullWidth(true)
    topRow:SetLayout("Flow")
    controlsGroup:AddChild(topRow)
    
    -- Limit dropdown
    local limitLabel = AceGUI:Create("Label")
    limitLabel:SetText("Show:")
    limitLabel:SetWidth(40)
    topRow:AddChild(limitLabel)

    local limitDropdown = AceGUI:Create("Dropdown")
    limitDropdown:SetWidth(80)
    limitDropdown:SetList({
        [25] = "25",
        [50] = "50",
        [100] = "100",
        [200] = "200",
        [999] = "All"
    })
    limitDropdown:SetValue(self.currentLimit or 50)
    limitDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        self.currentLimit = value
        self:RefreshHistoryTable()
    end)
    topRow:AddChild(limitDropdown)

    -- Filter dropdown
    local filterLabel = AceGUI:Create("Label")
    filterLabel:SetText("Filter:")
    filterLabel:SetWidth(40)
    topRow:AddChild(filterLabel)

    local filterDropdown = AceGUI:Create("Dropdown")
    filterDropdown:SetWidth(100)
    filterDropdown:SetList({
        all = "All",
        pass = "Pass Only",
        need = "Need Only",
        greed = "Greed Only"
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
    dateFormatLabel:SetText("(YYYY-MM-DD)")
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
