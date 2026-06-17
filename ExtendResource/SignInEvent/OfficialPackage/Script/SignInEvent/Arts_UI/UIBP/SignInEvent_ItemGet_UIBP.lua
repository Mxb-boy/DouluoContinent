---@class SignInEvent_ItemGet_UIBP_C:UUserWidget
---@field DX_Parachute UWidgetAnimation
---@field DX_GXHD UWidgetAnimation
---@field ConfirmButton UNewButton
---@field ItemList UUGC_ReuseList2_C
--Edit Below--

local SignInEvent_ItemGet_UIBP = { bInitDoOnce = false } 

function SignInEvent_ItemGet_UIBP:Construct()
    
    self.ItemList.OnUpdateItem:Add(self.OnUpdateItem, self);
    self.ConfirmButton.OnClicked:Add(self.OnConfirmClick, self);
end

function SignInEvent_ItemGet_UIBP:OnConfirmClick()
    
    self:SetVisibility(ESlateVisibility.Collapsed);
end

function SignInEvent_ItemGet_UIBP:Popup(ItemID, Num)

    self.Num = Num or 1;

    self.ItemData = Common.GetObjectDatas()[ItemID];
    self.ItemList:Reload(1);

    if CheckObjectContainsField(self, "DX_GXHD") then
        self:PlayAnimation(self.DX_GXHD, 0, 1, EUMGSequencePlayMode.Forward, 1);
    end

    UGCSoundManagerSystem.PlaySound2D(UE.LoadObject("/Game/WwiseEvent/UI_hall/Play_UI_hall_Shopping_Get.Play_UI_hall_Shopping_Get"));
end

function SignInEvent_ItemGet_UIBP:OnUpdateItem(Item, Idx)
    
    Common.LoadObjectAsync(self.ItemData.ItemIcon, 
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then
                Item.ItemIcon:SetBrushFromTexture(IconTexture);
                Item.ItemNameText:SetText(self.ItemData.ItemName);
                Item.NumText:SetText(tostring(self.Num));
            end
        end
    )
end

function SignInEvent_ItemGet_UIBP:OnAnimationFinished(Animation)
    
    if CheckObjectContainsField(self, "DX_GXHD") then
        self:PlayAnimation(self.DX_Parachute, 0, 0, EUMGSequencePlayMode.Forward, 1);
    end
end

return SignInEvent_ItemGet_UIBP