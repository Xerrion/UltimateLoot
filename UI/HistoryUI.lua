local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local HistoryUI = E:NewModule("HistoryUI")
E.HistoryUI = HistoryUI
local AceGUI = E.Libs.AceGUI

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
        return L["NEED_ROLLS"]
    elseif rollTypeName == "greed" then
        return L["GREED_ROLLS"]
    else -- "pass" or nil (legacy)
        return L["PASS_ROLLS"]
    end
end

function HistoryUI:CreateHistoryTab(container)
    -- Create scrolling table
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    container:AddChild(scrollFrame)

    -- Add column headers
    self:CreateHistoryHeaders(scrollFrame)

    -- Add history entries
    self:RefreshHistory(scrollFrame)
end

function HistoryUI:CreateHistoryHeaders(scrollFrame)
    local headerGroup = AceGUI:Create("InlineGroup")
    headerGroup:SetTitle("")
    headerGroup:SetFullWidth(true)
    headerGroup:SetLayout("Flow")

    -- Item header
    local itemHeader = AceGUI:Create("Label")
    itemHeader:SetText("Item")
    itemHeader:SetWidth(250)
    itemHeader:SetFontObject(GameFontNormalLarge)
    headerGroup:AddChild(itemHeader)

    -- Quality header
    local qualityHeader = AceGUI:Create("Label")
    qualityHeader:SetText("Quality")
    qualityHeader:SetWidth(80)
    qualityHeader:SetFontObject(GameFontNormalLarge)
    headerGroup:AddChild(qualityHeader)

    -- Decision header
    local decisionHeader = AceGUI:Create("Label")
    decisionHeader:SetText(L["DECISION"])
    decisionHeader:SetWidth(60)
    decisionHeader:SetFontObject(GameFontNormalLarge)
    headerGroup:AddChild(decisionHeader)

    -- Date header
    local dateHeader = AceGUI:Create("Label")
    dateHeader:SetText("Date")
    dateHeader:SetWidth(130)
    dateHeader:SetFontObject(GameFontNormalLarge)
    headerGroup:AddChild(dateHeader)

    scrollFrame:AddChild(headerGroup)
end

function HistoryUI:RefreshHistory(scrollFrame)
    -- Clear existing entries but keep the headers (first child)
    local children = scrollFrame.children
    for i = #children, 2, -1 do
        scrollFrame:ReleaseChildren(i)
    end

    local history = E.Tracker:GetHistory(100) -- Show last 100 items

    if #history == 0 then
        local label = AceGUI:Create("Label")
        label:SetText(L["NO_ITEMS_PASSED"] or "No items have been handled yet.")
        label:SetFullWidth(true)
        scrollFrame:AddChild(label)
        return
    end

    for i, pass in ipairs(history) do
        local itemGroup = AceGUI:Create("InlineGroup")
        itemGroup:SetTitle("")
        itemGroup:SetFullWidth(true)
        itemGroup:SetLayout("Flow")

        -- Item link
        local itemLabel = AceGUI:Create("InteractiveLabel")
        itemLabel:SetText(pass.itemLink or pass.itemName)
        itemLabel:SetWidth(250)
        local r, g, b = SetQualityColor(itemLabel, pass.quality)
        itemLabel:SetCallback("OnEnter", function(widget)
            if pass.itemLink and pass.itemLink:match("|H.-|h") then
                -- Only show tooltip for real WoW item links
                GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
                local success = pcall(GameTooltip.SetHyperlink, GameTooltip, pass.itemLink)
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
        qualityLabel:SetText(pass.qualityName)
        qualityLabel:SetWidth(80)
        qualityLabel:SetColor(r, g, b)
        itemGroup:AddChild(qualityLabel)

        -- Roll Decision
        local decisionLabel = AceGUI:Create("Label")
        local rollTypeName = pass.rollTypeName or "pass" -- Default to "pass" for legacy entries
        decisionLabel:SetText(GetRollDecisionText(rollTypeName))
        decisionLabel:SetWidth(60)
        local dr, dg, db = GetRollDecisionColor(rollTypeName)
        decisionLabel:SetColor(dr, dg, db)
        itemGroup:AddChild(decisionLabel)

        -- Date
        local dateLabel = AceGUI:Create("Label")
        dateLabel:SetText(pass.date)
        dateLabel:SetWidth(130)
        itemGroup:AddChild(dateLabel)

        scrollFrame:AddChild(itemGroup)
    end
end
