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
            if self.graphFrame.bars then
                for i = 0, 23 do
                    if self.graphFrame.bars[i] then
                        self.graphFrame.bars[i]:Hide()
                        self.graphFrame.bars[i] = nil
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
        if graphFrame.bars then
            for i = 0, 23 do
                if graphFrame.bars[i] then
                    graphFrame.bars[i]:Hide()
                end
            end
        end

        graphFrame.bars = graphFrame.bars or {}

        local barWidth = math.max(1, (frameWidth - 40) / 24)
        local barHeight = math.max(1, frameHeight - 60)

        for i = 0, 23 do
            local bar = graphFrame.bars[i] or CreateFrame("Frame", nil, graphFrame)
            bar:Show()
            bar:SetWidth(barWidth - 2)

            local count = hourlyData[23 - i] or 0
            local height = maxValue > 0 and (count / maxValue) * barHeight or 1
            bar:SetHeight(math.max(height, 1))
            bar:SetPoint("BOTTOMLEFT", graphFrame, "BOTTOMLEFT", 20 + (i * barWidth), 30)

            if not bar.texture then
                bar.texture = bar:CreateTexture(nil, "ARTWORK")
                bar.texture:SetAllPoints()
                -- Use SetTexture with color for WoW 3.3.5a compatibility
                bar.texture:SetTexture(0.1, 0.5, 0.8, 0.8)
            end

            if not bar.label then
                bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                bar.label:SetPoint("BOTTOM", bar, "TOP", 0, 2)
            end
            bar.label:SetText(tostring(count))

            if not bar.hourLabel then
                bar.hourLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                bar.hourLabel:SetPoint("TOP", bar, "BOTTOM", 0, -2)
            end
            bar.hourLabel:SetText(string.format("%dh", 23 - i))

            graphFrame.bars[i] = bar
        end

        -- Add title
        if not graphFrame.title then
            graphFrame.title = graphFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            graphFrame.title:SetPoint("TOP", graphFrame, "TOP", 0, -10)
        end
        graphFrame.title:SetText(string.format(L["TOTAL_ROLLS_24H"], E.Tracker:GetRollsByTimeframe(24).total))
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
