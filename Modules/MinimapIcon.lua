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

        local enabled = E:GetEnabled()
        local threshold = E:GetLootQualityThreshold()

        -- Title with status
        local status = enabled and E.ColorConstants:FormatText("ENABLED", "SUCCESS") or E.ColorConstants:FormatText("DISABLED", "ERROR")
        tooltip:AddLine("UltimateLoot [" .. status .. "]")

        if enabled then
            tooltip:AddLine("Threshold: " .. (threshold or "unknown"):upper(), 1, 1, 1)

            -- Show recent stats if available
            if E.Tracker then
                local stats = E.Tracker:GetStats()
                if stats and stats.totalHandled and stats.totalHandled > 0 then
                    tooltip:AddLine(" ")
                    tooltip:AddLine("Total Items Handled: " .. stats.totalHandled, 0.7, 0.7, 1)

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
    if E.Libs.LibDBIcon then
        -- Check if already registered to prevent "Already registered" error
        if not E.Libs.LibDBIcon:IsRegistered("UltimateLoot") then
            E.Libs.LibDBIcon:Register("UltimateLoot", minimapIconData, E.db.minimap)
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
    if E.Libs.LibDBIcon and E.Libs.LibDBIcon:IsRegistered("UltimateLoot") then
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
        local info = UIDropDownMenu_CreateInfo()

        if level == 1 then
            -- Toggle Enabled/Disabled
            info.text = E:GetEnabled() and "Disable UltimateLoot" or "Enable UltimateLoot"
            info.func = function()
                E:SetEnabled(not E:GetEnabled())
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)

            -- Separator
            info = UIDropDownMenu_CreateInfo()
            info.disabled = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)

            -- Open Main Window
            info = UIDropDownMenu_CreateInfo()
            info.text = "Open UltimateLoot"
            info.func = function()
                if E.TrackerUI and E.TrackerUI.ShowTracker then
                    E.TrackerUI:ShowTracker()
                else
                    E:Print("Tracker UI not available.")
                end
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)

            -- Quick threshold submenu
            info = UIDropDownMenu_CreateInfo()
            info.text = "Quality Threshold"
            info.hasArrow = true
            info.value = "threshold"
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)

            -- Separator
            info = UIDropDownMenu_CreateInfo()
            info.disabled = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)

            -- Hide minimap icon
            info = UIDropDownMenu_CreateInfo()
            info.text = "Hide Minimap Icon"
            info.func = function()
                MinimapIcon:Hide()
                E:Print("Minimap icon hidden. Use '/ultimateloot minimap show' to restore it.")
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)
        elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "threshold" then
            local thresholds = { "uncommon", "rare", "epic", "legendary" }
            local thresholdNames = {
                uncommon = "Uncommon (Green)",
                rare = "Rare (Blue)",
                epic = "Epic (Purple)",
                legendary = "Legendary (Orange)"
            }

            local currentThreshold = E:GetLootQualityThreshold()

            for _, threshold in ipairs(thresholds) do
                info = UIDropDownMenu_CreateInfo()
                info.text = thresholdNames[threshold]
                info.func = function()
                    E:SetLootQualityThreshold(threshold)
                end
                info.checked = (currentThreshold == threshold)
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end

    UIDropDownMenu_Initialize(menuFrame, InitializeMenu, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, "cursor", 3, -3)
end

function MinimapIcon:Show()
    if E.Libs.LibDBIcon and E.Libs.LibDBIcon:IsRegistered("UltimateLoot") then
        E.db.minimap.hide = false
        E.Libs.LibDBIcon:Show("UltimateLoot")
        E:DebugPrint("[DEBUG] MinimapIcon: Shown")
    else
        E:DebugPrint("[DEBUG] MinimapIcon: Cannot show - not registered or LibDBIcon unavailable")
    end
end

function MinimapIcon:Hide()
    if E.Libs.LibDBIcon and E.Libs.LibDBIcon:IsRegistered("UltimateLoot") then
        E.db.minimap.hide = true
        E.Libs.LibDBIcon:Hide("UltimateLoot")
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
    if E.Libs.LibDBIcon and E.Libs.LibDBIcon:IsRegistered("UltimateLoot") then
        return not E.db.minimap.hide
    end
    return false
end
