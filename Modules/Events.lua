local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

-- Local quality order (loaded before E.QUALITY_CONSTANTS is available)
local QUALITY_ORDER = {
  uncommon = 2, -- Uncommon (Green)
  rare = 3,     -- Rare (Blue)
  epic = 4,     -- Epic (Purple)
  legendary = 5 -- Legendary (Orange)
}

-- Initialize events system
function E:InitializeEvents()
  -- Core loot roll events
  self:RegisterEvent("START_LOOT_ROLL")
  self:RegisterEvent("CANCEL_LOOT_ROLL")
  self:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED")

  -- Player state events
  self:RegisterEvent("PLAYER_LOGIN")
  self:RegisterEvent("ADDON_LOADED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")

  -- Note: Group events removed as they were only used for debug logging

  -- Fire module initialization event
  E:DebugPrint("[DEBUG] Events system initialized, firing ULTIMATELOOT_EVENTS_INITIALIZED")
  self:SendMessage("ULTIMATELOOT_EVENTS_INITIALIZED")
end

function E:START_LOOT_ROLL(_, rollID)
  -- Safety checks
  if not rollID or rollID < 1 then
    E:DebugPrint("[DEBUG] Invalid rollID received: %s", tostring(rollID))
    return
  end

  if not self.UltimateLoot or not E:GetEnabled() then
    E:DebugPrint("[DEBUG] UltimateLoot not available or disabled")
    return
  end

  -- Get loot roll information with error handling
  local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant =
      GetLootRollItemInfo(rollID)

  if not name or not quality then
    E:DebugPrint("[DEBUG] Failed to get loot roll item info for rollID: %s", rollID)
    return
  end

  -- OPTIMIZED: Cache frequently accessed values and get itemLink once
  local db = self.db
  local threshold = db.loot_quality_threshold or "epic"
  local thresholdValue = QUALITY_ORDER[threshold] or 4
  
  -- Get item link once for reuse throughout function
  local itemLink = GetLootRollItemLink(rollID)
  if not itemLink then
    local qualityColors = E.QUALITY_CONSTANTS and E.QUALITY_CONSTANTS.COLORS[quality] or { 1, 1, 1 }
    itemLink = string.format("|cff%02x%02x%02x|Hitem:0:0:0:0:0:0:0:0:80|h[%s]|h|r",
      qualityColors[1] * 255, qualityColors[2] * 255, qualityColors[3] * 255, name)
  end

  E:DebugPrint("[DEBUG] Loot roll started: %s (Quality: %d, Threshold: %s=%d)",
    name, quality, threshold, thresholdValue)
  E:DebugPrint("[DEBUG] Roll options - Need: %s, Greed: %s, Disenchant: %s",
    tostring(canNeed), tostring(canGreed), tostring(canDisenchant))

  -- Check for Pass on All override first
  if E.db.pass_on_all then
    local success = pcall(RollOnLoot, rollID, 0) -- Always pass
    if success then
      E:DebugPrint("[DEBUG] Pass on All: Passed on %s", name)

      if db.show_notifications then
        local qualityName = E.QUALITY_CONSTANTS and E.QUALITY_CONSTANTS.NAMES[quality] or "Unknown"
        E:Print(string.format("Pass on All: Passed on %s (%s)", name, qualityName))
      end

      -- OPTIMIZED: Create event data once and reuse
      local eventData = {
        rollID = rollID,
        itemName = name,
        itemLink = itemLink,
        quality = quality,
        action = "Passed on (Pass on All mode)",
        rollType = 0,
        reason = "Pass on All override",
        timestamp = time()
      }

      self:SendMessage("ULTIMATELOOT_ITEM_HANDLED", eventData)

      if self.Tracker then
        self.Tracker:TrackRoll(itemLink, name, quality, 0) -- 0 = Pass
      end
    end
    return -- Exit early, don't process any other logic
  end

  -- Determine if we should automatically handle this item
  local shouldPass = quality <= thresholdValue
  local rollAction = 0 -- Default to pass
  local reason = "Quality threshold"

  -- Check item-specific rules first
  if E.ItemRules and E.ItemRules:IsEnabled() then
    local rule, ruleReason = E.ItemRules:CheckItemRule(name, itemLink, quality)

    if rule == "NEVER_PASS" then
      E:DebugPrint("[DEBUG] Item rule: Never pass on %s (%s)", name, ruleReason)
      return -- Don't automatically handle due to item rule
    elseif rule == "PASS" then
      shouldPass = true
      reason = ruleReason
      E:DebugPrint("[DEBUG] Item rule: Force pass on %s (%s)", name, ruleReason)
    elseif rule == "NEED" then
      rollAction = 1 -- Need
      shouldPass = true
      reason = ruleReason
      E:DebugPrint("[DEBUG] Item rule: Force need on %s (%s)", name, ruleReason)
    elseif rule == "GREED" then
      rollAction = 2 -- Always Greed (never disenchant for this rule)
      shouldPass = true
      reason = ruleReason
      E:DebugPrint("[DEBUG] Item rule: Force greed on %s (%s)", name, ruleReason)
    elseif rule == "GREED_DISENCHANT" then
      -- Use disenchant if available, otherwise greed
      rollAction = canDisenchant and 3 or 2
      shouldPass = true
      reason = canDisenchant and (ruleReason .. " (disenchanting)") or ruleReason
      E:DebugPrint("[DEBUG] Item rule: Force %s on %s (%s)", 
        canDisenchant and "disenchant" or "greed", name, ruleReason)
    else
      -- No specific rule, use quality threshold
      shouldPass = quality <= thresholdValue
      reason = string.format("Quality %d vs threshold %d", quality, thresholdValue)
    end
  end

  if shouldPass then
    -- If we would pass, check if we should disenchant instead (unless Pass on All is active)
    if rollAction == 0 and canDisenchant and not E.db.pass_on_all then
      rollAction = 3
      reason = reason .. " (disenchanting)"
      E:DebugPrint("[DEBUG] Switching from pass to disenchant for %s", name)
    end

    -- Roll on the loot
    local success = pcall(RollOnLoot, rollID, rollAction)

    if success then
      local actionName
      if rollAction == 1 then
        actionName = "needed"
      elseif rollAction == 2 then
        actionName = "greeded"
      elseif rollAction == 3 then
        actionName = "disenchanted"
      else
        actionName = "passed"
      end
      
      E:DebugPrint("[DEBUG] Successfully %s on %s (%s)", actionName, name, reason)

      -- Show notification if enabled  
      if db.show_notifications then
        local qualityName = E.QUALITY_CONSTANTS and E.QUALITY_CONSTANTS.NAMES[quality] or "Unknown"
        E:Print(string.format("Auto-%s on %s (%s) - %s", actionName, name, qualityName, reason))
      end

      -- OPTIMIZED: Create base event data once and extend as needed
      local eventData = {
        rollID = rollID,
        itemName = name,
        itemLink = itemLink,
        quality = quality,
        rollType = rollAction,
        reason = reason,
        timestamp = time()
      }

      -- Fire event for all loot decisions (expanded functionality)
      if rollAction == 0 then
        eventData.threshold = threshold
        eventData.thresholdValue = thresholdValue
        eventData.action = "Passed on"
      elseif rollAction == 1 then
        eventData.action = "Rolled Need on"
      elseif rollAction == 2 then
        eventData.action = "Rolled Greed on"
      elseif rollAction == 3 then
        eventData.action = "Disenchanted"
      end

      self:SendMessage("ULTIMATELOOT_ITEM_HANDLED", eventData)

      -- Track the roll for all actions (Pass=0, Need=1, Greed=2, Disenchant=3)
      -- Map disenchant (3) to greed (2) for tracking purposes since they're functionally similar
      local trackingRollType = rollAction == 3 and 2 or rollAction
      if self.Tracker then
        self.Tracker:TrackRoll(itemLink, name, quality, trackingRollType)
      end
    else
      E:DebugPrint("[DEBUG] Failed to roll on %s - RollOnLoot call failed", name)
      self:HandleError("ROLL_FAILED", "Failed to roll on " .. name, "START_LOOT_ROLL")
    end
  else
    E:DebugPrint("[DEBUG] Not auto-rolling on %s - %s", name, reason)
  end
