-- ToastManager.lua
local ToastManager = {}

local ToastItemClass = nil
local ActiveToasts = {}

-- ========== 配置 ==========
local CONFIG = {
    TopOffset = 200,
    FadeInDuration = 0.5,
    HoldDuration = 1.2,
    FadeOutDuration = 0.8,
    RiseDistance = 50,
    FadeOutRiseDistance = 40
}

-- ========== 公开 API ==========


-- ========== 内部函数 ==========

local function CleanupToast(data)
    data.widget:RemoveFromViewport()
    data.widget = nil
    for i, d in ipairs(ActiveToasts) do
        if d == data then
            table.remove(ActiveToasts, i)
            break
        end
    end
end

local function PlayFadeOut(data)
    local startY = data.baseY
    local endY = data.baseY - CONFIG.FadeOutRiseDistance

    local Callback = function(_, Progress)
        data.widget:SetRenderOpacity(1.0 - Progress)
        local currentY = startY + (endY - startY) * Progress
        data.widget:SetPositionInViewport(UGCMathUtility.MakeVector2D(data.baseX, currentY), false)
    end

    local Config = UGCTweenSystem.MakeConfig(0, 0, false, 0)
    local Handle =
        UGCTweenSystem.TweenFloatValue(0.0, 1.0, CONFIG.FadeOutDuration, EEasingType.QuadIn, Callback, Config)
    UGCTweenSystem.BindCompletedDelegate(Handle, function()
        CleanupToast(data)
    end)
    return Handle
end

local function PlayHold(data)
    local Config = UGCTweenSystem.MakeConfig(0, 0, false, 0)
    return UGCTweenSystem.TweenFloatValue(0.0, 0.0, CONFIG.HoldDuration, EEasingType.Linear, function()
    end, Config)
end

local function PlayFadeIn(data)
    local startY = data.baseY + CONFIG.RiseDistance
    data.widget:SetRenderOpacity(0.0)
    data.widget:SetPositionInViewport(UGCMathUtility.MakeVector2D(data.baseX, startY), false)

    local Callback = function(_, Progress)
        data.widget:SetRenderOpacity(Progress)
        local currentY = startY + (data.baseY - startY) * Progress
        data.widget:SetPositionInViewport(UGCMathUtility.MakeVector2D(data.baseX, currentY), false)
    end

    local Config = UGCTweenSystem.MakeConfig(0, 0, false, 0)
    return UGCTweenSystem.TweenFloatValue(0.0, 1.0, CONFIG.FadeInDuration, EEasingType.QuadOut, Callback, Config)
end

local function CreateAndShowToast(WidgetClass, text)
    local ToastWidget = UGCWidgetManagerSystem.CreateWidget(WidgetClass)

    ToastWidget:AddToViewport(10)
    ToastWidget:SetToastText(text)

    local ScreenSize = UGCWidgetManagerSystem.GetViewportSize()
    local baseX = (ScreenSize.X - 400) / 2
    local baseY = CONFIG.TopOffset

    local ToastData = {
        widget = ToastWidget,
        baseX = baseX,
        baseY = baseY
    }
    table.insert(ActiveToasts, ToastData)

    local FadeIn = PlayFadeIn(ToastData)
    local Hold = PlayHold(ToastData)
    local FadeOut = PlayFadeOut(ToastData)
    UGCTweenSystem.ChainTween(FadeIn, Hold)
    UGCTweenSystem.ChainTween(Hold, FadeOut)
end

function ToastManager.ShowToast(text)
    if not ToastItemClass then
        local Path = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Lin/L_Com/L_Com_UITips.L_Com_UITips_C')
        ToastItemClass = UE.LoadClass(Path)
    end
    CreateAndShowToast(ToastItemClass, text)
end

return ToastManager
