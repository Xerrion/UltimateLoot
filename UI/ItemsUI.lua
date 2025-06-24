local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local ItemsUI = E:NewModule("ItemsUI")
E.ItemsUI = ItemsUI
local AceGUI = E.Libs.AceGUI

-- Using UIUtils for shared functionality

function ItemsUI:CreateItemsTab(container)
    -- Get top passed items
    local topItems = E.Tracker:GetTopRolledItems(50) -- Show top 50 items

    if #topItems == 0 then
        E.UIUtils:ShowEmptyState(container, L["NO_ITEMS_PASSED"])
        return
    end

    -- Items list group
    local itemsGroup = AceGUI:Create("InlineGroup")
    itemsGroup:SetTitle(L["ITEMS_HANDLED_MOST_OFTEN"])
    itemsGroup:SetFullWidth(true)
    itemsGroup:SetFullHeight(true)
    itemsGroup:SetLayout("Fill")
    container:AddChild(itemsGroup)

    -- Create scrolling frame inside the group using UIUtils
    local scrollFrame = E.UIUtils:CreateScrollFrame(itemsGroup)

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
        local r, g, b = E.UIUtils:SetQualityColor(itemLabel, item.quality)

        -- Add tooltip if it's a real item link using UIUtils
        if item.itemKey and item.itemKey:match("|H.-|h") then
            E.UIUtils:AddItemTooltip(itemLabel, item.itemKey)
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
        local rollBreakdown = string.format(L["ROLL_STATS_FORMAT"], rollCounts.pass, rollCounts.need, rollCounts.greed)
        countLabel:SetText(string.format(L["TOTAL_WITH_ROLLS_FORMAT"], item.totalCount or item.count, rollBreakdown))
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
