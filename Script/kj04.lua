---@class kj04_C:UUserWidget
---@field Btn_Buy UButton
---@field Btn_Close UButton
---@field Image_0 UImage
---@field Image_1 UImage
---@field Image_45 UImage
---@field Image_107 UImage
---@field Image_108 UImage
---@field Image_109 UImage
---@field Image_110 UImage
---@field Image_111 UImage
---@field Image_112 UImage
---@field Image_113 UImage
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local RankMgr = UGCGameSystem.UGCRequire("Script.Xiao.RankMgr")

-- Fill this mapping after the standalone shop gift product is configured.
local KJ04_GIFT_PRODUCT = {
    ProductID = 9000051,
    ItemID = 1055,
}
local KJ04_REWARD_ITEMS = {
    {ItemID = 1028, BackpackItemID = 8310012, Num = 1},
    {ItemID = 1047, BackpackItemID = 8310051, Num = 6},
    {ItemID = 1057, BackpackItemID = 8310121, Num = 2},
}

local kj04 = { bInitDoOnce = false } 

function kj04:Construct()
    self:LuaInit()
end

function kj04:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    self:ApplyButtonEffect(self.Btn_Buy)
    self:ApplyButtonEffect(self.Btn_Close)

    if self.Btn_Buy ~= nil then
        self.Btn_Buy.OnClicked:Add(self.Btn_Buy_OnClicked, self)
    end

    if self.Btn_Close ~= nil then
        self.Btn_Close.OnClicked:Add(self.Btn_Close_OnClicked, self)
    end

    self:RefreshBuyButtonState()
end

function kj04:ApplyButtonEffect(Button)
    if Button == nil or UIEffectUtil == nil then
        return
    end

    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end

function kj04:Btn_Buy_OnClicked()
    if self:HasPurchasedGiftPack() then
        self:RefreshBuyButtonState()
        return
    end

    self:PurchaseGiftPack()
end

function kj04:Btn_Close_OnClicked()
    if self.RemoveFromParent ~= nil then
        self:RemoveFromParent()
    elseif self.SetVisibility ~= nil then
        self:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function kj04:PurchaseGiftPack()
    if self:HasPurchasedGiftPack() then
        self:RefreshBuyButtonState()
        return false
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    local ProductID = tonumber(KJ04_GIFT_PRODUCT.ProductID)
    local ItemID = tonumber(KJ04_GIFT_PRODUCT.ItemID)
    if ProductID == nil or ProductID <= 0 then
        ProductID = self:GetShopProductID(ItemID)
    end
    if PlayerController == nil or ProductID == nil then
        ugcprint("[kj04:PurchaseGiftPack] gift product mapping is not configured")
        return false
    end

    if ShopV2Manager == nil or ShopV2Manager.bBlockRepeatPurchase == true then
        return false
    end

    local ProductData = ShopV2Manager:GetProductConfigData(ProductID)
    if ProductData == nil then
        return false
    end

    self:EnsureShopPurchaseCallbacks()
    self.PurchasingProductID = ProductID
    self.PurchasingProductItemID = ProductData.ItemID
    ShopV2Manager.bBlockRepeatPurchase = true

    if ProductData ~= nil and RankMgr ~= nil and RankMgr.BeginConsumePurchase ~= nil then
        RankMgr:BeginConsumePurchase(ProductID, ProductData.ItemID, ShopV2Manager:GetDiscountPrice(ProductID), 1)
    end

    if ProductData.CurrencyType == ECurrencyType.OtherCoin then
        ShopV2Manager:BuyProduct(ProductID, 1, ShopV2Manager:GetDiscountPrice(ProductID))
    else
        local ObjectData = ShopV2Manager:GetItemConfigData(ProductData.ItemID)
        if ObjectData == nil then
            if RankMgr ~= nil and RankMgr.CancelConsumePurchase ~= nil then
                RankMgr:CancelConsumePurchase()
            end
            ShopV2Manager.bBlockRepeatPurchase = false
            self:RemoveShopPurchaseCallback()
            self.PurchasingProductID = nil
            self.PurchasingProductItemID = nil
            return false
        end

        self.GiftPackCanAfford = ShopV2Manager:CanAfford(ProductID, 1)
        local PromiseFuture = UGCCommoditySystem.BuyUGCCommodity2(ProductID, ObjectData.ItemIcon, ObjectData.ItemDesc, 1)
        if PromiseFuture ~= nil then
            PromiseFuture:Then(function(Result)
                local UI = Result:Get()
                if UI ~= nil and UI.ConfirmationOperationDelegate ~= nil then
                    UI.ConfirmationOperationDelegate:Add(self.OnGiftPackPurchaseConfirm, self)
                end
            end)
        else
            if RankMgr ~= nil and RankMgr.CancelConsumePurchase ~= nil then
                RankMgr:CancelConsumePurchase()
            end
            ShopV2Manager.bBlockRepeatPurchase = false
            self:RemoveShopPurchaseCallback()
            self.PurchasingProductID = nil
            self.PurchasingProductItemID = nil
            return false
        end
    end

    return true
