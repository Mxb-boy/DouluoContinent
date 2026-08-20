---@class ShopV2_PurchasePopups_UIBP_C:UUserWidget
---@field BuyButton UButton
---@field CloseButton UButton
---@field Common_PopupsBg_Medium_UIBP Common_PopupsBg_Medium_UIBP_C
---@field CountDownText UTextBlock
---@field CountText UTextBlock
---@field CurrencyIcon UImage
---@field DecreaseButton UButton
---@field Image_Bg_Quality UImage
---@field Image_Quality UImage
---@field Increase100Button UButton
---@field Increase10Button UButton
---@field IncreaseButton UButton
---@field ProductIcon UImage
---@field ProductName UTextBlock
---@field TotalPriceText UTextBlock
--Edit Below--

local RankMgr = UGCGameSystem.UGCRequire("Script.Xiao.RankMgr")

local ShopV2_PurchasePopups_UIBP = 
{ 
    bInitDoOnce = false;
    ProductData = nil;
    Count = 1;
    CurrentPrice = 0;
} 

function ShopV2_PurchasePopups_UIBP:Construct()
	
    self.BuyButton.OnClicked:Add(self.OnBuyClick, self);
    self.IncreaseButton.OnClicked:Add(self.OnIncreaseClick, self);
    self.Increase10Button.OnClicked:Add(self.OnIncrease10Click, self);
    self.Increase100Button.OnClicked:Add(self.OnIncrease100Click, self);
    self.DecreaseButton.OnClicked:Add(self.OnDecreaseClick, self);
    self.CloseButton.OnClicked:Add(self.OnCloseClick, self);
end

function ShopV2_PurchasePopups_UIBP:Refresh(ProductID)
    
    self.ProductData = ShopV2Manager:GetProductConfigData(ProductID);
    local ItemData = ShopV2Manager:GetItemConfigData(self.ProductData.ItemID);

    self.Count = 1;
    
    self.ProductName:SetText(self.ProductData.ProductName);
    Common.LoadObjectAsync(ItemData.ItemIcon, 
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then 
                self.ProductIcon:SetBrushFromTexture(IconTexture);
            end
        end
    )

    local Path = ShopV2Manager:GetProductCurrencyIconPath(ProductID);
    if Path ~= nil then
        Common.LoadObjectAsync(Path, 
            function (IconTexture)
                if self ~= nil and UE.IsValid(self) then 
                    self.CurrencyIcon:SetBrushFromTexture(IconTexture);
                end
            end
        ) 
    end
    
    if self.ProductData.AvailableForSale == EAvailableForSale.LimitedTimeSale then
        local RemainingDays = ShopV2Manager:GetRemainingDays(self.ProductData.DelistingTime);
        self.CountDownText:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        self.CountDownText:SetText(string.format("剩%d天下架", RemainingDays));
    else
        self.CountDownText:SetVisibility(ESlateVisibility.Collapsed);
    end
    
    self:RefreshNumAndPrice();
end

function ShopV2_PurchasePopups_UIBP:RefreshNumAndPrice()

    self.CurrentPrice = ShopV2Manager:GetDiscountPrice(self.ProductData.ProductID);
    self.CountText:SetText(tostring(self.Count))
    self.TotalPriceText:SetText(tostring(self.CurrentPrice * self.Count));

    if not ShopV2Manager:CanAfford(self.ProductData.ProductID, self.Count) then
        self.TotalPriceText:SetColorRGBStr("FF0000")
    else
        self.TotalPriceText:SetColorRGBStr("090A14FF")
    end
end

function ShopV2_PurchasePopups_UIBP:ChangeCount(Amount)

    local Tmp = self.Count + Amount;
    
    if Tmp <= 0 then
        Tmp = 1;
    end
    
    --- 超出已有金币数
    if ShopV2Manager:CanAfford(self.ProductData.ProductID, Tmp) == false then
        ShopV2Manager:ShowPurchaseTip("超出已有资金");
        return;
    end

    --- 超出购买限制
    local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(self);
    if self.ProductData.LimitType ~= ELimitType.NotLimited and 
    ShopV2Manager:GetLimitPurchasedTimes(self.ProductData.ProductID) + Tmp > self.ProductData.PurchaseLimit then
        ShopV2Manager:ShowPurchaseTip("超出限购次数");
        return;
    end

    self.Count = Tmp;
    self:RefreshNumAndPrice();
