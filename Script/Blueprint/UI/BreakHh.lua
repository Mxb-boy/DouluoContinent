---@class BreakHh_C:UUserWidget
---@field Image_0 UImage
---@field Image_58 UImage
---@field Image_59 UImage
---@field Img_Hh UImage
---@field text_dzcg UTextBlock
---@field TextBlock_58 UTextBlock
--Edit Below--
local NewUGCWidgetBlueprint = { bInitDoOnce = false } 
local BreakSuccessText = "突破成功"
local BreakFailText = "突破失败"
local BreakSuccessColor = { R = 1.0, G = 0.78, B = 0.22, A = 1.0 }
local BreakFailColor = { R = 1.0, G = 0.18, B = 0.12, A = 1.0 }
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
function NewUGCWidgetBlueprint:ShowBreakResult(IconPath, bSuccess)
    if self.SetIsEnabled ~= nil then
        self:SetIsEnabled(true)
    end
    self:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if self.text_dzcg ~= nil then
        self.text_dzcg:SetText(bSuccess and BreakSuccessText or BreakFailText)
        self:SetTextBlockColor(self.text_dzcg, bSuccess and BreakSuccessColor or BreakFailColor)
    end
    self:SetResultIcon(IconPath)
    self:AutoHideAfterDelay(3.0)
end
function NewUGCWidgetBlueprint:ShowBreakSuccess(IconPath)
    self:ShowBreakResult(IconPath, true)
end
function NewUGCWidgetBlueprint:AutoHideAfterDelay(DelaySeconds)
    self.AutoHideTimerName = self.AutoHideTimerName or ("BreakHhAutoHide_" .. tostring(self))
    UGCTimerUtility.RemoveLuaTimerByName(self.AutoHideTimerName)
    UGCTimerUtility.CreateLuaTimer(DelaySeconds, function()
        if self ~= nil then
            self:SetVisibility(ESlateVisibility.Collapsed)
            if self.SetIsEnabled ~= nil then
                self:SetIsEnabled(false)
            end
        end
    end, false, self.AutoHideTimerName)
end
function NewUGCWidgetBlueprint:SetResultIcon(IconPath)
    if self.Img_Hh == nil or IconPath == nil then
        return
    end
    self.IconTextureCache = self.IconTextureCache or {}
    local IconTexture = self.IconTextureCache[IconPath]
    if IconTexture == nil then
        IconTexture = UE.LoadObject(IconPath)
        self.IconTextureCache[IconPath] = IconTexture
    end
    if IconTexture == nil then
        ugcprint("[NewUGCWidgetBlueprint:SetResultIcon] Icon load failed: " .. tostring(IconPath))
        return
    end
    self.Img_Hh:SetBrushFromTexture(IconTexture)
    if self.Img_Hh.SetColorAndOpacity ~= nil then
        pcall(self.Img_Hh.SetColorAndOpacity, self.Img_Hh, { R = 1.0, G = 1.0, B = 1.0, A = 1.0 })
    end
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
