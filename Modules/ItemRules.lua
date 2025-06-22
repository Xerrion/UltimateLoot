local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local ItemRules = E:NewModule("ItemRules", "AceEvent-3.0")
E.ItemRules = ItemRules

-- Rule types
local RULE_TYPES = {
    BLACKLIST = "blacklist",      -- Never pass on these items
    WHITELIST = "whitelist",      -- Always pass on these items
    ALWAYS_NEED = "always_need",  -- Always roll need on these items
    ALWAYS_GREED = "always_greed" -- Always roll greed on these items
}

function ItemRules:OnInitialize()
    -- Register for loot decision events to apply rules
    self:RegisterMessage("ULTIMATELOOT_ITEM_HANDLED", "OnItemHandled")
end

function ItemRules:OnEnable()
    E:DebugPrint("[DEBUG] ItemRules: Module enabled")
end

-- Check if an item should have a specific rule applied
function ItemRules:CheckItemRule(itemName, itemLink, quality)
    if not E.db.item_rules_enabled then
        return nil, "Rules disabled"
    end

    if not itemName then
        return nil, "No item name"
    end

    local rules = E.db.item_rules

    -- Check whitelist first (always pass)
    if self:IsItemInList(itemName, itemLink, rules.whitelist) then
        return "PASS", "Item in whitelist"
    end

    -- Check blacklist (never pass)
    if self:IsItemInList(itemName, itemLink, rules.blacklist) then
        return "NEVER_PASS", "Item in blacklist"
    end

    -- Check always need
    if self:IsItemInList(itemName, itemLink, rules.always_need) then
        return "NEED", "Item in always need list"
    end

    -- Check always greed
    if self:IsItemInList(itemName, itemLink, rules.always_greed) then
        return "GREED", "Item in always greed list"
    end

    return nil, "No specific rule"
end

-- Check if an item is in a specific rule list
function ItemRules:IsItemInList(itemName, itemLink, ruleList)
    if not ruleList or #ruleList == 0 then return false end

    for _, rule in ipairs(ruleList) do
        -- Match by name (case insensitive)
        if rule.name and itemName and itemName:lower():find(rule.name:lower(), 1, true) then
            return true
        end

        -- Match by item ID if available
        if rule.itemId and itemLink then
            local itemId = self:ExtractItemIdFromLink(itemLink)
            if itemId and tonumber(itemId) == tonumber(rule.itemId) then
                return true
            end
        end

        -- Match by exact link
        if rule.link and itemLink and rule.link == itemLink then
            return true
        end
    end

    return false
end

-- Extract item ID from item link
function ItemRules:ExtractItemIdFromLink(itemLink)
    if not itemLink then return nil end

    local itemId = itemLink:match("Hitem:(%d+)")
    return itemId
end

-- Add an item to a rule list
function ItemRules:AddItemRule(ruleType, itemName, itemLink, itemId)
    if not RULE_TYPES[ruleType:upper()] then
        return false, "Invalid rule type"
    end

    local ruleKey = RULE_TYPES[ruleType:upper()]
    local rules = E.db.item_rules[ruleKey]

    if not rules then
        E.db.item_rules[ruleKey] = {}
        rules = E.db.item_rules[ruleKey]
    end

    -- Check if rule already exists
    if self:IsItemInList(itemName, itemLink, rules) then
        return false, "Rule already exists"
    end

    -- Add new rule
    local newRule = {
        name = itemName,
        link = itemLink,
        itemId = itemId or self:ExtractItemIdFromLink(itemLink),
        added = time(),
        addedBy = UnitName("player")
    }

    table.insert(rules, newRule)

    E:DebugPrint("[DEBUG] ItemRules: Added %s rule for %s", ruleType, itemName or "Unknown")

    -- Fire event for UI updates
    E:SendMessage("ULTIMATELOOT_ITEM_RULE_ADDED", {
        ruleType = ruleType,
        rule = newRule
    })

    return true, "Rule added successfully"
end

-- Remove an item from a rule list
function ItemRules:RemoveItemRule(ruleType, itemName, itemLink)
    if not RULE_TYPES[ruleType:upper()] then
        return false, "Invalid rule type"
    end

    local ruleKey = RULE_TYPES[ruleType:upper()]
    local rules = E.db.item_rules[ruleKey]

    if not rules then
        return false, "No rules of this type"
    end

    for i, rule in ipairs(rules) do
        if (rule.name and itemName and rule.name:lower() == itemName:lower()) or
            (rule.link and itemLink and rule.link == itemLink) then
            table.remove(rules, i)

            E:DebugPrint("[DEBUG] ItemRules: Removed %s rule for %s", ruleType, itemName or "Unknown")

            -- Fire event for UI updates
            E:SendMessage("ULTIMATELOOT_ITEM_RULE_REMOVED", {
                ruleType = ruleType,
                rule = rule
            })

            return true, "Rule removed successfully"
        end
    end

    return false, "Rule not found"
end

-- Get all rules of a specific type
function ItemRules:GetRules(ruleType)
    if ruleType then
        local ruleKey = RULE_TYPES[ruleType:upper()]
        return E.db.item_rules[ruleKey] or {}
    else
        return E.db.item_rules
    end
end

-- Clear all rules of a specific type
function ItemRules:ClearRules(ruleType)
    if not ruleType then
        -- Clear all rules
        E.db.item_rules.blacklist = {}
        E.db.item_rules.whitelist = {}
        E.db.item_rules.always_need = {}
        E.db.item_rules.always_greed = {}
        E:DebugPrint("[DEBUG] ItemRules: Cleared all rules")
    else
        local ruleKey = RULE_TYPES[ruleType:upper()]
        if ruleKey then
            E.db.item_rules[ruleKey] = {}
            E:DebugPrint("[DEBUG] ItemRules: Cleared %s rules", ruleType)
        end
    end

    -- Fire event for UI updates
    E:SendMessage("ULTIMATELOOT_ITEM_RULES_CLEARED", {
        ruleType = ruleType
    })
end

-- Handle item decision events for logging
function ItemRules:OnItemHandled(event, handledData)
    if not handledData.isTest then return end -- Only log test decisions for now

    local rule, reason = self:CheckItemRule(handledData.itemName, handledData.itemLink, handledData.quality)
    if rule then
        E:DebugPrint("[DEBUG] ItemRules: Item %s had rule %s (%s)",
            handledData.itemName, rule, reason)
    end
end

-- Enable/disable item rules
function ItemRules:SetEnabled(enabled)
    E.db.item_rules_enabled = enabled
    E:DebugPrint("[DEBUG] ItemRules: %s", enabled and "Enabled" or "Disabled")
end

function ItemRules:IsEnabled()
    return E.db.item_rules_enabled
end
