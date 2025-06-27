local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local SettingsUI = E:NewModule("SettingsUI")
E.SettingsUI = SettingsUI
local AceGUI = E.Libs.AceGUI

-- Helper function to refresh the current tab (passed from TrackerUI)
local RefreshCurrentTab = nil

function SettingsUI:SetRefreshCallback(callback)
    RefreshCurrentTab = callback
end

function SettingsUI:CreateSettingsTab(container)
    -- Main settings scroll frame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    container:AddChild(scrollFrame)

    -- General Settings Group
    local generalGroup = AceGUI:Create("InlineGroup")
    generalGroup:SetTitle(L["GENERAL_SETTINGS"])
    generalGroup:SetFullWidth(true)
    generalGroup:SetLayout("Flow")
    scrollFrame:AddChild(generalGroup)

    -- Enable/Disable UltimateLoot
    local enabledCheckbox = AceGUI:Create("CheckBox")
    enabledCheckbox:SetLabel(L["ENABLE_ULTIMATELOOT"])
    enabledCheckbox:SetDescription(L["ENABLE_ULTIMATELOOT_DESC"])
    enabledCheckbox:SetValue(E:GetEnabled())
    enabledCheckbox:SetFullWidth(true)
    enabledCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        E:SetEnabled(value)
    end)
    generalGroup:AddChild(enabledCheckbox)

    -- Minimap icon toggle
    local minimapCheckbox = AceGUI:Create("CheckBox")
    minimapCheckbox:SetLabel(L["SHOW_MINIMAP_ICON"])
    minimapCheckbox:SetDescription(L["SHOW_MINIMAP_ICON_DESC"])
    minimapCheckbox:SetValue(not E.db.minimap.hide)
    minimapCheckbox:SetFullWidth(true)
    minimapCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        if E.MinimapIcon then
            if value then
                E.MinimapIcon:Show()
            else
                E.MinimapIcon:Hide()
            end
        end
    end)
    generalGroup:AddChild(minimapCheckbox)


    -- Loot Quality Threshold
    local qualityDropdown = AceGUI:Create("Dropdown")
    qualityDropdown:SetLabel(L["LOOT_QUALITY_THRESHOLD"])
    qualityDropdown:SetText(L["LOOT_QUALITY_THRESHOLD_TEXT"])

    -- Set up ordered quality list 
    local qualityOrder = { "uncommon", "rare", "epic", "legendary" }
    local qualityLabels = {
        uncommon = L["QUALITY_UNCOMMON"],
        rare = L["QUALITY_RARE"],
        epic = L["QUALITY_EPIC"],
        legendary = L["QUALITY_LEGENDARY"]
    }

    qualityDropdown:SetList(qualityLabels, qualityOrder)
    qualityDropdown:SetValue(E:GetLootQualityThreshold())
    qualityDropdown:SetFullWidth(true)
    qualityDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        E:SetLootQualityThreshold(value)
    end)
    generalGroup:AddChild(qualityDropdown)

    -- Add description as a separate label since Dropdown doesn't support SetDescription
    local qualityDesc = AceGUI:Create("Label")
    qualityDesc:SetText(L["LOOT_QUALITY_THRESHOLD_DESC"])
    qualityDesc:SetFullWidth(true)
    qualityDesc:SetFontObject(GameFontNormalSmall)
    --[[ qualityDesc:SetColor(0.8, 0.8, 0.8) ]]
    generalGroup:AddChild(qualityDesc)

    -- Pass on All override
    local passOnAllCheckbox = AceGUI:Create("CheckBox")
    passOnAllCheckbox:SetLabel(L["PASS_ON_ALL"])
    passOnAllCheckbox:SetDescription(L["PASS_ON_ALL_DESC"])
    passOnAllCheckbox:SetValue(E.db.pass_on_all or false)
    passOnAllCheckbox:SetFullWidth(true)
    passOnAllCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        E.db.pass_on_all = value
        if value then
            E:Print(L["PASS_ON_ALL_WARNING"])
        else
            E:Print("Pass on All mode disabled.")
        end
    end)
    generalGroup:AddChild(passOnAllCheckbox)

    -- Warning label if Pass on All is active
    if E.db.pass_on_all then
        local warningLabel = AceGUI:Create("Label")
        warningLabel:SetText(L["PASS_ON_ALL_WARNING"])
        warningLabel:SetFullWidth(true)
        warningLabel:SetFontObject(GameFontNormal)
        generalGroup:AddChild(warningLabel)
    end

    -- Tracker Settings Group
    local trackerGroup = AceGUI:Create("InlineGroup")
    trackerGroup:SetTitle(L["TRACKER_SETTINGS"])
    trackerGroup:SetFullWidth(true)
    trackerGroup:SetLayout("Flow")
    scrollFrame:AddChild(trackerGroup)

    -- Show notifications
    local notificationsCheckbox = AceGUI:Create("CheckBox")
    notificationsCheckbox:SetLabel(L["SHOW_NOTIFICATIONS"])
    notificationsCheckbox:SetDescription(L["SHOW_NOTIFICATIONS_DESC"])
    notificationsCheckbox:SetValue(E.db.show_notifications or true)
    notificationsCheckbox:SetFullWidth(true)
    notificationsCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        E.db.show_notifications = value
    end)
    trackerGroup:AddChild(notificationsCheckbox)

    -- Debug mode toggle
    local debugModeCheckbox = AceGUI:Create("CheckBox")
    debugModeCheckbox:SetLabel(L["ENABLE_DEBUG_MODE"])
    debugModeCheckbox:SetDescription(L["ENABLE_DEBUG_MODE_DESC"])
    debugModeCheckbox:SetValue(E.db.debug_mode or false)
    debugModeCheckbox:SetFullWidth(true)
    debugModeCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        E.db.debug_mode = value
        if value then
            E:Print("Debug mode enabled. Debug tab is now available.")
        else
            E:Print("Debug mode disabled. Debug tab will be hidden.")
        end
        -- Rebuild tabs to show/hide debug tab appropriately
        if E.TrackerUI and E.TrackerUI.RebuildTabs then
            E.TrackerUI:RebuildTabs()
        end
    end)
    trackerGroup:AddChild(debugModeCheckbox)

    -- Max history entries
    local maxHistoryEditbox = AceGUI:Create("EditBox")
    maxHistoryEditbox:SetLabel(L["MAX_HISTORY_ENTRIES"])
    maxHistoryEditbox:SetText(tostring(E.db.max_history or 1000))
    maxHistoryEditbox:SetWidth(200)
    maxHistoryEditbox:SetCallback("OnEnterPressed", function(widget, event, text)
        local num = tonumber(text)
        if num and num > 0 and num <= 10000 then
            E.db.max_history = num
            widget:SetText(tostring(num))
        else
            widget:SetText(tostring(E.db.max_history or 1000))
        end
    end)
    trackerGroup:AddChild(maxHistoryEditbox)

    -- Action Buttons Group
    local actionsGroup = AceGUI:Create("InlineGroup")
    actionsGroup:SetTitle(L["ACTIONS"])
    actionsGroup:SetFullWidth(true)
    actionsGroup:SetLayout("Flow")
    scrollFrame:AddChild(actionsGroup)

    -- Clear all data button
    local clearAllButton = AceGUI:Create("Button")
    clearAllButton:SetText(L["CLEAR_ALL_DATA"])
    clearAllButton:SetWidth(140)
    clearAllButton:SetCallback("OnClick", function()
        -- Show confirmation dialog
        StaticPopupDialogs["ULTIMATELOOT_CLEAR_ALL"] = {
            text = L["CONFIRM_CLEAR_ALL"],
            button1 = L["YES"],
            button2 = L["NO"],
            OnAccept = function()
                E.Tracker:ClearAllData()
                -- Refresh current view immediately
                if RefreshCurrentTab then
                    RefreshCurrentTab()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ULTIMATELOOT_CLEAR_ALL")
    end)
    actionsGroup:AddChild(clearAllButton)

    -- Reset settings button
    local resetButton = AceGUI:Create("Button")
    resetButton:SetText(L["RESET_SETTINGS"])
    resetButton:SetWidth(140)
    resetButton:SetCallback("OnClick", function()
        StaticPopupDialogs["ULTIMATELOOT_RESET_SETTINGS"] = {
            text = L["CONFIRM_RESET_SETTINGS"],
            button1 = L["YES"],
            button2 = L["NO"],
            OnAccept = function()
                E:ResetSettings()
                -- Refresh current view immediately
                if RefreshCurrentTab then
                    RefreshCurrentTab()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ULTIMATELOOT_RESET_SETTINGS")
    end)
    actionsGroup:AddChild(resetButton)

    -- Export/Import Group
    local dataGroup = AceGUI:Create("InlineGroup")
    dataGroup:SetTitle(L["DATA_MANAGEMENT"])
    dataGroup:SetFullWidth(true)
    dataGroup:SetLayout("Flow")
    scrollFrame:AddChild(dataGroup)

    -- Export button
    local exportButton = AceGUI:Create("Button")
    exportButton:SetText(L["EXPORT_DATA"])
    exportButton:SetWidth(140)
    exportButton:SetCallback("OnClick", function()
        local exportData = E.Tracker:ExportData()
        if exportData then
            -- Create a text display frame for export data
            self:ShowExportFrame(exportData)
        else
            E:Print(L["NO_DATA_TO_EXPORT"])
        end
    end)
    dataGroup:AddChild(exportButton)

    -- Profile info
    local profileGroup = AceGUI:Create("InlineGroup")
    profileGroup:SetTitle(L["PROFILE_INFORMATION"])
    profileGroup:SetFullWidth(true)
    profileGroup:SetLayout("Flow")
    scrollFrame:AddChild(profileGroup)

    local profileInfo = AceGUI:Create("Label")
    profileInfo:SetText(string.format(L["PROFILE_INFO_FORMAT"],
        E.data:GetCurrentProfile(),
        UnitName("player"),
        GetRealmName()))
    profileInfo:SetFullWidth(true)
    profileGroup:AddChild(profileInfo)
end

function SettingsUI:ShowExportFrame(data)
    local exportFrame = AceGUI:Create("Frame")
    exportFrame:SetTitle(L["EXPORT_DATA_TITLE"])
    exportFrame:SetWidth(600)
    exportFrame:SetHeight(400)
    exportFrame:SetLayout("Fill")

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel(L["EXPORT_DATA_LABEL"])
    editBox:SetText(data)
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(true)
    editBox:DisableButton(true)
    exportFrame:AddChild(editBox)

    exportFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
end
