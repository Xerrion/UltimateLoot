local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local Tracker = E:NewModule("Tracker", "AceEvent-3.0")
E.Tracker = Tracker

-- Centralized quality constants - used across multiple files
E.QUALITY_CONSTANTS = {
    POOR = 0,
    COMMON = 1,
    UNCOMMON = 2,
    RARE = 3,
    EPIC = 4,
    LEGENDARY = 5,

    -- Quality order mapping for settings
    ORDER = {
        poor = 0,
        common = 1,
        uncommon = 2,
        rare = 3,
        epic = 4,
        legendary = 5
    },

    -- Quality colors matching WoW's item quality colors
    COLORS = {
        [0] = { 0.62, 0.62, 0.62 }, -- Poor (gray)
        [1] = { 1, 1, 1 },          -- Common (white)
        [2] = { 0.12, 1, 0 },       -- Uncommon (green)
        [3] = { 0, 0.44, 0.87 },    -- Rare (blue)
        [4] = { 0.64, 0.21, 0.93 }, -- Epic (purple)
        [5] = { 1, 0.5, 0 },        -- Legendary (orange)
    },

    -- Quality names
    NAMES = {
        [0] = "Poor",
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
    }
}

-- Legacy constants for backward compatibility (remove these later)
local QUALITY_COLORS = E.QUALITY_CONSTANTS.COLORS
local QUALITY_NAMES = E.QUALITY_CONSTANTS.NAMES

-- Helper function for safe printing with fallback
local function SafePrint(localeKey, fallback)
    E:Print(L[localeKey] or fallback)
end

function Tracker:OnInitialize()
    -- Initialize saved data
    if not E.db.tracker then
        E.db.tracker = {
            enabled = true,
            history = {},
            stats = {
                totalHandled = 0,
                rollsByType = {
                    pass = 0,  -- Pass rolls (rollType 0)
                    need = 0,  -- Need rolls (rollType 1)
                    greed = 0, -- Greed/Disenchant rolls (rollType 2)
                },
                rollsByQuality = {
                    [0] = { pass = 0, need = 0, greed = 0 }, -- Poor
                    [1] = { pass = 0, need = 0, greed = 0 }, -- Common
                    [2] = { pass = 0, need = 0, greed = 0 }, -- Uncommon
                    [3] = { pass = 0, need = 0, greed = 0 }, -- Rare
                    [4] = { pass = 0, need = 0, greed = 0 }, -- Epic
                    [5] = { pass = 0, need = 0, greed = 0 }, -- Legendary
                },
                itemCounts = {}                              -- Track individual items and their roll counts
            }
        }
    end

    -- Add itemCounts to existing saves if missing
    if not E.db.tracker.stats.itemCounts then
        E.db.tracker.stats.itemCounts = {}
    end

    -- Initialize roll tracking structures if missing
    if not E.db.tracker.stats.rollsByType then
        E.db.tracker.stats.rollsByType = {
            pass = 0,
            need = 0,
            greed = 0
        }
    end

    -- Ensure totalHandled is initialized
    if not E.db.tracker.stats.totalHandled then
        E.db.tracker.stats.totalHandled = 0
    end

    if not E.db.tracker.stats.rollsByQuality then
        E.db.tracker.stats.rollsByQuality = {}
    end

    -- Ensure all quality levels exist (0-5) with roll type tracking
    for quality = 0, 5 do
        if not E.db.tracker.stats.rollsByQuality[quality] then
            E.db.tracker.stats.rollsByQuality[quality] = { pass = 0, need = 0, greed = 0 }
            E:DebugPrint("[DEBUG] Fixed missing quality %d roll counters", quality)
        else
            -- Ensure all roll types exist for this quality
            if not E.db.tracker.stats.rollsByQuality[quality].pass then
                E.db.tracker.stats.rollsByQuality[quality].pass = 0
            end
            if not E.db.tracker.stats.rollsByQuality[quality].need then
                E.db.tracker.stats.rollsByQuality[quality].need = 0
            end
            if not E.db.tracker.stats.rollsByQuality[quality].greed then
                E.db.tracker.stats.rollsByQuality[quality].greed = 0
            end
        end
    end

    self.db = E.db.tracker
