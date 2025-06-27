local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local ItemRulesUI = E:NewModule("ItemRulesUI")
E.ItemRulesUI = ItemRulesUI
local AceGUI = E.Libs.AceGUI

-- Rule type definitions
local RULE_TYPES = {
    WHITELIST = { key = "whitelist", color = E.ColorConstants.COLORS.RULE_WHITELIST, title = L["ALWAYS_PASS"] or "Always Pass" },
    BLACKLIST = { key = "blacklist", color = E.ColorConstants.COLORS.RULE_BLACKLIST, title = L["NEVER_PASS"] or "Never Pass" },
    NEED = { key = "always_need", color = E.ColorConstants.COLORS.RULE_NEED, title = L["ALWAYS_NEED"] or "Always Need" },
    GREED = { key = "always_greed", color = E.ColorConstants.COLORS.RULE_GREED, title = L["ALWAYS_GREED"] or "Always Greed" },
    GREED_DISENCHANT = { key = "always_greed_disenchant", color = E.ColorConstants.COLORS.RULE_GREED_DISENCHANT, title = L["ALWAYS_GREED_DISENCHANT"] or "Always Greed/Disenchant" }
}

-- Helper function to apply default WoW styling to rule cards
local function ApplyCardStyling(card, ruleInfo)
    if not card or not card.frame or not ruleInfo or not ruleInfo.color then
        return
    end

    -- Use WoW's default backdrop border coloring system
    -- This works consistently across all UI skins
    if card.frame.SetBackdropBorderColor then
        local r, g, b = unpack(ruleInfo.color)
        card.frame:SetBackdropBorderColor(r, g, b, 0.8)
    end

    -- Clean up any existing overlays
    if card.colorOverlay then
        card.colorOverlay:Hide()
        card.colorOverlay = nil
    end
end

-- Helper function to refresh the rules display
local function RefreshRulesDisplay(self)
    if self.currentContainer then
        self:CreateItemRulesTab(self.currentContainer)
    end
end

-- Helper function to get total rule count
local function GetRuleCount()
    local itemRules = E.ItemRules
    if not itemRules then return 0 end

    local allRules = itemRules:GetRules()
    local totalCount = 0

    for ruleType, rules in pairs(allRules) do
        if rules then
            totalCount = totalCount + #rules
        end
    end

    return totalCount
end

-- Main tab function
function ItemRulesUI:CreateItemRulesTab(container)
    -- Store container for refreshing
    self.currentContainer = container

    -- Clear container to ensure clean refresh
    container:ReleaseChildren()

    -- Create header with title and controls
    self:CreateHeader(container)

    -- Main scroll frame using UIUtils
    local scrollFrame = E.UIUtils:CreateScrollFrame(container)
    self.scrollFrame = scrollFrame

    -- Cache ItemRules module
    local itemRules = E.ItemRules
    -- If module is disabled, show message and return
    if not itemRules or not itemRules:IsEnabled() then
        local disabledGroup = AceGUI:Create("InlineGroup")
        disabledGroup:SetTitle(L["ITEM_RULES_SYSTEM"])
        disabledGroup:SetFullWidth(true)
        disabledGroup:SetLayout("Flow")
        scrollFrame:AddChild(disabledGroup)

        local disabledLabel = AceGUI:Create("Label")
        disabledLabel:SetText("|cff888888" .. L["ITEM_RULES_DISABLED"] .. "|r")
        disabledLabel:SetFullWidth(true)
        disabledGroup:AddChild(disabledLabel)
        return
    end

    -- Show add rule form
    self:CreateAddRuleForm(scrollFrame)

    -- Rules summary
    self:CreateRulesSummary(scrollFrame)
end

