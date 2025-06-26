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

-- OPTIMIZED: Generate filter hash for caching
local function generateFilterHash(limit, filter, search, sortCol, sortDir)
    return string.format("%s_%s_%s_%s_%s", 
        tostring(limit), filter, search, sortCol, sortDir)
end

function HistoryUI:RefreshHistoryTable()
    if not self.scrollFrame then return end

    -- Generate cache key
    local filterHash = generateFilterHash(
        self.currentLimit, self.currentFilter, self.currentSearch,
        self.sortColumn, self.sortDirection
    )
    
    -- OPTIMIZED: Use cached result if available
    if self.lastFilterHash == filterHash and self.filteredHistory then
        E:DebugPrint("[DEBUG] HistoryUI: Using cached filter results")
        self:RenderTable()
        return
    end

    -- Clear existing content
    self.scrollFrame:ReleaseChildren()

    -- Get history data with current limit
    local limit = self.currentLimit or 50
    if limit == 999 then limit = nil end -- "All" option
    local allHistory = E.Tracker:GetHistory(limit)

    -- Apply filters in a single optimized pass
    local history = {}
    local filter = self.currentFilter or "all"
    local searchText = (self.currentSearch or ""):lower()
    local hasSearch = searchText ~= ""

    -- OPTIMIZED: Single pass filtering with boolean conditions (Lua 5.1 compatible)
    for _, entry in ipairs(allHistory) do
        local rollType = entry.rollTypeName or "pass"
        local passesFilter = true
        
        -- Quick filter check first (cheapest operation)
        if filter ~= "all" and filter ~= rollType then
            passesFilter = false
        end
        
        -- Search filter (more expensive, so do it last)
        if passesFilter and hasSearch then
            local itemName = (entry.itemName or ""):lower()
            if not itemName:find(searchText, 1, true) then
                passesFilter = false
            end
        end
        
        if passesFilter and entry then
            table.insert(history, entry)
        end
    end

    -- OPTIMIZED: Remove any nil entries and sort only once with cached comparator
    -- Clean up history table to ensure no nil values
    local cleanHistory = {}
    for _, entry in ipairs(history) do
        if entry then
            table.insert(cleanHistory, entry)
        end
    end
    history = cleanHistory

    if #history > 1 then
        local sortCol = self.sortColumn or "date"
        local sortDir = self.sortDirection or "desc"
        local ascending = sortDir == "asc"
        
        if sortCol == "item" then
            table.sort(history, function(a, b)
                if not a or not b then return false end
                local valA, valB = (a.itemName or ""):lower(), (b.itemName or ""):lower()
                return ascending and valA < valB or valA > valB
            end)
        elseif sortCol == "quality" then
            table.sort(history, function(a, b)
                if not a or not b then return false end
                local valA, valB = a.quality or 0, b.quality or 0
                return ascending and valA < valB or valA > valB
            end)
        elseif sortCol == "decision" then
            table.sort(history, function(a, b)
                if not a or not b then return false end
                local valA = a.rollTypeName == "need" and 3 or a.rollTypeName == "greed" and 2 or 1
                local valB = b.rollTypeName == "need" and 3 or b.rollTypeName == "greed" and 2 or 1
                return ascending and valA < valB or valA > valB
            end)
        else -- date
            table.sort(history, function(a, b)
                if not a or not b then return false end
                local valA, valB = a.timestamp or 0, b.timestamp or 0
                return ascending and valA < valB or valA > valB
            end)
        end
    end

    -- Cache the results
    self.filteredHistory = history
    self.lastFilterHash = filterHash
    
    -- Manage cache size
    if #self.filterCache > self.maxCacheSize then
        -- Clear old cache entries
        for k in pairs(self.filterCache) do
            self.filterCache[k] = nil
            break
        end
    end
    
    self:RenderTable()
end

-- OPTIMIZED: Separate rendering from filtering for better performance
function HistoryUI:RenderTable()
    if not self.scrollFrame or not self.filteredHistory then return end
    
    -- Clear existing content
    self.scrollFrame:ReleaseChildren()
    
    -- Add proper table header with sorting indicators
    CreateTableHeader(self.scrollFrame, self.sortColumn, self.sortDirection)

    if #self.filteredHistory == 0 then
        E.UIUtils:ShowEmptyState(self.scrollFrame, L["NO_ITEMS_PASSED"])
        return
    end

    -- OPTIMIZED: Create rows more efficiently
    local history = self.filteredHistory
    for i, entry in ipairs(history) do
        local rowFrame = self:CreateOptimizedTableRow(entry, i % 2 == 0)
        self.scrollFrame:AddChild(rowFrame)
    end

    -- Add summary
    self:AddTableSummary()
end

-- OPTIMIZED: More efficient row creation
function HistoryUI:CreateOptimizedTableRow(entry, isEven)
    local rowFrame = AceGUI:Create("SimpleGroup")
    rowFrame:SetFullWidth(true)
    rowFrame:SetLayout("Flow")
    
    -- Reuse background texture instead of creating new ones
    local rowBg = rowFrame.frame:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints(rowFrame.frame)
    rowBg:SetTexture(isEven and 0.1 or 0.05, isEven and 0.1 or 0.05, isEven and 0.15 or 0.1, 0.3)
    
    -- Use cached column data
    local columns = {
        { key = "item", width = 280, text = entry.itemLink or entry.itemName },
        { key = "quality", width = 90, text = entry.qualityName or "Unknown" },
        { key = "decision", width = 80, text = entry.rollTypeName or "pass" },
        { key = "date", width = 140, text = entry.date or "Unknown" }
    }
    
    for _, col in ipairs(columns) do
        local label = AceGUI:Create("Label")
        label:SetText(col.text)
        label:SetWidth(col.width)
        
        if col.key == "item" and entry.quality then
            E.UIUtils:SetQualityColor(label, entry.quality)
        end
        
        rowFrame:AddChild(label)
    end
    
    return rowFrame
end

function HistoryUI:OnInitialize()
    -- Initialize cached data for performance
    self.filteredHistory = {}
    self.lastFilterHash = ""
    self.sortColumn = "date"
    self.sortDirection = "desc"
    self.currentLimit = 50
    self.currentFilter = "all"
    self.currentSearch = ""
    
    -- OPTIMIZED: Cache for avoiding repeated filtering
    self.filterCache = {}
    self.maxCacheSize = 10
end

function HistoryUI:RefreshHistory(scrollFrame)
    -- For backward compatibility, but use the new table method
    self:RefreshHistoryTable()
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

        -- Search box
    local searchLabel = AceGUI:Create("Label")
    searchLabel:SetText(L["SEARCH"] or "Search:")
    searchLabel:SetWidth(60)
    topRow:AddChild(searchLabel)

    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetWidth(200)
    searchBox:DisableButton(true)
    searchBox:SetCallback("OnTextChanged", function(widget, event, text)
        self.currentSearch = text
        self:RefreshHistoryTable()
    end)
    topRow:AddChild(searchBox)

    -- Refresh button
--[[     local refreshButton = AceGUI:Create("Button")
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
    topRow:AddChild(clearButton) ]]

    -- Create a bottom row for search
    local bottomRow = AceGUI:Create("SimpleGroup")
    bottomRow:SetFullWidth(true)
    bottomRow:SetLayout("Flow")
    controlsGroup:AddChild(bottomRow)
end
