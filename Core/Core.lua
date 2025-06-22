--[[
    Core\Core.lua
    Abstract base for Ace3-based WoW addons.
    Handles localization, database, options, logging, and modular initialization.
]]

local _, Engine = ...

-- Locale setup (do this early like ElvUI)
do
    local convert = {
        ["enGB"] = "enUS",
        ["esES"] = "esMX",
        ["itIT"] = "enUS"
    }
    local lang = GetLocale()
    local gameLocale = convert[lang] or lang or "enUS"

    Engine[2] = Engine[1].Libs.AceLocale:GetLocale(Engine[1]._name, gameLocale)
end

local E, L, P = unpack(Engine) --Import: Engine, Locales, ProfileDB

-- Constants
E.myname = UnitName("player")
E.myrealm = GetRealmName()
E.myclass = select(2, UnitClass("player"))
E.mylevel = UnitLevel("player")
E.myfaction = UnitFactionGroup("player")
E.version = GetAddOnMetadata(E._name, "Version") or "Unknown"

-- Tables
E.media = {}
E.frames = {}
E.modules = {}
E.hooks = {}

function E:Log(level, msg, ...)
    if self.Logging and self.Logging[level] then
        self.Logging[level](self.Logging, msg:format(...))
    end
end

-- Debug print function that redirects to Debug module
function E:DebugPrint(msg, ...)
    if self.Debug then
        self.Debug:DebugPrint(msg, ...)
    end
end

-- Function to clear debug output (redirects to Debug module)
function E:ClearDebugOutput()
    if self.Debug then
        self.Debug:ClearDebugOutput()
    end
end

-- Function to get debug output (redirects to Debug module)
function E:GetDebugOutput()
    if self.Debug then
        return self.Debug:GetDebugOutput()
    end
    return {}
end

function E:SetupDatabase()
    return self.Libs.AceDB:New(string.format("%sDB", self._name), self.Defaults)
end

function E:SetupOptions()
    return self.CreateOptionsTable and self:CreateOptionsTable() or {}
end

function E:RegisterEvents()
    -- Call the events initialization from Events.lua
    if self.InitializeEvents then
        self:InitializeEvents()
    end
end

function E:GetAddonName()
    return self._name
end

function E:UpdateMedia()
    if not self.db then return end

    -- Set up any media here (fonts, textures, colors)
    self.media.font = self.Libs.LSM and self.Libs.LSM:Fetch("font", "Arial Narrow") or STANDARD_TEXT_FONT
    self.media.texture = self.Libs.LSM and self.Libs.LSM:Fetch("statusbar", "Blizzard") or
        "Interface\\TargetingFrame\\UI-StatusBar"

    -- Colors
    self.media.bordercolor = { 0.1, 0.1, 0.1 }
    self.media.backdropcolor = { 0.1, 0.1, 0.1 }
    self.media.backdropfadecolor = { 0.054, 0.054, 0.054, 0.8 }
end

function E:UpdateAll()
    self:UpdateMedia()

    -- Update all modules
    for name, module in pairs(self.modules) do
        if module.UpdateSettings then
            module:UpdateSettings()
        end
    end

    self:Log("Info", L["ADDON_LOADED"], self.name)
end

function E:InitializeCore()
    -- Set up player info
    self.myguid = UnitGUID("player")

    -- Initialize database
    self.data = self:SetupDatabase()
    self.data.RegisterCallback(self, "OnProfileChanged", "UpdateAll")
    self.data.RegisterCallback(self, "OnProfileCopied", "UpdateAll")
    self.db = self.data.profile

    -- Set up options
    self.options = self:SetupOptions()
    self.name = self:GetAddonName()

    -- Initialize modules
    self:InitializeModules()

    -- Register events and commands
    self:RegisterEvents()

    -- Update everything
    self:UpdateAll()

    self.initialized = true
end

function E:InitializeModules()
    -- Initialize all registered modules
    for name, module in self:IterateModules() do
        self.modules[name] = module

        if module.OnInitialize then
            module:OnInitialize()
        end

        if module.OnEnable then
            module:OnEnable()
        end
    end
end
