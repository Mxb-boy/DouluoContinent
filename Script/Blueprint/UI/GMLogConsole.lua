---@class GMLogConsole_C:UUserWidget
---@field AllButton UButton
---@field AllLabel UTextBlock
---@field Background UBorder
---@field ClearButton UButton
---@field ClearLabel UTextBlock
---@field CloseButton UButton
---@field CloseLabel UTextBlock
---@field ErrorButton UButton
---@field ErrorLabel UTextBlock
---@field FontDecreaseButton UButton
---@field FontDecreaseLabel UTextBlock
---@field FontIncreaseButton UButton
---@field FontIncreaseLabel UTextBlock
---@field InfoButton UButton
---@field InfoLabel UTextBlock
---@field LogScrollBox UScrollBox
---@field NextButton UButton
---@field NextLabel UTextBlock
---@field PageText UTextBlock
---@field PrevButton UButton
---@field PrevLabel UTextBlock
---@field SearchInput UEditableTextBox
---@field StatusText UTextBlock
---@field TitleText UTextBlock
---@field WarnButton UButton
---@field WarnLabel UTextBlock
--Edit Below--
local GMLogConsole = { bInitDoOnce = false }
local RuntimeLog = UGCGameSystem.UGCRequire("Script.Common.RuntimeLog")
local PAGE_SIZE = 200
local DEFAULT_LOG_FONT_SIZE = 24
local MIN_LOG_FONT_SIZE = 14
local MAX_LOG_FONT_SIZE = 36
local LOG_FONT_SIZE_STEP = 2

local COLORS = {
    Panel = { R = 0.045, G = 0.055, B = 0.065, A = 0.96 },
    White = { R = 0.92, G = 0.94, B = 0.96, A = 1.0 },
    Muted = { R = 0.60, G = 0.65, B = 0.70, A = 1.0 },
    Error = { R = 1.0, G = 0.18, B = 0.16, A = 1.0 },
    Warn = { R = 1.0, G = 0.62, B = 0.12, A = 1.0 },
}

local function SetTextColor(TextBlock, Color)
    if TextBlock == nil or TextBlock.SetColorAndOpacity == nil then
        return
    end
    pcall(TextBlock.SetColorAndOpacity, TextBlock, { SpecifiedColor = Color })
end

local function SetLabel(TextBlock, Text)
    if TextBlock ~= nil and TextBlock.SetText ~= nil then
        TextBlock:SetText(Text)
    end
end

local function TextValue(Text)
    if Text == nil then
        return ""
    end
    if Text.ToString ~= nil then
        local Success, Value = pcall(Text.ToString, Text)
        if Success and Value ~= nil then
            return tostring(Value)
        end
    end
    return tostring(Text)
end