-- Create the header with title and controls
function ItemRulesUI:CreateHeader(container)
    -- Header group
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetFullWidth(true)
    headerGroup:SetLayout("Flow")
    container:AddChild(headerGroup)

    -- Title
    local titleText = AceGUI:Create("Label")
    titleText:SetText(L["ITEM_RULES_SYSTEM"])
    titleText:SetFontObject(GameFontNormalLarge)
    titleText:SetWidth(200)
    headerGroup:AddChild(titleText)

    -- Enable checkbox
    local enabledCheckbox = AceGUI:Create("CheckBox")
    enabledCheckbox:SetLabel(L["ENABLE_ITEM_RULES"])
    enabledCheckbox:SetValue(E.ItemRules and E.ItemRules:IsEnabled() or false)
    enabledCheckbox:SetWidth(200)
    enabledCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        if E.ItemRules then
            E.ItemRules:SetEnabled(value)
            RefreshRulesDisplay(self)
        end
    end)
    headerGroup:AddChild(enabledCheckbox)

    -- Test rules button
    local testButton = AceGUI:Create("Button")
    testButton:SetText(L["TEST_RULES"])
    testButton:SetWidth(100)
    testButton:SetCallback("OnClick", function()
        if E.UltimateLoot and E.UltimateLoot.TestItemRules then
            E.UltimateLoot:TestItemRules()
        end
    end)
    headerGroup:AddChild(testButton)

    -- Description
    local descGroup = AceGUI:Create("SimpleGroup")
    descGroup:SetFullWidth(true)
    descGroup:SetLayout("Flow")
    container:AddChild(descGroup)

    local descText = AceGUI:Create("Label")
    descText:SetText(L["ITEM_RULES_DESC"] or
        "Configure automatic rules for handling specific items when loot rolls appear")
    descText:SetFullWidth(true)
    descText:SetFontObject(GameFontNormalSmall)
    descGroup:AddChild(descText)

    -- Add horizontal line
    local line = AceGUI:Create("Label")
    line:SetText("")
    line:SetFullWidth(true)
    line:SetHeight(8)
    container:AddChild(line)
end

