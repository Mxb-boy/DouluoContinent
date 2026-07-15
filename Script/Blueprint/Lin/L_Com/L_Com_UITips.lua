---@class L_Com_UITips_C:UUserWidget
---@field ToastBg UBorder
---@field ToastText UTextBlock
--Edit Below--
---@class W_ToastItem_C:UUserWidget
---@field ToastBg UBorder
---@field ToastText UTextBlock
local L_Com_UITips = {
    bInitDoOnce = false
}

--[==[ Construct
function L_Com_UITips:Construct()

end
-- Construct ]==]

function L_Com_UITips:SetToastText(text)
    self.ToastText:SetText(text)
end

-- function L_Com_UITips:Tick(MyGeometry, InDeltaTime)

-- end

-- function L_Com_UITips:Destruct()

-- end

return L_Com_UITips