end

function kj04:GetShopProductID(ItemID)
    if ItemID == nil or ItemID <= 0 then
        return nil
    end

    if ShopV2Manager == nil or ShopV2Manager.GetAllProductConfigData == nil then
        return nil
    end

    local ProductDatas = ShopV2Manager:GetAllProductConfigData()
    if ProductDatas == nil then
        return nil
    end

    for ProductID, ProductData in pairs(ProductDatas) do
        if tonumber(ProductData.ItemID) == tonumber(ItemID) then
            return tonumber(ProductData.ProductID) or tonumber(ProductData.ProductId) or tonumber(ProductID)
        end
    end

    return nil
end

function kj04:EnsureShopPurchaseCallbacks()
    if ShopV2Manager == nil then
        return
    end

    if ShopV2Manager.bBuyProductResultBinded ~= true then
        ShopV2Manager:GetCommodityOperationManager().BuyProductResultDelegate:Add(ShopV2Manager.OnBuyProductResult,
            ShopV2Manager)
        ShopV2Manager.bBuyProductResultBinded = true
    end

    if self.bKJ04BuyProductResultBinded ~= true then
        ShopV2Manager:GetCommodityOperationManager().BuyProductResultDelegate:Add(self.OnKJ04BuyProductResult, self)
        self.bKJ04BuyProductResultBinded = true
    end
end

function kj04:RemoveShopPurchaseCallback()
    if self.bKJ04BuyProductResultBinded ~= true or ShopV2Manager == nil then
        return
    end

    ShopV2Manager:GetCommodityOperationManager().BuyProductResultDelegate:Remove(self.OnKJ04BuyProductResult, self)
    self.bKJ04BuyProductResultBinded = false
end

function kj04:OnGiftPackPurchaseConfirm(Value)
    if not Value or not self.GiftPackCanAfford then
        if RankMgr ~= nil and RankMgr.CancelConsumePurchase ~= nil then
            RankMgr:CancelConsumePurchase()
        end
        ShopV2Manager.bBlockRepeatPurchase = false
        self:RemoveShopPurchaseCallback()
        self.PurchasingProductID = nil
        self.PurchasingProductItemID = nil
        self.GiftPackCanAfford = nil
        return
    end
end

function kj04:OnKJ04BuyProductResult(Result)
    if Result == nil or tonumber(Result.ProductID) ~= tonumber(self.PurchasingProductID) then
        return
    end

    if Result.bSucceeded == true then
        self:GrantRewardsToBackpack()
        self:UnlockFlight()
        self:ShowRewardPopup()
        self:SetGiftPackPurchased(true)
    end

    if RankMgr ~= nil and RankMgr.ConfirmConsumePurchase ~= nil then
        if Result.bSucceeded == true then
            RankMgr:ConfirmConsumePurchase(self.PurchasingProductItemID)
        elseif RankMgr.CancelConsumePurchase ~= nil then
            RankMgr:CancelConsumePurchase()
        end
    end

    ShopV2Manager.bBlockRepeatPurchase = false
    self:RemoveShopPurchaseCallback()
    self.PurchasingProductID = nil
    self.PurchasingProductItemID = nil
    self.GiftPackCanAfford = nil