function GMLogConsole:Construct()
    if self.bInitDoOnce then
        self:RefreshRuntimeLogs()
        return
    end
    self.bInitDoOnce = true
    self.FilterLevel = "ALL"
    self.SearchText = ""
    self.PageIndex = 1
    self.LogFontSize = DEFAULT_LOG_FONT_SIZE
    self.LogPollTimerName = "GMLogConsolePoll_" .. tostring(self)

    SetLabel(self.TitleText, "日志")
    SetLabel(self.AllLabel, "全部")
    SetLabel(self.InfoLabel, "信息")
    SetLabel(self.WarnLabel, "警告")
    SetLabel(self.ErrorLabel, "错误")
    SetLabel(self.ClearLabel, "清空")
    SetLabel(self.CloseLabel, "关")
    SetLabel(self.PrevLabel, "上页")
    SetLabel(self.NextLabel, "下页")
    SetLabel(self.FontDecreaseLabel, "A-")
    SetLabel(self.FontIncreaseLabel, "A+")
    if self.SearchInput ~= nil and self.SearchInput.SetHintText ~= nil then
        self.SearchInput:SetHintText("搜索日志")
    end
    SetTextColor(self.TitleText, COLORS.White)
    SetTextColor(self.StatusText, COLORS.Muted)
    SetTextColor(self.PageText, COLORS.Muted)
    if self.Background ~= nil and self.Background.SetBrushColor ~= nil then
        pcall(self.Background.SetBrushColor, self.Background, COLORS.Panel)
    end

    if self.AllButton ~= nil and self.AllButton.OnClicked ~= nil then
        self.AllButton.OnClicked:Add(function() self:SetFilter("ALL") end)
    end
    if self.InfoButton ~= nil and self.InfoButton.OnClicked ~= nil then
        self.InfoButton.OnClicked:Add(function() self:SetFilter("INFO") end)
    end
    if self.WarnButton ~= nil and self.WarnButton.OnClicked ~= nil then
        self.WarnButton.OnClicked:Add(function() self:SetFilter("WARN") end)
    end
    if self.ErrorButton ~= nil and self.ErrorButton.OnClicked ~= nil then
        self.ErrorButton.OnClicked:Add(function() self:SetFilter("ERROR") end)
    end
    if self.ClearButton ~= nil and self.ClearButton.OnClicked ~= nil then
        self.ClearButton.OnClicked:Add(function()
            local PlayerController = UGCGameSystem.GetLocalPlayerController()
            if PlayerController ~= nil and PlayerController.ClearRuntimeLogs ~= nil then
                PlayerController:ClearRuntimeLogs()
            end
        end)
    end
    if self.CloseButton ~= nil and self.CloseButton.OnClicked ~= nil then
        self.CloseButton.OnClicked:Add(function() self:SetVisibility(ESlateVisibility.Collapsed) end)
    end
    if self.PrevButton ~= nil and self.PrevButton.OnClicked ~= nil then
        self.PrevButton.OnClicked:Add(function() self.PageIndex = math.max(1, (self.PageIndex or 1) - 1); self:RefreshRuntimeLogs() end)
    end
    if self.NextButton ~= nil and self.NextButton.OnClicked ~= nil then
        self.NextButton.OnClicked:Add(function() self.PageIndex = (self.PageIndex or 1) + 1; self:RefreshRuntimeLogs() end)
    end
    if self.FontDecreaseButton ~= nil and self.FontDecreaseButton.OnClicked ~= nil then
        self.FontDecreaseButton.OnClicked:Add(function() self:AdjustLogFontSize(-LOG_FONT_SIZE_STEP) end)
    end
    if self.FontIncreaseButton ~= nil and self.FontIncreaseButton.OnClicked ~= nil then
        self.FontIncreaseButton.OnClicked:Add(function() self:AdjustLogFontSize(LOG_FONT_SIZE_STEP) end)
    end
    if self.SearchInput ~= nil and self.SearchInput.OnTextChanged ~= nil then
        self.SearchInput.OnTextChanged:Add(function(Text)
            self.SearchText = TextValue(Text)
            self.PageIndex = 1
            self:RefreshRuntimeLogs()
        end)
    end
    if UGCTimerUtility ~= nil and UGCTimerUtility.CreateLuaTimer ~= nil then
        UGCTimerUtility.CreateLuaTimer(1.0, function()
            local Visible = true
            if self.IsVisible ~= nil then
                local Success, Value = pcall(self.IsVisible, self)
                Visible = Success and Value == true
            end
            if Visible then
                local PlayerController = UGCGameSystem.GetLocalPlayerController()
                if PlayerController ~= nil and PlayerController.RequestRuntimeLogSync ~= nil then
                    PlayerController:RequestRuntimeLogSync()
                end
            end
        end, true, self.LogPollTimerName)
    end
    RuntimeLog.Info("[LOG_PROBE][UI][CONSTRUCT] console Lua construct active")
    self:RefreshRuntimeLogs()
end

function GMLogConsole:SetFilter(Level)
    self.FilterLevel = Level or "ALL"
    self.PageIndex = 1
    self:RefreshRuntimeLogs()
end

function GMLogConsole:AdjustLogFontSize(Delta)
    local CurrentSize = tonumber(self.LogFontSize) or DEFAULT_LOG_FONT_SIZE
    self.LogFontSize = math.min(MAX_LOG_FONT_SIZE,
        math.max(MIN_LOG_FONT_SIZE, CurrentSize + (tonumber(Delta) or 0)))
    self:RefreshRuntimeLogs()
