local RankMgr = {
    ZhanLiRankID = 1,
    ConsumeRankID = 2,
    LastUploadZhanLi = nil,
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

    return self:UpdateRankScore(self.ConsumeRankID, Amount, true)
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
    if StateMgr == nil or StateMgr.GetFinalZhanLi == nil then
        return false
    end

    return self:UpdateZhanLiRank(StateMgr:GetFinalZhanLi())
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

return RankMgr