-- Create the add rule form
function ItemRulesUI:CreateAddRuleForm(container)
    local addGroup = AceGUI:Create("InlineGroup")
    addGroup:SetTitle(L["ADD_NEW_RULE"])
    addGroup:SetFullWidth(true)
    addGroup:SetLayout("Flow")
    container:AddChild(addGroup)

    -- Create a 2-column layout
    local leftColumn = AceGUI:Create("SimpleGroup")
    leftColumn:SetWidth(300)
    leftColumn:SetLayout("Flow")
    addGroup:AddChild(leftColumn)

    local rightColumn = AceGUI:Create("SimpleGroup")
    rightColumn:SetWidth(300)
    rightColumn:SetLayout("Flow")
    addGroup:AddChild(rightColumn)

    -- Left column: Item input and rule type
    local itemInput = AceGUI:Create("EditBox")
    itemInput:SetLabel(L["ITEM_NAME_OR_LINK"])
    itemInput:SetText("")
    itemInput:SetFullWidth(true)
    leftColumn:AddChild(itemInput)

    local ruleTypeDropdown = AceGUI:Create("Dropdown")
    ruleTypeDropdown:SetLabel(L["RULE_TYPE"])
    ruleTypeDropdown:SetList({
        whitelist = "|cff00ff00" .. L["ALWAYS_PASS"] .. "|r",
        blacklist = "|cffff0000" .. L["NEVER_PASS"] .. "|r",
        always_need = "|cff0080ff" .. L["ALWAYS_NEED"] .. "|r",
        always_greed = "|cffffaa00" .. L["ALWAYS_GREED"] .. "|r",
        always_greed_disenchant = "|cffcc66cc" .. L["ALWAYS_GREED_DISENCHANT"] .. "|r"
    })
    ruleTypeDropdown:SetValue("whitelist")
    ruleTypeDropdown:SetFullWidth(true)
    leftColumn:AddChild(ruleTypeDropdown)

    -- Right column: Options
    local patternMatchCheck = AceGUI:Create("CheckBox")
    patternMatchCheck:SetLabel(L["USE_PATTERN"] or "Use pattern matching")
    patternMatchCheck:SetValue(false)
    patternMatchCheck:SetFullWidth(true)
    patternMatchCheck:SetDescription(L["USE_PATTERN_DESC"] or
        "Use Lua pattern matching for more flexible item name rules")
    rightColumn:AddChild(patternMatchCheck)

    -- Button group (bottom of form)
    local buttonGroup = AceGUI:Create("SimpleGroup")
    buttonGroup:SetFullWidth(true)
    buttonGroup:SetLayout("Flow")
    addGroup:AddChild(buttonGroup)

    -- Add button
    local addButton = AceGUI:Create("Button")
    addButton:SetText(L["ADD_RULE"])
    addButton:SetWidth(100)
    addButton:SetCallback("OnClick", function()
        local itemText = itemInput:GetText()
        local ruleType = ruleTypeDropdown:GetValue()
        local usePattern = patternMatchCheck:GetValue()

        if not itemText or itemText:trim() == "" then
            E:Print("Please enter an item name or link.")
            return
        end

        if not ruleType then
            E:Print("Please select a rule type.")
            return
        end

        -- Check pattern validity if pattern matching is enabled
        if usePattern then
            local success = pcall(function() return string.match("Test", itemText) end)
            if not success then
                E:Print("The pattern is not valid. Please check your syntax.")
                return
            end
        end

        -- Parse item link or name
        local itemName, itemLink, itemId
        if itemText:match("|H") then
            -- It's an item link
            itemLink = itemText
            itemName = itemText:match("%[(.-)%]") or "Unknown Item"
            itemId = itemText:match("Hitem:(%d+)")

            -- Pattern matching doesn't make sense with links
            usePattern = false
        else
            -- It's just a name
            itemName = itemText
        end

        -- Add the rule with options
        local options = {
            usePattern = usePattern
        }

        local success, message = E.ItemRules:AddItemRule(ruleType, itemName, itemLink, itemId, options)

        if success then
            E:Print(string.format("Added %s rule for %s%s",
                ruleType,
                itemName,
                usePattern and " (pattern matching)" or ""))
            itemInput:SetText("")
            patternMatchCheck:SetValue(false)
            RefreshRulesDisplay(self)

            -- If rules window is open, refresh it
            if self.rulesWindow and self.rulesWindow.frame:IsShown() then
                self:ShowRulesWindow()
            end
        else
            E:Print(string.format("Failed to add rule: %s", message))
        end
    end)
    buttonGroup:AddChild(addButton)

    -- Clear button
    local clearButton = AceGUI:Create("Button")
    clearButton:SetText(L["CLEAR"])
    clearButton:SetWidth(80)
    clearButton:SetCallback("OnClick", function()
        itemInput:SetText("")
        patternMatchCheck:SetValue(false)
    end)
    buttonGroup:AddChild(clearButton)
end

-- Create the rules summary section
function ItemRulesUI:CreateRulesSummary(container)
    local summaryGroup = AceGUI:Create("InlineGroup")
    summaryGroup:SetTitle(L["RULES_SUMMARY"] or "Rules Summary")
    summaryGroup:SetFullWidth(true)
    summaryGroup:SetLayout("Flow")
    container:AddChild(summaryGroup)

    local allRules = E.ItemRules:GetRules()
    local totalRules = GetRuleCount()

    if totalRules == 0 then
        E.UIUtils:ShowEmptyState(summaryGroup, L["NO_RULES_CONFIGURED"])
    else
        -- Summary text
        local summaryText = AceGUI:Create("Label")
        summaryText:SetText(L["TOTAL_RULES"] .. ": " .. totalRules)
        summaryText:SetFullWidth(true)
        summaryText:SetFontObject(GameFontNormal)
        summaryGroup:AddChild(summaryText)

        -- Rule type breakdown
        for _, ruleInfo in pairs(RULE_TYPES) do
            local rules = allRules[ruleInfo.key] or {}
            local count = #rules

            local ruleTypeGroup = AceGUI:Create("SimpleGroup")
            ruleTypeGroup:SetLayout("Flow")
            ruleTypeGroup:SetWidth(200)
            summaryGroup:AddChild(ruleTypeGroup)

            local ruleTypeLabel = AceGUI:Create("Label")
            ruleTypeLabel:SetText(ruleInfo.title .. ": " .. count)
            ruleTypeLabel:SetWidth(180)
            ruleTypeLabel:SetColor(unpack(ruleInfo.color))
            ruleTypeGroup:AddChild(ruleTypeLabel)
        end

        -- Clear all rules button (with confirmation) - only show when there are rules
        local clearAllButton = AceGUI:Create("Button")
        clearAllButton:SetText(L["CLEAR_ALL_RULES"])
        clearAllButton:SetWidth(130)
        clearAllButton:SetCallback("OnClick", function()
            E.UIUtils:ShowConfirmDialog("ULTIMATELOOT_CLEAR_ALL_RULES", L["CLEAR_ALL_RULES_CONFIRM"], function()
                if E.ItemRules then
                    E.ItemRules:ClearRules()
                    E:Print("All item rules cleared.")
                    RefreshRulesDisplay(self)

                    -- If rules window is open, close it
                    if self.rulesWindow and self.rulesWindow.frame:IsShown() then
                        self.rulesWindow:Release()
                        self.rulesWindow = nil
                    end
                end
            end)
        end)
        summaryGroup:AddChild(clearAllButton)
    end

    -- Manage Rules button (always show)
    local manageButton = AceGUI:Create("Button")
    manageButton:SetText(L["MANAGE_RULES"] or "Manage Rules")
    manageButton:SetWidth(150)
    manageButton:SetCallback("OnClick", function()
        self:ShowRulesWindow()
    end)
    summaryGroup:AddChild(manageButton)
