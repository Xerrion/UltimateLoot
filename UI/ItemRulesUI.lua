local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local ItemRulesUI = E:NewModule("ItemRulesUI")
E.ItemRulesUI = ItemRulesUI
local AceGUI = E.Libs.AceGUI

-- Using UIUtils for shared functionality

-- Helper function to refresh the rules display
local function RefreshRulesDisplay(self)
    if self.currentContainer then
        self:CreateItemRulesTab(self.currentContainer)
    end
end

function ItemRulesUI:CreateItemRulesTab(container)
    -- Store container for refreshing
    self.currentContainer = container

    -- Clear container to ensure clean refresh
    container:ReleaseChildren()

    -- Main scroll frame using UIUtils
    local scrollFrame = E.UIUtils:CreateScrollFrame(container)

    -- Item Rules Enable/Disable
    local enableGroup = AceGUI:Create("InlineGroup")
    enableGroup:SetTitle(L["ITEM_RULES_SYSTEM"])
    enableGroup:SetFullWidth(true)
    enableGroup:SetLayout("Flow")
    scrollFrame:AddChild(enableGroup)

    local enabledCheckbox = AceGUI:Create("CheckBox")
    enabledCheckbox:SetLabel(L["ENABLE_ITEM_RULES"])
    enabledCheckbox:SetDescription(L["ENABLE_ITEM_RULES_DESC"])
    enabledCheckbox:SetValue(E.ItemRules and E.ItemRules:IsEnabled() or false)
    enabledCheckbox:SetFullWidth(true)
    enabledCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        if E.ItemRules then
            E.ItemRules:SetEnabled(value)
            RefreshRulesDisplay(self)
        end
    end)
    enableGroup:AddChild(enabledCheckbox)

    if not E.ItemRules or not E.ItemRules:IsEnabled() then
        local disabledLabel = AceGUI:Create("Label")
        disabledLabel:SetText("|cff888888" .. L["ITEM_RULES_DISABLED"] .. "|r")
        disabledLabel:SetFullWidth(true)
        enableGroup:AddChild(disabledLabel)
        return
    end

    -- Add New Rule Section (only shown when enabled)
    local addGroup = AceGUI:Create("InlineGroup")
    addGroup:SetTitle(L["ADD_NEW_RULE"])
    addGroup:SetFullWidth(true)
    addGroup:SetLayout("Flow")
    scrollFrame:AddChild(addGroup)

    -- Item input field
    local itemInput = AceGUI:Create("EditBox")
    itemInput:SetLabel(L["ITEM_NAME_OR_LINK"])
    itemInput:SetText("")
    itemInput:SetWidth(300)
    itemInput:SetCallback("OnTextChanged", function(widget, event, text)
        -- Could add real-time validation here
    end)
    addGroup:AddChild(itemInput)

    -- Rule type dropdown
    local ruleTypeDropdown = AceGUI:Create("Dropdown")
    ruleTypeDropdown:SetLabel(L["RULE_TYPE"])
    ruleTypeDropdown:SetList({
        whitelist = "|cff00ff00" .. L["ALWAYS_PASS"] .. "|r - " .. L["ALWAYS_PASS_DESC"],
        blacklist = "|cffff0000" .. L["NEVER_PASS"] .. "|r - " .. L["NEVER_PASS_DESC"],
        always_need = "|cff0080ff" .. L["ALWAYS_NEED"] .. "|r - " .. L["ALWAYS_NEED_DESC"],
        always_greed = "|cffffaa00" .. L["ALWAYS_GREED"] .. "|r - " .. L["ALWAYS_GREED_DESC"]
    })
    ruleTypeDropdown:SetValue("whitelist")
    ruleTypeDropdown:SetWidth(250)
    addGroup:AddChild(ruleTypeDropdown)
    
    -- Advanced options section
    local optionsGroup = AceGUI:Create("SimpleGroup")
    optionsGroup:SetFullWidth(true)
    optionsGroup:SetLayout("Flow")
    addGroup:AddChild(optionsGroup)
    
    -- Pattern matching checkbox
    local patternMatchCheck = AceGUI:Create("CheckBox")
    patternMatchCheck:SetLabel(L["USE_PATTERN"] or "Use pattern matching")
    patternMatchCheck:SetDescription(L["USE_PATTERN_DESC"] or "Use Lua pattern matching for more flexible item name rules")
    patternMatchCheck:SetValue(false)
    patternMatchCheck:SetWidth(200)
    optionsGroup:AddChild(patternMatchCheck)
    
    -- Note field
    local noteInput = AceGUI:Create("EditBox")
    noteInput:SetLabel(L["RULE_NOTE"] or "Rule Note")
    noteInput:SetText("")
    noteInput:SetWidth(300)
    noteInput:SetCallback("OnTextChanged", function(widget, event, text)
        -- Optional validation
    end)
    optionsGroup:AddChild(noteInput)

    -- Add rule button
    local addButton = AceGUI:Create("Button")
    addButton:SetText(L["ADD_RULE"])
    addButton:SetWidth(100)
    addButton:SetCallback("OnClick", function()
        local itemText = itemInput:GetText()
        local ruleType = ruleTypeDropdown:GetValue()
        local usePattern = patternMatchCheck:GetValue()
        local note = noteInput:GetText()
        
        if not note or note:trim() == "" then
            note = nil  -- Don't store empty notes
        end

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
            usePattern = usePattern,
            note = note
        }
        
        local success, message = E.ItemRules:AddItemRule(ruleType, itemName, itemLink, itemId, options)

        if success then
            E:Print(string.format("Added %s rule for %s%s", 
                ruleType, 
                itemName, 
                usePattern and " (pattern matching)" or ""))
            itemInput:SetText("")
            noteInput:SetText("")
            patternMatchCheck:SetValue(false)
            RefreshRulesDisplay(self)
        else
            E:Print(string.format("Failed to add rule: %s", message))
        end
    end)
    addGroup:AddChild(addButton)

    -- Clear button
    local clearButton = AceGUI:Create("Button")
    clearButton:SetText(L["CLEAR"])
    clearButton:SetWidth(80)
    clearButton:SetCallback("OnClick", function()
        itemInput:SetText("")
        noteInput:SetText("")
        patternMatchCheck:SetValue(false)
    end)
    addGroup:AddChild(clearButton)

    -- Existing Rules Display
    self:CreateRulesList(scrollFrame)

    -- Management Buttons (only shown when enabled)
    local managementGroup = AceGUI:Create("InlineGroup")
    managementGroup:SetTitle(L["RULE_MANAGEMENT"])
    managementGroup:SetFullWidth(true)
    managementGroup:SetLayout("Flow")
    scrollFrame:AddChild(managementGroup)

    -- Test rules button
    local testButton = AceGUI:Create("Button")
    testButton:SetText(L["TEST_RULES"])
    testButton:SetWidth(100)
    testButton:SetCallback("OnClick", function()
        if E.UltimateLoot and E.UltimateLoot.TestItemRules then
            E.UltimateLoot:TestItemRules()
        end
    end)
    managementGroup:AddChild(testButton)

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
            end
        end)
    end)
    managementGroup:AddChild(clearAllButton)
