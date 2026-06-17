---@class Shop_Common_Get_FX_UIBP_C:UUserWidget
---@field DX_Flip UWidgetAnimation
---@field ItemIcon UImage
---@field ItemNameText UTextBlock
---@field NumText UTextBlock
--Edit Below--
local SignInEvent_Common_Get_FX_UIBP = { bInitDoOnce = false } 

function SignInEvent_Common_Get_FX_UIBP:Construct()
	
end

function SignInEvent_Common_Get_FX_UIBP:InitUI(ItemID, Num)

    Num = Num or 1;

    local ItemInfo = LotteryManager:GetObjectByID(ItemID);
    if ItemInfo and ItemInfo.ItemIcon then
        self.ItemIcon:SetBrushFromTexture(UE.LoadObject(ItemInfo.ItemIcon));
        self.ItemNameText(ItemInfo.ItemName);
        self.NumText(tostring(Num));
    end
end

return SignInEvent_Common_Get_FX_UIBP