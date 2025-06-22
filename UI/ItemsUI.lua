local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local ItemsUI = E:NewModule("ItemsUI")
E.ItemsUI = ItemsUI
local AceGUI = E.Libs.AceGUI

-- Helper function to get quality color and apply it to a widget
local function SetQualityColor(widget, quality)
    local r, g, b = unpack(E.Tracker:GetQualityColor(quality))
    widget:SetColor(r, g, b)
    return r, g, b
end

function ItemsUI:CreateItemsTab(container)
    -- Get top passed items
    local topItems = E.Tracker:GetTopRolledItems(50) -- Show top 50 items

    if #topItems == 0 then
        local label = AceGUI:Create("Label")
        label:SetText(L["NO_ITEMS_PASSED"])
        label:SetFullWidth(true)
        container:AddChild(label)
        return
    end

    -- Items list group
    local itemsGroup = AceGUI:Create("InlineGroup")
    itemsGroup:SetTitle(L["ITEMS_HANDLED_MOST_OFTEN"])
    itemsGroup:SetFullWidth(true)
    itemsGroup:SetFullHeight(true)
    itemsGroup:SetLayout("Fill")
    container:AddChild(itemsGroup)

    -- Create scrolling frame inside the group
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    itemsGroup:AddChild(scrollFrame)

    -- Add item entries
    for i, item in ipairs(topItems) do
        local itemGroup = AceGUI:Create("InlineGroup")
        itemGroup:SetTitle("")
        itemGroup:SetFullWidth(true)
        itemGroup:SetLayout("Flow")

        -- Item link/name
        local itemLabel = AceGUI:Create("InteractiveLabel")
        itemLabel:SetText(item.itemKey or item.itemName)
        itemLabel:SetWidth(300)
        local r, g, b = SetQualityColor(itemLabel, item.quality)

        -- Add tooltip if it's a real item link
        if item.itemKey and item.itemKey:match("|H.-|h") then
            itemLabel:SetCallback("OnEnter", function(widget)
                GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
                local success = pcall(GameTooltip.SetHyperlink, GameTooltip, item.itemKey)
                if success then
                    GameTooltip:Show()
                else
                    GameTooltip:Hide()
                end
            end)
            itemLabel:SetCallback("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
        itemGroup:AddChild(itemLabel)

        -- Quality
        local qualityLabel = AceGUI:Create("Label")
        qualityLabel:SetText(item.qualityName)
        qualityLabel:SetWidth(100)
        qualityLabel:SetColor(r, g, b)
        itemGroup:AddChild(qualityLabel)

        -- Count with roll breakdown
        local countLabel = AceGUI:Create("Label")
        local rollCounts = item.rollCounts or { pass = item.count or item.totalCount, need = 0, greed = 0 }
        local rollBreakdown = string.format("P:%d N:%d G:%d", rollCounts.pass, rollCounts.need, rollCounts.greed)
        countLabel:SetText(string.format("Total: %d (%s)", item.totalCount or item.count, rollBreakdown))
        countLabel:SetWidth(150)
        itemGroup:AddChild(countLabel)

        -- Last seen
        local lastSeenLabel = AceGUI:Create("Label")
        lastSeenLabel:SetText(string.format(L["LAST_SEEN"], date("%Y-%m-%d %H:%M", item.lastSeen)))
        lastSeenLabel:SetWidth(150)
        itemGroup:AddChild(lastSeenLabel)

        scrollFrame:AddChild(itemGroup)
    end
end
