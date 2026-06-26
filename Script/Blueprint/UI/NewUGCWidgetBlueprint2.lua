---@class NewUGCWidgetBlueprint2_C:UUserWidget
---@field Image_0 UImage
---@field Image_58 UImage
---@field Image_59 UImage
---@field Image_132 UImage
---@field text_dzcg UTextBlock
---@field TextBlock_58 UTextBlock
--Edit Below--
local NewUGCWidgetBlueprint = { bInitDoOnce = false } 
local ResultText = {
    Success = string.char(233, 148, 187, 233, 128, 160, 230, 136, 144, 229, 138, 159),
    Keep = string.char(233, 148, 187, 233, 128, 160, 228, 191, 157, 230, 140, 129),
    Down = string.char(233, 148, 187, 233, 128, 160, 233, 153, 141, 231, 186, 167),
}
local ResultColor = {
    Success = { R = 1.0, G = 0.78, B = 0.22, A = 1.0 },
    Keep = { R = 0.56, G = 0.86, B = 1.0, A = 1.0 },
    Down = { R = 1.0, G = 0.32, B = 0.22, A = 1.0 },
}
--[==[ Construct
function NewUGCWidgetBlueprint:Construct()
    self:SetVisibility(ESlateVisibility.Collapsed)
    if self.SetIsEnabled ~= nil then
        self:SetIsEnabled(false)
    end
end
-- Construct ]==]
function NewUGCWidgetBlueprint:Construct()
    self:SetVisibility(ESlateVisibility.Collapsed)
    if self.SetIsEnabled ~= nil then
        self:SetIsEnabled(false)
    end
end
-- function NewUGCWidgetBlueprint:Tick(MyGeometry, InDeltaTime)
-- end
function NewUGCWidgetBlueprint:ShowForgeResult(ResultType, IconPath)
    local Text = ResultText[ResultType] or ResultText.Keep
    local Color = ResultColor[ResultType] or ResultColor.Keep
    if self.SetIsEnabled ~= nil then
        self:SetIsEnabled(true)
    end
    self:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if self.text_dzcg ~= nil then
        self.text_dzcg:SetText(Text)
        self:SetTextBlockColor(self.text_dzcg, Color)
    end
    self:SetResultIcon(IconPath)
    self:AutoHideAfterDelay(2.0)
end
function NewUGCWidgetBlueprint:AutoHideAfterDelay(DelaySeconds)
    UGCTimerUtility.CreateLuaTimer(DelaySeconds, function()
        if self ~= nil then
            self:SetVisibility(ESlateVisibility.Collapsed)
            if self.SetIsEnabled ~= nil then
                self:SetIsEnabled(false)
            end
        end
    end, false)
end
function NewUGCWidgetBlueprint:SetResultIcon(IconPath)
    if self.Image_132 == nil or IconPath == nil then
        return
    end
    local IconTexture = UE.LoadObject(IconPath)
    if IconTexture == nil then
        ugcprint("[NewUGCWidgetBlueprint:SetResultIcon] Icon load failed: " .. tostring(IconPath))
        return
    end
    self.Image_132:SetBrushFromTexture(IconTexture)
end
function NewUGCWidgetBlueprint:SetTextBlockColor(TextBlock, Color)
    if TextBlock == nil or Color == nil then
        return
    end
    local SlateColor = {
        SpecifiedColor = {
            R = Color.R,
            G = Color.G,
            B = Color.B,
            A = Color.A,
        },
    }
    if TextBlock.SetColorAndOpacity ~= nil then
        pcall(TextBlock.SetColorAndOpacity, TextBlock, SlateColor)
    end
    if TextBlock.ColorAndOpacity ~= nil and TextBlock.ColorAndOpacity.SpecifiedColor ~= nil then
        TextBlock.ColorAndOpacity.SpecifiedColor.R = Color.R
        TextBlock.ColorAndOpacity.SpecifiedColor.G = Color.G
        TextBlock.ColorAndOpacity.SpecifiedColor.B = Color.B
        TextBlock.ColorAndOpacity.SpecifiedColor.A = Color.A
    end
end
-- function NewUGCWidgetBlueprint:Destruct()
-- end
return NewUGCWidgetBlueprint