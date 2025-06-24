local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

-- Create UI utilities module
local UIUtils = E:NewModule("UIUtils")
E.UIUtils = UIUtils
local AceGUI = E.Libs.AceGUI

--[[
    UIUtils Module
    
    A collection of shared UI utility functions to reduce code duplication
    and provide consistent UI behavior across the addon.
]]

-- Error handling utilities
local ERROR_HANDLING_ENABLED = true  -- Can be toggled for debugging

-- Safe function call wrapper
function UIUtils:SafeCall(funcName, func, ...)
    if not ERROR_HANDLING_ENABLED then
        return true, func(...)
    end
    
    local success, result = pcall(func, ...)
    if not success then
        -- Log the error
        E:DebugPrint("[ERROR] UIUtils: %s failed - %s", funcName or "Function", result or "Unknown error")
        -- Display a user-friendly message if in debug mode
        if E.db and E.db.debug_mode then
            E:Print("|cffff0000Error in " .. (funcName or "function") .. ":|r " .. (result or "Unknown error"))
        end
        return false, result
    end
    return true, result
end

-- Create UI elements safely
function UIUtils:SafeCreateWidget(widgetType, errorCallback)
    local widget
    
    local success, result = self:SafeCall("CreateWidget(" .. widgetType .. ")", function()
        return AceGUI:Create(widgetType)
    end)
    
    if success then
        widget = result
        if not widget then
            E:DebugPrint("[ERROR] UIUtils: Failed to create widget of type %s", widgetType)
            if errorCallback then
                errorCallback("Failed to create widget of type " .. widgetType)
            end
        end
    else
        if errorCallback then
            errorCallback(result)
        end
    end
    
    return widget
end

-- Safe error display
function UIUtils:ShowError(container, errorMsg)
    E:DebugPrint("[ERROR] UIUtils: %s", errorMsg)
    
    local errorGroup = self:SafeCreateWidget("InlineGroup")
    if errorGroup then
        errorGroup:SetTitle("Error")
        errorGroup:SetFullWidth(true)
        errorGroup:SetLayout("Flow")
        
        local errorLabel = self:SafeCreateWidget("Label")
        if errorLabel then
            errorLabel:SetText("|cffff0000Error:|r " .. errorMsg)
            errorLabel:SetFullWidth(true)
            errorGroup:AddChild(errorLabel)
        end
        
        if container then
            container:AddChild(errorGroup)
        end
        
        return errorGroup
    end
    
    return nil
end

-- Function to set quality colors on widgets
function UIUtils:SetQualityColor(widget, quality)
    if not widget then
        E:DebugPrint("[ERROR] UIUtils: Cannot set quality color - widget is nil")
        return 1, 1, 1 -- Default white
    end
    
    local r, g, b = 1, 1, 1 -- Default white
    local success, colors = self:SafeCall("GetQualityColor", function()
        return E.Tracker:GetQualityColor(quality)
    end)
    
    if success and colors then 
        r, g, b = unpack(colors)
    end
    
    self:SafeCall("SetWidgetColor", function()
        widget:SetColor(r, g, b)
    end)
    
    return r, g, b
end

-- Get color for roll decision type
function UIUtils:GetRollDecisionColor(rollTypeName)
    if rollTypeName == "need" then
        return 0.12, 1, 0    -- Green (like Uncommon items)
    elseif rollTypeName == "greed" then
        return 0, 0.44, 0.87 -- Blue (like Rare items)
    else                     -- "pass" or nil (legacy)
        return 0.8, 0.8, 0.8 -- Light gray
    end
end

-- Get localized text for roll decision type
function UIUtils:GetRollDecisionText(rollTypeName)
    if rollTypeName == "need" then
        return L["NEED_ROLLS"]
    elseif rollTypeName == "greed" then
        return L["GREED_ROLLS"]
    else -- "pass" or nil (legacy)
        return L["PASS_ROLLS"]
    end
end

-- Create a scroll frame with proper settings
function UIUtils:CreateScrollFrame(parent)
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    if parent then
        parent:AddChild(scrollFrame)
    end
    return scrollFrame
end