end

-- Handle loot roll cancellation for cleanup
function E:CANCEL_LOOT_ROLL(_, rollID)
  E:DebugPrint("[DEBUG] Loot roll cancelled: %s", tostring(rollID))

  -- Fire event for UI updates or cleanup
  self:SendMessage("ULTIMATELOOT_LOOT_ROLL_CANCELLED", {
    rollID = rollID,
    timestamp = time()
  })
end

-- Monitor loot roll changes (when players make their choices)
function E:LOOT_HISTORY_ROLL_CHANGED(_, rollID, playerName)
  if not self.db.debug_mode then return end -- Only log in debug mode

  E:DebugPrint("[DEBUG] Loot roll changed for %s on rollID %s",
    tostring(playerName), tostring(rollID))
end

-- Group change events removed - were only used for debug logging with no functionality

function E:PLAYER_LOGIN()
  E:DebugPrint("[DEBUG] PLAYER_LOGIN event received")
  
  if self.UltimateLoot then
    self.UltimateLoot:PrintStatus()

    -- Fire login event for other modules
    E:DebugPrint("[DEBUG] Firing ULTIMATELOOT_PLAYER_LOGIN event")
    self:SendMessage("ULTIMATELOOT_PLAYER_LOGIN")
  end
end

function E:ADDON_LOADED(_, addonName)
  E:DebugPrint("[DEBUG] ADDON_LOADED event received for: %s", addonName)
  
  if self.UltimateLoot and addonName == self._name then
    self.UltimateLoot:PrintStatus()

    -- Fire addon loaded event
    E:DebugPrint("[DEBUG] Firing ULTIMATELOOT_ADDON_LOADED event")
    self:SendMessage("ULTIMATELOOT_ADDON_LOADED", addonName)
  end
end

function E:PLAYER_ENTERING_WORLD()
  E:DebugPrint("[DEBUG] PLAYER_ENTERING_WORLD event received")
  
  if self.UltimateLoot then
    self.UltimateLoot:PrintStatus()

    -- Fire world enter event
    E:DebugPrint("[DEBUG] Firing ULTIMATELOOT_WORLD_ENTERED event")
    self:SendMessage("ULTIMATELOOT_WORLD_ENTERED")
  end
end

-- Error handling function that fires events
function E:HandleError(errorType, errorMessage, context)
  E:DebugPrint("[DEBUG] HandleError called: %s - %s", errorType, errorMessage)

  self:SendMessage("ULTIMATELOOT_ERROR", {
    type = errorType,
    message = errorMessage,
    context = context,
    timestamp = time()
  })

  -- Also log to console/saved variables
  if self.Log then
    self:Log("Error", "%s: %s (Context: %s)", errorType, errorMessage, tostring(context))
  end
end
