local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local ItemRulesUI = E:NewModule("ItemRulesUI")
E.ItemRulesUI = ItemRulesUI
local AceGUI = E.Libs.AceGUI

-- Helper function to get quality color and apply it to a widget
local function SetQualityColor(widget, quality)
    local r, g, b = unpack(E.Tracker:GetQualityColor(quality))
    widget:SetColor(r, g, b)
    return r, g, b
end

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

    -- Main scroll frame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    container:AddChild(scrollFrame)

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

    -- Add rule button
    local addButton = AceGUI:Create("Button")
    addButton:SetText(L["ADD_RULE"])
    addButton:SetWidth(100)
    addButton:SetCallback("OnClick", function()
        local itemText = itemInput:GetText()
        local ruleType = ruleTypeDropdown:GetValue()

        if not itemText or itemText:trim() == "" then
            E:Print("Please enter an item name or link.")
            return
        end

        if not ruleType then
            E:Print("Please select a rule type.")
            return
        end

        -- Parse item link or name
        local itemName, itemLink, itemId
        if itemText:match("|H") then
            -- It's an item link
            itemLink = itemText
            itemName = itemText:match("%[(.-)%]") or "Unknown Item"
            itemId = itemText:match("Hitem:(%d+)")
        else
            -- It's just a name
            itemName = itemText
        end

        -- Add the rule
        local success, message = E.ItemRules:AddItemRule(ruleType, itemName, itemLink, itemId)

        if success then
            E:Print(string.format("Added %s rule for %s", ruleType, itemName))
            itemInput:SetText("")
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
        StaticPopupDialogs["ULTIMATELOOT_CLEAR_ALL_RULES"] = {
            text = L["CLEAR_ALL_RULES_CONFIRM"],
            button1 = L["YES"],
            button2 = L["NO"],
            OnAccept = function()
                if E.ItemRules then
                    E.ItemRules:ClearRules()
                    E:Print("All item rules cleared.")
                    RefreshRulesDisplay(self)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ULTIMATELOOT_CLEAR_ALL_RULES")
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

        local noRulesLabel = AceGUI:Create("Label")
        noRulesLabel:SetText(L["NO_RULES_CONFIGURED"])
        noRulesLabel:SetFullWidth(true)
        noRulesGroup:AddChild(noRulesLabel)
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
                itemLabel:SetText(displayText)
                itemLabel:SetWidth(300)
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
                    idLabel:SetWidth(80)
                    idLabel:SetColor(0.7, 0.7, 0.7)
                    ruleFrame:AddChild(idLabel)
                end

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