end

function Tracker:TrackRoll(itemLink, itemName, quality, rollType)
    if not self.db.enabled then return end

    -- Validate input parameters for edge case testing
    if quality == nil or quality < 0 or quality > 5 then
        E:DebugPrint("[DEBUG] TrackRoll: Invalid quality %s, skipping", tostring(quality))
        return
    end

    if rollType == nil or rollType < 0 or rollType > 2 then
        E:DebugPrint("[DEBUG] TrackRoll: Invalid rollType %s, skipping", tostring(rollType))
        return
    end

    if not itemName or itemName == "" then
        E:DebugPrint("[DEBUG] TrackRoll: Invalid itemName '%s', skipping", tostring(itemName))
        return
    end

    -- Convert rollType to string for consistency
    local rollTypeName = rollType == 1 and "need" or rollType == 2 and "greed" or "pass"

    E:DebugPrint("[DEBUG] Tracker:TrackRoll called for: %s (quality: %s, rollType: %s)",
        itemName, tostring(quality), rollTypeName)

    local timestamp = time()
    local rollData = {
        itemLink = itemLink,
        itemName = itemName,
        quality = quality,
        qualityName = QUALITY_NAMES[quality] or "Unknown",
        rollType = rollType,
        rollTypeName = rollTypeName,
        timestamp = timestamp,
        date = date("%Y-%m-%d %H:%M:%S", timestamp)
    }

    -- OPTIMIZED: Use append-only approach (O(1) instead of O(n))
    table.insert(self.db.history, rollData)
    
    -- Maintain size limit with efficient removal from end
    if #self.db.history > 1000 then
        -- Remove oldest entries (at the end after sorting)
        for i = #self.db.history, 1001, -1 do
            self.db.history[i] = nil
        end
    end

    -- Cache frequently accessed nested table references
    local stats = self.db.stats
    local rollsByType = stats.rollsByType
    local rollsByQuality = stats.rollsByQuality

    -- Update stats (optimized access)
    stats.totalHandled = stats.totalHandled + 1
    rollsByType[rollTypeName] = rollsByType[rollTypeName] + 1

    -- Update quality + roll type counters with cached reference
    local qualityStats = rollsByQuality[quality]
    if qualityStats and qualityStats[rollTypeName] then
        local oldCount = qualityStats[rollTypeName]
        qualityStats[rollTypeName] = oldCount + 1

        -- Only debug legendary items to reduce spam
        if quality == 5 then
            E:DebugPrint("[DEBUG] *** LEGENDARY %s TRACKED! Count: %d -> %d ***", rollTypeName:upper(), oldCount, oldCount + 1)
        end
    else
        E:DebugPrint("[DEBUG] WARNING: rollsByQuality[%s][%s] is nil!", tostring(quality), rollTypeName)
    end

    -- Track individual item counts with roll type breakdown
    local itemKey = itemLink or itemName
    if itemKey then
        local itemData = stats.itemCounts[itemKey]
        if not itemData then
            itemData = {
                totalCount = 0,
                rollCounts = { pass = 0, need = 0, greed = 0 },
                itemName = itemName,
                quality = quality,
                qualityName = QUALITY_NAMES[quality] or "Unknown",
                lastSeen = timestamp,
                lastRollType = rollTypeName
            }
            stats.itemCounts[itemKey] = itemData
        end
        
        itemData.totalCount = itemData.totalCount + 1
        itemData.rollCounts[rollTypeName] = itemData.rollCounts[rollTypeName] + 1
        itemData.lastSeen = timestamp
        itemData.lastRollType = rollTypeName
    end

    -- Fire event for UI updates (single event instead of multiple)
    E:DebugPrint("[DEBUG] Tracker:TrackRoll - Firing ULTIMATELOOT_ITEM_TRACKED event")
    self:SendMessage("ULTIMATELOOT_ITEM_TRACKED", rollData)
