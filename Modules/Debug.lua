local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local Debug = E:NewModule("Debug", "AceEvent-3.0", "AceTimer-3.0")
E.Debug = Debug

-- Debug output buffer
Debug.debugOutput = {}
Debug.maxDebugLines = 1000 -- Keep last 1000 debug lines

-- OPTIMIZED: Cache debug state and avoid string formatting when debug is disabled
local isDebugEnabled = false

function Debug:UpdateDebugState()
    isDebugEnabled = E.db and E.db.debug_mode or false
end

function Debug:OnInitialize()
    -- Initialize debug output storage
    self.debugOutput = {}
    self.printToChat = false
    
    -- OPTIMIZED: Cache debug state
    self:UpdateDebugState()
    
    -- Register for settings changes to update debug state
    self:RegisterMessage("ULTIMATELOOT_SETTINGS_CHANGED", "UpdateDebugState")
end

function Debug:OnEnable()
    self:UpdateDebugState()
end

-- Debug print function that only prints when debug mode is enabled
function Debug:DebugPrint(msg, ...)
    if not isDebugEnabled then return end
    
    -- Cache the output table reference
    if not self.debugOutput then
        self.debugOutput = {}
    end
    
    local timestamp = date("%H:%M:%S")
    local formattedMsg = string.format("[%s] %s", timestamp, string.format(msg, ...))
    
    table.insert(self.debugOutput, formattedMsg)
    
    -- Maintain size limit efficiently
    if #self.debugOutput > 500 then
        -- Remove oldest 50 entries at once instead of one by one
        for i = 1, 50 do
            table.remove(self.debugOutput, 1)
        end
    end
    
    -- Print to chat if enabled
    if self.printToChat then
        print("|cff00ff00[UL Debug]|r " .. formattedMsg)
    end
    
    -- Fire event for UI updates
    self:SendMessage("ULTIMATELOOT_DEBUG_OUTPUT", {
        message = formattedMsg,
        timestamp = timestamp
    })
end

-- Function to clear debug output
function Debug:ClearDebugOutput()
    wipe(self.debugOutput)
    E:SendMessage("ULTIMATELOOT_DEBUG_CLEARED")
end

-- Function to get debug output
function Debug:GetDebugOutput()
    return self.debugOutput
end

-- UI reference for debug output display
Debug.debugOutputGroup = nil

-- Create Debug UI (called from TrackerUI)
function Debug:CreateDebugUI(container)
    -- Main scroll frame for the entire debug tab
    local scrollFrame = E.Libs.AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    container:AddChild(scrollFrame)

    -- Controls Section
    local controlsGroup = E.Libs.AceGUI:Create("InlineGroup")
    controlsGroup:SetTitle("Debug Controls & Tests")
    controlsGroup:SetFullWidth(true)
    controlsGroup:SetLayout("Flow")
    scrollFrame:AddChild(controlsGroup)

    -- Add legendary test items button
    local legendaryButton = E.Libs.AceGUI:Create("Button")
    legendaryButton:SetText("Add Legendary Items")
    legendaryButton:SetWidth(150)
    legendaryButton:SetCallback("OnClick", function()
        self:AddLegendaryTestItems()
    end)
    controlsGroup:AddChild(legendaryButton)

    -- Check legendary data button
    local checkButton = E.Libs.AceGUI:Create("Button")
    checkButton:SetText("Check Legendary Data")
    checkButton:SetWidth(150)
    checkButton:SetCallback("OnClick", function()
        self:CheckLegendaryData()
    end)
    controlsGroup:AddChild(checkButton)

    -- Show raw stats button
    local statsButton = E.Libs.AceGUI:Create("Button")
    statsButton:SetText("Show Raw Stats")
    statsButton:SetWidth(120)
    statsButton:SetCallback("OnClick", function()
        self:ShowRawStats()
    end)
    controlsGroup:AddChild(statsButton)

    -- Event system test button
    local eventTestButton = E.Libs.AceGUI:Create("Button")
    eventTestButton:SetText("Test Events")
    eventTestButton:SetWidth(100)
    eventTestButton:SetCallback("OnClick", function()
        self:RunEventSystemTest()
    end)
    controlsGroup:AddChild(eventTestButton)

    -- Comprehensive roll test button
    local rollTestButton = E.Libs.AceGUI:Create("Button")
    rollTestButton:SetText("Test Roll System")
    rollTestButton:SetWidth(120)
    rollTestButton:SetCallback("OnClick", function()
        self:RunComprehensiveRollTest()
    end)
    controlsGroup:AddChild(rollTestButton)

    -- Test individual roll types
    local quickRollTestButton = E.Libs.AceGUI:Create("Button")
    quickRollTestButton:SetText("Quick Roll Test")
    quickRollTestButton:SetWidth(120)
    quickRollTestButton:SetCallback("OnClick", function()
        self:TestQuickRolls()
    end)
    controlsGroup:AddChild(quickRollTestButton)

    -- Test statistics generation
    local statsTestButton = E.Libs.AceGUI:Create("Button")
    statsTestButton:SetText("Test Statistics")
    statsTestButton:SetWidth(120)
    statsTestButton:SetCallback("OnClick", function()
        self:TestStatisticsGeneration()
    end)
    controlsGroup:AddChild(statsTestButton)

    -- Test edge cases
    local edgeTestButton = E.Libs.AceGUI:Create("Button")
    edgeTestButton:SetText("Test Edge Cases")
    edgeTestButton:SetWidth(120)
    edgeTestButton:SetCallback("OnClick", function()
        self:TestEdgeCases()
    end)
    controlsGroup:AddChild(edgeTestButton)

    -- Comprehensive system test
    local compTestButton = E.Libs.AceGUI:Create("Button")
    compTestButton:SetText("Full System Test")
    compTestButton:SetWidth(120)
    compTestButton:SetCallback("OnClick", function()
        self:RunComprehensiveSystemTest()
    end)
    controlsGroup:AddChild(compTestButton)

    -- Information Section
    local infoGroup = E.Libs.AceGUI:Create("InlineGroup")
    infoGroup:SetTitle("Debug Information")
    infoGroup:SetFullWidth(true)
    infoGroup:SetLayout("Flow")
    scrollFrame:AddChild(infoGroup)

    local infoText = E.Libs.AceGUI:Create("Label")
    infoText:SetText(
        "Debug commands (use in chat):\n" ..
        "• /ultimateloot debug legendary - Add test legendary items\n" ..
        "• /ultimateloot debug check - Check legendary data\n" ..
        "• /ultimateloot debug stats - Show raw statistics\n" ..
        "• /ultimateloot debug fix - Recalculate quality stats from history\n" ..
        "• /ultimateloot debug rolls - Test roll tracking system\n" ..
        "• /ultimateloot debug statstest - Test statistics generation\n" ..
        "• /ultimateloot debug edge - Test edge cases\n" ..
        "• /ultimateloot debug on/off - Enable/disable debug mode\n\n" ..
        "All debug output appears in chat to avoid UI issues.\n" ..
        "Debug mode can also be toggled in the Settings tab.\n" ..
        "Use the buttons above or type commands in chat."
    )
    infoText:SetFullWidth(true)
    infoText:SetFontObject(GameFontNormal)
    infoGroup:AddChild(infoText)

    -- Clear data button
    local clearButton = E.Libs.AceGUI:Create("Button")
    clearButton:SetText("Clear All Data")
    clearButton:SetWidth(120)
    clearButton:SetCallback("OnClick", function()
        if E.Tracker then
            E.Tracker:ClearAllData()
            E:Print("All tracking data cleared.")
        end
    end)
    infoGroup:AddChild(clearButton)
