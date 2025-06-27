function unpack(...) return ... end

function CreateFrame(...) return {} end

function RollOnLoot(...) end

function GetLootRollItemInfo(...) return 0, 0, 0, 0 end

function IsAddOnLoaded(name) return false end

-- WoW Color Constants (stubs for static analysis)
ORANGE_FONT_COLOR_CODE = "|cffff8000"
RED_FONT_COLOR_CODE = "|cffff0000"
GREEN_FONT_COLOR_CODE = "|cff00ff00"
FONT_COLOR_CODE_CLOSE = "|r"

-- Font Color Objects (stubs)
ORANGE_FONT_COLOR = { r = 1, g = 0.5, b = 0 }
RED_FONT_COLOR = { r = 1, g = 0, b = 0 }
GREEN_FONT_COLOR = { r = 0, g = 1, b = 0 }
NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }
GRAY_FONT_COLOR = { r = 0.5, g = 0.5, b = 0.5 }

-- Item Quality Colors (stubs)
ITEM_QUALITY_COLORS = {
    [0] = { r = 0.6, g = 0.6, b = 0.6 }, -- Poor
    [1] = { r = 1, g = 1, b = 1 }, -- Common
    [2] = { r = 0.12, g = 1, b = 0 }, -- Uncommon
    [3] = { r = 0, g = 0.44, b = 0.87 }, -- Rare
    [4] = { r = 0.64, g = 0.21, b = 0.93 }, -- Epic
    [5] = { r = 1, g = 0.5, b = 0 }, -- Legendary
}

SLASH_ULTIMATELOOT1 = ""
SlashCmdList = {}
UltimateLootDB = {}