end

function ShopV2_PurchasePopups_UIBP:OnBuyClick()

    local bRequested = false

    if ShopV2Manager:CheckBackpackBeforePurchase() == false then
        bRequested = false
    elseif ShopV2Manager:CanAfford(self.ProductData.ProductID, self.Count) == false then
        ShopV2Manager:ShowPurchaseTip("资金不足");
    elseif self.CurrentPrice ~= ShopV2Manager:GetDiscountPrice(self.ProductData.ProductID) then
        ShopV2Manager:ShowPurchaseTip("购买失败，价格已更新");
    elseif ShopV2Manager:IsProductValid(self.ProductData.ProductID) == false then
        ShopV2Manager:ShowPurchaseTip("购买失败，商品未上架");
    else
        if self.ProductData.CurrencyType == ECurrencyType.OtherCoin then
            bRequested = ShopV2Manager:BuyProduct(self.ProductData.ProductID, self.Count, self.CurrentPrice) ~= false
        else
            local ItemData = ShopV2Manager:GetItemConfigData(self.ProductData.ItemID)
            if ItemData ~= nil then
                self.bCanAfford = ShopV2Manager:CanAfford(self.ProductData.ProductID, self.Count)
                if RankMgr ~= nil and RankMgr.BeginConsumePurchase ~= nil then
                    RankMgr:BeginConsumePurchase(self.ProductData.ProductID, self.ProductData.ItemID,
                        self.CurrentPrice, self.Count)
                end

                local PurchaseFuture = UGCCommoditySystem.BuyUGCCommodity2(self.ProductData.ProductID,
                    ItemData.ItemIcon, ItemData.ItemDesc, self.Count)
                if PurchaseFuture ~= nil then
                    bRequested = true
                    PurchaseFuture:Then(function(Result)
                        local ConfirmUI = Result ~= nil and Result:Get() or nil
                        if ConfirmUI ~= nil and ConfirmUI.ConfirmationOperationDelegate ~= nil then
                            ConfirmUI.ConfirmationOperationDelegate:Add(self.OnOasisCoinPurchaseConfirm, self)
                        else
                            if RankMgr ~= nil and RankMgr.CancelConsumePurchase ~= nil then
                                RankMgr:CancelConsumePurchase()
                            end
                            ShopV2Manager.bBlockRepeatPurchase = false
                        end
                    end)
                elseif RankMgr ~= nil and RankMgr.CancelConsumePurchase ~= nil then
                    RankMgr:CancelConsumePurchase()
                end
            end
        end
    end

    self:SetVisibility(ESlateVisibility.Collapsed);

    if not bRequested then
        ShopV2Manager.bBlockRepeatPurchase = false
    end
end

function ShopV2_PurchasePopups_UIBP:OnOasisCoinPurchaseConfirm(Value)

    if Value ~= true or self.bCanAfford ~= true then
        if RankMgr ~= nil and RankMgr.CancelConsumePurchase ~= nil then
            RankMgr:CancelConsumePurchase()
        end
        ShopV2Manager.bBlockRepeatPurchase = false
        return
    end

    if RankMgr ~= nil and RankMgr.ConfirmConsumePurchase ~= nil then
        RankMgr:ConfirmConsumePurchase()
    end
    -- 确认后保持防重复购买，正式购买结果会由 ShopV2Manager 解除。
    ShopV2Manager.bBlockRepeatPurchase = true
end

function ShopV2_PurchasePopups_UIBP:OnIncreaseClick()
    
    self:ChangeCount(1);
end

function ShopV2_PurchasePopups_UIBP:OnDecreaseClick()
    
    self:ChangeCount(-1);
end

function ShopV2_PurchasePopups_UIBP:OnIncrease10Click()
    
    self:ChangeCount(10);
end

function ShopV2_PurchasePopups_UIBP:OnIncrease100Click()
    
    self:ChangeCount(100);
end

function ShopV2_PurchasePopups_UIBP:OnCloseClick()
    
    self:SetVisibility(ESlateVisibility.Collapsed);
    ShopV2Manager.bBlockRepeatPurchase = false;
end

return ShopV2_PurchasePopups_UIBP
