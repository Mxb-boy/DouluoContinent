UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.Common.Common");
local BackpackCapacityUtil = UGCGameSystem.UGCRequire("Script.Common.BackpackCapacityUtil")

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

local GET_ITEM_ENTRY_CLASS_PATH = "/Game/UGC/UITemplate/Get/Item/UGC_Get_FX_UIBP.UGC_Get_FX_UIBP_C"
local GET_ITEM_POPUP_CLASS_PATH = "/Game/UGC/UITemplate/Get/UGC_Get_UIBP.UGC_Get_UIBP_C"
local GET_ITEM_COUNT_WHITE = {
    SpecifiedColor = {
        R = 1.0,
        G = 1.0,
        B = 1.0,
        A = 1.0,
    },
}

local function ApplyEntryCountWhite(Entry)
    if Entry == nil then
        return false
    end

    local CountText = Entry.TextBlock_IconNumber
    if CountText == nil then
        CountText = UGCWidgetManagerSystem.GetSubWidget(Entry, "TextBlock_IconNumber")
    end

    if CountText ~= nil and CountText.SetColorAndOpacity ~= nil then
        return pcall(CountText.SetColorAndOpacity, CountText, GET_ITEM_COUNT_WHITE)
    end

    return false
end

-- The official get-item popup owns the row widgets. Change only the live row
-- instances so the official VirtualItemManager and popup creation flow remain intact.
local function ApplyGetItemCountWhite()
    local EntryClass = UE.LoadClass(GET_ITEM_ENTRY_CLASS_PATH)
    if EntryClass == nil then
        print("[ShopV2][GetItemWhiteCount] entry class load failed")
        return
    end

    local Entries = UGCWidgetManagerSystem.GetAllWidgetsOfClass(EntryClass, false) or {}
    local ChangedCount = 0
    for _, Entry in pairs(Entries) do
        if ApplyEntryCountWhite(Entry) then
            ChangedCount = ChangedCount + 1
        end
    end

    print("[ShopV2][GetItemWhiteCount] changed=" .. tostring(ChangedCount))
end

function ShopV2Manager:OnGetItemEntryUpdated(Item, Idx)
    ApplyEntryCountWhite(Item)
    print("[ShopV2][GetItemWhiteCount] updated idx=" .. tostring(Idx))
end

function ShopV2Manager:BindGetItemPopupLists()
    local PopupClass = UE.LoadClass(GET_ITEM_POPUP_CLASS_PATH)
    if PopupClass == nil then
        return false
    end

    if self.GetItemWhiteBoundPopups == nil then
        self.GetItemWhiteBoundPopups = setmetatable({}, { __mode = "k" })
    end

    local Popups = UGCWidgetManagerSystem.GetAllWidgetsOfClass(PopupClass, false) or {}
    local FoundPopup = false
    for _, Popup in pairs(Popups) do
        FoundPopup = true
        if not self.GetItemWhiteBoundPopups[Popup] then
            if Popup.ItemList ~= nil and Popup.ItemList.OnUpdateItem ~= nil then
                Popup.ItemList.OnUpdateItem:Add(self.OnGetItemEntryUpdated, self)
            end
            if Popup.ReuseList2_02 ~= nil and Popup.ReuseList2_02.OnUpdateItem ~= nil then
                Popup.ReuseList2_02.OnUpdateItem:Add(self.OnGetItemEntryUpdated, self)
            end
            self.GetItemWhiteBoundPopups[Popup] = true
            print("[ShopV2][GetItemWhiteCount] popup lists bound")
        end
    end

    return FoundPopup
end

local function ScheduleGetItemCountWhite()
    -- Bind once after the asynchronous popup creation. If it is not ready yet,
    -- perform one short retry. After binding, OnUpdateItem handles every row.
    Timer.InsertTimer(0.05,
        function()
            if ShopV2Manager:BindGetItemPopupLists() then
                -- One-time compensation for rows created before the delegate bind.
                ApplyGetItemCountWhite()
                return
            end

            Timer.InsertTimer(0.30,
                function()
                    if ShopV2Manager:BindGetItemPopupLists() then
                        ApplyGetItemCountWhite()
                    else
                        print("[ShopV2][GetItemWhiteCount] popup bind missed")
                    end
                end,
            false)
        end,
    false)
end

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

--- 购买前统一检查背包容量，包含装备在身上的物品。
function ShopV2Manager:IsBackpackFull()
    if BackpackCapacityUtil == nil or BackpackCapacityUtil.IsFullIncludingEquipped == nil then
        return false
    end

    local PlayerController = (UGCGameSystem.GetLocalPlayerController ~= nil and
        UGCGameSystem.GetLocalPlayerController()) or GameplayStatics.GetPlayerController(UGCGameSystem.GameState, 0)
    local PlayerPawn = PlayerController and (PlayerController.Pawn or
        (PlayerController.K2_GetPawn ~= nil and PlayerController:K2_GetPawn() or nil)) or nil
    if PlayerPawn == nil then
        return false
    end

    return BackpackCapacityUtil.IsFullIncludingEquipped(PlayerPawn)
