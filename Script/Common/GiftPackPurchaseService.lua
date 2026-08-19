UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage.Script.ShopV2.ShopV2Manager")
UGCGameSystem.UGCRequire("ExtendResource.GiftPack.OfficialPackage.Script.GiftPack.GiftPackManager")

local GiftPackConfig = UGCGameSystem.UGCRequire("Script.Common.GiftPackConfig")
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")
local RankMgr = UGCGameSystem.UGCRequire("Script.Xiao.RankMgr")

local GiftPackPurchaseService = {
    PendingPurchase = nil,
    NextToken = 0,
    bAddItemResultBound = false,
    bBuyProductResultBound = false,
}

local function GetLocalPlayerController()
    if UGCGameSystem.GetLocalPlayerController ~= nil then
        local PlayerController = UGCGameSystem.GetLocalPlayerController()
        if PlayerController ~= nil then
            return PlayerController
        end
    end
    return GameplayStatics.GetPlayerController(UGCGameSystem.GameState, 0)
end

local function IsLocalResult(Result)
    local PlayerController = GetLocalPlayerController()
    if PlayerController == nil or Result == nil then
        return false
    end
    if PlayerController.GetInt64PlayerKey == nil or Result.PlayerKey == nil then
        return true
    end
    local ResultPlayerKey = tonumber(Result.PlayerKey)
    local LocalPlayerKey = tonumber(PlayerController:GetInt64PlayerKey())
    if ResultPlayerKey ~= nil and LocalPlayerKey ~= nil then
        return ResultPlayerKey == LocalPlayerKey
    end
    return tostring(Result.PlayerKey) == tostring(PlayerController:GetInt64PlayerKey())
end

function GiftPackPurchaseService:GetPack(PackKey)
    return GiftPackConfig.Packs[PackKey]
end

function GiftPackPurchaseService:EnsureCallbacks()
    if ShopV2Manager == nil then
        return false
    end

    local VirtualItemManager = ShopV2Manager:GetVirtualItemManager()
    local CommodityOperationManager = ShopV2Manager:GetCommodityOperationManager()
    if VirtualItemManager == nil or CommodityOperationManager == nil or GiftPackManager == nil then
        return false
    end

    if self.bAddItemResultBound ~= true then
        VirtualItemManager.AddItemResultDelegate:Add(self.OnAddVirtualItem, self)
        self.bAddItemResultBound = true
    end
    if self.bBuyProductResultBound ~= true then
        CommodityOperationManager.BuyProductResultDelegate:Add(self.OnBuyProductResult, self)
        self.bBuyProductResultBound = true
    end
    return self.bAddItemResultBound and self.bBuyProductResultBound
end

function GiftPackPurchaseService:SetOfficialGetUIActive(bActive)
    local Pending = self.PendingPurchase
    if Pending == nil or Pending.Config.SuppressOfficialGetUI ~= true then
        return true
    end

    local VirtualItemManager = ShopV2Manager ~= nil and ShopV2Manager:GetVirtualItemManager() or nil
    if VirtualItemManager == nil or VirtualItemManager.SetGetItemUIActive == nil then
        return false
    end

    local Succeeded = pcall(VirtualItemManager.SetGetItemUIActive, VirtualItemManager, bActive == true)
    if Succeeded then
        Pending.bOfficialGetUISuppressed = bActive ~= true
    end
    return Succeeded
end

function GiftPackPurchaseService:ScheduleTimeout(Seconds, Reason)
    local Pending = self.PendingPurchase
    if Pending == nil or Timer == nil or Timer.InsertTimer == nil then
        return
    end

    Pending.TimeoutVersion = (Pending.TimeoutVersion or 0) + 1
    local Token = Pending.Token
    local Version = Pending.TimeoutVersion
    Timer.InsertTimer(Seconds, function()
        local Current = GiftPackPurchaseService.PendingPurchase
        if Current ~= nil and Current.Token == Token and Current.TimeoutVersion == Version then
            GiftPackPurchaseService:Finish(false, Reason)
        end
    end, false)
end

function GiftPackPurchaseService:Finish(bCompleted, Reason)
    local Pending = self.PendingPurchase
    if Pending == nil then
        return
    end

    if Pending.bOfficialGetUISuppressed == true then
        self:SetOfficialGetUIActive(true)
    end
    ShopV2Manager.bBlockRepeatPurchase = false

    if bCompleted ~= true and RankMgr ~= nil and RankMgr.CancelConsumePurchase ~= nil then
        RankMgr:CancelConsumePurchase()
    end

    ugcprint("[GiftPackService] finish key=" .. tostring(Pending.PackKey) ..
                 " completed=" .. tostring(bCompleted == true) .. " reason=" .. tostring(Reason))
    self.PendingPurchase = nil
end