end

-- Create and show the rules management window
function ItemRulesUI:ShowRulesWindow()
    -- If window already exists, just update its content
    if self.rulesWindow and self.rulesWindow.frame and self.rulesWindow.frame:IsShown() then
        self:UpdateRulesWindowContent()
        return
    end

    -- Create window frame
    local window = AceGUI:Create("Frame")
    window:SetTitle(L["ITEM_RULES_MANAGER"] or "Item Rules Manager")
    window:SetLayout("Fill")
    window:SetWidth(800)
    window:SetHeight(600)

    -- Set up close callback to clean up references
    window:SetCallback("OnClose", function(widget)
        self.rulesWindow = nil
        widget:Release()
    end)

    self.rulesWindow = window
    self.activeRuleType = self.activeRuleType or "always_greed"

    -- Create main container with proper layout
    local mainContainer = AceGUI:Create("SimpleGroup")
    mainContainer:SetFullWidth(true)
    mainContainer:SetFullHeight(true)
    mainContainer:SetLayout("Flow")
    window:AddChild(mainContainer)

    -- Create header with statistics
    self:CreateManagerHeader(mainContainer)

    -- Create tab group for rule types
    self:CreateManagerTabs(mainContainer)

    -- Create content area
    self:CreateManagerContent(mainContainer)
end

