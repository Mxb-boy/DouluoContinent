---@class SignInEvent_Rule_Popup_UIBP_C:UUserWidget
---@field CloseButton UButton
---@field ContentText UUTRichTextBlock
--Edit Below--
local SignInEvent_Rule_Popup_UIBP = { bInitDoOnce = false } 

function SignInEvent_Rule_Popup_UIBP:Construct()
    
    self.CloseButton.OnClicked:Add(self.CloseClick, self);
end

function SignInEvent_Rule_Popup_UIBP:CloseClick()
    
    self:SetVisibility(ESlateVisibility.Collapsed);
end

function SignInEvent_Rule_Popup_UIBP:Refresh(Text)
    
    self.ContentText:SetText(Text);
end

return SignInEvent_Rule_Popup_UIBP