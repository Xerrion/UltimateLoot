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
    -- Register for rule update events (for note editing)
    self:RegisterMessage("ULTIMATELOOT_ITEM_RULE_UPDATED", "OnItemRuleUpdated")
end

function ItemRules:OnEnable()
    if E.db.debug_mode then
        E:DebugPrint("[DEBUG] ItemRules: Module enabled")
    end
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
    local debugMode = E.db.debug_mode
    
    -- OPTIMIZED: Check rules in priority order, return immediately on first match
    -- Priority order: blacklist > always_need > always_greed > whitelist
    
    -- Check blacklist first (highest priority)
    if self:IsItemInList(itemName, itemLink, rules.blacklist) then
        if debugMode then
            E:DebugPrint("[DEBUG] ItemRules: Found blacklist rule for %s", itemName)
        end
        return "NEVER_PASS", "Item in blacklist"
    end
    
    -- Check always_need (second priority)
    if self:IsItemInList(itemName, itemLink, rules.always_need) then
        if debugMode then
            E:DebugPrint("[DEBUG] ItemRules: Found always_need rule for %s", itemName)
        end
        return "NEED", "Item in always need list"
    end
    
    -- Check always_greed (third priority)
    if self:IsItemInList(itemName, itemLink, rules.always_greed) then
        if debugMode then
            E:DebugPrint("[DEBUG] ItemRules: Found always_greed rule for %s", itemName)
        end
        return "GREED", "Item in always greed list"
    end
    
    -- Check whitelist (lowest priority)
    if self:IsItemInList(itemName, itemLink, rules.whitelist) then
        if debugMode then
            E:DebugPrint("[DEBUG] ItemRules: Found whitelist rule for %s", itemName)
        end
        return "PASS", "Item in whitelist"
    end
    
    return nil, "No specific rule"
end

-- Check if an item is in a specific rule list
function ItemRules:IsItemInList(itemName, itemLink, ruleList)
    if not ruleList or #ruleList == 0 then return false end

    -- OPTIMIZED: Cache lowercased item name to avoid repeated string operations
    local itemNameLower = itemName and itemName:lower()
    local itemId = itemLink and self:ExtractItemIdFromLink(itemLink)
    
    for _, rule in ipairs(ruleList) do
        -- Match by exact link first (fastest comparison)
        if rule.link and itemLink and rule.link == itemLink then
            return true
        end

        -- Match by item ID if available (second fastest)
        if rule.itemId and itemId and tonumber(itemId) == tonumber(rule.itemId) then
            return true
        end

        -- Match by name (slower, string operations)
        if rule.name and itemNameLower then
            if rule.usePattern then
                -- Use Lua pattern matching (regex-like) - wrapped in pcall for safety
                local success, result = pcall(function() 
                    return itemNameLower:match(rule.name:lower()) 
                end)
                if success and result then
                    if E.db.debug_mode then
                        E:DebugPrint("[DEBUG] ItemRules: Pattern match for %s with pattern %s", itemName, rule.name)
                    end
                    return true
                end
            else
                -- Use standard substring match (case insensitive) - faster than pattern matching
                if itemNameLower:find(rule.name:lower(), 1, true) then
                    return true
                end
            end
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
function ItemRules:AddItemRule(ruleType, itemName, itemLink, itemId, options)
    if not RULE_TYPES[ruleType:upper()] then
        return false, "Invalid rule type"
    end

    local ruleKey = RULE_TYPES[ruleType:upper()]
    local rules = E.db.item_rules[ruleKey]

    if not rules then
        E.db.item_rules[ruleKey] = {}
        rules = E.db.item_rules[ruleKey]
    end
    
    options = options or {}
    
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
        addedBy = UnitName("player"),
        usePattern = options.usePattern or false,
        note = options.note
    }

    table.insert(rules, newRule)

    if E.db.debug_mode then
        E:DebugPrint("[DEBUG] ItemRules: Added %s rule for %s%s", 
            ruleType, 
            itemName or "Unknown", 
            newRule.usePattern and " (pattern)" or "")
    end

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

            if E.db.debug_mode then
                E:DebugPrint("[DEBUG] ItemRules: Removed %s rule for %s", ruleType, itemName or "Unknown")
            end

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
        if E.db.debug_mode then
            E:DebugPrint("[DEBUG] ItemRules: Cleared all rules")
        end
    else
        local ruleKey = RULE_TYPES[ruleType:upper()]
        if ruleKey then
            E.db.item_rules[ruleKey] = {}
            if E.db.debug_mode then
                E:DebugPrint("[DEBUG] ItemRules: Cleared %s rules", ruleType)
            end
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
    if rule and E.db.debug_mode then
        E:DebugPrint("[DEBUG] ItemRules: Item %s had rule %s (%s)",
            handledData.itemName, rule, reason)
    end
end

-- Handle rule update events (for note editing)
function ItemRules:OnItemRuleUpdated(event, updateData)
    if not updateData or not updateData.ruleType or not updateData.rule then return end
    if E.db.debug_mode then
        E:DebugPrint("[DEBUG] ItemRules: Updated rule for %s", updateData.rule.name or "Unknown")
    end
end

-- Enable/disable item rules
function ItemRules:SetEnabled(enabled)
    E.db.item_rules_enabled = enabled
    if E.db.debug_mode then
        E:DebugPrint("[DEBUG] ItemRules: %s", enabled and "Enabled" or "Disabled")
    end
end

function ItemRules:IsEnabled()
    return E.db.item_rules_enabled
end
