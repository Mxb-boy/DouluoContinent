UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.Common.Common");

---@type UKismetMathLibrary
KismetMathLibrary = KismetMathLibrary == nil and nil or KismetMathLibrary

local Delegate = UGCGameSystem.UGCRequire("common.Delegate");

ShopV2Manager = ShopV2Manager or
{
    ShopComponentClass = nil;

    bBlockRepeatPurchase = false;

    LocalComponent = nil;

    ProductIDGroupByTabID = nil;

    VirtualItemManager = nil;
    CommodityOperationManager = nil;

    OnItemNumChangeDelegate = Delegate.New();

    ItemQuality = nil;

    bBuyProductResultBinded = false,
    bLimitProductDelegateBinded = false,
    bAddItemResultDelegateBinded = false,
    bItemNumUpdateDelegateBinded = false,
}

function ShopV2Manager:RegisterComponentClass(CompClass)

    if CompClass ~= nil then
        self.ComponentClass = CompClass;
    end
end

function ShopV2Manager:RegisterMainUI(MainUI)
    
    if self.MainUI == nil then
        self.MainUI = MainUI;
    end
end

function ShopV2Manager:UnregisterMainUI()
    
    self.MainUI = nil;
    self:GetCommodityOperationManager().BuyProductResultDelegate:Remove(self.OnBuyProductResult, self);
    self.bBuyProductResultBinded = false
end

function ShopV2Manager:GetCommodityOperationManager()

    if self.CommodityOperationManager == nil then
        self.CommodityOperationManager = UGCGamePartSystem.CommodityOperationManager.GetGlobalActor();
    end

    return self.CommodityOperationManager;
end

function ShopV2Manager:GetVirtualItemManager()
    
    if self.VirtualItemManager == nil then
        self.VirtualItemManager = UGCGamePartSystem.VirtualItemManager.GetGlobalActor();
    end

    return self.VirtualItemManager;
end

function ShopV2Manager:GetProductConfigData(ProductID)
    
    return self:GetCommodityOperationManager():GetProductData(ProductID);
end

function ShopV2Manager:GetItemConfigData(ItemID)
    
    return self:GetVirtualItemManager():GetItemData(ItemID);
end

function ShopV2Manager:GetAllProductConfigData()
    
    return self:GetCommodityOperationManager():GetAllProductData();
end

function ShopV2Manager:GetAllItemConfigDatas()
    
    return self:GetVirtualItemManager():GetItemDatas();
end

function ShopV2Manager:GetLimitPurchasedTimes(ProductID, PlayerController)
    
    return self:GetCommodityOperationManager():GetLimitPurchasedTimes(ProductID, PlayerController);
end

function ShopV2Manager:GetPurchasedTimes(ProductID, PlayerController)
    
    return self:GetCommodityOperationManager():GetPurchasedTimes(ProductID, PlayerController);
end

function ShopV2Manager:GetAllLimitPurchasedProducts(PlayerController)
    
    return self:GetCommodityOperationManager():GetAllLimitPurchasedProducts(PlayerController);
end

function ShopV2Manager:GetAllPurchasedProducts(PlayerController)
    
    return self:GetCommodityOperationManager():GetAllPurchasedProducts(PlayerController);
end

function ShopV2Manager:GetQualityTexturePath(ItemID, bBigSize)
    
    if self.ItemQuality == nil then
        self:GetShopV2Component():ReadItemQualityTable();
    end

    local QualityRank = self.ItemQuality[ItemID];
    if QualityRank == nil or QualityRank < 0 or QualityRank > 6 then
        QualityRank = 0;
    end

    local Path = bBigSize == true and UGCItemSystem.GetBigQualityTexturePath(QualityRank) or UGCItemSystem.GetQualityTexturePath(QualityRank);

    return Path;
end

function ShopV2Manager:GetQualityBarTexturePath(ItemID)

    if self.ItemQuality == nil then
        self:GetShopV2Component():ReadItemQualityTable();
    end

    local QualityRank = self.ItemQuality[ItemID];
    if QualityRank == nil or QualityRank < 0 or QualityRank > 6 then
        QualityRank = 0;
    end

    local Path = UGCItemSystem.GetQualityBarTexturePath(QualityRank);
    return Path;
end

function ShopV2Manager:CanAfford(ProductID, Num, PlayerController)
    
    return self:GetCommodityOperationManager():CanAfford(ProductID, Num, PlayerController);
end

