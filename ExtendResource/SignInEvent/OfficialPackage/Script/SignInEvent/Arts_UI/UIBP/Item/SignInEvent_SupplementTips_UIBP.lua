---@class SignInEvent_SupplementTips_UIBP_C:UUserWidget
---@field DX_In UWidgetAnimation
---@field TipsText UTextBlock
--Edit Below--
local SignInEvent_SupplementTips_UIBP = { bInitDoOnce = false } 

function SignInEvent_SupplementTips_UIBP:Construct()
	
end

function SignInEvent_SupplementTips_UIBP:ShowMessageTip(Text)
    
    self.TipsText:SetText(Text);    

    -- 播放动画
    if CheckObjectContainsField(self, "DX_In") then
        self:PlayAnimation(self.DX_In, 0, 1, EUMGSequencePlayMode.Forward, 1);
    end
end

return SignInEvent_SupplementTips_UIBP