end

function ShopV2Manager:CheckBackpackBeforePurchase()
    if not self:IsBackpackFull() then
        return true
    end

    local Bubble = UGCGameSystem.UGCRequire("Script.Blueprint.Lin.Actor.BXCollition")
    if Bubble == nil or Bubble.ShowBubble == nil or Bubble.ShowBubble("背包已满") ~= true then
        self:ShowPurchaseTip("背包已满")
    end
    self.bBlockRepeatPurchase = false
    return false
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
    if not self:CheckBackpackBeforePurchase() then
        return false
    end
    print("[ShopV2] BuyProduct: ProductID=" .. tostring(ProductID) .. " Num=" .. tostring(Num) .. " Price=" .. tostring(CurrentPrice))
    self:GetCommodityOperationManager():BuyProduct(ProductID, CurrentPrice, Num);
    return true
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
        local count = vm ~= nil and vm.GetItemNum ~= nil and vm:GetItemNum(1002, PlayerController) or 0
        print("[ShopV2]  ItemID=1002 virtual count BEFORE cleanup: " .. tostring(count))
        if count > 0 and UnrealNetwork ~= nil and UnrealNetwork.CallUnrealRPC ~= nil then
            -- RemoveVirtualItem is server-only. Ask the owning controller to clean it on the server.
            local ok, err = pcall(UnrealNetwork.CallUnrealRPC, PlayerController, PlayerController,
                "Server_CleanupStaleShopVirtualItem", 1002)
            print("[ShopV2]  -> RPC Server_CleanupStaleShopVirtualItem ok=" .. tostring(ok) ..
                      " err=" .. tostring(err))
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
        [1013] = 8310038,  -- 融魂玉
        [1014] = 8310037,  -- 魂师之证
        [1015] = 8310039,  -- 领域之核
        [1016] = 8310040,  -- 法则碎片
        [1017] = 8310041,  -- 帝魂印
        [1018] = 8310042,  -- 圣魂玉
        [1019] = 8310043,  -- 神兽之血
        [1020] = 8310044,  -- 封号神印
        [1021] = 8310045,  -- 九色神光
        [1022] = 8310035,  -- 火融金（锻造材料）
        [1023] = 8310036,  -- 千年魂环（锻造材料）
        [1024] = 8310047,  -- 英雄无敌 1024
        [1025] = 8310008,  -- 抽奖券
        [1026] = 8310007,  -- 自动攻击
        [1027] = 8310009,  -- 自动拾取
        [1028] = 8310012,  -- 月光绒羽
        [1029] = 8310013,  -- 青金渐变柔羽
        [1030] = 8310014,  -- 赛博机械羽翼
        [1031] = 8310058,  -- 白金圣天使翼
        [1032] = 8310059,  -- 骸骨亡灵骨翼
        [1033] = 8310010,  -- 星澜幻彩羽翼
        [1037] = 8310062,  -- 幸运符
        [1038] = 8310063,  -- 密道终身通行证
        [1039] = 8310064,  -- 爬塔传送卷
        [1040] = 8310065,  -- 10分钟双倍魂环爆率
        [1041] = 8310066,  -- 30分钟双倍魂环爆率
        [1042] = 8310067,  -- 永久双倍魂环爆率
        [1043] = 8310068,  -- 10分钟十倍魂环爆率
        [1044] = 8310069,  -- 30分钟十倍魂环爆率
        [1045] = 8310070,  -- 永久十倍魂环爆率
        [1011] = 8310048,  -- 魂环1 (HunHuan_01)
        [1046] = 8310049,  -- 魂环2 (HunHuan_02)
        [1047] = 8310051,  -- 魂环3 (HunHuan_03)
        [1048] = 8310053,  -- 魂环4 (HunHuan_04)
        [1049] = 8310054,  -- 魂环5 (HunHuan_05)
        [1050] = 8310055,  -- 魂环6 (HunHuan_06)
        [1051] = 8310056,  -- 魂环7 (HunHuan_07)
        [1052] = 8310057,  -- 魂环8 (HunHuan_08)
        [1053] = 8310052,  -- 魂环9 (HunHuan_09)
        [1054] = 8310050,  -- 魂环10 (HunHuan_10)
        [1057] = 8310121,  -- 强化保护卷
        [1058] = 8310132,  -- 技能书
        [1036] = 8310002,  -- 商城武器锤子1级
        [1034] = 8310003,  -- 商城武器圣剑1级
        [1035] = 8310004,  -- 商城武器镰刀1级
        [1061] = 8310135,  -- 属性锁
    }

    for ItemID, Num in pairs(Result.ItemList) do
        print("[ShopV2] OnAddVirtualItem: ItemID=" .. tostring(ItemID) .. " Num=" .. tostring(Num))
        -- self:ShowItemGetPopup(ItemID, Num);

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

    ScheduleGetItemCountWhite()
end

function ShopV2Manager:OnBuyProductResult(Result)
    print("[ShopV2] OnBuyProductResult: bSucceeded=" .. tostring(Result.bSucceeded))
    self.bBlockRepeatPurchase = false;
end
