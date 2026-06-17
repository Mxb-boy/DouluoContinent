---@class SignInEvent_Supplementary_Popup_UIBP_C:UUserWidget
---@field CloseButton UButton
---@field Icon UImage
---@field NoButton UButton
---@field NumText UTextBlock
---@field YesButton UButton
--Edit Below--
local SignInEvent_Supplementary_Popup_UIBP = 
{
     bInitDoOnce = false;
    
     EventID = 0;
} 

function SignInEvent_Supplementary_Popup_UIBP:Construct()
    
    self.YesButton.OnClicked:Add(self.OnYesClick, self);
    self.NoButton.OnClicked:Add(self.Close, self);
    self.CloseButton.OnClicked:Add(self.Close, self);
end

function SignInEvent_Supplementary_Popup_UIBP:Refresh(EventID, ItemID, Num)
    
    self.EventID = EventID;

    local ItemData = Common.GetObjectDatas()[ItemID];
    if ItemData == nil then
        return;
    end

    self.NumText:SetText(tostring(Num));
    Common.LoadObjectAsync(ItemData.ItemIcon, 
        function (Object)
            if self ~= nil and Object ~= nil then
                self.Icon:SetBrushFromTexture(Object);
            end
        end
    )
end

function SignInEvent_Supplementary_Popup_UIBP:Close()

    self:SetVisibility(ESlateVisibility.Collapsed);
end

function SignInEvent_Supplementary_Popup_UIBP:OnYesClick()

    local Config = SignInEventManager:GetEventConfigData(self.EventID);
    if SignInEventManager:GetItemNum(Config.SupplementItemID) >= Config.SupplementItemNum then
        SignInEventManager:UseSupplement(self.EventID); 
    else
        SignInEventManager:ShowSupplementTip("补签道具不足");
    end

    self:SetVisibility(ESlateVisibility.Collapsed);
end

return SignInEvent_Supplementary_Popup_UIBP