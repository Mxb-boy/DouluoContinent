local RankMgr = {
    ZhanLiRankID = 1,
    LastUploadZhanLi = nil,
    TestBonusIndex = 0,
    TestBonusRanks = {1, 5, 0},
    BonusByRank = {
        {MinRank = 1, MaxRank = 1, Percent = 10},
        {MinRank = 2, MaxRank = 3, Percent = 8},
        {MinRank = 4, MaxRank = 10, Percent = 5},
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

function RankMgr:ApplyZhanLiRankBonusForTest(Rank)
    local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
    if StateMgr == nil or StateMgr.PaiHangTextShow == nil or StateMgr.UI == nil then
        return false
    end

    local Percent = self:GetZhanLiBonusByRank(Rank)
    StateMgr:PaiHangTextShow(Percent)

    if StateMgr.GetFinalZhanLi ~= nil then
        self:UpdateZhanLiRank(StateMgr:GetFinalZhanLi())
    end

    return true
end

function RankMgr:ApplyNextZhanLiRankBonusForTest()
    self.TestBonusIndex = (tonumber(self.TestBonusIndex) or 0) + 1
    if self.TestBonusIndex > #self.TestBonusRanks then
        self.TestBonusIndex = 1
    end

    local Rank = self.TestBonusRanks[self.TestBonusIndex]
    return self:ApplyZhanLiRankBonusForTest(Rank)
end

return RankMgr