end

function Tracker:GetHistory(limit)
    -- OPTIMIZED: Sort history by timestamp descending once, then slice
    -- This is more efficient than inserting at position 1 every time
    local sortedHistory = {}
    for i, entry in ipairs(self.db.history) do
        sortedHistory[i] = entry
    end
    
    -- Sort newest first (descending timestamp)
    table.sort(sortedHistory, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)
    
    -- Return requested slice
    limit = limit or #sortedHistory
    local result = {}
    for i = 1, math.min(limit, #sortedHistory) do
        result[i] = sortedHistory[i]
    end
    return result
end

function Tracker:GetStats()
    return self.db.stats
end

function Tracker:GetRollsByTimeframe(hours)
    local cutoff = time() - (hours * 3600)
    local counts = { total = 0, pass = 0, need = 0, greed = 0 }

    for _, roll in ipairs(self.db.history) do
        if roll.timestamp >= cutoff then
            counts.total = counts.total + 1
            if roll.rollTypeName then
                counts[roll.rollTypeName] = counts[roll.rollTypeName] + 1
            else
                -- Legacy data compatibility - assume pass if no roll type
                counts.pass = counts.pass + 1
            end
        else
            break -- History is sorted newest first
        end
    end

    return counts
end

function Tracker:GetHourlyData(hours)
    hours = hours or 24
    local hourlyData = {}
    local now = time()

    -- Initialize hourly buckets
    for i = 0, hours - 1 do
        hourlyData[i] = 0
    end

    -- Fill buckets with data
    for _, roll in ipairs(self.db.history) do
        local hoursSince = math.floor((now - roll.timestamp) / 3600)
        if hoursSince < hours and hoursSince >= 0 then
            hourlyData[hoursSince] = hourlyData[hoursSince] + 1
        elseif hoursSince >= hours then
            break
        end
    end

    return hourlyData
end

function Tracker:ClearHistory()
    E:DebugPrint("[DEBUG] Tracker:ClearHistory called")

    wipe(self.db.history)
    self.db.stats.totalHandled = 0

    -- Clear roll type counters
    for rollType in pairs(self.db.stats.rollsByType) do
        self.db.stats.rollsByType[rollType] = 0
    end

    -- Clear quality + roll type counters
    for quality = 0, 5 do
        if self.db.stats.rollsByQuality[quality] then
            for rollType in pairs(self.db.stats.rollsByQuality[quality]) do
                self.db.stats.rollsByQuality[quality][rollType] = 0
            end
        end
    end

    wipe(self.db.stats.itemCounts)

    -- Fire multiple events for different listeners
    E:DebugPrint("[DEBUG] Tracker:ClearHistory - Firing ULTIMATELOOT_HISTORY_CLEARED event")
    self:SendMessage("ULTIMATELOOT_HISTORY_CLEARED")

    E:DebugPrint("[DEBUG] Tracker:ClearHistory - Firing ULTIMATELOOT_STATS_RESET event")
    self:SendMessage("ULTIMATELOOT_STATS_RESET")

    E:DebugPrint("[DEBUG] Tracker:ClearHistory - Firing ULTIMATELOOT_DATA_CHANGED event")
    self:SendMessage("ULTIMATELOOT_DATA_CHANGED", {
        type = "history_cleared",
        timestamp = time()
    })
end

function Tracker:ClearStats()
    E:DebugPrint("[DEBUG] Tracker:ClearStats called")

    self.db.stats.totalHandled = 0

    -- Clear roll type counters
    for rollType in pairs(self.db.stats.rollsByType) do
        self.db.stats.rollsByType[rollType] = 0
    end

    -- Clear quality + roll type counters
    for quality = 0, 5 do
        if self.db.stats.rollsByQuality[quality] then
            for rollType in pairs(self.db.stats.rollsByQuality[quality]) do
                self.db.stats.rollsByQuality[quality][rollType] = 0
            end
        end
    end

    wipe(self.db.stats.itemCounts)

    -- Fire event for stats reset
    E:DebugPrint("[DEBUG] Tracker:ClearStats - Firing ULTIMATELOOT_STATS_RESET event")
    self:SendMessage("ULTIMATELOOT_STATS_RESET")

    E:DebugPrint("[DEBUG] Tracker:ClearStats - Firing ULTIMATELOOT_DATA_CHANGED event")
    self:SendMessage("ULTIMATELOOT_DATA_CHANGED", {
        type = "stats_cleared",
        timestamp = time()
    })
end

function Tracker:ClearAllData()
    E:DebugPrint("[DEBUG] Tracker:ClearAllData called")

    self:ClearHistory()
    self:ClearStats()

    -- Fire comprehensive data change event
    E:DebugPrint("[DEBUG] Tracker:ClearAllData - Firing ULTIMATELOOT_ALL_DATA_CLEARED event")
    self:SendMessage("ULTIMATELOOT_ALL_DATA_CLEARED")

    E:DebugPrint("[DEBUG] Tracker:ClearAllData - Firing ULTIMATELOOT_DATA_CHANGED event")
    self:SendMessage("ULTIMATELOOT_DATA_CHANGED", {
        type = "all_data_cleared",
        timestamp = time()
    })

    SafePrint("ALL_DATA_CLEARED", "All data cleared.")
end

function Tracker:ExportData()
    if not self.db.history or #self.db.history == 0 then
        return nil
    end

    local exportTable = {
        version = "1.0",
        exportDate = date("%Y-%m-%d %H:%M:%S"),
        character = UnitName("player"),
        realm = GetRealmName(),
        history = self.db.history,
        stats = self.db.stats
    }

    -- Convert to string representation
    local function serializeTable(tbl, indent)
        indent = indent or 0
        local result = {}
        local indentStr = string.rep("  ", indent)

        for k, v in pairs(tbl) do
            local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%s]", k)

            if type(v) == "table" then
                table.insert(result, string.format("%s%s = {", indentStr, key))
                table.insert(result, serializeTable(v, indent + 1))
                table.insert(result, string.format("%s},", indentStr))
            elseif type(v) == "string" then
                table.insert(result, string.format("%s%s = %q,", indentStr, key, v))
            else
                table.insert(result, string.format("%s%s = %s,", indentStr, key, tostring(v)))
            end
        end

        return table.concat(result, "\n")
    end

    local exportString = "-- UltimateLoot Export Data\n"
    exportString = exportString .. "-- Generated on " .. exportTable.exportDate .. "\n"
    exportString = exportString .. "-- Character: " .. exportTable.character .. " - " .. exportTable.realm .. "\n\n"
    exportString = exportString .. "local exportData = {\n"
    exportString = exportString .. serializeTable(exportTable, 1)
    exportString = exportString .. "\n}\n\nreturn exportData"

    return exportString
end

function Tracker:GetQualityColor(quality)
    return QUALITY_COLORS[quality] or { 1, 1, 1 }
end

function Tracker:GetQualityName(quality)
    return QUALITY_NAMES[quality] or "Unknown"
end

function Tracker:GetItemCounts()
    return self.db.stats.itemCounts
end

function Tracker:GetTopRolledItems(limit)
    limit = limit or 10
    local items = {}

    -- Convert to sorted array
    for itemKey, data in pairs(self.db.stats.itemCounts) do
        table.insert(items, {
            itemKey = itemKey,
            itemName = data.itemName,
            totalCount = data.totalCount or data.count,                                      -- Support legacy data
            rollCounts = data.rollCounts or { pass = data.count or 0, need = 0, greed = 0 }, -- Support legacy data
            quality = data.quality,
            qualityName = data.qualityName,
            lastSeen = data.lastSeen,
            lastRollType = data.lastRollType or "pass"
        })
    end

    -- Sort by total count (descending)
    table.sort(items, function(a, b) return a.totalCount > b.totalCount end)

    -- Return top items
    local result = {}
    for i = 1, math.min(limit, #items) do
        result[i] = items[i]
    end

    return result
end
