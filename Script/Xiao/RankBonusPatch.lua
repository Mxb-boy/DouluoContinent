local RankBonusPatch = {}

local RankMgr = UGCGameSystem.UGCRequire("Script.Xiao.RankMgr")

local POLL_INTERVAL = 0.5
local MAX_POLL_COUNT = 120
local RE_REQUEST_INTERVAL = 5

local function SafeNumber(Value)
    return tonumber(Value) or 0
end

local function IsValidObject(Object)
    return Object ~= nil and (UE == nil or UE.IsValid == nil or UE.IsValid(Object))
end

local function GetPlayerState(PlayerController)
    if PlayerController == nil then
        return nil
    end
    if PlayerController.PlayerState ~= nil then
        return PlayerController.PlayerState
    end
    if PlayerController.GetCurPlayerState ~= nil then
        return PlayerController:GetCurPlayerState()
    end
    return nil
end

local function GetReliableUID(Component, PlayerController)
    local UID = 0
    if Component ~= nil and Component.GetSelfUID ~= nil then
        UID = SafeNumber(Component:GetSelfUID())
    end
    if UID > 0 then
        return UID
    end

    local PlayerState = GetPlayerState(PlayerController)
    if PlayerState ~= nil then
        UID = SafeNumber(PlayerState.UID)
        if UID > 0 then
            return UID
        end
    end

    if PlayerController ~= nil and PlayerController.GetInt64UID ~= nil then
        UID = SafeNumber(PlayerController:GetInt64UID())
        if UID > 0 then
            return UID
        end
    end

    return 0
end

local function GetRankFromPlayerRankData(PlayerRankData)
    if PlayerRankData == nil then
        return nil
    end
    return tonumber(PlayerRankData.Rank or PlayerRankData.rank or PlayerRankData.rank_no or PlayerRankData.RankNo)
end

local function FindRankInRankList(RankListData, UID)
    if RankListData == nil or UID == nil or UID <= 0 then
        return nil
    end

    for Index, Entry in pairs(RankListData) do
        if SafeNumber(Entry.UID or Entry.uid) == UID then
            return tonumber(Entry.Rank or Entry.rank or Entry.rank_no or Entry.RankNo) or tonumber(Index)
        end
    end

    return nil
end