-- Add item tooltip functionality to a widget
function UIUtils:AddItemTooltip(widget, itemLink)
    widget:SetCallback("OnEnter", function()
        if itemLink and itemLink:match("|H.-|h") then
            GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
            local success = pcall(GameTooltip.SetHyperlink, GameTooltip, itemLink)
            if success then
                GameTooltip:Show()
            else
                GameTooltip:Hide()
            end
        end
    end)
    
    widget:SetCallback("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Show empty state message
function UIUtils:ShowEmptyState(container, message)
    if not container then
        E:DebugPrint("[ERROR] UIUtils: Cannot show empty state - container is nil")
        return nil
    end
    
    local label = self:SafeCreateWidget("Label")
    if not label then
        E:DebugPrint("[ERROR] UIUtils: Failed to create label for empty state")
        return nil
    end
    
    self:SafeCall("SetEmptyStateText", function()
        label:SetText(message or L["NO_DATA_TO_DISPLAY"])
        label:SetFullWidth(true)
        label:SetFontObject(GameFontNormalLarge)
        container:AddChild(label)
    end)
    
    return label
end

-- Create confirmation dialog
function UIUtils:ShowConfirmDialog(dialogName, message, onAccept)
    if not dialogName or dialogName == "" then
        E:DebugPrint("[ERROR] UIUtils: Cannot show confirmation dialog - invalid dialog name")
        return false
    end
    
    if not message then
        message = "Are you sure?"
        E:DebugPrint("[WARNING] UIUtils: No message provided for confirmation dialog")
    end
    
    local success = self:SafeCall("CreateConfirmDialog", function()
        StaticPopupDialogs[dialogName] = {
            text = message,
            button1 = L["YES"],
            button2 = L["NO"],
            OnAccept = function()
                if onAccept then
                    self:SafeCall("DialogAcceptHandler", onAccept)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show(dialogName)
    end)
    
    return success
end

-- Create table header row with sorting support
function UIUtils:CreateTableHeader(scrollFrame, columns, sortInfo)
    local headerFrame = AceGUI:Create("SimpleGroup")
    headerFrame:SetFullWidth(true)
    headerFrame:SetLayout("Flow")

    -- Create header background (WoW 3.3.5a compatible)
    local headerBg = headerFrame.frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(headerFrame.frame)
    headerBg:SetTexture(0.2, 0.2, 0.3, 0.8)

    for _, column in ipairs(columns) do
        -- Create an interactive label for headers to support clicking
        local header = AceGUI:Create("InteractiveLabel")
        
        -- Add sort indicators if this is the currently sorted column
        local headerText = column.label
        if sortInfo and sortInfo.column == column.key then
            headerText = headerText .. (sortInfo.direction == "asc" and " \226\134\145" or " \226\134\147")
        end
        
        header:SetText(headerText)
        header:SetWidth(column.width)
        header:SetFontObject(GameFontNormalLarge)
        header:SetColor(1, 1, 1)
        
        -- Make headers clickable for sorting if sort callback is provided
        if sortInfo and sortInfo.callback then
            header:SetCallback("OnClick", function()
                sortInfo.callback(column.key)
            end)
            
            -- Add hover effect to indicate clickable headers
            header:SetCallback("OnEnter", function(widget)
                widget:SetColor(1, 1, 0) -- Yellow on hover
            end)
            
            header:SetCallback("OnLeave", function(widget)
                widget:SetColor(1, 1, 1) -- White when not hovering
            end)
        end
        
        headerFrame:AddChild(header)
    end

    scrollFrame:AddChild(headerFrame)
    return headerFrame
end

-- Create table row with alternating background
function UIUtils:CreateTableRow(scrollFrame, isEven)
    local rowFrame = AceGUI:Create("SimpleGroup")
    rowFrame:SetFullWidth(true)
    rowFrame:SetLayout("Flow")

    -- Add alternating row background (WoW 3.3.5a compatible)
    local rowBg = rowFrame.frame:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints(rowFrame.frame)
    if isEven then
        rowBg:SetTexture(0.1, 0.1, 0.15, 0.3)
    else
        rowBg:SetTexture(0.05, 0.05, 0.1, 0.5)
    end

    scrollFrame:AddChild(rowFrame)
    return rowFrame
end

-- Create a data export popup
function UIUtils:ShowExportFrame(title, data)
    local exportFrame = AceGUI:Create("Frame")
    exportFrame:SetTitle(title)
    exportFrame:SetWidth(600)
    exportFrame:SetHeight(400)
    exportFrame:SetLayout("Fill")
    
    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel(L["EXPORT_DATA_LABEL"])
    editBox:SetText(data)
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(true)
    editBox:DisableButton(true)
    exportFrame:AddChild(editBox)
    
    exportFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
    
    return exportFrame
end