local E, L, P = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB

local GraphUI = E:NewModule("GraphUI")
E.GraphUI = GraphUI
local AceGUI = E.Libs.AceGUI

function GraphUI:CreateGraphTab(container)
    local hourlyData = E.Tracker:GetHourlyData(24)
    local maxValue = 0
    for _, count in pairs(hourlyData) do
        maxValue = math.max(maxValue, count)
    end

    if maxValue == 0 then
        E.UIUtils:ShowEmptyState(container, L["NO_DATA_TO_DISPLAY"])
        return
    end

    -- Create a proper AceGUI container for the graph
    local graphGroup = AceGUI:Create("InlineGroup")
    graphGroup:SetTitle(L["HOURLY_ACTIVITY"])
    graphGroup:SetFullWidth(true)
    graphGroup:SetFullHeight(true)
    graphGroup:SetLayout("Fill")
    container:AddChild(graphGroup)

    -- Create a simple group to hold our graph
    local graphContainer = AceGUI:Create("SimpleGroup")
    graphContainer:SetFullWidth(true)
    graphContainer:SetFullHeight(true)
    graphContainer:SetLayout("Fill")
    graphGroup:AddChild(graphContainer)

    -- Create the graph frame as a child of the AceGUI container
    local graphFrame = CreateFrame("Frame", nil, graphContainer.frame)
    graphFrame:SetAllPoints()

    -- Store reference for cleanup
    graphContainer.graphFrame = graphFrame

    -- Override the release function to cleanup our custom frame
    local originalRelease = graphContainer.Release
    graphContainer.Release = function(self)
        if self.graphFrame then
            local bars = self.graphFrame.bars
            if bars then
                for i = 0, 23 do
                    if bars[i] then
                        bars[i]:Hide()
                        bars[i] = nil
                    end
                end
                self.graphFrame.bars = nil
            end
            if self.graphFrame.title then
                self.graphFrame.title = nil
            end
            self.graphFrame:Hide()
            self.graphFrame = nil
        end
        originalRelease(self)
    end

    -- Cache math functions for performance
    local mathMax = math.max

    -- Function to render the graph
    local function RenderGraph()
        local frameWidth = graphFrame:GetWidth()
        local frameHeight = graphFrame:GetHeight()

        -- Check if frame has valid dimensions
        if not frameWidth or frameWidth <= 0 or not frameHeight or frameHeight <= 0 then
            -- Retry after a short delay using WoW 3.3.5a compatible method
            if C_Timer and C_Timer.After then
                C_Timer.After(0.1, RenderGraph)
            else
                -- Fallback for older WoW versions
                local retryFrame = CreateFrame("Frame")
                retryFrame.elapsed = 0
                retryFrame:SetScript("OnUpdate", function(self, elapsed)
                    self.elapsed = self.elapsed + elapsed
                    if self.elapsed >= 0.1 then
                        self:SetScript("OnUpdate", nil)
                        RenderGraph()
                    end
                end)
            end
            return
        end

        -- Clear existing bars
        local bars = graphFrame.bars
        if bars then
            for i = 0, 23 do
                if bars[i] then
                    bars[i]:Hide()
                end
            end
        end

        graphFrame.bars = bars or {}
        bars = graphFrame.bars

        local barWidth = mathMax(1, (frameWidth - 40) / 24)
        local barHeight = mathMax(1, frameHeight - 60)
        local maxValueInv = maxValue > 0 and (1 / maxValue) or 0

        for i = 0, 23 do
            local bar = bars[i] or CreateFrame("Frame", nil, graphFrame)
            bar:Show()
            bar:SetWidth(barWidth - 2)

            local count = hourlyData[23 - i] or 0
            local height = maxValueInv > 0 and (count * maxValueInv) * barHeight or 1
            bar:SetHeight(mathMax(height, 1))
            bar:SetPoint("BOTTOMLEFT", graphFrame, "BOTTOMLEFT", 20 + (i * barWidth), 30)

            if not bar.texture then
                bar.texture = bar:CreateTexture(nil, "ARTWORK")
                bar.texture:SetAllPoints()
                -- Use SetTexture with color for WoW 3.3.5a compatibility
                bar.texture:SetTexture(0.1, 0.5, 0.8, 0.8)
            end

            local label = bar.label
            if not label then
                label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetPoint("BOTTOM", bar, "TOP", 0, 2)
                bar.label = label
            end
            label:SetText(tostring(count))

            local hourLabel = bar.hourLabel
            if not hourLabel then
                hourLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                hourLabel:SetPoint("TOP", bar, "BOTTOM", 0, -2)
                bar.hourLabel = hourLabel
            end
            hourLabel:SetText(string.format("%dh", 23 - i))

            bars[i] = bar
        end

        -- Add title
        local title = graphFrame.title
        if not title then
            title = graphFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            title:SetPoint("TOP", graphFrame, "TOP", 0, -10)
            graphFrame.title = title
        end
        title:SetText(string.format(L["TOTAL_ROLLS_24H"], E.Tracker:GetRollsByTimeframe(24).total))
    end

    graphFrame:SetScript("OnShow", function(self)
        RenderGraph()
    end)

    graphFrame:SetScript("OnSizeChanged", function(self)
        RenderGraph()
    end)

    -- Initial render with a small delay to ensure frame is properly sized
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, RenderGraph)
    else
        local initFrame = CreateFrame("Frame")
        initFrame.elapsed = 0
        initFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 0.05 then
                self:SetScript("OnUpdate", nil)
                RenderGraph()
            end
        end)
    end
end