end

function ItemRulesUI:CreateRulesList(container)
    if not E.ItemRules then return end

    local allRules = E.ItemRules:GetRules()
    local hasAnyRules = false

    -- Check if we have any rules at all
    for ruleType, rules in pairs(allRules) do
        if rules and #rules > 0 then
            hasAnyRules = true
            break
        end
    end

    if not hasAnyRules then
        local noRulesGroup = AceGUI:Create("InlineGroup")
        noRulesGroup:SetTitle(L["CURRENT_RULES"])
        noRulesGroup:SetFullWidth(true)
        noRulesGroup:SetLayout("Flow")
        container:AddChild(noRulesGroup)

        E.UIUtils:ShowEmptyState(noRulesGroup, L["NO_RULES_CONFIGURED"])
        return
    end

    -- Create sections for each rule type
    local ruleTypeInfo = {
        whitelist = { title = L["ALWAYS_PASS_RULES"], color = { 0, 1, 0 }, desc = L["ALWAYS_PASS_RULES_DESC"] },
        blacklist = { title = L["NEVER_PASS_RULES"], color = { 1, 0, 0 }, desc = L["NEVER_PASS_RULES_DESC"] },
        always_need = { title = L["ALWAYS_NEED_RULES"], color = { 0, 0.5, 1 }, desc = L["ALWAYS_NEED_RULES_DESC"] },
        always_greed = { title = L["ALWAYS_GREED_RULES"], color = { 1, 0.67, 0 }, desc = L["ALWAYS_GREED_RULES_DESC"] }
    }

    for ruleType, info in pairs(ruleTypeInfo) do
        local rules = allRules[ruleType]
        if rules and #rules > 0 then
            local ruleGroup = AceGUI:Create("InlineGroup")
            ruleGroup:SetTitle(info.title .. " (" .. #rules .. ")")
            ruleGroup:SetFullWidth(true)
            ruleGroup:SetLayout("Flow")
            container:AddChild(ruleGroup)

            -- Description
            local descLabel = AceGUI:Create("Label")
            descLabel:SetText(info.desc)
            descLabel:SetColor(unpack(info.color))
            descLabel:SetFullWidth(true)
            descLabel:SetFontObject(GameFontNormalSmall)
            ruleGroup:AddChild(descLabel)

            -- Rules list
            for i, rule in ipairs(rules) do
                local ruleFrame = AceGUI:Create("SimpleGroup")
                ruleFrame:SetLayout("Flow")
                ruleFrame:SetFullWidth(true)
                ruleGroup:AddChild(ruleFrame)

                -- Item name/link
                local itemLabel = AceGUI:Create("InteractiveLabel")
                local displayText = rule.link or rule.name or "Unknown Item"
                
                -- Add pattern indicator if it's a pattern match rule
                if rule.usePattern then
                    displayText = "|cffff8c00[Pattern]|r " .. displayText
                end
                
                itemLabel:SetText(displayText)
                itemLabel:SetWidth(240)
                if rule.link then
                    itemLabel:SetCallback("OnClick", function()
                        -- Copy item link to chat
                        if ChatEdit_GetActiveWindow() then
                            ChatEdit_GetActiveWindow():Insert(rule.link)
                        end
                    end)
                end
                ruleFrame:AddChild(itemLabel)

                -- Item ID if available
                if rule.itemId then
                    local idLabel = AceGUI:Create("Label")
                    idLabel:SetText("ID: " .. rule.itemId)
                    idLabel:SetWidth(60)
                    idLabel:SetColor(0.7, 0.7, 0.7)
                    ruleFrame:AddChild(idLabel)
                end
                
                -- Note section
                local noteGroup = AceGUI:Create("SimpleGroup")
                noteGroup:SetLayout("Flow")
                noteGroup:SetWidth(200)
                ruleFrame:AddChild(noteGroup)
                
                -- Note display or placeholder
                local noteText = rule.note or L["NO_NOTE"]
                local noteColor = rule.note and {0.6, 0.8, 0.9} or {0.5, 0.5, 0.5}
                local noteLabel = AceGUI:Create("InteractiveLabel")
                noteLabel:SetText(rule.note or L["ADD_NOTE"])
                noteLabel:SetWidth(180)
                noteLabel:SetColor(unpack(noteColor))
                
                -- Edit functionality
                noteLabel:SetCallback("OnClick", function()
                    -- Create popup for editing note
                    StaticPopupDialogs["ULTIMATELOOT_EDIT_NOTE"] = {
                        text = L["EDIT_NOTE_FOR"] .. (rule.link or rule.name or L["UNKNOWN_ITEM"]),
                        button1 = L["OKAY"] or "Okay",
                        button2 = L["CANCEL"] or "Cancel",
                        hasEditBox = true,
                        editBoxWidth = 300,
                        OnShow = function(dialog)
                            dialog.editBox:SetText(rule.note or "")
                            dialog.editBox:SetFocus()
                        end,
                        OnAccept = function(dialog)
                            local newNote = dialog.editBox:GetText()
                            if newNote and newNote:trim() ~= "" then
                                rule.note = newNote
                            else
                                rule.note = nil
                            end
                            -- Refresh UI to show updated note
                            RefreshRulesDisplay(self)
                            -- Fire event for data update
                            E:SendMessage("ULTIMATELOOT_ITEM_RULE_UPDATED", {
                                ruleType = ruleType,
                                rule = rule
                            })
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ULTIMATELOOT_EDIT_NOTE")
                end)
                noteGroup:AddChild(noteLabel)

                -- Remove button
                local removeButton = AceGUI:Create("Button")
                removeButton:SetText(L["REMOVE"])
                removeButton:SetWidth(80)
                removeButton:SetCallback("OnClick", function()
                    local success, message = E.ItemRules:RemoveItemRule(ruleType, rule.name, rule.link)
                    if success then
                        E:Print(string.format("Removed %s rule for %s", ruleType, rule.name or "Unknown"))
                        RefreshRulesDisplay(self)
                    else
                        E:Print(string.format("Failed to remove rule: %s", message))
                    end
                end)
                ruleFrame:AddChild(removeButton)
            end

            -- Clear this type button
            local clearTypeButton = AceGUI:Create("Button")
            clearTypeButton:SetText("Clear All " .. info.title)
            clearTypeButton:SetWidth(150)
            clearTypeButton:SetCallback("OnClick", function()
                StaticPopupDialogs["ULTIMATELOOT_CLEAR_RULE_TYPE"] = {
                    text = string.format(L["CLEAR_RULE_TYPE_CONFIRM"], info.title:lower()),
                    button1 = L["YES"],
                    button2 = L["NO"],
                    OnAccept = function()
                        E.ItemRules:ClearRules(ruleType)
                        E:Print(string.format("Cleared all %s rules.", ruleType))
                        RefreshRulesDisplay(self)
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("ULTIMATELOOT_CLEAR_RULE_TYPE")
            end)
            ruleGroup:AddChild(clearTypeButton)
        end
    end
end
