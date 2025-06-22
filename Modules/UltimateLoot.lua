local E, L = unpack(select(2, ...)) --Import: Engine, Locales

local UltimateLoot = E:NewModule("Core", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")
E.UltimateLoot = UltimateLoot

function UltimateLoot:OnInitialize()
    -- Register slash commands
    self:RegisterChatCommand("ultimateloot", "HandleSlashCommand")
    self:RegisterChatCommand("ul", "HandleSlashCommand") -- Short alias

    E:DebugPrint("[DEBUG] UltimateLoot:OnInitialize - Registering for events")

    -- Register for UltimateLoot-specific events
    self:RegisterMessage("ULTIMATELOOT_ENABLED_CHANGED", "OnEnabledChanged")
    self:RegisterMessage("ULTIMATELOOT_THRESHOLD_CHANGED", "OnThresholdChanged")
    self:RegisterMessage("ULTIMATELOOT_ERROR", "OnError")
    self:RegisterMessage("ULTIMATELOOT_ITEM_HANDLED", "OnItemHandled")
    self:RegisterMessage("ULTIMATELOOT_EVENTS_INITIALIZED", "OnEventsInitialized")
    self:RegisterMessage("ULTIMATELOOT_PLAYER_LOGIN", "OnPlayerLogin")
    self:RegisterMessage("ULTIMATELOOT_ADDON_LOADED", "OnAddonLoaded")
    self:RegisterMessage("ULTIMATELOOT_WORLD_ENTERED", "OnWorldEntered")

    E:DebugPrint("[DEBUG] UltimateLoot:OnInitialize - Event registration complete")
end

function UltimateLoot:HandleSlashCommand(input)
    local cmd = input and input:match("^(%S*)") or ""
    if cmd == "toggle" then
        E:SetEnabled(not E:GetEnabled())
        self:PrintStatus()
    elseif cmd == "config" or cmd == "settings" then
        if E.TrackerUI then
            E.TrackerUI:ShowTracker()
            E.TrackerUI:SelectTab("settings")
        else
            E:Print("UI not available.")
        end
    elseif cmd == "tracker" or cmd == "history" then
        if E.TrackerUI then
            E.TrackerUI:ShowTracker()
        else
            E:Print("Tracker not available.")
        end
    elseif cmd == "ui" or cmd == "show" or cmd == "" then
        if E.TrackerUI then
            E.TrackerUI:ShowTracker()
        else
            E:Print("UI not available.")
        end
    elseif cmd == "debug" then
        local subCmd = input and input:match("^%S*%s+(.*)") or ""
        if E.Debug then
            E.Debug:HandleDebugCommand(subCmd)
        else
            E:Print("Debug module not available. E.Debug is: " .. tostring(E.Debug))
            E:Print("Available modules:")
            for name, module in pairs(E.modules or {}) do
                E:Print("  " .. name .. ": " .. tostring(module))
            end
        end
    elseif cmd == "debugtab" then
        if E.TrackerUI then
            E.TrackerUI:ShowTracker()
            E.TrackerUI:SelectTab("debug")
        else
            E:Print("UI not available.")
        end
    elseif cmd == "itemrules" or cmd == "rules" then
        if E.TrackerUI then
            E.TrackerUI:ShowTracker()
            E.TrackerUI:SelectTab("itemrules")
        else
            E:Print("UI not available.")
        end
    elseif cmd == "minimap" then
        local subCmd = input and input:match("^%S*%s+(.*)") or ""
        self:HandleMinimapCommand(subCmd)
    elseif cmd == "test" then
        local subCmd = input and input:match("^%S*%s+(.*)") or ""
        self:HandleTestCommand(subCmd)
    elseif cmd == "status" then
        self:ShowDetailedStatus()
    elseif cmd == "passall" or cmd == "passonall" then
        local newValue = not E.db.pass_on_all
        E.db.pass_on_all = newValue
        if newValue then
            E:Print(L["PASS_ON_ALL_WARNING"])
        else
            E:Print("Pass on All mode disabled.")
        end
    else
        E:Print("Usage: /ultimateloot [toggle|ui|config|tracker|show|rules|debug|debugtab|minimap|test|status|passall]")
        E:Print("  toggle - Enable/disable UltimateLoot")
        E:Print("  ui, show - Open the main interface")
        E:Print("  config, settings - Open the main interface on settings tab")
        E:Print("  tracker, history - Open the main interface on history tab")
        E:Print("  rules, itemrules - Open the item rules tab")
        E:Print("  debug [test|rolltest|on|off] - Debug commands and test events")
        E:Print("  debugtab - Open the main interface on debug tab")
        E:Print("  minimap [show|hide|toggle] - Control minimap icon")
        E:Print("  test [roll|rules] - Test loot roll functionality or item rules")
        E:Print("  status - Show detailed addon status")
        E:Print("  passall, passonall - Toggle Pass on All mode (overrides all rules)")
        E:Print("Aliases: /ul (short form)")
        E:Print("Current status: " .. (E:GetEnabled() and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
        local passOnAllStatus = E.db.pass_on_all and "|cffff0000Pass on All ACTIVE|r" or
            "|cff888888Pass on All disabled|r"
        E:Print("Pass on All: " .. passOnAllStatus)
    end
end

function UltimateLoot:ToggleUltimateLoot()
    E:SetEnabled(not E:GetEnabled())
    self:PrintStatus()
end

function UltimateLoot:PrintStatus()
    if E:GetEnabled() then
        E:Print("UltimateLoot is |cff00ff00ENABLED|r")
    else
        E:Print("UltimateLoot is |cffff0000DISABLED|r")
    end
end

function UltimateLoot:OnEnabledChanged(event, enabled, oldEnabled)
    E:DebugPrint("[DEBUG] UltimateLoot:OnEnabledChanged - Event received: %s -> %s", tostring(oldEnabled),
        tostring(enabled))

    -- React to enable/disable changes
    if enabled ~= oldEnabled then
        local message = enabled and
            "UltimateLoot has been |cff00ff00ENABLED|r" or
            "UltimateLoot has been |cffff0000DISABLED|r"
        E:Print(message)
    end
end

function UltimateLoot:OnThresholdChanged(event, newThreshold, oldThreshold)
    E:DebugPrint("[DEBUG] UltimateLoot:OnThresholdChanged - Event received: %s -> %s", tostring(oldThreshold),
        tostring(newThreshold))

    -- React to threshold changes
    local newName = E.QUALITY_CONSTANTS.NAMES[E.QUALITY_CONSTANTS.ORDER[newThreshold]] or newThreshold
    local oldName = E.QUALITY_CONSTANTS.NAMES[E.QUALITY_CONSTANTS.ORDER[oldThreshold]] or oldThreshold

    E:Print("Loot quality threshold changed from " .. oldName .. " to " .. newName)
end

function UltimateLoot:OnError(event, errorData)
    E:DebugPrint("[DEBUG] UltimateLoot:OnError - Event received: %s", errorData.type)

    -- Handle errors
    E:Print("|cffff0000Error:|r " .. errorData.message)

    -- Could also log to a separate error log or send to debugging addon
    if E.db and E.db.debug_mode then
        E:Print("Error context: " .. tostring(errorData.context))
        E:Print("Error type: " .. errorData.type)
    end
end

function UltimateLoot:OnItemHandled(event, handledData)
    E:DebugPrint("[DEBUG] UltimateLoot:OnItemHandled - Event received for: %s", handledData.itemName or "Unknown")

    -- Handle item decision notifications
    if E.db and E.db.show_notifications then
        local qualityName = E.QUALITY_CONSTANTS.NAMES[handledData.quality] or "Unknown"
        local actionText = handledData.action or "handled"
        E:Print(actionText .. " " .. (handledData.itemName or "Unknown Item") .. " (" .. qualityName .. ")")
    end
end

function UltimateLoot:OnEventsInitialized(event)
    E:DebugPrint("[DEBUG] UltimateLoot:OnEventsInitialized - Event system ready")
end

function UltimateLoot:OnPlayerLogin(event)
    E:DebugPrint("[DEBUG] UltimateLoot:OnPlayerLogin - Player login event received")
end

function UltimateLoot:OnAddonLoaded(event, addonName)
    E:DebugPrint("[DEBUG] UltimateLoot:OnAddonLoaded - Addon loaded: %s", addonName)
end

function UltimateLoot:OnWorldEntered(event)
    E:DebugPrint("[DEBUG] UltimateLoot:OnWorldEntered - Player entered world")
end

function UltimateLoot:HandleMinimapCommand(subCmd)
    if not E.MinimapIcon then
        E:Print("Minimap icon module not available.")
        return
    end

    if subCmd == "show" then
        E.MinimapIcon:Show()
        E:Print("Minimap icon shown.")
    elseif subCmd == "hide" then
        E.MinimapIcon:Hide()
        E:Print("Minimap icon hidden.")
    elseif subCmd == "toggle" then
        E.MinimapIcon:Toggle()
        local status = E.MinimapIcon:IsShown() and "shown" or "hidden"
        E:Print("Minimap icon " .. status .. ".")
    else
        E:Print("Minimap commands:")
        E:Print("  /ultimateloot minimap show - Show the minimap icon")
        E:Print("  /ultimateloot minimap hide - Hide the minimap icon")
        E:Print("  /ultimateloot minimap toggle - Toggle minimap icon visibility")
        local status = E.MinimapIcon:IsShown() and "|cff00ff00shown|r" or "|cffff0000hidden|r"
        E:Print("Current status: " .. status)
    end
end

function UltimateLoot:HandleTestCommand(subCmd)
    if subCmd == "roll" or subCmd == "" then
        self:TestLootRoll()
    elseif subCmd == "rules" then
        self:TestItemRules()
    else
        E:Print("Test commands:")
        E:Print("  /ultimateloot test roll - Simulate a loot roll to test functionality")
        E:Print("  /ultimateloot test rules - Test item rules functionality")
        E:Print("  /ultimateloot test - Same as 'test roll'")
    end
end

-- Simulate a loot roll for testing
function UltimateLoot:TestLootRoll()
    if not E:GetEnabled() then
        E:Print("|cffff8000Warning:|r UltimateLoot is disabled. Enable it first to test.")
        return
    end

    E:Print("Testing UltimateLoot functionality...")

    -- Test items with different qualities
    local testItems = {
        { name = "Worn Dagger", quality = 0, shouldPass = true },
        { name = "Linen Cloth", quality = 1, shouldPass = true },
        { name = "Aquamarine",  quality = 2, shouldPass = false },
        { name = "Shadowfang",  quality = 3, shouldPass = false },
        { name = "Krol Blade",  quality = 4, shouldPass = false },
        { name = "Thunderfury", quality = 5, shouldPass = false }
    }

    local threshold = E:GetLootQualityThreshold()
    local thresholdValue = E.QUALITY_CONSTANTS.ORDER[threshold] or 4

    E:Print(string.format("Current threshold: %s (quality %d)", threshold:upper(), thresholdValue))
    E:Print("Testing items against threshold...")

    for _, item in ipairs(testItems) do
        local wouldPass = item.quality <= thresholdValue
        local action = wouldPass and "|cffff0000PASS|r" or "|cff00ff00ROLL|r"
        local qualityName = E.QUALITY_CONSTANTS.NAMES[item.quality] or "Unknown"

        E:Print(string.format("  %s (%s): %s", item.name, qualityName, action))

        -- Simulate the actual event
        if wouldPass then
            -- Simulate a successful pass
            local fakeItemLink = string.format("|cff%02x%02x%02x|Hitem:0:0:0:0:0:0:0:0:80|h[%s]|h|r",
                unpack(E.QUALITY_CONSTANTS.COLORS[item.quality]), item.name)

            if E.Tracker then
                E.Tracker:TrackRoll(fakeItemLink, item.name, item.quality, 0) -- 0 = Pass
            end

            E:SendMessage("ULTIMATELOOT_ITEM_HANDLED", {
                rollID = 999,
                itemName = item.name,
                itemLink = fakeItemLink,
                quality = item.quality,
                threshold = threshold,
                thresholdValue = thresholdValue,
                action = "Passed on",
                timestamp = time(),
                isTest = true
            })
        end
    end

    E:Print("Test completed! Check the History tab to see tracked decisions.")
end

-- Test item rules functionality
function UltimateLoot:TestItemRules()
    if not E.ItemRules then
        E:Print("ItemRules module not available.")
        return
    end

    E:Print("Testing UltimateLoot item rules functionality...")

    -- Add some test rules
    E:Print("Adding test rules...")
    E.ItemRules:AddItemRule("whitelist", "Thunderfury", nil, 19019)
    E.ItemRules:AddItemRule("blacklist", "Hearthstone", nil, 6948)
    E.ItemRules:AddItemRule("always_need", "Quel'Serrar", nil, 18348)

    -- Test items that should trigger rules
    local testItems = {
        { name = "Thunderfury, Blessed Blade of the Windseeker", quality = 5, expected = "PASS" },
        { name = "Hearthstone",                                  quality = 0, expected = "NEVER_PASS" },
        { name = "Quel'Serrar",                                  quality = 4, expected = "NEED" },
        { name = "Random Item",                                  quality = 3, expected = nil }
    }

    E:Print("Testing rule evaluation:")
    for _, item in ipairs(testItems) do
        local rule, reason = E.ItemRules:CheckItemRule(item.name, nil, item.quality)
        local result = rule or "No rule"

        E:Print(string.format("  %s: %s (%s)", item.name, result, reason or "No specific rule"))
    end

    -- Clean up test rules
    E:Print("Cleaning up test rules...")
    E.ItemRules:RemoveItemRule("whitelist", "Thunderfury")
    E.ItemRules:RemoveItemRule("blacklist", "Hearthstone")
    E.ItemRules:RemoveItemRule("always_need", "Quel'Serrar")

    E:Print("Item rules test completed!")
end

-- Show comprehensive addon status
function UltimateLoot:ShowDetailedStatus()
    E:Print("=== UltimateLoot Detailed Status ===")

    -- Core status
    local enabled = E:GetEnabled()
    local threshold = E:GetLootQualityThreshold()
    local passOnAll = E.db.pass_on_all
    E:Print(string.format("Enabled: %s", enabled and "|cff00ff00YES|r" or "|cffff0000NO|r"))
    E:Print(string.format("Quality Threshold: %s", (threshold or "unknown"):upper()))
    E:Print(string.format("Pass on All: %s", passOnAll and "|cffff0000ACTIVE|r" or "|cff888888Disabled|r"))

    -- Statistics
    if E.Tracker then
        local stats = E.Tracker:GetStats()
        E:Print(string.format("Total Items Handled: %d", stats.totalHandled or 0))

        local hour1 = E.Tracker:GetRollsByTimeframe(1)
        local hour24 = E.Tracker:GetRollsByTimeframe(24)
        E:Print(string.format("Recent Activity: %d (1h) | %d (24h)", hour1.total, hour24.total))
    else
        E:Print("Tracker: |cffff0000Not Available|r")
    end

    -- Item Rules
    if E.ItemRules then
        local rulesEnabled = E.ItemRules:IsEnabled()
        E:Print(string.format("Item Rules: %s", rulesEnabled and "|cff00ff00Enabled|r" or "|cffff8000Disabled|r"))

        if rulesEnabled then
            local rules = E.ItemRules:GetRules()
            local counts = {
                blacklist = #(rules.blacklist or {}),
                whitelist = #(rules.whitelist or {}),
                always_need = #(rules.always_need or {}),
                always_greed = #(rules.always_greed or {})
            }

            if counts.blacklist + counts.whitelist + counts.always_need + counts.always_greed > 0 then
                E:Print(string.format("  Rules: Blacklist(%d) Whitelist(%d) Need(%d) Greed(%d)",
                    counts.blacklist, counts.whitelist, counts.always_need, counts.always_greed))
            else
                E:Print("  No item rules configured")
            end
        end
    else
        E:Print("Item Rules: |cffff0000Not Available|r")
    end

    -- UI Status
    if E.TrackerUI then
        local frameShown = E.TrackerUI:IsMainFrameShown()
        E:Print(string.format("Main UI: %s", frameShown and "|cff00ff00Open|r" or "|cffff8000Closed|r"))
    end

    -- Minimap Icon
    if E.MinimapIcon then
        local iconShown = E.MinimapIcon:IsShown()
        E:Print(string.format("Minimap Icon: %s", iconShown and "|cff00ff00Visible|r" or "|cffff8000Hidden|r"))
    end

    -- Debug Mode
    local debugMode = E.db.debug_mode
    E:Print(string.format("Debug Mode: %s", debugMode and "|cff00ff00ON|r" or "|cffff0000OFF|r"))

    -- Settings
    local notifications = E.db.show_notifications
    E:Print(string.format("Notifications: %s", notifications and "|cff00ff00ON|r" or "|cffff0000OFF|r"))

    E:Print("=== End Status Report ===")
end
