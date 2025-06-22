--[[
    Init.lua
    This file sets up the core Engine table, creates the addon, and handles all initialization.
    It combines the functionality of both Setup.lua and the old Init.lua.

    To load the AddOn engine add this to the top of your file:
        local E, L, P = unpack(select(2, ...)); --Import: Engine, Locales, ProfileDB
]]

local AceAddon = LibStub("AceAddon-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

-- Get addon name and engine table from varargs
local AddOnName, Engine = ...

-- Create the main AceAddon instance
local AddOn = AceAddon:NewAddon(AddOnName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0",
    "AceSerializer-3.0")
AddOn.callbacks = AddOn.callbacks or CallbackHandler:New(AddOn)

-- Core addon setup
AddOn._name = AddOnName
AddOn.DF = { profile = {} } -- Defaults will be populated later

-- Libraries used by the addon
AddOn.Modules = {}
do
    AddOn.Libs = {}
    function AddOn:AddLib(name, libname, silent)
        if not name then return end
        self.Libs[name] = LibStub(libname, silent)
        return self.Libs[name]
    end

    AddOn:AddLib("AceAddon", "AceAddon-3.0")
    AddOn:AddLib("AceDB", "AceDB-3.0")
    AddOn:AddLib("AceLocale", "AceLocale-3.0")
    AddOn:AddLib("AceConfig", "AceConfig-3.0")
    AddOn:AddLib("AceConfigDialog", "AceConfigDialog-3.0")
    AddOn:AddLib("AceGUI", "AceGUI-3.0")
    AddOn:AddLib("AceDBOptions", "AceDBOptions-3.0")
    AddOn:AddLib("LSM", "LibSharedMedia-3.0", true)  -- Silent fail if not available
    AddOn:AddLib("LibDBIcon", "LibDBIcon-1.0", true) -- For minimap icon
end

-- Logging module
AddOn.Logging = {
    Info = function(self, msg) AddOn:Print(msg) end,
    Warn = function(self, msg) AddOn:Print("|cffff0000" .. msg .. "|r") end,
    Error = function(self, msg) AddOn:Print("|cffff0000" .. msg .. "|r") end,
    Debug = function(self, msg) if AddOn.db and AddOn.db.debug_mode then AddOn:Print(msg) end end
}

-- Initialize Engine table components
Engine[1] = AddOn            -- E - Main AddOn object
Engine[2] = {}               -- L - Locale object (will be populated by locale files)
Engine[3] = AddOn.DF.profile -- P - Profile defaults (will be populated later)

-- Expose Engine globally for other files if necessary
_G[AddOnName] = Engine

-- Now set up the defaults and slash commands
local E = Engine[1]

-- Override Print to use a cleaner prefix
function E:Print(...)
    local msg = strjoin(" ", "|cff1784d1UltimateLoot:|r", ...)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Set up defaults using the ProfileDefaults from Settings/Profile.lua
E.Defaults = {
    profile = ProfileDefaults
}
E.DF.profile = ProfileDefaults

-- OnInitialize lifecycle event
function E:OnInitialize()
    -- Initialize components
    if self.InitializeCore then
        self:InitializeCore()
    end
end