end

function GMLogConsole:OpenRuntimeLogs(SearchText)
    self:SetVisibility(ESlateVisibility.Visible)
    self.SearchText = tostring(SearchText or "")
    self.PageIndex = 1
    if self.SearchInput ~= nil and self.SearchInput.SetText ~= nil then
        self.SearchInput:SetText(self.SearchText)
    end
    self:RefreshRuntimeLogs()
end

function GMLogConsole:Destruct()
    if self.LogPollTimerName ~= nil and UGCTimerUtility ~= nil and
        UGCTimerUtility.RemoveLuaTimerByName ~= nil then
        UGCTimerUtility.RemoveLuaTimerByName(self.LogPollTimerName)
    end
end

function GMLogConsole:Matches(Entry)
    if self.FilterLevel ~= "ALL" and string.upper(tostring(Entry.Level or "INFO")) ~= self.FilterLevel then
        return false
    end
    local Query = string.lower(tostring(self.SearchText or ""))
    if Query == "" then
        return true
    end
    local Haystack = string.lower(table.concat({Entry.TimeText, Entry.Source, Entry.Level, Entry.Message}, " "))
    return string.find(Haystack, Query, 1, true) ~= nil
end

function GMLogConsole:RefreshRuntimeLogs()
    local Matches = {}
    local Entries = RuntimeLog.GetEntries()
    -- Operational logs are most useful newest-first. With thousands of entries,
    -- putting the oldest record on page 1 hides the failure that just occurred.
    for Index = #Entries, 1, -1 do
        local Entry = Entries[Index]
        if self:Matches(Entry) then
            table.insert(Matches, Entry)
        end
    end
    local Total = #Matches
    local PageCount = math.max(1, math.ceil(Total / PAGE_SIZE))
    self.PageIndex = math.min(math.max(1, self.PageIndex or 1), PageCount)
    local First = (self.PageIndex - 1) * PAGE_SIZE + 1
    local Last = math.min(Total, First + PAGE_SIZE - 1)

    if self.LogScrollBox == nil then
        if self.ScrollBoxFailureLogged ~= true then
            self.ScrollBoxFailureLogged = true
            RuntimeLog.Error("[LOG_PROBE][UI][SCROLL_BOX_NIL] LogScrollBox is not exposed to Lua")
        end
        SetLabel(self.StatusText, "日志滚动区不可用")
        return
    end
    self.LogScrollBox:ClearChildren()
    local RowClass = UE.LoadClass(UGCGameSystem.GetUGCResourcesFullPath(
        "Asset/Blueprint/UI/GMLogRow.GMLogRow_C"))
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    if RowClass == nil then
        if self.RowClassFailureLogged ~= true then
            self.RowClassFailureLogged = true
            RuntimeLog.Error("[LOG_PROBE][UI][ROW_CLASS_NIL] GMLogRow class load failed")
        end
        SetLabel(self.StatusText, "日志行加载失败")
        return
    end
    if PlayerController == nil then
        if self.PlayerControllerFailureLogged ~= true then
            self.PlayerControllerFailureLogged = true
            RuntimeLog.Error("[LOG_PROBE][UI][PLAYER_CONTROLLER_NIL] local player controller unavailable")
        end
        SetLabel(self.StatusText, "玩家控制器不可用")
        return
    end
    if RowClass ~= nil and PlayerController ~= nil and self.LogScrollBox ~= nil then
        for Index = First, Last do
            local Row = UserWidget.NewWidgetObjectBP(PlayerController, RowClass)
            if Row ~= nil then
                self.LogScrollBox:AddChild(Row)
                if Row.SetupLogEntry ~= nil then
                    Row:SetupLogEntry(Matches[Index], self.LogFontSize)
                end
            end
        end
    end
    SetLabel(self.StatusText, string.format("共 %d 条日志  字号 %d", Total,
        tonumber(self.LogFontSize) or DEFAULT_LOG_FONT_SIZE))
    SetLabel(self.PageText, string.format("%d / %d", self.PageIndex, PageCount))
end

return GMLogConsole
