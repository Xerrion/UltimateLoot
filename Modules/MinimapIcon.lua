local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local MinimapIcon = E:NewModule("MinimapIcon", "AceEvent-3.0")
E.MinimapIcon = MinimapIcon

-- Create the minimap icon data
local minimapIconData = {
    type = "data source",
    text = "UltimateLoot",
    icon = "Interface\\Icons\\inv_misc_desecrated_platehelm", -- Gold coin icon
    OnClick = function(self, button)
        if button == "LeftButton" then
            -- Left click: Open/Close main window
            if E.TrackerUI and E.TrackerUI.ToggleMainFrame then
                E.TrackerUI:ToggleMainFrame()
            else
                E:Print("Tracker UI not available yet.")
            end
        elseif button == "RightButton" then
            -- Right click: Show context menu
            MinimapIcon:ShowContextMenu()
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end

        -- Cache values to avoid multiple function calls
        local enabled = E:GetEnabled()
        local status = enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
        tooltip:AddLine("UltimateLoot [" .. status .. "]")

        if enabled then
            local threshold = E:GetLootQualityThreshold()
            tooltip:AddLine("Threshold: " .. (threshold or "unknown"):upper(), 1, 1, 1)

            -- Show recent stats if available
            if E.Tracker then
                local stats = E.Tracker:GetStats()
                if stats and stats.totalHandled and stats.totalHandled > 0 then
                    tooltip:AddLine(" ")
                    tooltip:AddLine("Total Items Handled: " .. stats.totalHandled, 0.7, 0.7, 1)

                    -- Cache timeframe stats to avoid duplicate calculations
                    local hour1 = E.Tracker:GetRollsByTimeframe(1)
                    local hour24 = E.Tracker:GetRollsByTimeframe(24)
                    if hour1.total > 0 or hour24.total > 0 then
                        tooltip:AddLine("Last hour: " .. hour1.total .. " | Last 24h: " .. hour24.total, 0.7, 0.7, 1)
                    end
                end
            end
        else
            tooltip:AddLine("UltimateLoot is disabled", 1, 0.5, 0.5)
        end

        tooltip:AddLine(" ")
        tooltip:AddLine("|cffeda55fLeft-click|r to open window", 0.2, 1, 0.2)
        tooltip:AddLine("|cffeda55fRight-click|r for options", 0.2, 1, 0.2)
    end,
}

function MinimapIcon:OnInitialize()
    -- Register the minimap icon
    local LibDBIcon = E.Libs.LibDBIcon
    if LibDBIcon then
        -- Check if already registered to prevent "Already registered" error
        if not LibDBIcon:IsRegistered("UltimateLoot") then
            LibDBIcon:Register("UltimateLoot", minimapIconData, E.db.minimap)
            E:DebugPrint("[DEBUG] MinimapIcon: Registered with LibDBIcon")
        else
            E:DebugPrint("[DEBUG] MinimapIcon: Already registered, skipping registration")
        end
    else
        E:Print("LibDBIcon not available - minimap icon disabled")
    end
end

function MinimapIcon:OnEnable()
    -- Register for events to update tooltip
    self:RegisterMessage("ULTIMATELOOT_ENABLED_CHANGED", "UpdateIcon")
    self:RegisterMessage("ULTIMATELOOT_THRESHOLD_CHANGED", "UpdateIcon")
    self:RegisterMessage("ULTIMATELOOT_ITEM_TRACKED", "UpdateIcon")
end

function MinimapIcon:UpdateIcon()
    -- Force tooltip refresh by updating the icon slightly
    local LibDBIcon = E.Libs.LibDBIcon
    if LibDBIcon and LibDBIcon:IsRegistered("UltimateLoot") then
        -- The tooltip will be refreshed on next hover
        E:DebugPrint("[DEBUG] MinimapIcon: Icon updated")
    end
end

