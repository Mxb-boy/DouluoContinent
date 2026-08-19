local RankMgr = {
    ZhanLiRankID = 1,
    WealthRankID = 2,
    ConsumeRankID = 2, -- 兼容旧调用：财富榜按成功消费金额累计
    TowerRankID = 3,
    PreviousRankingCycle = 1,
    RankBonusTopCount = 50,
    RankBonusReadyDelaySeconds = 2,
    RankBonusCycleCheckIntervalSeconds = 60,
    RankBonusSettlementDelaySeconds = 120,
    LastUploadZhanLi = nil,
    bConsumePurchaseResultBound = false,
    RankRewardBackpackItemIDs = {
        [1057] = 8310121, -- 强化保护卷
        [1044] = 8310069, -- 30分钟十倍魂环爆率
        [1039] = 8310064, -- 爬塔传送卷
    },
    BonusByRank = {
        {MinRank = 1, MaxRank = 1, Percent = 100},
        {MinRank = 2, MaxRank = 2, Percent = 82},
        {MinRank = 3, MaxRank = 3, Percent = 65},
        {MinRank = 4, MaxRank = 10, Percent = 40},
        {MinRank = 11, MaxRank = 20, Percent = 22},
        {MinRank = 21, MaxRank = 30, Percent = 10},
        {MinRank = 31, MaxRank = 50, Percent = 2},
    },
}

local function GetLocalPlayerController()
    if UGCGameSystem ~= nil and UGCGameSystem.GetLocalPlayerController ~= nil then
        return UGCGameSystem.GetLocalPlayerController()
    end
    if GameplayStatics ~= nil then
        return GameplayStatics.GetPlayerController(UGCGameSystem.GameState, 0)
    end
    return nil
end

local function GetLocalUID(PlayerController)
    local Pawn = nil
    if UGCGameSystem ~= nil and UGCGameSystem.GetLocalPlayerPawn ~= nil then
        Pawn = UGCGameSystem.GetLocalPlayerPawn()
    elseif PlayerController ~= nil and PlayerController.Pawn ~= nil then
        Pawn = PlayerController.Pawn
    end

    if Pawn ~= nil and UGCPawnAttrSystem ~= nil and UGCPawnAttrSystem.GetPlayerUID ~= nil then
        local UID = tonumber(UGCPawnAttrSystem.GetPlayerUID(Pawn))
        if UID ~= nil and UID > 0 then
            return UID
        end
    end

    if RankingListManager ~= nil and RankingListManager.GetSelfUID ~= nil then
        local UID = tonumber(RankingListManager:GetSelfUID())
        if UID ~= nil and UID > 0 then
            return UID
        end
    end

    return nil
end