end

function kj04:UnlockFlight()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    if PlayerController.PlayerState ~= nil then
        PlayerController.PlayerState.FeiButton0Hidden = 1
    end
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_SetFeiButton0Hidden", 1)
end

function kj04:GrantRewardsToBackpack()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil or UnrealNetwork == nil or UnrealNetwork.CallUnrealRPC == nil then
        return
    end

    for _, Reward in ipairs(KJ04_REWARD_ITEMS) do
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_AddShopItemToBackpackV2",
            Reward.BackpackItemID, Reward.Num or 1, nil)
    end
end

function kj04:ShowRewardPopup()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local LotteryComponent = PlayerController and PlayerController.LotteryComponent or nil
    if LotteryComponent ~= nil and LotteryComponent.OpenGetItemUI ~= nil then
        local ItemList = {}
        for _, Reward in ipairs(KJ04_REWARD_ITEMS) do
            table.insert(ItemList, {ItemID = Reward.ItemID, ItemNum = Reward.Num or 1})
        end
        LotteryComponent:OpenGetItemUI(ItemList)
        return
    end

    for _, Reward in ipairs(KJ04_REWARD_ITEMS) do
        if ShopV2Manager ~= nil and ShopV2Manager.ShowItemGetPopup ~= nil then
            ShopV2Manager:ShowItemGetPopup(Reward.ItemID, Reward.Num or 1)
        end
    end
end

function kj04:HasPurchasedGiftPack()
    if self.bGiftPackPurchased == true then
        return true
    end

    if self:HasReachedShopPurchaseLimit() then
        self.bGiftPackPurchased = true
        return true
    end

    local PlayerState = self:GetLocalPlayerState()
    if PlayerState == nil then
        return false
    end

    if PlayerState.GetKJ04GiftPackPurchased ~= nil then
        return PlayerState:GetKJ04GiftPackPurchased() == true
    end

    return tonumber(PlayerState.KJ04GiftPackPurchased) == 1
end

function kj04:HasReachedShopPurchaseLimit()
    local ProductID = tonumber(KJ04_GIFT_PRODUCT.ProductID)
    if ProductID == nil or ProductID <= 0 or ShopV2Manager == nil or
        ShopV2Manager.GetProductConfigData == nil or ShopV2Manager.GetLimitPurchasedTimes == nil then
        return false
    end

    local ProductOK, ProductData = pcall(ShopV2Manager.GetProductConfigData, ShopV2Manager, ProductID)
    if not ProductOK or ProductData == nil then
        return false
    end

    local PurchaseLimit = tonumber(ProductData.PurchaseLimit) or 0
    if PurchaseLimit <= 0 then
        return false
    end

    local PurchasedOK, PurchasedTimes = pcall(ShopV2Manager.GetLimitPurchasedTimes, ShopV2Manager, ProductID)
    return PurchasedOK and (tonumber(PurchasedTimes) or 0) >= PurchaseLimit
end

function kj04:GetLocalPlayerState()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    return PlayerController and PlayerController.PlayerState or nil
end

function kj04:SetGiftPackPurchased(value)
    local bPurchased = value == true or tonumber(value) == 1
    self.bGiftPackPurchased = bPurchased

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        if PlayerController.PlayerState ~= nil then
            PlayerController.PlayerState.KJ04GiftPackPurchased = bPurchased and 1 or 0
        end
    end

    self:RefreshBuyButtonState()
end

function kj04:RefreshBuyButtonState()
    if self.Btn_Buy == nil then
        return
    end

    local bPurchased = self:HasPurchasedGiftPack()
    self.Btn_Buy:SetIsEnabled(not bPurchased)

    if self.Btn_Buy.SetRenderOpacity ~= nil then
        self.Btn_Buy:SetRenderOpacity(bPurchased and 0.45 or 1)
    end
end

-- function kj04:Tick(MyGeometry, InDeltaTime)

-- end

function kj04:Destruct()
    self:RemoveShopPurchaseCallback()
end

return kj04