function MinimapIcon:ShowContextMenu()
    -- Safety check
    if not E or not E.GetEnabled or not E.SetEnabled then
        E:Print("UltimateLoot core not ready yet.")
        return
    end

    local menuFrame = CreateFrame("Frame", "UltimateLootMinimapMenu", UIParent, "UIDropDownMenuTemplate")

    local function InitializeMenu(self, level)
        if level == 1 then
            -- Toggle Enabled/Disabled
            local info = UIDropDownMenu_CreateInfo()
            info.text = E:GetEnabled() and "Disable UltimateLoot" or "Enable UltimateLoot"
            info.func = function()
                E:SetEnabled(not E:GetEnabled())
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)

            -- Separator
            local sepInfo = UIDropDownMenu_CreateInfo()
            sepInfo.disabled = true
            sepInfo.notCheckable = true
            UIDropDownMenu_AddButton(sepInfo)

            -- Open Main Window
            local openInfo = UIDropDownMenu_CreateInfo()
            openInfo.text = "Open UltimateLoot"
            openInfo.func = function()
                if E.TrackerUI and E.TrackerUI.ShowTracker then
                    E.TrackerUI:ShowTracker()
                else
                    E:Print("Tracker UI not available.")
                end
            end
            openInfo.notCheckable = true
            UIDropDownMenu_AddButton(openInfo)

            -- Quick threshold submenu
            local thresholdInfo = UIDropDownMenu_CreateInfo()
            thresholdInfo.text = "Quality Threshold"
            thresholdInfo.hasArrow = true
            thresholdInfo.value = "threshold"
            thresholdInfo.notCheckable = true
            UIDropDownMenu_AddButton(thresholdInfo)

            -- Separator
            local sepInfo2 = UIDropDownMenu_CreateInfo()
            sepInfo2.disabled = true
            sepInfo2.notCheckable = true
            UIDropDownMenu_AddButton(sepInfo2)

            -- Hide minimap icon
            local hideInfo = UIDropDownMenu_CreateInfo()
            hideInfo.text = "Hide Minimap Icon"
            hideInfo.func = function()
                MinimapIcon:Hide()
                E:Print("Minimap icon hidden. Use '/ultimateloot minimap show' to restore it.")
            end
            hideInfo.notCheckable = true
            UIDropDownMenu_AddButton(hideInfo)
        elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "threshold" then
            local thresholds = { "poor", "common", "uncommon", "rare", "epic", "legendary" }
            local thresholdNames = {
                poor = "Poor (Gray)",
                common = "Common (White)",
                uncommon = "Uncommon (Green)",
                rare = "Rare (Blue)",
                epic = "Epic (Purple)",
                legendary = "Legendary (Orange)"
            }

            local currentThreshold = E:GetLootQualityThreshold()

            for _, threshold in ipairs(thresholds) do
                local thresholdItemInfo = UIDropDownMenu_CreateInfo()
                thresholdItemInfo.text = thresholdNames[threshold]
                thresholdItemInfo.func = function()
                    E:SetLootQualityThreshold(threshold)
                end
                thresholdItemInfo.checked = (currentThreshold == threshold)
                UIDropDownMenu_AddButton(thresholdItemInfo, level)
            end
        end
    end

    UIDropDownMenu_Initialize(menuFrame, InitializeMenu, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, "cursor", 3, -3)
end

function MinimapIcon:Show()
    local LibDBIcon = E.Libs.LibDBIcon
    if LibDBIcon and LibDBIcon:IsRegistered("UltimateLoot") then
        E.db.minimap.hide = false
        LibDBIcon:Show("UltimateLoot")
        E:DebugPrint("[DEBUG] MinimapIcon: Shown")
    else
        E:DebugPrint("[DEBUG] MinimapIcon: Cannot show - not registered or LibDBIcon unavailable")
    end
end

function MinimapIcon:Hide()
    local LibDBIcon = E.Libs.LibDBIcon
    if LibDBIcon and LibDBIcon:IsRegistered("UltimateLoot") then
        E.db.minimap.hide = true
        LibDBIcon:Hide("UltimateLoot")
        E:DebugPrint("[DEBUG] MinimapIcon: Hidden")
    else
        E:DebugPrint("[DEBUG] MinimapIcon: Cannot hide - not registered or LibDBIcon unavailable")
    end
end

function MinimapIcon:Toggle()
    if E.db.minimap.hide then
        self:Show()
    else
        self:Hide()
    end
end

function MinimapIcon:IsShown()
    local LibDBIcon = E.Libs.LibDBIcon
    if LibDBIcon and LibDBIcon:IsRegistered("UltimateLoot") then
        return not E.db.minimap.hide
    end
    return false
end
