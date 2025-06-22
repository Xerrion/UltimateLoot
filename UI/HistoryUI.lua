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

    -- Create header background
    local headerBg = headerFrame.frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(headerFrame.frame)
    headerBg:SetColorTexture(0.2, 0.2, 0.3, 0.8)

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

    -- Add alternating row background
    local rowBg = rowFrame.frame:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints(rowFrame.frame)
    if isEven then
        rowBg:SetColorTexture(0.1, 0.1, 0.15, 0.3)
    else
        rowBg:SetColorTexture(0.05, 0.05, 0.1, 0.5)
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

    -- Table container with scroll
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    mainGroup:AddChild(scrollFrame)

    -- Store reference for refreshing
    self.scrollFrame = scrollFrame

    -- Populate the table
    self:RefreshHistoryTable()
end

function HistoryUI:RefreshHistoryTable()
    if not self.scrollFrame then return end

    -- Clear existing content
    self.scrollFrame:ReleaseChildren()

    -- Get history data
    local history = E.Tracker:GetHistory(100) -- Show last 100 items

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
    local history = E.Tracker:GetHistory(100)
    if #history == 0 then return end

    -- Count roll types
    local counts = { pass = 0, need = 0, greed = 0 }
    for _, entry in ipairs(history) do
        local rollType = entry.rollTypeName or "pass"
        counts[rollType] = counts[rollType] + 1
    end

    -- Create summary row
    local summaryFrame = AceGUI:Create("SimpleGroup")
    summaryFrame:SetFullWidth(true)
    summaryFrame:SetLayout("Flow")

    -- Summary background
    local summaryBg = summaryFrame.frame:CreateTexture(nil, "BACKGROUND")
    summaryBg:SetAllPoints(summaryFrame.frame)
    summaryBg:SetColorTexture(0.3, 0.3, 0.4, 0.6)

    -- Summary text
    local summaryText = string.format("Showing %d items | Pass: %d | Need: %d | Greed: %d",
        #history, counts.pass, counts.need, counts.greed)

    local summaryLabel = AceGUI:Create("Label")
    summaryLabel:SetText(summaryText)
    summaryLabel:SetFullWidth(true)
    summaryLabel:SetJustifyH("CENTER")
    summaryLabel:SetColor(1, 1, 1)
    summaryLabel:SetFontObject(GameFontNormal)
    summaryFrame:AddChild(summaryLabel)

    self.scrollFrame:AddChild(summaryFrame)
end

-- Refresh function for external calls
function HistoryUI:RefreshHistory(scrollFrame)
    -- For backward compatibility, but use the new table method
    self:RefreshHistoryTable()
end
