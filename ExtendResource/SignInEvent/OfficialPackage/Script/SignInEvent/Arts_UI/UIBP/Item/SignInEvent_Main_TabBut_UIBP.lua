---@class SignInEvent_Main_TabBut_UIBP_C:UUserWidget
---@field RedDot UImage
---@field StateSwitcher UWidgetSwitcher
---@field TabButton UNewButton
---@field TabNameText_Normal UTextBlock
---@field TabNameText_Select UTextBlock
--Edit Below--
local SignInEvent_Main_TabBut_UIBP = 
{ 
    bInitDoOnce = false;

    EventID = 0;
} 

function SignInEvent_Main_TabBut_UIBP:Construct()
	
    self.TabButton.OnClicked:Add(self.OnButtonClicked, self);
end

function SignInEvent_Main_TabBut_UIBP:SetTabName(Name)

    self.TabNameText_Normal:SetText(Name);
    self.TabNameText_Select:SetText(Name);
end

function SignInEvent_Main_TabBut_UIBP:Select()
    
    self.StateSwitcher:SetActiveWidgetIndex(1);
end

function SignInEvent_Main_TabBut_UIBP:Deselect()
    
    self.StateSwitcher:SetActiveWidgetIndex(0);
end

function SignInEvent_Main_TabBut_UIBP:ShouldShowRedDot(Value)
    
    self.RedDot:SetVisibility(Value == true and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed);
end

function SignInEvent_Main_TabBut_UIBP:OnButtonClicked()

    SignInEventManager:SelectEvent(self.EventID);
end

return SignInEvent_Main_TabBut_UIBP