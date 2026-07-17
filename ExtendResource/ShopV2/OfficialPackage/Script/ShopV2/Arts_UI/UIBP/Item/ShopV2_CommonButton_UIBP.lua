---@class ShopV2_CommonButton_UIBP_C:UUserWidget
---@field BuyButtonSwitcher UWidgetSwitcher
---@field CurrencyIcon UImage
---@field CurrentPriceText UTextBlock
---@field FreeButton UButton
---@field OriginalPrice UCanvasPanel
---@field OriginalPriceText UTextBlock
---@field PriceButton UButton
---@field SoldOutButton UButton
--Edit Below--

local ShopV2_CommonButton_UIBP = 
{ 
    bInitDoOnce = false;
    ProductID = 0;
}; 

function ShopV2_CommonButton_UIBP:Construct()
    
end

function ShopV2_CommonButton_UIBP:Reset()
    
    self.OriginalPrice:SetVisibility(ESlateVisibility.Collapsed);
end

function ShopV2_CommonButton_UIBP:Refresh(ProductID)
    
    self.ProductID = ProductID;
    local ProductData = ShopV2Manager:GetProductConfigData(ProductID);
    local CurrentPrice = UGCCommoditySystem.GetSellingPriceAfterDiscount(ProductID);
    local CurrentTime = UGCGameSystem.GetServerTimeSec();

    self:Reset();

    local PurchasedTimes = ShopV2Manager:GetLimitPurchasedTimes(ProductID);
    local bValid = ProductData.ListingTime <= CurrentTime and ProductData.DelistingTime > CurrentTime;
    if ProductData.LimitType ~= ELimitType.NotLimited and PurchasedTimes >= ProductData.PurchaseLimit then
        self.BuyButtonSwitcher:SetActiveWidgetIndex(2);
        return;
    elseif bValid == false then
        self.BuyButtonSwitcher:SetActiveWidgetIndex(2);
        return;
    elseif CurrentPrice == 0 then
        self.BuyButtonSwitcher:SetActiveWidgetIndex(1);
        return;
    else
        self.BuyButtonSwitcher:SetActiveWidgetIndex(0);
    end

    --- 不能购买时字体红色
    self.CurrentPriceText:SetText(tostring(CurrentPrice));

    if ShopV2Manager:CanAfford(ProductData.ProductID, 1) == false then
        self.CurrentPriceText:SetColorRGBStr("FF0000");
    else
        self.CurrentPriceText:SetColorRGBStr("FFFFFF")
    end

    local IconPath = ShopV2Manager:GetProductCurrencyIconPath(ProductID);
    if IconPath ~= nil then
        Common.LoadObjectAsync(IconPath, 
            function (IconTexture)
                if self ~= nil and UE.IsValid(self) then 
                    self.CurrencyIcon:SetBrushFromTexture(IconTexture)
                end
            end
        ) 
    end

    if CurrentPrice ~= ProductData.SellingPrice then
        self.OriginalPrice:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.OriginalPriceText:SetText(ProductData.SellingPrice);
    end
end

function ShopV2_CommonButton_UIBP:OnClick()

    if ShopV2Manager.bBlockRepeatPurchase == true then
        return;
    end

    if self.BuyButtonSwitcher:GetActiveWidgetIndex() == 2 then
        ShopV2Manager:ShowPurchaseTip("商品已售罄");
        return;
    end

    ShopV2Manager.bBlockRepeatPurchase = true;
    ShopV2Manager:OpenPurchaseUI(self.ProductID);
end

return ShopV2_CommonButton_UIBP;
