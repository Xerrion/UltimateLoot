--[[
Core\Options.lua
Handles the creation and management of configuration options using AceConfig.

Main Functions:
- E:GetEnabled(): Returns the current enabled state.
- E:SetEnabled(val): Sets the enabled state.
- E:GetLootQualityThreshold(): Returns the current loot quality threshold.
- E:SetLootQualityThreshold(val): Sets the loot quality threshold.
- E:AddOption(key, name, desc, type, getter, setter, values): Adds a new dynamic option.
- E:CreateOptionsTable(): Creates the configuration options table.
- E:ShowOptionsDialog(): Opens the options dialog in the UI.
- E:CloseOptionsDialog(): Closes the options dialog.
]]

local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

function E:GetEnabled()
    return self.db.enabled
end

function E:SetEnabled(val)
    local oldValue = self.db.enabled
    self.db.enabled = val
    if self.UltimateLoot then
        self.UltimateLoot.enabled = val
    end

    E:DebugPrint("[DEBUG] E:SetEnabled called: %s -> %s", tostring(oldValue), tostring(val))

    -- Fire event if value changed
    if oldValue ~= val then
        E:DebugPrint("[DEBUG] E:SetEnabled - Firing ULTIMATELOOT_ENABLED_CHANGED event")
        self:SendMessage("ULTIMATELOOT_ENABLED_CHANGED", val, oldValue)

        E:DebugPrint("[DEBUG] E:SetEnabled - Firing ULTIMATELOOT_STATE_CHANGED event")
        self:SendMessage("ULTIMATELOOT_STATE_CHANGED", {
            type = "enabled",
            newValue = val,
            oldValue = oldValue
        })
    else
        E:DebugPrint("[DEBUG] E:SetEnabled - No change, not firing events")
    end
end

function E:GetLootQualityThreshold()
    return self.db.loot_quality_threshold
end

function E:SetLootQualityThreshold(val)
    local oldValue = self.db.loot_quality_threshold
    self.db.loot_quality_threshold = val

    E:DebugPrint("[DEBUG] E:SetLootQualityThreshold called: %s -> %s", tostring(oldValue), tostring(val))

    -- Fire event if value changed
    if oldValue ~= val then
        E:DebugPrint("[DEBUG] E:SetLootQualityThreshold - Firing ULTIMATELOOT_THRESHOLD_CHANGED event")
        self:SendMessage("ULTIMATELOOT_THRESHOLD_CHANGED", val, oldValue)

        E:DebugPrint("[DEBUG] E:SetLootQualityThreshold - Firing ULTIMATELOOT_STATE_CHANGED event")
        self:SendMessage("ULTIMATELOOT_STATE_CHANGED", {
            type = "threshold",
            newValue = val,
            oldValue = oldValue
        })
    else
        E:DebugPrint("[DEBUG] E:SetLootQualityThreshold - No change, not firing events")
    end
end

E.DynamicOptions = {}

function E:AddOption(key, name, desc, type, getter, setter, values)
    self.DynamicOptions[key] = {
        name = name,
        desc = desc,
        type = type,
        get = getter,
        set = setter,
        values = values
    }
end

function E:RegisterGeneralOptions()
    self:AddOption(
        "enabled",
        "Enable UltimateLoot",
        "Enable or disable intelligent loot management system.",
        "toggle",
        function() return self:GetEnabled() end,
        function(_, val) self:SetEnabled(val) end
    )
    self:AddOption(
        "loot_quality_threshold",
        "Loot Quality Threshold",
        "Quality threshold for automatic loot handling.",
        "select",
        function() return self:GetLootQualityThreshold() end,
        function(_, val) self:SetLootQualityThreshold(val) end,
        {
            poor = "Poor",
            common = "Common",
            uncommon = "Uncommon",
            rare = "Rare",
            epic = "Epic",
            legendary = "Legendary"
        }
    )
end

function E:CreateOptionsTable()
    local options = {
        handler = self,
        type = "group",
        args = {
            general = {
                name = "General",
                type = "group",
                args = {}
            }
        }
    }

    self:RegisterGeneralOptions()

    for key, option in pairs(self.DynamicOptions) do
        options.args.general.args[key] = option
    end

    options.args.profiles = self.Libs.AceDBOptions:GetOptionsTable(self.data)

    self.Libs.AceConfig:RegisterOptionsTable(self._name, options)

    return options
end

function E:ShowOptionsDialog()
    self.Libs.AceConfigDialog:Open(self._name)
end

function E:CloseOptionsDialog()
    self.Libs.AceConfigDialog:Close(self._name)
end

function E:ResetSettings()
    -- Reset to defaults
    self:SetEnabled(true)
    self:SetLootQualityThreshold("uncommon")
    self.db.show_notifications = true
    self.db.max_history = 1000
    self.db.debug_mode = false
    self.db.debug_to_chat = true

    -- Reset minimap settings
    self.db.minimap = {
        hide = false,
        minimapPos = 220,
        lock = false
    }

    self:Print(L and L["SETTINGS_RESET"] or "Settings reset to defaults.")
end