function RankBonusPatch.Apply(RankingListComponent)
    if RankingListComponent == nil or RankMgr == nil then
        return false
    end

    function RankingListComponent:ResolveRankAttackBonusData(bAllowZero)
        if self.bRankAttackBonusResolved == true then
            return true
        end

        local PlayerController = self:GetOwner()
        local RankingListGlobalActor = self:GetRankingListGlobalActor()
        local UID = GetReliableUID(self, PlayerController)
        if not IsValidObject(PlayerController) or PlayerController:HasAuthority() == false or
            not IsValidObject(RankingListGlobalActor) or UID <= 0 then
            ugcprint(string.format("[RankBonusPatch] Resolve pending: UID=%s GlobalActor=%s",
                tostring(UID), tostring(IsValidObject(RankingListGlobalActor))))
            return false
        end

        local Rank = nil
        local PlayerRankData = RankingListGlobalActor:GetPlayerRankData(UID, RankMgr.ZhanLiRankID,
            RankMgr.PreviousRankingCycle)
        Rank = GetRankFromPlayerRankData(PlayerRankData)

        if Rank == nil or Rank <= 0 then
            local RankListData = RankingListGlobalActor:GetRankListData(RankMgr.ZhanLiRankID,
                RankMgr.PreviousRankingCycle)
            Rank = FindRankInRankList(RankListData, UID)
        end

        if Rank ~= nil and Rank > 0 and Rank <= RankMgr.RankBonusTopCount then
            local bApplied = RankMgr:ApplyPreviousZhanLiRank(PlayerController, Rank)
            self.bRankAttackBonusResolved = bApplied == true
            ugcprint(string.format("[RankBonusPatch] Rank bonus resolved: UID=%s Rank=%s Applied=%s",
                tostring(UID), tostring(Rank), tostring(bApplied)))
            return bApplied == true
        end

        if bAllowZero == true then
            local bApplied = RankMgr:ApplyPreviousZhanLiRank(PlayerController, -1)
            self.bRankAttackBonusResolved = bApplied == true
            ugcprint(string.format("[RankBonusPatch] Rank bonus resolved as zero after timeout: UID=%s Rank=%s",
                tostring(UID), tostring(Rank)))
            return bApplied == true
        end

        ugcprint(string.format("[RankBonusPatch] Rank bonus pending: UID=%s Rank=%s", tostring(UID), tostring(Rank)))
        return false
    end

    function RankingListComponent:StartRankAttackBonusPoll()
        self:StopRankAttackBonusPoll()
        self.RankAttackBonusPollCount = 0
        self.RankAttackBonusReadyTime = nil
        self.LastRankAttackBonusRequestTime = UGCGameSystem.GetServerTimeSec()

        self.RankAttackBonusPollTimer = Timer.InsertTimer(
            POLL_INTERVAL,
            function()
                local RankingListGlobalActor = self:GetRankingListGlobalActor()
                self.RankAttackBonusPollCount = self.RankAttackBonusPollCount + 1
                if not IsValidObject(RankingListGlobalActor) then
                    self:StopRankAttackBonusPoll()
                    return
                end

                local ServerTime = UGCGameSystem.GetServerTimeSec()
                if self.RankAttackBonusPollCount >= MAX_POLL_COUNT then
                    self:ResolveRankAttackBonusData(true)
                    self:StopRankAttackBonusPoll()
                    return
                end

                if RankingListGlobalActor:GetIsRequesting(RankMgr.ZhanLiRankID, RankMgr.PreviousRankingCycle) then
                    self.RankAttackBonusReadyTime = nil
                    return
                end

                if self.RankAttackBonusReadyTime == nil then
                    self.RankAttackBonusReadyTime = ServerTime + RankMgr.RankBonusReadyDelaySeconds
                    return
                end
                if ServerTime < self.RankAttackBonusReadyTime then
                    return
                end

                if self:ResolveRankAttackBonusData(false) then
                    self:StopRankAttackBonusPoll()
                    return
                end

                if self.LastRankAttackBonusRequestTime == nil or
                    ServerTime - self.LastRankAttackBonusRequestTime >= RE_REQUEST_INTERVAL then
                    local PlayerController = self:GetOwner()
                    local UID = GetReliableUID(self, PlayerController)
                    if UID > 0 then
                        RankingListGlobalActor:RequestRankingListData(UID, RankMgr.ZhanLiRankID, 1,
                            RankMgr.RankBonusTopCount, RankMgr.PreviousRankingCycle)
                        self.LastRankAttackBonusRequestTime = ServerTime
                    end
                end

            end,
            true,
            "RankAttackBonusPollTimer",
            1
        )
    end

    function RankingListComponent:RequestRankAttackBonusData()
        if self.bRankAttackBonusRequested == true or RankMgr == nil then
            return false
        end

        local PlayerController = self:GetOwner()
        local RankingListGlobalActor = self:GetRankingListGlobalActor()
        local UID = GetReliableUID(self, PlayerController)
        if not IsValidObject(PlayerController) or PlayerController:HasAuthority() == false or
            not IsValidObject(RankingListGlobalActor) or UID <= 0 then
            ugcprint(string.format("[RankBonusPatch] Request rejected: UID=%s GlobalActor=%s",
                tostring(UID), tostring(IsValidObject(RankingListGlobalActor))))
            return false
        end

        self.bRankAttackBonusRequested = true
        self.bRankAttackBonusResolved = false
        self.LastRankAttackBonusRequestTime = UGCGameSystem.GetServerTimeSec()
        RankingListGlobalActor:RequestRankingListData(UID, RankMgr.ZhanLiRankID, 1, RankMgr.RankBonusTopCount,
            RankMgr.PreviousRankingCycle)
        self:StartRankAttackBonusPoll()
        return true
    end

    return true
end

return RankBonusPatch
