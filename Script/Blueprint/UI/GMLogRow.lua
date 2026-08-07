---@class GMLogRow_C:UUserWidget
---@field LogText UTextBlock
---@field RowBackground UBorder
--Edit Below--
local GMLogRow = { bInitDoOnce = false }

local COLORS = {
    Info = { R = 0.88, G = 0.90, B = 0.93, A = 1.0 },
    Warn = { R = 1.0, G = 0.62, B = 0.12, A = 1.0 },
    Error = { R = 1.0, G = 0.15, B = 0.14, A = 1.0 },
    InfoBackground = { R = 0.06, G = 0.07, B = 0.08, A = 0.72 },
    WarnBackground = { R = 0.18, G = 0.12, B = 0.04, A = 0.82 },
    ErrorBackground = { R = 0.20, G = 0.05, B = 0.05, A = 0.86 },
}

local function SetTextColor(TextBlock, Color)
    if TextBlock ~= nil and TextBlock.SetColorAndOpacity ~= nil then
        pcall(TextBlock.SetColorAndOpacity, TextBlock, { SpecifiedColor = Color })
    end
end

local function SetFontSize(TextBlock, FontSize)
    if TextBlock == nil or TextBlock.SetFont == nil or TextBlock.Font == nil then
        return
    end
    local Size = math.max(1, math.floor((tonumber(FontSize) or 24) + 0.5))
    pcall(function()
        local FontInfo = TextBlock.Font
        FontInfo.Size = Size
        pcall(function() FontInfo.TypefaceFontName = "Regular" end)
        TextBlock:SetFont(FontInfo)
    end)
end

function GMLogRow:SetupLogEntry(Entry, FontSize)
    Entry = Entry or {}
    local Level = string.upper(tostring(Entry.Level or "INFO"))
    local TextColor, BackgroundColor = COLORS.Info, COLORS.InfoBackground
    if Level == "WARN" then
        TextColor, BackgroundColor = COLORS.Warn, COLORS.WarnBackground
    elseif Level == "ERROR" then
        TextColor, BackgroundColor = COLORS.Error, COLORS.ErrorBackground
    end
    local Line = string.format("[%s][%s][%s] %s", tostring(Entry.TimeText or "--:--:--"),
        tostring(Entry.Source or "CLIENT"), Level, tostring(Entry.Message or ""))
    if self.LogText ~= nil then
        SetFontSize(self.LogText, FontSize)
        self.LogText:SetText(Line)
        SetTextColor(self.LogText, TextColor)
    end
    if self.RowBackground ~= nil and self.RowBackground.SetBrushColor ~= nil then
        pcall(self.RowBackground.SetBrushColor, self.RowBackground, BackgroundColor)
    end
    if self.ForceLayoutPrepass ~= nil then
        pcall(self.ForceLayoutPrepass, self)
    end
end

return GMLogRow
