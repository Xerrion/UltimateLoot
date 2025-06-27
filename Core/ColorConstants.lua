local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

-- Color Constants Module
-- Provides centralized access to WoW's default colors and consistent color usage across the addon
local ColorConstants = E:NewModule("ColorConstants")
E.ColorConstants = ColorConstants

-- WoW's built-in color constants (available in 3.3.5a)
ColorConstants.COLORS = {
    -- Status Colors
    SUCCESS = { GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b },
    WARNING = { ORANGE_FONT_COLOR.r, ORANGE_FONT_COLOR.g, ORANGE_FONT_COLOR.b },
    ERROR = { RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b },
    INFO = { HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b },
    
    -- UI Colors
    NORMAL = { NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b },
    HIGHLIGHT = { HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b },
    DISABLED = { GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b },
    
    -- Item Quality Colors (use WoW's built-in quality color table)
    POOR = { ITEM_QUALITY_COLORS[0].r, ITEM_QUALITY_COLORS[0].g, ITEM_QUALITY_COLORS[0].b },
    COMMON = { ITEM_QUALITY_COLORS[1].r, ITEM_QUALITY_COLORS[1].g, ITEM_QUALITY_COLORS[1].b },
    UNCOMMON = { ITEM_QUALITY_COLORS[2].r, ITEM_QUALITY_COLORS[2].g, ITEM_QUALITY_COLORS[2].b },
    RARE = { ITEM_QUALITY_COLORS[3].r, ITEM_QUALITY_COLORS[3].g, ITEM_QUALITY_COLORS[3].b },
    EPIC = { ITEM_QUALITY_COLORS[4].r, ITEM_QUALITY_COLORS[4].g, ITEM_QUALITY_COLORS[4].b },
    LEGENDARY = { ITEM_QUALITY_COLORS[5].r, ITEM_QUALITY_COLORS[5].g, ITEM_QUALITY_COLORS[5].b },
    
    -- Rule Type Colors (using default UI colors for consistency)
    RULE_WHITELIST = { GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b }, -- Always Pass (Green)
    RULE_BLACKLIST = { RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b }, -- Never Pass (Red)
    RULE_NEED = { ITEM_QUALITY_COLORS[3].r, ITEM_QUALITY_COLORS[3].g, ITEM_QUALITY_COLORS[3].b }, -- Need (Rare Blue)
    RULE_GREED = { ORANGE_FONT_COLOR.r, ORANGE_FONT_COLOR.g, ORANGE_FONT_COLOR.b }, -- Greed (Orange)
    RULE_GREED_DISENCHANT = { ITEM_QUALITY_COLORS[4].r, ITEM_QUALITY_COLORS[4].g, ITEM_QUALITY_COLORS[4].b }, -- Greed/Disenchant (Epic Purple)
}

-- Color strings for easy text formatting
ColorConstants.COLOR_STRINGS = {
    SUCCESS = "|cff00ff00",
    WARNING = "|cffff8000", 
    ERROR = "|cffff0000",
    INFO = "|cffffffff",
    NORMAL = "|cffffd700",
    HIGHLIGHT = "|cffffffff",
    DISABLED = "|cff808080",
}

-- Helper functions for color formatting
function ColorConstants:GetColorString(colorType)
    return self.COLOR_STRINGS[colorType] or "|cffffffff"
end

function ColorConstants:FormatText(text, colorType)
    local colorString = self:GetColorString(colorType)
    return colorString .. text .. "|r"
end

function ColorConstants:GetRuleTypeColor(ruleType)
    local colorMap = {
        whitelist = self.COLORS.RULE_WHITELIST,
        blacklist = self.COLORS.RULE_BLACKLIST,
        always_need = self.COLORS.RULE_NEED,
        always_greed = self.COLORS.RULE_GREED,
        always_greed_disenchant = self.COLORS.RULE_GREED_DISENCHANT,
    }
    return colorMap[ruleType] or self.COLORS.NORMAL
end

function ColorConstants:GetQualityColor(quality)
    if quality and quality >= 0 and quality <= 5 then
        local qualityColors = {
            [0] = self.COLORS.POOR,
            [1] = self.COLORS.COMMON,
            [2] = self.COLORS.UNCOMMON,
            [3] = self.COLORS.RARE,
            [4] = self.COLORS.EPIC,
            [5] = self.COLORS.LEGENDARY,
        }
        return qualityColors[quality] or self.COLORS.NORMAL
    end
    return self.COLORS.NORMAL
end

-- Apply color to AceGUI widget text
function ColorConstants:SetWidgetTextColor(widget, colorType)
    if not widget or not widget.label then return end
    
    local color = self.COLORS[colorType]
    if color and widget.label.SetTextColor then
        widget.label:SetTextColor(color[1], color[2], color[3])
    end
end

-- Get quality color strings using WoW's built-in colors
function ColorConstants:GetQualityColorString(quality)
    if quality and ITEM_QUALITY_COLORS[quality] then
        local color = ITEM_QUALITY_COLORS[quality]
        return string.format("|cff%02x%02x%02x", 
            color.r * 255, color.g * 255, color.b * 255)
    end
    return "|cffffffff" -- Default to white
end

-- Format quality name with appropriate color
function ColorConstants:FormatQualityText(qualityName, quality)
    local colorString = self:GetQualityColorString(quality)
    return colorString .. qualityName .. "|r"
end
