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

function HistoryUI:CreateHistoryTab(container)
    -- Create scrolling table
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    container:AddChild(scrollFrame)

    -- Add history entries
    self:RefreshHistory(scrollFrame)
end

function HistoryUI:RefreshHistory(scrollFrame)
    -- Clear existing entries except the button
    local children = scrollFrame.children
    for i = #children, 2, -1 do
        scrollFrame:ReleaseChildren(i)
    end

    local history = E.Tracker:GetHistory(100) -- Show last 100 items

    if #history == 0 then
        local label = AceGUI:Create("Label")
        label:SetText("No items have been passed yet.")
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
        itemLabel:SetWidth(300)
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
        qualityLabel:SetWidth(100)
        qualityLabel:SetColor(r, g, b)
        itemGroup:AddChild(qualityLabel)

        -- Date
        local dateLabel = AceGUI:Create("Label")
        dateLabel:SetText(pass.date)
        dateLabel:SetWidth(150)
        itemGroup:AddChild(dateLabel)

        scrollFrame:AddChild(itemGroup)
    end
end
