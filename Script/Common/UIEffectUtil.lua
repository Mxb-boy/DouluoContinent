local UIEffectUtil = {}

function UIEffectUtil.BindPressScale(Owner, Button, TargetWidget, PressScale, NormalScale)
    if Owner == nil or Button == nil then
        return
    end

    PressScale = PressScale or 1.06
    NormalScale = NormalScale or 1.0
    TargetWidget = TargetWidget or Button

    if Button.OnPressed ~= nil then
        Button.OnPressed:Add(function()
            UIEffectUtil.SetRenderScale(TargetWidget, PressScale)
        end, Owner)
    end

    if Button.OnReleased ~= nil then
        Button.OnReleased:Add(function()
            UIEffectUtil.SetRenderScale(TargetWidget, NormalScale)
        end, Owner)
    end
end

function UIEffectUtil.SetRenderScale(Widget, Scale)
    if Widget == nil or Widget.SetRenderScale == nil then
        return false
    end

    local Success = pcall(Widget.SetRenderScale, Widget, { X = Scale, Y = Scale })
    return Success
end

return UIEffectUtil