function GiftPackPurchaseService:OnPurchaseConfirmation(Value)
    local Pending = self.PendingPurchase
    if Pending == nil then
        return
    end

    local bConfirmed = Value == true or tonumber(Value) == 1
    if bConfirmed ~= true or Pending.bCanAfford ~= true then
        self:Finish(false, "purchase canceled")
        return
    end

    self:SetOfficialGetUIActive(false)
    self:ScheduleTimeout(GiftPackConfig.ProcessTimeoutSeconds, "gift process timeout")
end

function GiftPackPurchaseService:FinalizeGiftRewardFrame()
    local Pending = self.PendingPurchase
    if Pending == nil or Pending.bGiftCompleted ~= true then
        return
    end

    Pending.bRewardFinalizeScheduled = false
    self:HideOfficialGiftPopup()
    if Pending.bOfficialGetUISuppressed == true then
        self:SetOfficialGetUIActive(true)
    end
    if Pending.bPurchaseSuccessHandled == true then
        self:Finish(true, "purchase and gift completed")
    else
        self:ScheduleTimeout(GiftPackConfig.ProcessTimeoutSeconds, "purchase result timeout")
    end
end

function GiftPackPurchaseService:ScheduleGiftRewardFinalization()
    local Pending = self.PendingPurchase
    if Pending == nil or Pending.bRewardFinalizeScheduled == true then
        return
    end

    Pending.bRewardFinalizeScheduled = true
    local Token = Pending.Token
    if Timer ~= nil and Timer.InsertTimer ~= nil then
        Timer.InsertTimer(0.05, function()
            local Current = GiftPackPurchaseService.PendingPurchase
            if Current ~= nil and Current.Token == Token then
                GiftPackPurchaseService:FinalizeGiftRewardFrame()
            end
        end, false)
    else
        self:FinalizeGiftRewardFrame()
    end
end

function GiftPackPurchaseService:Purchase(PackKey, Options)
    local Config = self:GetPack(PackKey)
    if Config == nil then
        ugcprint("[GiftPackService] unknown pack key=" .. tostring(PackKey))
        return nil
    end
    if self.PendingPurchase ~= nil or ShopV2Manager == nil or
        ShopV2Manager.bBlockRepeatPurchase == true then
        return nil
    end
    if ShopV2Manager:CheckBackpackBeforePurchase() ~= true or self:EnsureCallbacks() ~= true then
        return nil
    end

    local ProductID = tonumber(Config.ProductID)
    local ProductData = ProductID ~= nil and ShopV2Manager:GetProductConfigData(ProductID) or nil
    if ProductData == nil or tonumber(ProductData.ItemID) ~= tonumber(Config.GiftItemID) then
        ugcprint("[GiftPackService] invalid product mapping key=" .. tostring(PackKey))
        return nil
    end

    self.NextToken = self.NextToken + 1
    self.PendingPurchase = {
        Token = self.NextToken,
        PackKey = PackKey,
        Config = Config,
        Options = Options or {},
        ProductID = ProductID,
        bCanAfford = ShopV2Manager:CanAfford(ProductID, 1) == true,
        bPurchaseSuccessHandled = false,
        bGiftOpenRequested = false,
    }
    ShopV2Manager.bBlockRepeatPurchase = true
    self:ScheduleTimeout(GiftPackConfig.ConfirmationTimeoutSeconds, "confirmation timeout")

    local PurchaseFuture = L_Com.BuyShopProduct(ProductID, 1)
    if PurchaseFuture == nil then
        self:Finish(false, "purchase request failed")
        return nil
    end

    PurchaseFuture:Then(function(Result)
        local UI = Result ~= nil and Result:Get() or nil
        local Pending = GiftPackPurchaseService.PendingPurchase
        if Pending ~= nil and Pending.ProductID == ProductID and UI ~= nil and
            UI.ConfirmationOperationDelegate ~= nil then
            UI.ConfirmationOperationDelegate:Add(GiftPackPurchaseService.OnPurchaseConfirmation,
                GiftPackPurchaseService)
        end
    end)
    return PurchaseFuture
end

function GiftPackPurchaseService:OnBuyProductResult(Result)
    local Pending = self.PendingPurchase
    if Pending == nil or Result == nil or
        tonumber(Result.ProductID) ~= tonumber(Pending.ProductID) then
        return
    end

    if Result.bSucceeded ~= true then
        self:Finish(false, "purchase result failed")
        return
    end
    if Pending.bPurchaseSuccessHandled == true then
        return
    end

    Pending.bPurchaseSuccessHandled = true
    local OnPurchaseSuccess = Pending.Options.OnPurchaseSuccess
    if OnPurchaseSuccess ~= nil then
        local Succeeded, ErrorMessage = pcall(OnPurchaseSuccess)
        if not Succeeded then
            ugcprint("[GiftPackService] purchase success callback failed: " .. tostring(ErrorMessage))
        end
    end
    if Pending.bGiftCompleted == true then
        self:ScheduleGiftRewardFinalization()
    end