function RankMgr:GrantRankRewardsToBackpackV2(PlayerController, ItemList)
    if PlayerController == nil or PlayerController.HasAuthority == nil or
        PlayerController:HasAuthority() == false then
        print("[RankMgr] GrantRankRewardsToBackpackV2 failed: invalid authority")
        return false
    end

    if ItemList == nil then
        print("[RankMgr] GrantRankRewardsToBackpackV2 failed: invalid ItemList")
        return false
    end

    local Pawn = PlayerController.Pawn
    if Pawn == nil and PlayerController.K2_GetPawn ~= nil then
        Pawn = PlayerController:K2_GetPawn()
    end
    if Pawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.AddItemV2 == nil then
        print("[RankMgr] GrantRankRewardsToBackpackV2 failed: backpack is unavailable")
        return false
    end

    local VirtualItemManager = nil
    if UGCGamePartSystem ~= nil and UGCGamePartSystem.GetGamePartGlobalActor ~= nil then
        VirtualItemManager = UGCGamePartSystem.GetGamePartGlobalActor("VirtualItemManager")
    end
    if VirtualItemManager == nil or VirtualItemManager.RemoveVirtualItem == nil then
        print("[RankMgr] GrantRankRewardsToBackpackV2 failed: VirtualItemManager is unavailable")
        return false
    end

    local bAllSucceeded = true
    for RawVirtualItemID, RawNum in pairs(ItemList) do
        local VirtualItemID = tonumber(RawVirtualItemID)
        local RequestedNum = math.floor(tonumber(RawNum) or 0)
        local BackpackItemID = VirtualItemID ~= nil and self.RankRewardBackpackItemIDs[VirtualItemID] or nil

        if BackpackItemID == nil or RequestedNum <= 0 then
            bAllSucceeded = false
            print(string.format("[RankMgr] Rank reward mapping missing or invalid: VirtualItemID=%s Num=%s",
                tostring(RawVirtualItemID), tostring(RawNum)))
        else
            local CallOK, AddedCount = pcall(UGCBackpackSystemV2.AddItemV2, Pawn, BackpackItemID, RequestedNum)
            AddedCount = math.floor(tonumber(AddedCount) or 0)
            AddedCount = math.max(0, math.min(AddedCount, RequestedNum))

            if not CallOK or AddedCount <= 0 then
                bAllSucceeded = false
                print(string.format("[RankMgr] AddItemV2 failed: VirtualItemID=%s BackpackItemID=%s Num=%s",
                    tostring(VirtualItemID), tostring(BackpackItemID), tostring(RequestedNum)))
            else
                local RemoveOK, RemoveResult = pcall(VirtualItemManager.RemoveVirtualItem, VirtualItemManager,
                    PlayerController, VirtualItemID, AddedCount)
                if not RemoveOK or RemoveResult == false then
                    bAllSucceeded = false
                    print(string.format("[RankMgr] RemoveVirtualItem failed after AddItemV2: VirtualItemID=%s Num=%s",
                        tostring(VirtualItemID), tostring(AddedCount)))
                end

                if AddedCount < RequestedNum then
                    bAllSucceeded = false
                    print(string.format("[RankMgr] Rank reward partially added: BackpackItemID=%s Requested=%s Added=%s",
                        tostring(BackpackItemID), tostring(RequestedNum), tostring(AddedCount)))
                else
                    print(string.format("[RankMgr] Rank reward added: BackpackItemID=%s Num=%s",
                        tostring(BackpackItemID), tostring(AddedCount)))
                end
            end
        end
    end

    return bAllSucceeded
end

function RankMgr:UpdateZhanLiRank(ZhanLi)
    local Score = math.floor((tonumber(ZhanLi) or 0) + 0.5)
    if Score <= 0 then
        return false
    end

    if self.LastUploadZhanLi == Score then
        return false
    end

    local PlayerController = GetLocalPlayerController()
    if PlayerController == nil then
        return false
    end

    local UID = GetLocalUID(PlayerController)
    if UID == nil then
        return false
    end

    self.LastUploadZhanLi = Score
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_UpdateRankingListScore", UID,
        self.ZhanLiRankID, Score, 0)
    return true
end

function RankMgr:UpdateRankScore(RankID, Score, bIncremental)
    RankID = tonumber(RankID)
    Score = math.floor((tonumber(Score) or 0) + 0.5)
    if RankID == nil or RankID <= 0 or Score <= 0 then
        return false
    end

    local PlayerController = GetLocalPlayerController()
    if PlayerController == nil then
        return false
    end

    local UID = GetLocalUID(PlayerController)
    if UID == nil then
        return false
    end

    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_UpdateRankingListScore", UID, RankID, Score,
        bIncremental == true and 1 or 0)
    return true
end

function RankMgr:NotifyPurchaseSuccess(ProductID, Price, Num)
    Price = tonumber(Price) or 0
    Num = tonumber(Num) or 1

    local Amount = Price * Num
    if Amount <= 0 then
        return false
    end

    return self:UpdateRankScore(self.WealthRankID, Amount, true)
end

-- 每次成功登顶累加 1 分；榜单周期与重置规则由排行榜表配置负责。
function RankMgr:NotifyTowerTop()
    return self:UpdateRankScore(self.TowerRankID, 1, true)
end

function RankMgr:BeginConsumePurchase(ProductID, ItemID, Price, Num)
    ProductID = tonumber(ProductID)
    ItemID = tonumber(ItemID)
    Price = tonumber(Price) or 0
    Num = tonumber(Num) or 1

    if ProductID == nil or ItemID == nil or Price <= 0 or Num <= 0 then
        self.PendingConsumePurchase = nil
        return false
    end

    self.PendingConsumePurchase = {
        ProductID = ProductID,
        ItemID = ItemID,
        Price = Price,
        Num = Num,
    }
    return true
end