-- Create the manager header with overall statistics
function ItemRulesUI:CreateManagerHeader(container)
    local headerGroup = AceGUI:Create("InlineGroup")
    headerGroup:SetTitle(L["RULES_OVERVIEW"] or "Rules Overview")
    headerGroup:SetFullWidth(true)
    headerGroup:SetHeight(120)
    headerGroup:SetLayout("Flow")
    container:AddChild(headerGroup)

    -- Get all rules data
    local allRules = E.ItemRules:GetRules()
    local totalRules = GetRuleCount()

    -- Left side: Overall stats
    local statsGroup = AceGUI:Create("SimpleGroup")
    statsGroup:SetWidth(300)
    statsGroup:SetLayout("Flow")
    headerGroup:AddChild(statsGroup)

    local totalLabel = AceGUI:Create("Label")
    totalLabel:SetText(string.format("|cffffffff%s:|r |cff00ff00%d|r", L["TOTAL_RULES"] or "Total Rules", totalRules))
    totalLabel:SetFontObject(GameFontNormal)
    totalLabel:SetFullWidth(true)
    statsGroup:AddChild(totalLabel)

    local statusLabel = AceGUI:Create("Label")
    local statusText = E.ItemRules and E.ItemRules:IsEnabled() and
        "|cff00ff00" .. (L["ENABLED"] or "Enabled") .. "|r" or
        "|cffff0000" .. (L["DISABLED"] or "Disabled") .. "|r"
    statusLabel:SetText(string.format("|cffffffff%s:|r %s", L["STATUS"] or "Status", statusText))
    statusLabel:SetFontObject(GameFontNormal)
    statusLabel:SetFullWidth(true)
    statsGroup:AddChild(statusLabel)

    -- Right side: Quick actions
    local actionsGroup = AceGUI:Create("SimpleGroup")
    actionsGroup:SetWidth(300)
    actionsGroup:SetLayout("Flow")
    headerGroup:AddChild(actionsGroup)

    --[[     -- Import/Export rules button
    local importExportButton = AceGUI:Create("Button")
    importExportButton:SetText(L["IMPORT_EXPORT"] or "Import/Export")
    importExportButton:SetWidth(140)
    importExportButton:SetCallback("OnClick", function()
        self:ShowImportExportDialog()
    end)
    actionsGroup:AddChild(importExportButton) ]]

    --[[ -- Clear all rules button (only if there are rules)
    if totalRules > 0 then
        local clearAllButton = AceGUI:Create("Button")
        clearAllButton:SetText(L["CLEAR_ALL_RULES"])
        clearAllButton:SetWidth(140)
        clearAllButton:SetCallback("OnClick", function()
            E.UIUtils:ShowConfirmDialog("ULTIMATELOOT_CLEAR_ALL_RULES", L["CLEAR_ALL_RULES_CONFIRM"], function()
                if E.ItemRules then
                    E.ItemRules:ClearRules()
                    E:Print("All item rules cleared.")
                    self:UpdateRulesWindowContent()
                    RefreshRulesDisplay(self)
                end
            end)
        end)
        actionsGroup:AddChild(clearAllButton)
    end ]]
end

-- Create tab group for rule types
function ItemRulesUI:CreateManagerTabs(container)
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetFullWidth(true)
    tabGroup:SetFullHeight(true)
    tabGroup:SetLayout("Fill")

    -- Build tab list
    local tabs = {}
    local tabOrder = { "always_greed", "always_greed_disenchant", "always_need", "blacklist", "whitelist" }

    for _, ruleKey in ipairs(tabOrder) do
        for _, ruleInfo in pairs(RULE_TYPES) do
            if ruleInfo.key == ruleKey then
                local allRules = E.ItemRules:GetRules()
                local count = #(allRules[ruleInfo.key] or {})
                table.insert(tabs, {
                    text = string.format("%s (%d)", ruleInfo.title, count),
                    value = ruleInfo.key
                })
                break
            end
        end
    end

    tabGroup:SetTabs(tabs)
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, value)
        self.activeRuleType = value
        self:UpdateManagerTabContent(widget)
    end)

    container:AddChild(tabGroup)
    self.tabGroup = tabGroup

    -- Set initial tab
    tabGroup:SelectTab(self.activeRuleType)
end

-- Create content area (will be populated by tab selection)
function ItemRulesUI:CreateManagerContent(container)
    -- Content will be created dynamically by UpdateManagerTabContent
end

-- Update the content of the selected tab
function ItemRulesUI:UpdateManagerTabContent(tabGroup)
    tabGroup:ReleaseChildren()

    -- Get rules for active type
    local allRules = E.ItemRules:GetRules()
    local activeRules = allRules[self.activeRuleType] or {}

    -- Get rule info for styling
    local activeRuleInfo = nil
    for _, ruleInfo in pairs(RULE_TYPES) do
        if ruleInfo.key == self.activeRuleType then
            activeRuleInfo = ruleInfo
            break
        end
    end

    if #activeRules == 0 then
        -- Show empty state with add rule form
        self:CreateEmptyTabContent(tabGroup, activeRuleInfo)
    else
        -- Show rules list with management options
        self:CreatePopulatedTabContent(tabGroup, activeRules, activeRuleInfo)
    end
end