end

function GiftPackPurchaseService:TryOpenPendingGift(RetryCount)
    local Pending = self.PendingPurchase
    if Pending == nil or Pending.bGiftOpenRequested == true then
        return
    end

    local Succeeded, Opened = pcall(GiftPackManager.OpenGiftPack, GiftPackManager,
        tonumber(Pending.Config.GiftPackID))
    if Succeeded and Opened == true then
        Pending.bGiftOpenRequested = true
        self:ScheduleTimeout(GiftPackConfig.ProcessTimeoutSeconds, "gift reward timeout")
        ugcprint("[GiftPackService] gift opened key=" .. tostring(Pending.PackKey))
        return
    end

    RetryCount = tonumber(RetryCount) or 0
    if RetryCount >= GiftPackConfig.OpenRetryCount or Timer == nil or Timer.InsertTimer == nil then
        self:Finish(false, "gift open failed")
        return
    end

    local Token = Pending.Token
    Timer.InsertTimer(GiftPackConfig.OpenRetryIntervalSeconds, function()
        local Current = GiftPackPurchaseService.PendingPurchase
        if Current ~= nil and Current.Token == Token then
            GiftPackPurchaseService:TryOpenPendingGift(RetryCount + 1)
        end
    end, false)
end

function GiftPackPurchaseService:OnAddVirtualItem(Result)
    local Pending = self.PendingPurchase
    if Pending == nil or Result == nil or Result.bSucceeded ~= true or
        IsLocalResult(Result) ~= true then
        return
    end

    if Result.RequestMark == "GiftPack" then
        self:OnGiftRewardsAdded(Result.ItemList)
        return
    end

    for ItemID, ItemNum in pairs(Result.ItemList or {}) do
        if tonumber(ItemID) == tonumber(Pending.Config.GiftItemID) and
            tonumber(ItemNum) ~= nil and tonumber(ItemNum) > 0 then
            self:TryOpenPendingGift(0)
            return
        end
    end
end

function GiftPackPurchaseService:ConvertGiftOnlyRewards(ItemList)
    local PlayerController = GetLocalPlayerController()
    if PlayerController == nil or UnrealNetwork == nil or UnrealNetwork.CallUnrealRPC == nil then
        return false
    end

    local Rewards = {}
    for ItemKey, RewardValue in pairs(ItemList or {}) do
        local VirtualItemID = nil
        local ItemNum = 0
        if type(RewardValue) == "table" then
            VirtualItemID = tonumber(RewardValue.ItemID)
            ItemNum = math.max(0, math.floor(tonumber(RewardValue.ItemNum) or 0))
        else
            VirtualItemID = tonumber(ItemKey)
            ItemNum = math.max(0, math.floor(tonumber(RewardValue) or 0))
        end
        local Mapping = VirtualItemID ~= nil and GiftPackConfig.RewardMappings[VirtualItemID] or nil
        if Mapping == nil or ItemNum <= 0 then
            ugcprint("[GiftPackService] reward mapping missing item=" .. tostring(VirtualItemID))
            return false
        end
        table.insert(Rewards, {
            VirtualItemID = VirtualItemID,
            ItemNum = ItemNum,
            Mapping = Mapping,
        })
    end
    if #Rewards <= 0 then
        return false
    end

    for _, Reward in ipairs(Rewards) do
        if Reward.Mapping.HandledByShopV2 ~= true then
            local Succeeded = pcall(UnrealNetwork.CallUnrealRPC, PlayerController, PlayerController,
                "Server_AddShopItemToBackpackV2", Reward.Mapping.BackpackItemID,
                Reward.ItemNum, Reward.VirtualItemID)
            if not Succeeded then
                return false
            end
        end
    end
    return true
end

function GiftPackPurchaseService:HideOfficialGiftPopup()
    local Succeeded, GiftPackComponent = pcall(GiftPackManager.GetGiftPackComponent, GiftPackManager)
    if Succeeded and GiftPackComponent ~= nil and GiftPackComponent.ItemGetUI ~= nil then
        GiftPackComponent.ItemGetUI:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function GiftPackPurchaseService:OnGiftRewardsAdded(ItemList)
    local Pending = self.PendingPurchase
    if Pending == nil or Pending.bGiftOpenRequested ~= true then
        return
    end

    if self:ConvertGiftOnlyRewards(ItemList) ~= true then
        self:Finish(false, "reward conversion incomplete")
        return
    end

    self:HideOfficialGiftPopup()
    Pending.bGiftCompleted = true
    self:ScheduleGiftRewardFinalization()
end

return GiftPackPurchaseService
