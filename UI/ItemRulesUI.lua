local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local ItemRulesUI = E:NewModule("ItemRulesUI")
E.ItemRulesUI = ItemRulesUI
local AceGUI = E.Libs.AceGUI

-- Rule type definitions
local RULE_TYPES = {
    WHITELIST = { key = "whitelist", color = { 0, 1, 0 }, title = L["ALWAYS_PASS"] or "Always Pass" },
    BLACKLIST = { key = "blacklist", color = { 1, 0, 0 }, title = L["NEVER_PASS"] or "Never Pass" },
    NEED = { key = "always_need", color = { 0, 0.5, 1 }, title = L["ALWAYS_NEED"] or "Always Need" },
    GREED = { key = "always_greed", color = { 1, 0.67, 0 }, title = L["ALWAYS_GREED"] or "Always Greed" }
}

-- Helper function to refresh the rules display
local function RefreshRulesDisplay(self)
    if self.currentContainer then
        self:CreateItemRulesTab(self.currentContainer)
    end
end

-- Helper function to get total rule count
local function GetRuleCount()
    if not E.ItemRules then return 0 end

    local allRules = E.ItemRules:GetRules()
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

    -- If module is disabled, show message and return
    if not E.ItemRules or not E.ItemRules:IsEnabled() then
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
        always_greed = "|cffffaa00" .. L["ALWAYS_GREED"] .. "|r"
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
    end

    -- Manage Rules button
    local manageButton = AceGUI:Create("Button")
    manageButton:SetText(L["MANAGE_RULES"] or "Manage Rules")
    manageButton:SetWidth(150)
    manageButton:SetCallback("OnClick", function()
        self:ShowRulesWindow()
    end)
    summaryGroup:AddChild(manageButton)

    -- Clear all rules button (with confirmation)
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
    window:SetLayout("Flow")
    window:SetWidth(600)
    window:SetHeight(500)

    self.rulesWindow = window
    self.activeRuleType = self.activeRuleType or "always_greed"

    -- Create tabs for rule types
    local tabGroup = AceGUI:Create("SimpleGroup")
    tabGroup:SetFullWidth(true)
    tabGroup:SetHeight(30)
    tabGroup:SetLayout("Flow")
    window:AddChild(tabGroup)
    
    -- Store tabGroup reference for later updates
    self.tabGroup = tabGroup

    self.tabGroup = tabGroup -- Store reference to tab group

    -- Create tab buttons
    for _, ruleInfo in pairs(RULE_TYPES) do
        local allRules = E.ItemRules:GetRules()
        local rules = allRules[ruleInfo.key] or {}
        local count = #rules

        local tabButton = AceGUI:Create("Button")
        local isActive = self.activeRuleType == ruleInfo.key

        tabButton:SetText(ruleInfo.title .. " (" .. count .. ")")
        tabButton:SetWidth(140)

        -- Style active tab differently
        if isActive then
            -- Add a visual indicator to the active tab
            tabButton:SetText("» " .. ruleInfo.title .. " (" .. count .. ") «")
        end

        tabButton:SetCallback("OnClick", function()
            self.activeRuleType = ruleInfo.key
            self:UpdateRulesWindowContent()
        end)
        
        -- Store the rule type with the button for later updates
        tabButton.ruleType = ruleInfo.key

        tabGroup:AddChild(tabButton)
    end
    
    -- Add content for the active rule type
    self:AddRuleTypeContent(window)

    -- Create rules grid
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    window:AddChild(scrollFrame)

    -- Get rules for active type
    local allRules = E.ItemRules:GetRules()
    local activeRules = allRules[self.activeRuleType] or {}
    local activeRuleInfo = nil

    -- Find the active rule info
    for _, ruleInfo in pairs(RULE_TYPES) do
        if ruleInfo.key == self.activeRuleType then
            activeRuleInfo = ruleInfo
            break
        end
    end

    if #activeRules == 0 then
        -- Show empty state if no rules
        E.UIUtils:ShowEmptyState(scrollFrame, L["NO_RULES_OF_TYPE"] or "No rules of this type configured")
    else
        -- Create grid container
        local gridContainer = AceGUI:Create("SimpleGroup")
        gridContainer:SetFullWidth(true)
        gridContainer:SetLayout("Flow")
        scrollFrame:AddChild(gridContainer)

        -- Title and description
        local titleText = AceGUI:Create("Label")
        
        titleText:SetText(activeRuleInfo.title)
        --[[ titleText:SetColor(unpack(activeRuleInfo.color)) ]]
        titleText:SetFontObject(GameFontNormalLarge)
        titleText:SetFullWidth(true)
        gridContainer:AddChild(titleText)

        -- Create grid of rule cards
        local cardsPerRow = 2
        local currentRow = nil

        for i, rule in ipairs(activeRules) do
            -- Create new row if needed
            if (i - 1) % cardsPerRow == 0 then
                currentRow = AceGUI:Create("SimpleGroup")
                currentRow:SetFullWidth(true)
                currentRow:SetLayout("Flow")
                gridContainer:AddChild(currentRow)
            end

            -- Create card for this rule
            local card = AceGUI:Create("InlineGroup")
            card:SetWidth(270)
            card:SetLayout("List")

            -- Style card based on rule type
            local r, g, b = unpack(activeRuleInfo.color)
            card.frame:SetBackdropBorderColor(r, g, b, 0.7)

            currentRow:AddChild(card)

            -- Create a header group for item label and remove button side by side
            local headerGroup = AceGUI:Create("SimpleGroup")
            headerGroup:SetFullWidth(true)
            headerGroup:SetLayout("Flow")
            card:AddChild(headerGroup)

            -- Item name/link with icon if possible
            local itemLabel = AceGUI:Create("InteractiveLabel")
            local displayText = rule.link or rule.name or "Unknown Item"

            -- Add pattern indicator if it's a pattern match rule
            if rule.usePattern then
                displayText = "|cffff8c00[Pattern]|r " .. displayText
            end

            -- Add ID if available
            if rule.itemId then
                displayText = displayText .. " |cff7f7f7f[" .. rule.itemId .. "]|r"
            end

            itemLabel:SetText(displayText)
            itemLabel:SetWidth(180) -- Set width to allow space for remove button

            -- Add tooltip for item links
            if rule.link then
                E.UIUtils:AddItemTooltip(itemLabel, rule.link)

                -- Make item link clickable
                itemLabel:SetCallback("OnClick", function()
                    if ChatEdit_GetActiveWindow() then
                        ChatEdit_GetActiveWindow():Insert(rule.link)
                    end
                end)
            end
            headerGroup:AddChild(itemLabel)

            -- Remove button (right-aligned in the header)
            local removeButton = AceGUI:Create("Button")
            removeButton:SetText(L["REMOVE"])
            removeButton:SetWidth(80)
            removeButton:SetCallback("OnClick", function()
                local success, message = E.ItemRules:RemoveItemRule(self.activeRuleType, rule.name, rule.link)
                if success then
                    E:Print(string.format("Removed %s rule for %s", self.activeRuleType, rule.name or "Unknown"))
                    self:ShowRulesWindow()
                    RefreshRulesDisplay(self)
                else
                    E:Print(string.format("Failed to remove rule: %s", message))
                end
            end)
            headerGroup:AddChild(removeButton)

            -- Rule info
            local infoGroup = AceGUI:Create("SimpleGroup")
            infoGroup:SetLayout("Flow")
            infoGroup:SetFullWidth(true)
            card:AddChild(infoGroup)

            -- Pattern info
            if rule.usePattern then
                local patternLabel = AceGUI:Create("Label")
                patternLabel:SetText(L["PATTERN_MATCHING"] or "Pattern matching: |cffff8c00Enabled|r")
                patternLabel:SetWidth(200)
                infoGroup:AddChild(patternLabel)
            end

            -- Actions group (keeping this for potential future actions, but not adding a remove button)
            local actionsGroup = AceGUI:Create("SimpleGroup")
            actionsGroup:SetLayout("Flow")
            actionsGroup:SetFullWidth(true)
            card:AddChild(actionsGroup)
        end
    end

    -- Bottom controls
    local bottomControls = AceGUI:Create("SimpleGroup")
    bottomControls:SetFullWidth(true)
    bottomControls:SetLayout("Flow")
    window:AddChild(bottomControls)

    -- Clear rules of this type button
    local clearTypeButton = AceGUI:Create("Button")
    clearTypeButton:SetText(L["CLEAR_RULES_OF_TYPE"] or "Clear All Rules of This Type")
    clearTypeButton:SetWidth(200)
    clearTypeButton:SetCallback("OnClick", function()
        local ruleTypeTitle = ""
        for _, ruleInfo in pairs(RULE_TYPES) do
            if ruleInfo.key == self.activeRuleType then
                ruleTypeTitle = ruleInfo.title
                break
            end
        end

        StaticPopupDialogs["ULTIMATELOOT_CLEAR_RULE_TYPE"] = {
            text = string.format(L["CLEAR_RULE_TYPE_CONFIRM"] or "Are you sure you want to clear all %s rules?",
                ruleTypeTitle:lower()),
            button1 = L["YES"] or "Yes",
            button2 = L["NO"] or "No",
            OnAccept = function()
                E.ItemRules:ClearRules(self.activeRuleType)
                E:Print(string.format("Cleared all %s rules.", self.activeRuleType))
                self:ShowRulesWindow()
                RefreshRulesDisplay(self)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ULTIMATELOOT_CLEAR_RULE_TYPE")
    end)
    bottomControls:AddChild(clearTypeButton)
end

-- Update content of the rules window based on the selected rule type
function ItemRulesUI:UpdateRulesWindowContent()
    if not self.rulesWindow then return end
    
    -- Store all child widgets except the first (which is the tab group)
    local children = {}
    for i=2, select("#", self.rulesWindow.children:GetChildren()) do
        children[#children + 1] = select(i, self.rulesWindow.children:GetChildren())
    end
    
    -- Release all children except the tab group
    for _, child in ipairs(children) do
        self.rulesWindow:RemoveChild(child)
        child:Release()
    end
    
    -- Re-style the tab buttons
    if self.tabGroup then
        for _, child in ipairs({self.tabGroup:GetChildren()}) do
            if child.SetText then
                local ruleType = child.ruleType
                local count = #(E.ItemRules:GetRules()[ruleType] or {})
                local title = nil
                
                -- Find title for this rule type
                for _, ruleInfo in pairs(RULE_TYPES) do
                    if ruleInfo.key == ruleType then
                        title = ruleInfo.title
                        break
                    end
                end
                
                if title then
                    if ruleType == self.activeRuleType then
                        child:SetText("» " .. title .. " (" .. count .. ") «")
                    else
                        child:SetText(title .. " (" .. count .. ")")
                    end
                end
            end
        end
    end
    
    -- Add active rule type content
    self:AddRuleTypeContent(self.rulesWindow)
end

-- Add content specific to the selected rule type
function ItemRulesUI:AddRuleTypeContent(window)
    -- Create scrollFrame for rule list
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    window:AddChild(scrollFrame)
    
    -- Get active rules
    local allRules = E.ItemRules:GetRules()
    local activeRules = allRules[self.activeRuleType] or {}
    
    -- Get active rule info
    local activeRuleInfo = nil
    for _, ruleInfo in pairs(RULE_TYPES) do
        if ruleInfo.key == self.activeRuleType then
            activeRuleInfo = ruleInfo
            break
        end
    end
    
    if #activeRules == 0 then
        -- Show empty state if no rules
        E.UIUtils:ShowEmptyState(scrollFrame, L["NO_RULES_OF_TYPE"])
    else
        -- Create grid container
        local gridContainer = AceGUI:Create("SimpleGroup")
        gridContainer:SetFullWidth(true)
        gridContainer:SetLayout("Flow")
        scrollFrame:AddChild(gridContainer)
        
        -- Title and description
        local titleText = AceGUI:Create("Label")
        if activeRuleInfo and activeRuleInfo.title then
            titleText:SetText(activeRuleInfo.title)
            if activeRuleInfo.color then
                titleText:SetColor(unpack(activeRuleInfo.color))
            end
        else
            titleText:SetText("Rules")
        end
        titleText:SetFontObject(GameFontNormalLarge)
        titleText:SetFullWidth(true)
        gridContainer:AddChild(titleText)
        
        -- Create grid of rule cards
        local cardsPerRow = 2
        local currentRow = nil
        
        for i, rule in ipairs(activeRules) do
            -- Create new row if needed
            if (i-1) % cardsPerRow == 0 then
                currentRow = AceGUI:Create("SimpleGroup")
                if currentRow then
                    currentRow:SetFullWidth(true)
                    currentRow:SetLayout("Flow")
                    gridContainer:AddChild(currentRow)
                end
            end
            
            if currentRow then
                -- Create card for this rule
                local card = AceGUI:Create("InlineGroup")
                card:SetWidth(270)
                card:SetLayout("List")
                
                -- Style card based on rule type
                if activeRuleInfo and activeRuleInfo.color then
                    local r, g, b = unpack(activeRuleInfo.color)
                    card.frame:SetBackdropBorderColor(r, g, b, 0.7)
                end
                
                currentRow:AddChild(card)
                
                -- Create a header group for item label and remove button side by side
                local headerGroup = AceGUI:Create("SimpleGroup")
                headerGroup:SetFullWidth(true)
                headerGroup:SetLayout("Flow")
                card:AddChild(headerGroup)
                
                -- Item name/link with icon if possible
                local itemLabel = AceGUI:Create("InteractiveLabel")
                local displayText = rule.link or rule.name or "Unknown Item"
                
                -- Add pattern indicator if it's a pattern match rule
                if rule.usePattern then
                    displayText = "|cffff8c00[Pattern]|r " .. displayText
                end
                
                -- Add ID if available
                if rule.itemId then
                    displayText = displayText .. " |cff7f7f7f[" .. rule.itemId .. "]|r"
                end
                
                itemLabel:SetText(displayText)
                itemLabel:SetWidth(180) -- Set width to allow space for remove button
                
                -- Add tooltip for item links
                if rule.link then
                    E.UIUtils:AddItemTooltip(itemLabel, rule.link)
                    
                    -- Make item link clickable
                    itemLabel:SetCallback("OnClick", function()
                        if ChatEdit_GetActiveWindow() then
                            ChatEdit_GetActiveWindow():Insert(rule.link)
                        end
                    end)
                end
                headerGroup:AddChild(itemLabel)
                
                -- Remove button (right-aligned in the header)
                local removeButton = AceGUI:Create("Button")
                removeButton:SetText(L["REMOVE"])
                removeButton:SetWidth(80)
                removeButton:SetCallback("OnClick", function()
                    local success, message = E.ItemRules:RemoveItemRule(self.activeRuleType, rule.name, rule.link)
                    if success then
                        E:Print(string.format("Removed %s rule for %s", self.activeRuleType, rule.name or "Unknown"))
                        self:UpdateRulesWindowContent()
                    else
                        E:Print(string.format("Failed to remove rule: %s", message))
                    end
                end)
                headerGroup:AddChild(removeButton)
                
                -- Pattern info
                if rule.usePattern then
                    local patternLabel = AceGUI:Create("Label")
                    patternLabel:SetText(L["PATTERN_MATCHING"] or "Pattern matching: |cffff8c00Enabled|r")
                    patternLabel:SetWidth(200)
                    card:AddChild(patternLabel)
                end
                
                -- Actions group (keeping this for potential future actions)
                local actionsGroup = AceGUI:Create("SimpleGroup")
                actionsGroup:SetLayout("Flow")
                actionsGroup:SetFullWidth(true)
                card:AddChild(actionsGroup)
            end
        end
    end
    
    -- Bottom controls
    local bottomControls = AceGUI:Create("SimpleGroup")
    bottomControls:SetFullWidth(true)
    bottomControls:SetLayout("Flow")
    window:AddChild(bottomControls)
    
    -- Clear rules of this type button
    local clearTypeButton = AceGUI:Create("Button")
    clearTypeButton:SetText(L["CLEAR_RULES_OF_TYPE"])
    clearTypeButton:SetWidth(200)
    clearTypeButton:SetCallback("OnClick", function()
        local ruleTypeTitle = ""
        for _, ruleInfo in pairs(RULE_TYPES) do
            if ruleInfo.key == self.activeRuleType then
                ruleTypeTitle = ruleInfo.title
                break
            end
        end
        
        local dialogText = string.format(L["CLEAR_RULE_TYPE_CONFIRM"], ruleTypeTitle)
        
        StaticPopupDialogs["ULTIMATELOOT_CLEAR_RULE_TYPE"] = {
            text = dialogText,
            button1 = L["YES"],
            button2 = L["NO"],
            OnAccept = function()
                local success = E.ItemRules:ClearRules(self.activeRuleType)
                if success then
                    E:Print("Cleared all " .. ruleTypeTitle .. " rules")
                    self:UpdateRulesWindowContent()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        
        StaticPopup_Show("ULTIMATELOOT_CLEAR_RULE_TYPE")
    end)
    bottomControls:AddChild(clearTypeButton)
    
    -- Add rule form
    self:CreateAddRuleForm(window)
end
