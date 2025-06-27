local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local StatisticsUI = E:NewModule("StatisticsUI")
E.StatisticsUI = StatisticsUI
local AceGUI = E.Libs.AceGUI

-- Using UIUtils for shared functionality

function StatisticsUI:CreateStatsTab(container)
    local stats = E.Tracker:GetStats()

    -- Overall stats
    local overallGroup = AceGUI:Create("InlineGroup")
    overallGroup:SetTitle(L["OVERALL_STATISTICS"])
    overallGroup:SetFullWidth(true)
    overallGroup:SetLayout("Flow")
    container:AddChild(overallGroup)

    local totalLabel = AceGUI:Create("Label")
    totalLabel:SetText(string.format(L["TOTAL_ITEMS_HANDLED"], stats.totalHandled or 0))
    totalLabel:SetFontObject(GameFontNormalLarge)
    totalLabel:SetFullWidth(true)
    overallGroup:AddChild(totalLabel)

    -- Roll type breakdown
    if stats.rollsByType then
        local rollTypeGroup = AceGUI:Create("InlineGroup")
        rollTypeGroup:SetTitle(L["ROLL_TYPE_BREAKDOWN"])
        rollTypeGroup:SetFullWidth(true)
        rollTypeGroup:SetLayout("Flow")
        container:AddChild(rollTypeGroup)

        local passCount = stats.rollsByType.pass or 0
        local needCount = stats.rollsByType.need or 0
        local greedCount = stats.rollsByType.greed or 0
        local total = passCount + needCount + greedCount

        if total > 0 then
            local passPercent = (passCount / total) * 100
            local needPercent = (needCount / total) * 100
            local greedPercent = (greedCount / total) * 100

            local rollBreakdown = string.format(
                L["ROLL_BREAKDOWN_FORMAT"],
                passCount, passPercent, needCount, needPercent, greedCount, greedPercent
            )

            local rollLabel = AceGUI:Create("Label")
            rollLabel:SetText(rollBreakdown)
            rollLabel:SetFullWidth(true)
            rollTypeGroup:AddChild(rollLabel)
        else
            E.UIUtils:ShowEmptyState(rollTypeGroup, L["NO_ROLL_DATA"])
        end
    end

    -- Timeframe stats
    local timeGroup = AceGUI:Create("InlineGroup")
    timeGroup:SetTitle(L["RECENT_ACTIVITY"])
    timeGroup:SetFullWidth(true)
    timeGroup:SetLayout("Flow")
    container:AddChild(timeGroup)

    local hour1 = E.Tracker:GetRollsByTimeframe(1)
    local hour24 = E.Tracker:GetRollsByTimeframe(24)
    local hour168 = E.Tracker:GetRollsByTimeframe(168) -- 7 days

    local timeStats = string.format(
        "%s\n%s\n%s",
        string.format(L["LAST_HOUR"], hour1.total),
        string.format(L["LAST_24_HOURS"], hour24.total),
        string.format(L["LAST_7_DAYS"], hour168.total)
    )
    local timeLabel = AceGUI:Create("Label")
    timeLabel:SetText(timeStats)
    timeLabel:SetFullWidth(true)
    timeGroup:AddChild(timeLabel)

    -- Quality breakdown
    local qualityGroup = AceGUI:Create("InlineGroup")
    qualityGroup:SetTitle(L["QUALITY_BREAKDOWN"])
    qualityGroup:SetFullWidth(true)
    qualityGroup:SetLayout("Flow")
    container:AddChild(qualityGroup)

    for quality = 2, 5 do -- Only show uncommon and above
        local rollData = stats.rollsByQuality and stats.rollsByQuality[quality] or { pass = 0, need = 0, greed = 0 }
        local totalForQuality = rollData.pass + rollData.need + rollData.greed
        local qualityLabel = AceGUI:Create("Label")
        local qualityName = E.Tracker:GetQualityName(quality)

        if totalForQuality > 0 then
            local percentage = (totalForQuality / (stats.totalHandled or 1)) * 100
            local breakdown = string.format(L["ROLL_STATS_FORMAT"], rollData.pass, rollData.need, rollData.greed)
            qualityLabel:SetText(string.format(L["QUALITY_STATS_FORMAT"], qualityName, totalForQuality, percentage,
                breakdown))
            E.UIUtils:SetQualityColor(qualityLabel, quality)
        else
            qualityLabel:SetText(string.format(L["QUALITY_NO_DATA_FORMAT"], qualityName))
            qualityLabel:SetColor(0.5, 0.5, 0.5) -- Gray out zero counts
        end

        qualityLabel:SetFullWidth(true)
        qualityGroup:AddChild(qualityLabel)
    end
end