--- 获取玩家的 SignInEventComponent
--- 生效范围：客户端&&服务器
---@param PlayerController UGCPlayerController_C @玩家控制器，客户端可以不传入，默认客户端的主控玩家控制器
---@return ShopV2Component_C @商城V2组件
function ShopV2Manager:GetShopV2Component(PlayerController)

    if PlayerController == nil and UGCGameSystem.GameState:HasAuthority() == false then
        if self.LocalComponent == nil then
            if self.ComponentClass ~= nil and UGCGameSystem.GameState ~= nil then
                local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(UGCGameSystem.GameState);
                self.LocalComponent = PlayerController:GetComponentByClass(self.ComponentClass);
            else
                print("[ShopV2Manager:GetShopV2Component] Cannot get local component!");
            end
        end
           
        return self.LocalComponent;
    end

    if self.ComponentClass ~= nil then
        return PlayerController:GetComponentByClass(self.ComponentClass);
    else
        print("[ShopV2Manager:GetShopV2Component] ComponentClass is nil!");
        return nil;
    end
end

function ShopV2Manager:OpenMainUI(TabID)

    if self.MainUI == nil then
        print("[ShopV2] OpenMainUI: MainUI nil, retry in 0.5s");
        Timer.InsertTimer(0.5,
            function()
                if self ~= nil and self.MainUI ~= nil then
                    self:OpenMainUI(TabID)
                else
                    print("[ShopV2] OpenMainUI: MainUI still nil after retry, check MainUIClassPath in ShopV2Component CDO")
                end
            end
        , false)
        return;
    end

    print("[ShopV2] OpenMainUI: MainUI OK, binding delegates...")

    -- 一次性清理 UGCObjectMapping bug 残留的堆积虚拟物品
    if not self._bCleanedVirtualItems then
        self._bCleanedVirtualItems = true
        self:CleanupAccumulatedVirtualItems()
    end

    if not self.bBuyProductResultBinded then
        self:GetCommodityOperationManager().BuyProductResultDelegate:Add(self.OnBuyProductResult, self);
        self.bBuyProductResultBinded = true
        print("[ShopV2]  + BuyProductResultDelegate binded")
    end

    if not self.bLimitProductDelegateBinded then
        self:GetCommodityOperationManager().LimitProductUpdateDelegate:Add(self.RefreshProducts, self);
        self.bLimitProductDelegateBinded = true
        print("[ShopV2]  + LimitProductUpdateDelegate binded")
    end

    if not self.bAddItemResultDelegateBinded then
        self:GetVirtualItemManager().AddItemResultDelegate:Add(self.OnAddVirtualItem, self);
        self.bAddItemResultDelegateBinded = true
        print("[ShopV2]  + AddItemResultDelegate binded")
    end

    if not self.bItemNumUpdateDelegateBinded then
        self:GetVirtualItemManager().OnItemNumUpdatedDelegate:Add(self.OnItemNumUpdate, self);
        self.bItemNumUpdateDelegateBinded = true
        print("[ShopV2]  + OnItemNumUpdatedDelegate binded")
    end

    print("[ShopV2] OpenMainUI: all delegates ready, opening UI TabID=" .. tostring(TabID))

    if TabID ~= nil then
        self.MainUI.SelectedTabID = TabID;
        self.MainUI.ShopGoods.TabID = TabID;
    end

    self.MainUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.MainUI:RefreshTabs();
    self.MainUI:InitCurrencyBar()
    self.MainUI:CheckRefreshTime();
    
    self.OnItemNumChangeDelegate();
end

function ShopV2Manager:CloseMainUI()

    if self.MainUI == nil then
        print("[ShopV2Manager:OpenMainUI] MainUI is nil!");
        return;
    end

    self:GetCommodityOperationManager().LimitProductUpdateDelegate:Remove(self.RefreshProducts, self);
    self.bLimitProductDelegateBinded = false
    self:GetVirtualItemManager().AddItemResultDelegate:Remove(self.OnAddVirtualItem, self);
    self.bAddItemResultDelegateBinded = false
    self:GetVirtualItemManager().OnItemNumUpdatedDelegate:Remove(self.OnItemNumUpdate, self);
    self.bItemNumUpdateDelegateBinded = false
    self.MainUI:SetVisibility(ESlateVisibility.Collapsed);
end

function ShopV2Manager:OpenPurchaseUI(ProductID)
    
    self.MainUI:ShowPurchasePanel(ProductID);
end

function ShopV2Manager:RefreshProducts()

    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return;
    end

    self.MainUI.ShopGoods:RefreshCurrentList(false);
end

function ShopV2Manager:RefreshProductDetail()
    
    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return;
    end

    self.MainUI.ShopGoods:RefreshCurrentProductDetailPanel();
end

function ShopV2Manager:ResetSelectedProductID()
    
    if self.MainUI == nil or self.MainUI:GetIsVisible() == false then
        return;
    end

    self.MainUI.ShopGoods.LastSelectedProductID = 0;
    self.MainUI.ShopGoods.SelectedProductID = 0;