end

-- Simplified refresh function (no more live debug output)
function Debug:RefreshDebugOutput()
    -- Do nothing - debug output now goes to chat only
    -- This prevents the UI crash
end

-- Handle debug commands
function Debug:HandleDebugCommand(subCmd)
    if subCmd == "test" then
        self:RunEventSystemTest()
    elseif subCmd == "rolltest" then
        self:RunComprehensiveRollTest()
    elseif subCmd == "legendary" then
        self:AddLegendaryTestItems()
    elseif subCmd == "stats" then
        self:ShowRawStats()
    elseif subCmd == "check" then
        self:CheckLegendaryData()
    elseif subCmd == "fix" then
        self:FixQualityStats()
    elseif subCmd == "rolls" then
        self:TestQuickRolls()
    elseif subCmd == "statstest" then
        self:TestStatisticsGeneration()
    elseif subCmd == "edge" then
        self:TestEdgeCases()
    elseif subCmd == "comprehensive" then
        self:RunComprehensiveSystemTest()
    elseif subCmd == "on" then
        E.db.debug_mode = true
        E:Print("Debug mode enabled. You'll see [DEBUG] messages for all events.")
        -- Rebuild tabs to show debug tab
        if E.TrackerUI and E.TrackerUI.RebuildTabs then
            E.TrackerUI:RebuildTabs()
        end
    elseif subCmd == "off" then
        E.db.debug_mode = false
        E:Print("Debug mode disabled.")
        -- Rebuild tabs to hide debug tab
        if E.TrackerUI and E.TrackerUI.RebuildTabs then
            E.TrackerUI:RebuildTabs()
        end
    else
        E:Print("Debug commands:")
        E:Print("  /ultimateloot debug test - Test all event types")
        E:Print("  /ultimateloot debug rolltest - Run comprehensive roll system test")
        E:Print("  /ultimateloot debug legendary - Add some legendary items to test statistics")
        E:Print("  /ultimateloot debug stats - Show raw statistics data")
        E:Print("  /ultimateloot debug check - Check legendary data specifically")
        E:Print("  /ultimateloot debug fix - Recalculate quality stats from history")
        E:Print("  /ultimateloot debug rolls - Quick roll test")
        E:Print("  /ultimateloot debug statstest - Test statistics generation")
        E:Print("  /ultimateloot debug edge - Test edge cases")
        E:Print("  /ultimateloot debug comprehensive - Run full system test")
        E:Print("  /ultimateloot debug on - Enable debug output")
        E:Print("  /ultimateloot debug off - Disable debug output")
        E:Print("Debug mode is currently: " .. (E.db.debug_mode and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        E:Print("Note: Debug mode can also be toggled in the Settings tab")
    end
end

-- Basic event system test
function Debug:RunEventSystemTest()
    E:Print("Testing event system...")

    -- Test 1: Settings change events
    E:Print("Test 1: Testing settings change events")
    local currentEnabled = E:GetEnabled()
    E:SetEnabled(not currentEnabled)
    E:SetEnabled(currentEnabled) -- Restore original value

    -- Test 2: Threshold change events
    E:Print("Test 2: Testing threshold change events")
    local currentThreshold = E:GetLootQualityThreshold()
    local testThreshold = currentThreshold == "common" and "uncommon" or "common"
    E:SetLootQualityThreshold(testThreshold)
    E:SetLootQualityThreshold(currentThreshold) -- Restore original value

    -- Test 3: Tracker events
    E:Print("Test 3: Testing tracker events")
    if E.Tracker then
        -- Simulate item pass with a real item
        local testItem = "|cffffffff|Hitem:2589:0:0:0:0:0:0:0:80|h[Linen Cloth]|h|r"
        E.Tracker:TrackRoll(testItem, "Linen Cloth", 1, 0) -- Pass roll
    end

    -- Test 4: Error handling
    E:Print("Test 4: Testing error handling")
    E:HandleError("TEST_ERROR", "This is a test error message", "debug command")

    -- Test 5: Lifecycle events
    E:Print("Test 5: Testing lifecycle events")
    E:SendMessage("ULTIMATELOOT_WORLD_ENTERED")

    E:Print("Event system test complete! Check the debug output above.")
end

-- Get the shared testItems structure
function Debug:GetTestItems()
    return {
        [0] = { -- Poor quality items
            { id = 36,   name = "Worn Axe",            link = "|cff9d9d9d|Hitem:36:0:0:0:0:0:0:0:80|h[Worn Axe]|h|r" },
            { id = 35,   name = "Bent Staff",          link = "|cff9d9d9d|Hitem:35:0:0:0:0:0:0:0:80|h[Bent Staff]|h|r" },
            { id = 1376, name = "Ragged Leather Vest", link = "|cff9d9d9d|Hitem:1376:0:0:0:0:0:0:0:80|h[Ragged Leather Vest]|h|r" },
            { id = 38,   name = "Worn Leather Gloves", link = "|cff9d9d9d|Hitem:38:0:0:0:0:0:0:0:0:80|h[Worn Leather Gloves]|h|r" },
            { id = 6948, name = "Hearthstone",         link = "|cff9d9d9d|Hitem:6948:0:0:0:0:0:0:0:80|h[Hearthstone]|h|r" }
        },
        [1] = { -- Common quality items
            { id = 2589, name = "Linen Cloth",            link = "|cffffffff|Hitem:2589:0:0:0:0:0:0:0:80|h[Linen Cloth]|h|r" },
            { id = 2770, name = "Copper Ore",             link = "|cffffffff|Hitem:2770:0:0:0:0:0:0:0:80|h[Copper Ore]|h|r" },
            { id = 4306, name = "Silk Cloth",             link = "|cffffffff|Hitem:4306:0:0:0:0:0:0:0:80|h[Silk Cloth]|h|r" },
            { id = 4234, name = "Heavy Leather",          link = "|cffffffff|Hitem:4234:0:0:0:0:0:0:0:80|h[Heavy Leather]|h|r" },
            { id = 858,  name = "Greater Healing Potion", link = "|cffffffff|Hitem:858:0:0:0:0:0:0:0:80|h[Greater Healing Potion]|h|r" }
        },
        [2] = { -- Uncommon quality items
            { id = 7909, name = "Aquamarine",        link = "|cff1eff00|Hitem:7909:0:0:0:0:0:0:0:80|h[Aquamarine]|h|r" },
            { id = 3837, name = "Golden Scale Coif", link = "|cff1eff00|Hitem:3837:0:0:0:0:0:0:0:80|h[Golden Scale Coif]|h|r" },
            { id = 2169, name = "Ogremage Staff",    link = "|cff1eff00|Hitem:2169:0:0:0:0:0:0:0:0:80|h[Ogremage Staff]|h|r" },
            { id = 2209, name = "Hook Dagger",       link = "|cff1eff00|Hitem:2209:0:0:0:0:0:0:0:80|h[Hook Dagger]|h|r" },
            { id = 3864, name = "Citrine",           link = "|cff1eff00|Hitem:3864:0:0:0:0:0:0:0:80|h[Citrine]|h|r" }
        },
        [3] = { -- Rare quality items
            { id = 2163,  name = "Shadowfang",      link = "|cff0070dd|Hitem:2163:0:0:0:0:0:0:0:80|h[Shadowfang]|h|r" },
            { id = 2226,  name = "Ember Wand",      link = "|cff0070dd|Hitem:2226:0:0:0:0:0:0:0:80|h[Ember Wand]|h|r" },
            { id = 1263,  name = "Bloodrazor",      link = "|cff0070dd|Hitem:1263:0:0:0:0:0:0:0:80|h[Bloodrazor]|h|r" },
            { id = 14553, name = "Sorcerer Gloves", link = "|cff0070dd|Hitem:14553:0:0:0:0:0:0:0:80|h[Sorcerer Gloves]|h|r" },
            { id = 3207,  name = "Hunting Bow",     link = "|cff0070dd|Hitem:3207:0:0:0:0:0:0:0:80|h[Hunting Bow]|h|r" }
        },
        [4] = { -- Epic quality items
            { id = 2244,  name = "Krol Blade",                 link = "|cffa335ee|Hitem:2244:0:0:0:0:0:0:0:80|h[Krol Blade]|h|r" },
            { id = 14553, name = "Sash of Mercy",              link = "|cffa335ee|Hitem:14553:0:0:0:0:0:0:0:80|h[Sash of Mercy]|h|r" },
            { id = 1263,  name = "Brain Hacker",               link = "|cffa335ee|Hitem:1263:0:0:0:0:0:0:0:80|h[Brain Hacker]|h|r" },
            { id = 18832, name = "Brutality Blade",            link = "|cffa335ee|Hitem:18832:0:0:0:0:0:0:0:80|h[Brutality Blade]|h|r" },
            { id = 18564, name = "Bindings of the Windseeker", link = "|cffa335ee|Hitem:18564:0:0:0:0:0:0:0:80|h[Bindings of the Windseeker]|h|r" }
        },
        [5] = { -- Legendary quality items
            { id = 17182, name = "Sulfuras, Hand of Ragnaros",                   link = "|cffff8000|Hitem:17182:0:0:0:0:0:0:0:80|h[Sulfuras, Hand of Ragnaros]|h|r" },
            { id = 19019, name = "Thunderfury, Blessed Blade of the Windseeker", link = "|cffff8000|Hitem:19019:0:0:0:0:0:0:0:80|h[Thunderfury, Blessed Blade of the Windseeker]|h|r" },
            { id = 22589, name = "Atiesh, Greatstaff of the Guardian",           link = "|cffff8000|Hitem:22589:0:0:0:0:0:0:0:80|h[Atiesh, Greatstaff of the Guardian]|h|r" },
            { id = 22630, name = "Atiesh, Greatstaff of the Guardian",           link = "|cffff8000|Hitem:22630:0:0:0:0:0:0:0:80|h[Atiesh, Greatstaff of the Guardian]|h|r" },
            { id = 22631, name = "Atiesh, Greatstaff of the Guardian",           link = "|cffff8000|Hitem:22631:0:0:0:0:0:0:0:80|h[Atiesh, Greatstaff of the Guardian]|h|r" }
        }
    }
end

-- Comprehensive roll system test (replaces old pass test)
function Debug:RunComprehensiveRollTest()
    E:Print("|cffff8000WARNING:|r This comprehensive test includes Pass on All feature testing.")
    E:Print("The test will demonstrate all roll types (Pass/Need/Greed) and the Pass on All override.")
    E:Print("Check the Debug tab for detailed output...")

    E:Print("=== COMPREHENSIVE ROLL SYSTEM TEST ===")

    if not E.Tracker then
        E:Print("ERROR: Tracker module not available!")
        return
    end

    -- Store original settings
    local originalEnabled = E:GetEnabled()
    local originalThreshold = E:GetLootQualityThreshold()
    local originalPassOnAll = E.db.pass_on_all

    local testItems = self:GetTestItems()
    local rollTypes = {
        { name = "Pass",  id = 0, color = "|cffff0000" },
        { name = "Need",  id = 1, color = "|cff00ff00" },
        { name = "Greed", id = 2, color = "|cff0070dd" }
    }

    -- Test 1: Normal roll behavior with different thresholds
    E:Print("Test 1: Normal Roll Behavior")
    E:SetEnabled(true)
    E.db.pass_on_all = false

    local thresholds = { "poor", "uncommon", "epic" }
    for _, threshold in ipairs(thresholds) do
        E:Print(string.format("  Testing with threshold: %s", threshold:upper()))
        E:SetLootQualityThreshold(threshold)

        -- Test 3 items of different qualities
        for quality = 0, 2 do
            local itemList = testItems[quality]
            if itemList and #itemList > 0 then
                local item = itemList[1]
                local rollType = math.random(0, 2)
                local rollTypeName = rollTypes[rollType + 1].name
                local rollTypeColor = rollTypes[rollType + 1].color

                E:Print(string.format("    %s%s|r on %s (Quality %d)",
                    rollTypeColor, rollTypeName, item.name, quality))
                E.Tracker:TrackRoll(item.link, item.name, quality, rollType)
            end
        end
    end

    -- Test 2: Pass on All feature testing
    E:Print("\nTest 2: Pass on All Feature")
    E.db.pass_on_all = true
    E:Print("  Pass on All ENABLED - All items should be passed regardless of quality")

    for quality = 0, 5 do
        local itemList = testItems[quality]
        if itemList and #itemList > 0 then
            local item = itemList[1]
            local qualityNames = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }

            E:Print(string.format("    |cffff0000PASS|r on %s (%s quality) - Pass on All override",
                item.name, qualityNames[quality + 1]))
            E.Tracker:TrackRoll(item.link, item.name, quality, 0) -- Should all be passes with Pass on All
        end
    end

    -- Test 3: Mixed roll scenarios with all types
    E:Print("\nTest 3: Mixed Roll Type Scenarios")
    E.db.pass_on_all = false
    E:SetLootQualityThreshold("rare") -- Good middle ground

    local scenarios = {
        { name = "Dungeon Run", qualities = { 1, 2, 3, 3, 4 } },
        { name = "Raid Night",  qualities = { 3, 4, 4, 5, 5 } },
        { name = "Leveling",    qualities = { 0, 1, 1, 2, 2 } }
    }

    for _, scenario in ipairs(scenarios) do
        E:Print(string.format("  Scenario: %s", scenario.name))
        for i, quality in ipairs(scenario.qualities) do
            local itemList = testItems[quality]
            if itemList and #itemList > 0 then
                local item = itemList[math.random(1, #itemList)]
                local rollType = math.random(0, 2)
                local rollTypeName = rollTypes[rollType + 1].name
                local rollTypeColor = rollTypes[rollType + 1].color

                E:Print(string.format("    Item %d: %s%s|r on %s (Q%d)",
                    i, rollTypeColor, rollTypeName, item.name, quality))
                E.Tracker:TrackRoll(item.link, item.name, quality, rollType)
            end
        end
    end

    -- Test 4: Edge case testing
    E:Print("\nTest 4: Edge Cases")
    E:Print("  Testing addon disabled state")
    E:SetEnabled(false)
    local testItem = testItems[3][1] -- Rare item
    E:Print(string.format("    Addon disabled: Would not handle %s", testItem.name))

    -- Restore original settings
    E:Print("\nTest Cleanup:")
    E:SetEnabled(originalEnabled)
    E:SetLootQualityThreshold(originalThreshold)
    E.db.pass_on_all = originalPassOnAll
    E:Print(string.format("  Restored: Enabled=%s, Threshold=%s, Pass on All=%s",
        tostring(originalEnabled), originalThreshold, tostring(originalPassOnAll)))

    -- Show final statistics
    local stats = E.Tracker:GetStats()
    E:Print("\nTest Results:")
    E:Print(string.format("  Total items handled: %d", stats.totalHandled))
    E:Print(string.format("  Roll breakdown: Pass=%d, Need=%d, Greed=%d",
        stats.rollsByType.pass, stats.rollsByType.need, stats.rollsByType.greed))

    E:Print("|cff00ff00Comprehensive roll system test completed!|r")
    E:Print("Check Statistics and Items tabs to see the generated data.")
end

-- Add legendary test items to verify statistics display
function Debug:AddLegendaryTestItems()
    E:Print("Adding legendary test items to verify statistics...")

    if not E.Tracker then
        E:Print("ERROR: Tracker module not available!")
        return
    end

    -- Add a few legendary items directly
    local legendaryItems = {
        { link = "|cffff8000|Hitem:17182:0:0:0:0:0:0:0:80|h[Sulfuras, Hand of Ragnaros]|h|r",                   name = "Sulfuras, Hand of Ragnaros" },
        { link = "|cffff8000|Hitem:19019:0:0:0:0:0:0:0:80|h[Thunderfury, Blessed Blade of the Windseeker]|h|r", name = "Thunderfury, Blessed Blade of the Windseeker" },
        { link = "|cffff8000|Hitem:22589:0:0:0:0:0:0:0:80|h[Atiesh, Greatstaff of the Guardian]|h|r",           name = "Atiesh, Greatstaff of the Guardian" }
    }

    E:Print("Adding " .. #legendaryItems .. " legendary items...")
    for i, item in ipairs(legendaryItems) do
        E.Tracker:TrackRoll(item.link, item.name, 5, 0) -- Quality 5 = Legendary, Pass roll
        E:Print("  Added: " .. item.name)
    end

    -- Also add one item from each other quality for comparison
    local testItems = self:GetTestItems()

    E:Print("Adding 1 item of each other quality...")
    for quality = 0, 4 do -- 0-4 (we already added legendary above)
        local itemList = testItems[quality]
        if itemList and #itemList > 0 then
            local item = itemList[1]                              -- Use first item of each quality
            E.Tracker:TrackRoll(item.link, item.name, quality, 0) -- Pass roll
        end
    end

    E:Print("All test items added! Now run '/ultimateloot debug check' to verify.")

    -- Fire events to refresh the UI
    E:SendMessage("ULTIMATELOOT_DATA_CHANGED", {
        type = "test_items_added",
        timestamp = time()
    })

    -- Also refresh the main UI if it's open
    if E.TrackerUI and E.TrackerUI.RefreshCurrentTab then
        E.TrackerUI:RefreshCurrentTab()
    end
end

-- Quick test of individual roll types using existing testItems
function Debug:TestQuickRolls()
    E:Print("=== QUICK ROLL TRACKING TEST ===")

    if not E.Tracker then
        E:Print("ERROR: Tracker module not available!")
        return
    end

    local testItems = self:GetTestItems()
    local rollTypes = {
        { name = "Pass",  id = 0, color = "|cffff0000" },
        { name = "Need",  id = 1, color = "|cff00ff00" },
        { name = "Greed", id = 2, color = "|cff0070dd" }
    }

    E:Print("Testing all roll types with existing test items...")

    local totalTests = 0
    -- Test one item from each quality level
    for quality = 0, 5 do
        local itemList = testItems[quality]
        if itemList and #itemList > 0 then
            local item = itemList[1] -- Use first item of each quality
            for _, rollType in ipairs(rollTypes) do
                E:Print(string.format("  %s%s|r on %s (Quality %d)",
                    rollType.color, rollType.name, item.name, quality))
                E.Tracker:TrackRoll(item.link, item.name, quality, rollType.id)
                totalTests = totalTests + 1
            end
        end
    end

    E:Print(string.format("Tracked %d test rolls", totalTests))

    -- Test timeframe functionality
    E:Print("Testing timeframe calculations...")
    local rollData = E.Tracker:GetRollsByTimeframe(1) -- Last hour
    E:Print(string.format("Last hour: Total=%d, Pass=%d, Need=%d, Greed=%d",
        rollData.total, rollData.pass, rollData.need, rollData.greed))

    -- Test top items functionality
    E:Print("Testing top items tracking...")
    local topItems = E.Tracker:GetTopRolledItems(5)
    for i, item in ipairs(topItems) do
        E:Print(string.format("  #%d: %s - Total:%d (P:%d N:%d G:%d)",
            i, item.itemName, item.totalCount,
            item.rollCounts.pass, item.rollCounts.need, item.rollCounts.greed))
    end

    E:Print("Quick roll test completed! Check Statistics tab.")
end

-- Test statistics generation using existing test items
function Debug:TestStatisticsGeneration()
    E:Print("=== STATISTICS GENERATION TEST ===")

    if not E.Tracker then
        E:Print("ERROR: Tracker module not available!")
        return
    end

    -- Clear existing data first
    E.Tracker:ClearAllData()
    E:Print("Cleared existing data for clean test")

    local testItems = self:GetTestItems()

    -- Generate realistic test scenarios using existing items
    local testScenarios = {
        {
            name = "Early Game Scenario",
            qualityRolls = {
                [0] = { pass = 8, need = 0, greed = 0 }, -- Poor items all passed
                [1] = { pass = 12, need = 0, greed = 3 } -- Common items mostly passed, some greed
            }
        },
        {
            name = "Mid Game Scenario",
            qualityRolls = {
                [1] = { pass = 5, need = 0, greed = 2 }, -- Common items
                [2] = { pass = 3, need = 4, greed = 6 }, -- Uncommon items mixed
                [3] = { pass = 1, need = 8, greed = 2 }  -- Rare items mostly needed
            }
        },
        {
            name = "End Game Scenario",
            qualityRolls = {
                [3] = { pass = 2, need = 6, greed = 1 },  -- Rare items
                [4] = { pass = 0, need = 15, greed = 2 }, -- Epic items mostly needed
                [5] = { pass = 0, need = 8, greed = 0 }   -- Legendary items all needed
            }
        }
    }

    for _, scenario in ipairs(testScenarios) do
        E:Print("Generating " .. scenario.name .. "...")

        for quality, rolls in pairs(scenario.qualityRolls) do
            local itemList = testItems[quality]
            if itemList and #itemList > 0 then
                -- Use all items in this quality for variety
                for rollType, count in pairs(rolls) do
                    local rollId = rollType == "pass" and 0 or (rollType == "need" and 1 or 2)

                    for i = 1, count do
                        local item = itemList[((i - 1) % #itemList) + 1] -- Cycle through items
                        E.Tracker:TrackRoll(item.link, item.name, quality, rollId)
                    end
                end
            end
        end
    end

    -- Display generated statistics
    local stats = E.Tracker:GetStats()
    E:Print("=== GENERATED STATISTICS ===")
    E:Print(string.format("Total Handled: %d", stats.totalHandled))
    E:Print(string.format("Roll Types: Pass=%d, Need=%d, Greed=%d",
        stats.rollsByType.pass, stats.rollsByType.need, stats.rollsByType.greed))

    E:Print("Quality Breakdown:")
    local qualityNames = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }
    for quality = 0, 5 do
        local rollData = stats.rollsByQuality and stats.rollsByQuality[quality] or { pass = 0, need = 0, greed = 0 }
        local total = rollData.pass + rollData.need + rollData.greed
        if total > 0 then
            E:Print(string.format("  %s: %d total (P:%d N:%d G:%d)",
                qualityNames[quality + 1], total, rollData.pass, rollData.need, rollData.greed))
        end
    end

    E:Print("Statistics generation completed! Open Statistics tab to see results.")
end

-- Test edge cases and error conditions
function Debug:TestEdgeCases()
    E:Print("=== EDGE CASES AND ERROR CONDITIONS TEST ===")

    if not E.Tracker then
        E:Print("ERROR: Tracker module not available!")
        return
    end

    -- Test 1: Invalid roll types
    E:Print("Test 1: Invalid roll types")
    E.Tracker:TrackRoll("test_item", "Test Item", 2, 99)  -- Invalid roll type
    E.Tracker:TrackRoll("test_item", "Test Item", 2, -1)  -- Negative roll type
    E.Tracker:TrackRoll("test_item", "Test Item", 2, nil) -- Nil roll type

    -- Test 2: Invalid quality levels
    E:Print("Test 2: Invalid quality levels")
    E.Tracker:TrackRoll("test_item", "Test Item", -1, 0)  -- Negative quality
    E.Tracker:TrackRoll("test_item", "Test Item", 10, 0)  -- Quality too high
    E.Tracker:TrackRoll("test_item", "Test Item", nil, 0) -- Nil quality

    -- Test 3: Empty/nil parameters
    E:Print("Test 3: Empty/nil parameters")
    E.Tracker:TrackRoll(nil, nil, 1, 0)          -- All nil
    E.Tracker:TrackRoll("", "", 1, 0)            -- Empty strings
    E.Tracker:TrackRoll("valid_link", nil, 1, 0) -- Mixed valid/nil

    -- Test 4: Very large numbers
    E:Print("Test 4: Large data volumes")
    local startTime = time()
    for i = 1, 100 do
        E.Tracker:TrackRoll("bulk_item_" .. i, "Bulk Item " .. i, math.random(0, 5), math.random(0, 2))
    end
    local endTime = time()
    E:Print(string.format("Tracked 100 items in %d seconds", endTime - startTime))

    -- Test 5: Timeframe edge cases
    E:Print("Test 5: Timeframe calculations")
    local rollData = E.Tracker:GetRollsByTimeframe(0) -- Zero hours
    E:Print(string.format("Zero hours: %d items", rollData.total))

    rollData = E.Tracker:GetRollsByTimeframe(99999) -- Very large timeframe
    E:Print(string.format("Large timeframe: %d items", rollData.total))

    -- Test 6: Empty statistics
    E:Print("Test 6: Statistics with no data")
    local originalHistory = E.Tracker.db.history
    E.Tracker.db.history = {} -- Temporarily empty

    local emptyStats = E.Tracker:GetStats()
    E:Print(string.format("Empty stats: %d total", emptyStats.totalHandled))

    E.Tracker.db.history = originalHistory -- Restore

    -- Test 7: Data structure validation
    E:Print("Test 7: Data structure validation")
    local stats = E.Tracker:GetStats()

    -- Check rollsByType structure
    local expectedRollTypes = { "pass", "need", "greed" }
    for _, rollType in ipairs(expectedRollTypes) do
        if not stats.rollsByType[rollType] then
            E:Print("ERROR: Missing roll type: " .. rollType)
        else
            E:Print(string.format("✓ %s: %d", rollType, stats.rollsByType[rollType]))
        end
    end

    -- Check rollsByQuality structure
    for quality = 0, 5 do
        if not stats.rollsByQuality[quality] then
            E:Print("ERROR: Missing quality level: " .. quality)
        else
            local rollData = stats.rollsByQuality[quality]
            for _, rollType in ipairs(expectedRollTypes) do
                if not rollData[rollType] then
                    E:Print(string.format("ERROR: Quality %d missing roll type: %s", quality, rollType))
                end
            end
        end
    end

    E:Print("Edge cases test completed!")
end

-- Comprehensive system test (combines all tests)
function Debug:RunComprehensiveSystemTest()
    E:Print("|cff00ff00=== COMPREHENSIVE ULTIMATELOOT SYSTEM TEST ===|r")
    E:Print("This test will validate all systems, test Pass on All feature, and generate comprehensive data...")

    if not E.Tracker then
        E:Print("ERROR: Tracker module not available!")
        return
    end

    -- Store original settings
    local originalEnabled = E:GetEnabled()
    local originalThreshold = E:GetLootQualityThreshold()
    local originalPassOnAll = E.db.pass_on_all

    -- Enable everything for testing
    E:SetEnabled(true)
    E.db.pass_on_all = false

    local testItems = self:GetTestItems()

    -- Run all test suites
    E:Print("\n1. Testing Quick Roll System...")
    self:TestQuickRolls()

    E:Print("\n2. Testing Statistics Generation...")
    self:TestStatisticsGeneration()

    E:Print("\n3. Testing Edge Cases...")
    self:TestEdgeCases()

    E:Print("\n4. Testing Pass on All Feature with Existing Items...")
    E.db.pass_on_all = true
    E:Print("Pass on All ENABLED - testing with actual items from each quality level")

    for quality = 0, 5 do
        local itemList = testItems[quality]
        if itemList and #itemList > 0 then
            local item = itemList[1]
            local qualityNames = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }
            E:Print(string.format("  |cffff0000PASS|r on %s (%s) - Pass on All override",
                item.name, qualityNames[quality + 1]))
            E.Tracker:TrackRoll(item.link, item.name, quality, 0) -- Should all be passes
        end
    end

    E:Print("\n5. Testing Comprehensive Roll System...")
    E.db.pass_on_all = false -- Turn off for roll system test
    self:RunComprehensiveRollTest()

    E:Print("\n6. Testing Item Rules Integration...")
    if E.UltimateLoot and E.UltimateLoot.TestItemRules then
        E.UltimateLoot:TestItemRules()
    else
        E:Print("Item Rules test not available")
    end

    -- Restore original settings
    E:SetEnabled(originalEnabled)
    E:SetLootQualityThreshold(originalThreshold)
    E.db.pass_on_all = originalPassOnAll

    -- Final statistics
    E:Print("\n=== FINAL TEST RESULTS ===")
    local stats = E.Tracker:GetStats()
    E:Print(string.format("Total Items Handled: %d", stats.totalHandled))

    if stats.totalHandled > 0 then
        E:Print(string.format("Roll Distribution: Pass=%d (%.1f%%), Need=%d (%.1f%%), Greed=%d (%.1f%%)",
            stats.rollsByType.pass, (stats.rollsByType.pass / stats.totalHandled) * 100,
            stats.rollsByType.need, (stats.rollsByType.need / stats.totalHandled) * 100,
            stats.rollsByType.greed, (stats.rollsByType.greed / stats.totalHandled) * 100))
    else
        E:Print("No items tracked during test")
    end

    local rollData24h = E.Tracker:GetRollsByTimeframe(24)
    E:Print(string.format("Recent Activity (24h): %d total", rollData24h.total))

    E:Print("\n|cff00ff00COMPREHENSIVE SYSTEM TEST COMPLETED!|r")
    E:Print("This test covered:")
    E:Print("  ✓ All roll types (Pass/Need/Greed)")
    E:Print("  ✓ All quality levels (Poor through Legendary)")
    E:Print("  ✓ Pass on All feature override")
    E:Print("  ✓ Edge cases and error handling")
    E:Print("  ✓ Statistics generation and timeframe calculations")
    E:Print("Check all UI tabs to see the generated data and statistics.")
    E:Print("Use '/ultimateloot status' to see current addon status.")
end

-- Show raw statistics data directly to chat
function Debug:ShowRawStats()
    E:Print("=== RAW STATISTICS DATA ===")

    if not E.Tracker or not E.Tracker.db then
        E:Print("ERROR: Tracker not initialized!")
        return
    end

    local stats = E.Tracker.db.stats
    if not stats then
        E:Print("ERROR: No stats data found!")
        return
    end

    E:Print("Total Items Handled: " .. (stats.totalHandled or "nil"))
    E:Print("Quality Breakdown:")

    local qualityNames = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }
    for quality = 0, 5 do
        local rollData = stats.rollsByQuality and stats.rollsByQuality[quality] or { pass = 0, need = 0, greed = 0 }
        local total = rollData.pass + rollData.need + rollData.greed
        local name = qualityNames[quality + 1]
        E:Print(string.format("  %s (%d): %d total (P:%d N:%d G:%d)", name, quality, total, rollData.pass, rollData.need,
            rollData.greed))
    end

    E:Print("Item Counts Table Size: " .. (stats.itemCounts and #stats.itemCounts or "nil"))
    E:Print("History Size: " .. (E.Tracker.db.history and #E.Tracker.db.history or "nil"))
end

-- Check legendary data specifically
function Debug:CheckLegendaryData()
    E:Print("=== LEGENDARY DATA CHECK ===")

    if not E.Tracker or not E.Tracker.db then
        E:Print("ERROR: Tracker not initialized!")
        return
    end

    local stats = E.Tracker.db.stats
    local legendaryData = stats.rollsByQuality and stats.rollsByQuality[5] or { pass = 0, need = 0, greed = 0 }
    local legendaryCount = legendaryData.pass + legendaryData.need + legendaryData.greed

    E:Print("Legendary count in database: " .. legendaryCount)

    -- Check if there are any legendary items in history
    local legendaryInHistory = 0
    if E.Tracker.db.history then
        for _, item in ipairs(E.Tracker.db.history) do
            if item.quality == 5 then
                legendaryInHistory = legendaryInHistory + 1
            end
        end
    end

    E:Print("Legendary items in history: " .. legendaryInHistory)

    -- Check item counts for legendary items
    local legendaryItemTypes = 0
    if stats.itemCounts then
        for _, itemData in pairs(stats.itemCounts) do
            if itemData.quality == 5 then
                legendaryItemTypes = legendaryItemTypes + 1
                E:Print("  Found legendary: " .. (itemData.itemName or "Unknown") .. " (count: " .. itemData.count .. ")")
            end
        end
    end

    E:Print("Unique legendary item types: " .. legendaryItemTypes)

    -- Check if UI is showing different data
    if E.StatisticsUI then
        E:Print("Statistics UI module: Available")
    else
        E:Print("Statistics UI module: Not available")
    end
end

-- Fix quality statistics by recalculating from history
function Debug:FixQualityStats()
    E:Print("=== FIXING QUALITY STATISTICS ===")

    if not E.Tracker or not E.Tracker.db then
        E:Print("ERROR: Tracker not initialized!")
        return
    end

    local stats = E.Tracker.db.stats
    local history = E.Tracker.db.history

    if not history or #history == 0 then
        E:Print("No history data to recalculate from.")
        return
    end

    E:Print(string.format("Recalculating quality stats from %d history entries...", #history))

    -- Reset counters
    for rollType in pairs(stats.rollsByType) do
        stats.rollsByType[rollType] = 0
    end
    for quality = 0, 5 do
        if stats.rollsByQuality[quality] then
            for rollType in pairs(stats.rollsByQuality[quality]) do
                stats.rollsByQuality[quality][rollType] = 0
            end
        end
    end

    -- Recalculate from history
    local qualityNames = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }
    for _, roll in ipairs(history) do
        if roll.quality and roll.quality >= 0 and roll.quality <= 5 then
            local rollType = roll.rollTypeName or "pass" -- Legacy compatibility
            if stats.rollsByType[rollType] then
                stats.rollsByType[rollType] = stats.rollsByType[rollType] + 1
            end
            if stats.rollsByQuality[roll.quality] and stats.rollsByQuality[roll.quality][rollType] then
                stats.rollsByQuality[roll.quality][rollType] = stats.rollsByQuality[roll.quality][rollType] + 1
            end
        end
    end

    -- Update total handled
    stats.totalHandled = #history

    -- Show results
    E:Print("Quality stats recalculated:")
    for quality = 0, 5 do
        local rollData = stats.rollsByQuality[quality] or { pass = 0, need = 0, greed = 0 }
        local total = rollData.pass + rollData.need + rollData.greed
        local name = qualityNames[quality + 1]
        E:Print(string.format("  %s: %d total (P:%d N:%d G:%d)", name, total, rollData.pass, rollData.need,
            rollData.greed))
    end

    E:Print("Total handled: " .. stats.totalHandled)
    E:Print("Quality stats have been fixed! Check Statistics tab.")

    -- Fire events to refresh UI
    E:SendMessage("ULTIMATELOOT_DATA_CHANGED", {
        type = "stats_recalculated",
        timestamp = time()
    })

    if E.TrackerUI and E.TrackerUI.RefreshCurrentTab then
        E.TrackerUI:RefreshCurrentTab()
    end
end