function RankMgr:EnsureConsumePurchaseResultCallback()
    if self.bConsumePurchaseResultBound == true then
        return true
    end
    if UGCCommoditySystem == nil or UGCCommoditySystem.BuyUGCCommodityResultDelegate == nil then
        return false
    end

    UGCCommoditySystem.BuyUGCCommodityResultDelegate:Add(self.OnConsumePurchaseResult, self)
    self.bConsumePurchaseResultBound = true
    return true
end

function RankMgr:OnConsumePurchaseResult(bSucceeded, PlayerKey, CommodityID, Count, UID, ProductID)
    local Pending = self.PendingConsumePurchase
    ProductID = tonumber(ProductID)
    if Pending == nil or ProductID == nil or Pending.ProductID ~= ProductID then
        return
    end

    if bSucceeded == true then
        local Amount = Pending.Price * Pending.Num
        local bUpdated = self:ConfirmConsumePurchase()
        ugcprint("[RankMgr] Consume purchase confirmed: ProductID=" .. tostring(ProductID) ..
            " Amount=" .. tostring(Amount) .. " Updated=" .. tostring(bUpdated))
        return
    end

    self:CancelConsumePurchase()
    ugcprint("[RankMgr] Consume purchase canceled: ProductID=" .. tostring(ProductID))
end

function RankMgr:CancelConsumePurchase()
    self.PendingConsumePurchase = nil
end

function RankMgr:ConfirmConsumePurchase(ItemID)
    local Pending = self.PendingConsumePurchase
    if Pending == nil then
        return false
    end

    ItemID = tonumber(ItemID)
    if ItemID ~= nil and Pending.ItemID ~= ItemID then
        return false
    end

    self.PendingConsumePurchase = nil
    return self:NotifyPurchaseSuccess(Pending.ProductID, Pending.Price, Pending.Num)
end

function RankMgr:TryUploadCurrentZhanLi()
    local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
    if StateMgr == nil or StateMgr.GetRankZhanLi == nil or
        StateMgr.bPlayerDataResetInProgress == true then
        return false
    end

    return self:UpdateZhanLiRank(StateMgr:GetRankZhanLi())
end

function RankMgr:GetZhanLiBonusByRank(Rank)
    Rank = tonumber(Rank) or 0
    if Rank <= 0 then
        return 0
    end

    for _, Config in ipairs(self.BonusByRank) do
        if Rank >= Config.MinRank and Rank <= Config.MaxRank then
            return Config.Percent
        end
    end

    return 0
end

-- 仅在官方排行榜确认返回上期数据后调用；Rank <= 0 表示上期未进入前 50。
function RankMgr:ApplyPreviousZhanLiRank(PlayerController, Rank)
    if PlayerController == nil or PlayerController.HasAuthority == nil or
        PlayerController:HasAuthority() == false then
        return false
    end

    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil and PlayerController.GetCurPlayerState ~= nil then
        PlayerState = PlayerController:GetCurPlayerState()
    end
    if PlayerState == nil or PlayerState.SetRankAttackBonus == nil then
        return false
    end

    Rank = tonumber(Rank) or -1
    local Bonus = self:GetZhanLiBonusByRank(Rank)
    local OldBonus = PlayerState.GetRankAttackBonus ~= nil and PlayerState:GetRankAttackBonus() or
        (tonumber(PlayerState.RankAttackBonus) or 0)
    local bChanged = PlayerState:SetRankAttackBonus(Bonus)
    if bChanged then
        local Pawn = PlayerController.Pawn
        if Pawn == nil and PlayerController.K2_GetPawn ~= nil then
            Pawn = PlayerController:K2_GetPawn()
        end
        if Pawn ~= nil and Pawn.ApplyRankAttackBonusDelta ~= nil then
            Pawn:ApplyRankAttackBonusDelta(OldBonus, Bonus)
        end

        local TitleMgr = UGCGameSystem.UGCRequire("Script.Xiao.TitleMgr")
        if TitleMgr ~= nil and TitleMgr.CheckCombatPowerTitles ~= nil then
            TitleMgr:CheckCombatPowerTitles(PlayerController)
        end
    end
    ugcprint(string.format("[RankMgr] Previous rank confirmed: Rank=%s Bonus=%s", tostring(Rank), tostring(Bonus)))
    return true
end

return RankMgr