end

function ShopV2Manager:ShowPurchaseTip(Message)

    if self.MainUI == nil then
        return;
    end

    self.MainUI:ShowPurchaseTip(Message);
end

function ShopV2Manager:ShowItemGetPopup(ItemID, Num)
    
    if self.MainUI == nil then
        return;
    end

    self.MainUI:ShowItemGet(ItemID, Num);
end

function ShopV2Manager:GetProductCurrencyIconPath(ProductID)
    
    local ProductData = self:GetCommodityOperationManager():GetProductData(ProductID);

    if ProductData.CurrencyType == ECurrencyType.OasisCoin then
        return KismetSystemLibrary.BreakSoftObjectPath(self.MainUI.OasisIconPath);
    end

    if ProductData.CurrencyType == ECurrencyType.OtherCoin then
        local VirtualItemManager = UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager");
        return VirtualItemManager:GetItemData(ProductData.CostID).ItemIcon;
    end

    return nil;
end

function ShopV2Manager:OnItemNumUpdate()
    
    self:RefreshProducts();
    self.OnItemNumChangeDelegate();
end

function ShopV2Manager:SelectShopTab(TabID)
    
    self.MainUI:SelectTab(TabID);
end

function ShopV2Manager:SelectProduct(ProductID)

    self.MainUI:SelectProduct(ProductID);
end

--- 获取到截止日期的剩余天数
--- 生效范围：服务器&&客户端
---@param EndTime int
---@return int
function ShopV2Manager:GetRemainingDays(EndTime)
    
    local RemainingSec = EndTime - UGCGameSystem.GetServerTimeSec();

    return RemainingSec > 0 and math.floor(RemainingSec/3600/24) or 0; 
end

function ShopV2Manager:GetDiscountPrice(ProductID)
    
    return UGCCommoditySystem.GetSellingPriceAfterDiscount(ProductID);
end

--- 检查商品的是否能够上架
--- 生效范围：服务器&&客户端
---@param ProductID int
---@return bool
function ShopV2Manager:IsProductValid(ProductID)

    local ProductData = self:GetCommodityOperationManager():GetProductData(ProductID);
    
    if ProductData == nil then
        return false;
    end

    if ProductData.AvailableForSale == EAvailableForSale.NotForSale then
        return false;
    end

    if ProductData.StoreID == EStoreId.Lobby then
        return false;
    end

    local CurrentTime = UGCGameSystem.GetServerTimeSec();
    local ListingTime = ProductData.ListingTime;
    
    return CurrentTime >= ListingTime;
end

function ShopV2Manager:IsPermanentDiscount(EndTime)
    
    local Date = os.date("*t", EndTime);

    return Date.year >= 3000;
end

---发起购买非绿洲币商品
---生效范围：客户端
---@param ProductID int
---@param Num int 购买商品数量
---@param CurrentPrice int 商品价格
function ShopV2Manager:BuyProduct(ProductID, Num, CurrentPrice)
    print("[ShopV2] BuyProduct: ProductID=" .. tostring(ProductID) .. " Num=" .. tostring(Num) .. " Price=" .. tostring(CurrentPrice))
    self:GetCommodityOperationManager():BuyProduct(ProductID, CurrentPrice, Num);
end

---获取对应页签的所有商品ID
---@param TabID int @页签ID
---@param bRefresh bool @是否刷新全部商品（会添加满足上架条件的商品）
---@return Array @排序后同一页签下的商品ID数组
function ShopV2Manager:GetProductIDsInTab(TabID, bRefresh)

    if self.ProductIDGroupByTabID == nil or bRefresh == true then
        print("[ShopV2Manager:GetProductIDsInTab] Group ProductID by TabID");
        self:GroupProductIDByTabID();
    end

    if self.ProductIDGroupByTabID[tostring(TabID)] == nil then
        print("[ShopV2Manager:GetProductIDsInTab] No products in TabID");
        return {};
    end

    return self.ProductIDGroupByTabID[tostring(TabID)];
end