-- Create content for empty tabs
function ItemRulesUI:CreateEmptyTabContent(container, ruleInfo)
    local emptyGroup = AceGUI:Create("SimpleGroup")
    emptyGroup:SetFullWidth(true)
    emptyGroup:SetFullHeight(true)
    emptyGroup:SetLayout("Flow")
    container:AddChild(emptyGroup)

    -- Empty state message
    local emptyMessage = AceGUI:Create("Label")
    emptyMessage:SetText(string.format(L["NO_RULES_OF_TYPE_DETAILED"] or
        "No %s rules configured.",
        ruleInfo.title:lower()))
    emptyMessage:SetFontObject(GameFontNormal)
    emptyMessage:SetFullWidth(true)
    emptyMessage:SetJustifyH("CENTER")
    emptyGroup:AddChild(emptyMessage)

    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText("")
    spacer:SetFullWidth(true)
    spacer:SetHeight(20)
    emptyGroup:AddChild(spacer)

    -- Quick add rule form
    self:CreateQuickAddForm(emptyGroup, self.activeRuleType)
end

-- Create content for tabs with rules
function ItemRulesUI:CreatePopulatedTabContent(container, rules, ruleInfo)
    local contentGroup = AceGUI:Create("SimpleGroup")
    contentGroup:SetFullWidth(true)
    contentGroup:SetFullHeight(true)
    contentGroup:SetLayout("Fill")
    container:AddChild(contentGroup)

    -- Create scroll frame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    scrollFrame:SetLayout("Flow")
    contentGroup:AddChild(scrollFrame)

    -- Tab header with info
    local headerGroup = AceGUI:Create("InlineGroup")
    headerGroup:SetTitle(string.format("%s (%d %s)", ruleInfo.title, #rules,
        #rules == 1 and (L["RULE"] or "rule") or (L["RULES"] or "rules")))
    headerGroup:SetFullWidth(true)
    headerGroup:SetLayout("Flow")
    scrollFrame:AddChild(headerGroup)

    -- Bulk actions
    local bulkGroup = AceGUI:Create("SimpleGroup")
    bulkGroup:SetFullWidth(true)
    bulkGroup:SetLayout("Flow")
    headerGroup:AddChild(bulkGroup)



    -- Rules list
    local rulesGroup = AceGUI:Create("InlineGroup")
    rulesGroup:SetTitle(L["CONFIGURED_RULES"] or "Configured Rules")
    rulesGroup:SetFullWidth(true)
    rulesGroup:SetLayout("Flow")
    scrollFrame:AddChild(rulesGroup)

    -- Create rule cards in a more organized layout
    self:CreateRuleCards(rulesGroup, rules, ruleInfo)
end

-- Create organized rule cards
function ItemRulesUI:CreateRuleCards(container, rules, ruleInfo)
    for i, rule in ipairs(rules) do
        local card = AceGUI:Create("InlineGroup")
        card:SetFullWidth(true)
        card:SetLayout("Flow")

        -- Apply appropriate styling based on UI skin
        ApplyCardStyling(card, ruleInfo)

        container:AddChild(card)

        -- Left side: Item info
        local itemGroup = AceGUI:Create("SimpleGroup")
        itemGroup:SetWidth(400)
        itemGroup:SetLayout("Flow")
        card:AddChild(itemGroup)

        local itemLabel = AceGUI:Create("InteractiveLabel")
        local displayText = rule.link or rule.name or "Unknown Item"

        -- Add indicators
        if rule.usePattern then
            displayText = "|cffff8c00[Pattern]|r " .. displayText
        end
        if rule.itemId then
            displayText = displayText .. " |cff888888(ID: " .. rule.itemId .. ")|r"
        end

        itemLabel:SetText(displayText)
        itemLabel:SetWidth(380)

        -- Add tooltip and click functionality
        if rule.link then
            E.UIUtils:AddItemTooltip(itemLabel, rule.link)
            itemLabel:SetCallback("OnClick", function()
                if ChatEdit_GetActiveWindow() then
                    ChatEdit_GetActiveWindow():Insert(rule.link)
                end
            end)
        end
        itemGroup:AddChild(itemLabel)

        -- Right side: Actions
        local actionsGroup = AceGUI:Create("SimpleGroup")
        actionsGroup:SetWidth(200)
        actionsGroup:SetLayout("Flow")
        card:AddChild(actionsGroup)

--[[         local editButton = AceGUI:Create("Button")
        editButton:SetText(L["EDIT"] or "Edit")
        editButton:SetWidth(80)
        editButton:SetCallback("OnClick", function()
            self:ShowEditRuleDialog(rule, self.activeRuleType)
        end)
        actionsGroup:AddChild(editButton) ]]

        local removeButton = AceGUI:Create("Button")
        removeButton:SetText(L["REMOVE"])
        removeButton:SetWidth(80)
        removeButton:SetCallback("OnClick", function()
            local success, message = E.ItemRules:RemoveItemRule(self.activeRuleType, rule.name, rule.link)
            if success then
                E:Print(string.format("Removed %s rule for %s", self.activeRuleType, rule.name or "Unknown"))
                self:UpdateRulesWindowContent()
                RefreshRulesDisplay(self)
            else
                E:Print(string.format("Failed to remove rule: %s", message))
            end
        end)
        actionsGroup:AddChild(removeButton)
    end
end

-- Create a quick add rule form
function ItemRulesUI:CreateQuickAddForm(container, ruleType)
    local formGroup = AceGUI:Create("SimpleGroup")
    formGroup:SetFullWidth(true)
    formGroup:SetLayout("Flow")
    container:AddChild(formGroup)

    -- Item input
    local itemInput = AceGUI:Create("EditBox")
    itemInput:SetLabel(L["ITEM_NAME_OR_LINK"])
    itemInput:SetWidth(300)
    itemInput:SetText("")
    formGroup:AddChild(itemInput)

    -- Pattern checkbox (commented out for now)
    --[[ local patternCheck = AceGUI:Create("CheckBox")
    patternCheck:SetLabel(L["USE_PATTERN"] or "Pattern")
    patternCheck:SetWidth(100)
    patternCheck:SetValue(false)
    formGroup:AddChild(patternCheck) ]]

    -- Add button
    local addButton = AceGUI:Create("Button")
    addButton:SetText(L["ADD_RULE"])
    addButton:SetWidth(100)
    addButton:SetCallback("OnClick", function()
        local itemText = itemInput:GetText()
        if not itemText or itemText:trim() == "" then
            E:Print("Please enter an item name or link.")
            return
        end

        local usePattern = false -- patternCheck:GetValue()
        local itemName, itemLink, itemId

        if itemText:match("|H") then
            itemLink = itemText
            itemName = itemText:match("%[(.-)%]") or "Unknown Item"
            itemId = itemText:match("Hitem:(%d+)")
            usePattern = false
        else
            itemName = itemText
        end

        local options = { usePattern = usePattern }
        local success, message = E.ItemRules:AddItemRule(ruleType, itemName, itemLink, itemId, options)

        if success then
            E:Print(string.format("Added %s rule for %s", ruleType, itemName))
            itemInput:SetText("")
            -- patternCheck:SetValue(false)
            self:UpdateRulesWindowContent()
            RefreshRulesDisplay(self)
        else
            E:Print(string.format("Failed to add rule: %s", message))
        end
    end)
    formGroup:AddChild(addButton)
end

-- Show edit rule dialog
function ItemRulesUI:ShowEditRuleDialog(rule, ruleType)
    E:Print("Edit functionality not yet implemented") -- TODO: Implement rule editing
end

-- Show import/export dialog
function ItemRulesUI:ShowImportExportDialog()
    E:Print("Import/Export functionality not yet implemented") -- TODO: Implement import/export
end

-- Update content of the rules window
function ItemRulesUI:UpdateRulesWindowContent()
    if not self.rulesWindow then return end

    -- Recreate the entire window content
    self.rulesWindow:ReleaseChildren()

    -- Create main container
    local mainContainer = AceGUI:Create("SimpleGroup")
    mainContainer:SetFullWidth(true)
    mainContainer:SetFullHeight(true)
    mainContainer:SetLayout("Flow")
    self.rulesWindow:AddChild(mainContainer)

    -- Recreate all components
    self:CreateManagerHeader(mainContainer)
    self:CreateManagerTabs(mainContainer)
end
