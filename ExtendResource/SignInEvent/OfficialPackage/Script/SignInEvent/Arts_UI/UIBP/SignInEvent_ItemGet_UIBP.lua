---@class SignInEvent_ItemGet_UIBP_C:UUserWidget
---@field DX_Parachute UWidgetAnimation
---@field DX_GXHD UWidgetAnimation
---@field ConfirmButton UNewButton
---@field ItemList UGC_ReuseList2_C
--Edit Below--

local SignInEvent_ItemGet_UIBP = { bInitDoOnce = false } 

function SignInEvent_ItemGet_UIBP:Construct()
    
    self.ItemList.OnUpdateItem:Add(self.OnUpdateItem, self);
    self.ConfirmButton.OnClicked:Add(self.OnConfirmClick, self);
end

function SignInEvent_ItemGet_UIBP:OnConfirmClick()
    
    self:SetVisibility(ESlateVisibility.Collapsed);
end

function SignInEvent_ItemGet_UIBP:Popup(ItemID, Num, ExtraItemID, ExtraNum)

    self.Rewards = {};
    local ObjectDatas = Common.GetObjectDatas() or {};
    local function AddReward(RewardItemID, RewardNum)
        local NumericItemID = tonumber(RewardItemID)
        local NumericNum = math.max(0, math.floor(tonumber(RewardNum) or 0))
        local ItemData = NumericItemID ~= nil and ObjectDatas[NumericItemID] or nil
        if ItemData ~= nil and NumericNum > 0 then
            table.insert(self.Rewards, {ItemData = ItemData, Num = NumericNum})
        end
    end

    AddReward(ItemID, Num or 1);
    AddReward(ExtraItemID, ExtraNum);
    self.ItemList:Reload(#self.Rewards);

    if CheckObjectContainsField(self, "DX_GXHD") then
        self:PlayAnimation(self.DX_GXHD, 0, 1, EUMGSequencePlayMode.Forward, 1);
    end

    UGCSoundManagerSystem.PlaySound2D(UE.LoadObject("/Game/WwiseEvent/UI_hall/Play_UI_hall_Shopping_Get.Play_UI_hall_Shopping_Get"));
end

function SignInEvent_ItemGet_UIBP:OnUpdateItem(Item, Idx)

    local Reward = self.Rewards ~= nil and self.Rewards[Idx + 1] or nil
    if Reward == nil then
        return
    end

    Common.LoadObjectAsync(Reward.ItemData.ItemIcon,
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) and self.Rewards ~= nil and
                self.Rewards[Idx + 1] == Reward and Item ~= nil and UE.IsValid(Item) and
                IconTexture ~= nil then
                Item.ItemIcon:SetBrushFromTexture(IconTexture);
                Item.ItemNameText:SetText(Reward.ItemData.ItemName);
                Item.NumText:SetText(tostring(Reward.Num));
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