function ShopV2Manager:GroupProductIDByTabID()

    print("[ShopV2Manager:GroupProductIDByTabID] Start group ProductID by TabID");

    local ProductDatas = self:GetCommodityOperationManager():GetAllProductData();
    self.ProductIDGroupByTabID = {};

    for ProductID, ProductData in pairs(ProductDatas) do
       --- 按照 TabID 分组
        local TabID = tostring(ProductData.TabID);
        self.ProductIDGroupByTabID[TabID] = self.ProductIDGroupByTabID[TabID] or {};
        --- 只添加有效的商品到分组
        if self:IsProductValid(ProductData.ProductID) == true then
            table.insert(self.ProductIDGroupByTabID[TabID], ProductID);
        end 
    end

    local function Compare(ProductIDA, ProductIDB)
    
        local ProductDataA = ShopV2Manager:GetCommodityOperationManager():GetProductData(ProductIDA);
        local ProductDataB = ShopV2Manager:GetCommodityOperationManager():GetProductData(ProductIDB);
    
        if ProductDataA.SortPriority ~= ProductDataB.SortPriority then
            return ProductDataA.SortPriority < ProductDataB.SortPriority;
        end
        
        -- 优先级一样按照 ID 排序
        return ProductDataA.ProductID < ProductDataB.ProductID;
    end

    --- 商品排序，优先级越小的越靠前
    for _, Tab in pairs(self.ProductIDGroupByTabID) do
        table.sort(Tab, Compare);
    end

    return self.ProductIDGroupByTabID;
end

-- 一次性清理 UGCObjectMapping bug 残留的堆积虚拟物品
function ShopV2Manager:CleanupAccumulatedVirtualItems()
    print("[ShopV2] CleanupAccumulatedVirtualItems: removing stale virtual items...")
    local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(UGCGameSystem.GameState)
    if PlayerController then
        local vm = self:GetVirtualItemManager()
        local count = vm:GetItemNum(PlayerController, 1002)
        print("[ShopV2]  ItemID=1002 virtual count BEFORE cleanup: " .. tostring(count))
        if count > 0 then
            vm:RemoveVirtualItem(PlayerController, 1002, count)
            print("[ShopV2]  Removed " .. tostring(count) .. " stale virtual items")
        end
    end
end

function ShopV2Manager:OnAddVirtualItem(Result)

    if Result.bSucceeded == false then
        print("[ShopV2] OnAddVirtualItem: FAILED")
        return;
    end

    -- 虚拟物品ID → 背包物品ID 映射（后续新增商品在此扩展）
    local VIRTUAL_TO_BACKPACK = {
        [1002] = 8310001,  -- 核子可乐
        [1013] = 8310038,  -- 图鉴 1013
        [1014] = 8310037,  -- 图鉴 1014
        [1015] = 8310039,  -- 图鉴 1015
        [1016] = 8310040,  -- 图鉴 1016
        [1017] = 8310041,  -- 图鉴 1017
        [1018] = 8310042,  -- 图鉴 1018
        [1019] = 8310043,  -- 图鉴 1019
        [1020] = 8310044,  -- 图鉴 1020
        [1021] = 8310045,  -- 图鉴 1021
        [1022] = 8310035,  -- 火融金（锻造材料）
        [1023] = 8310036,  -- 千年魂环（锻造材料）
        [1024] = 8310047,  -- 英雄无敌 1024
        [1025] = 8310008,  -- 抽奖券
        [1026] = 8310007,  -- 自动攻击
        [1027] = 8310009,  -- 自动拾取
    }

    for ItemID, Num in pairs(Result.ItemList) do
        print("[ShopV2] OnAddVirtualItem: ItemID=" .. tostring(ItemID) .. " Num=" .. tostring(Num))
        self:ShowItemGetPopup(ItemID, Num);

        local BackpackItemID = VIRTUAL_TO_BACKPACK[ItemID]
        if BackpackItemID then
            local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(UGCGameSystem.GameState)
            print("[ShopV2]  -> PC=" .. tostring(PlayerController))
            if PlayerController and UnrealNetwork and UnrealNetwork.CallUnrealRPC then
                print("[ShopV2]  -> RPC Server_AddShopItemToBackpackV2: BP_ID=" .. tostring(BackpackItemID) .. " Num=" .. tostring(Num) .. " VItemID=" .. tostring(ItemID))
                -- BugFix: 传入 VirtualItemID，由服务端统一完成 AddItemV2 + RemoveVirtualItem
                local ok, err = pcall(UnrealNetwork.CallUnrealRPC, PlayerController, PlayerController, "Server_AddShopItemToBackpackV2", BackpackItemID, Num, ItemID)
                print("[ShopV2]  -> RPC ok=" .. tostring(ok) .. " err=" .. tostring(err))
            else
                print("[ShopV2]  -> MISSING PC or UnrealNetwork")
            end
        else
            print("[ShopV2]  -> No mapping for ItemID=" .. tostring(ItemID) .. " (not a shop reward)")
        end
    end
end

function ShopV2Manager:OnBuyProductResult(Result)
    print("[ShopV2] OnBuyProductResult: bSucceeded=" .. tostring(Result.bSucceeded))
    self.bBlockRepeatPurchase = false;
end
