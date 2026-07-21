---@class UGCGameMode_C:BP_UGCGameBase_C
-- Edit Below--
local UGCGameMode = {};
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")
local PlayerLevelMgr = UGCGameSystem.UGCRequire("Script.Lin.PlayerLevelMgr")

-- Keep safe defaults on the Lua class as some mobile/server lifecycle callbacks may arrive
-- before ReceiveBeginPlay has finished initializing the per-match state.
UGCGameMode.PlayerKeyList = {}
UGCGameMode.OriginalTeamByPlayer = {}
UGCGameMode.Squads = {}
UGCGameMode.MemberSquad = {}
UGCGameMode.PendingInvites = {}
UGCGameMode.CampByTeam = {}
UGCGameMode.BackfillRequestPending = false
UGCGameMode.BackfillRequestedTeamID = nil
UGCGameMode.BackfillPlayerCountAtRequest = 0
UGCGameMode.BackfillLoginSerial = 0
UGCGameMode.BackfillLoginSerialAtRequest = 0
UGCGameMode.BackfillRequestSerial = 0
UGCGameMode.BackfillMatchCallbackSeen = false
UGCGameMode.BackfillMatchedUID = nil
UGCGameMode.BackfillRefreshScheduled = false
--[[--------------------全局引用--------------------------]] --
L_Enum = UGCGameSystem.UGCRequire("Script.Lin.L_Enum")
TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
-- 保存玩家死亡前的背包快照，键为 PlayerKey。
local PlayerBackpackSnapshots = {};
local WingItemIDs = {
    [8310012] = true,
    [8310013] = true,
    [8310014] = true,
    [8310058] = true,
    [8310059] = true,
    [8310010] = true
}
local DisuseItemFunctionNames = {"DisuseItemV2", "UnUseItemV2", "CancelUseItemV2", "StopUseItemV2"}

local function AddV2ItemIfMissing(PlayerPawn, ItemID, Count)
    local CurrentCount = UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID) or 0
    if CurrentCount <= 0 then
        UGCBackpackSystemV2.AddItemV2(PlayerPawn, ItemID, Count)
    end
end

local function SyncPlayerExpToClient(PlayerController)
    local PlayerState = PlayerController and PlayerController.PlayerState
    if PlayerState == nil or PlayerLevelMgr == nil then
        return
    end

    local playerExp = PlayerState:GetPlayerExp()
    local playerLevel = PlayerState:GetPlayerLevel()
    local currentExp = PlayerLevelMgr:GetCurrentLevelExp(playerExp, playerLevel)
    local currentMaxExp = PlayerLevelMgr:GetCurrentLevelMaxExp(playerLevel, PlayerState:GetPlayerMaxExp())
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_RefreshPlayerExp", currentExp, currentMaxExp,
        playerLevel)
end

local function TryDisuseItem(PlayerPawn, ItemDefineID)
    for _, FunctionName in ipairs(DisuseItemFunctionNames) do
        local Func = UGCBackpackSystemV2[FunctionName]
        if Func ~= nil then
            local Success, Result = pcall(Func, PlayerPawn, ItemDefineID)
            if Success and Result ~= false then
                return true
            end
        end
    end

    local BackpackComponent = PlayerPawn.BackpackComponent or PlayerPawn.BackpackComponentV2 or PlayerPawn.BP_BackpackComponentV2
    if BackpackComponent == nil and PlayerPawn.Controller ~= nil then
        BackpackComponent = PlayerPawn.Controller.BackpackComponent or PlayerPawn.Controller.BackpackComponentV2 or
                                PlayerPawn.Controller.BP_BackpackComponentV2
    end
    if BackpackComponent ~= nil then
        for _, FunctionName in ipairs(DisuseItemFunctionNames) do
            local Func = BackpackComponent[FunctionName]
            if Func ~= nil then
                local Success, Result = pcall(Func, BackpackComponent, ItemDefineID)
                if Success and Result ~= false then
                    return true
                end
            end
        end
    end

    return false
end

local function DisuseEquippedWings(PlayerPawn)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetAllItemDefineIDsV2 == nil then
        return
    end

    local AllItemData = UGCBackpackSystemV2.GetAllItemDefineIDsV2(PlayerPawn)
    if AllItemData == nil then
        return
    end

    for _, ItemDefineID in pairs(AllItemData) do
        local ItemID = tonumber(ItemDefineID.TypeSpecificID)
        if WingItemIDs[ItemID] then
            TryDisuseItem(PlayerPawn, ItemDefineID)
        end
    end
end

local function SaveBackpackSnapshot(PlayerKey, PlayerPawn)
    if not PlayerKey or not PlayerPawn then
        return
    end

    local AllItemData = UGCBackpackSystemV2.GetAllItemDefineIDsV2(PlayerPawn)
    local Snapshot = {}

    if AllItemData then
        for _, ItemDefineID in pairs(AllItemData) do
            local ItemID = tonumber(ItemDefineID.TypeSpecificID)
            local Count = tonumber(UGCBackpackSystemV2.GetItemCountByDefineIDV2(PlayerPawn, ItemDefineID)) or 0
            if ItemID and Count > 0 then
                Snapshot[ItemID] = (Snapshot[ItemID] or 0) + Count
            end
        end
    end

    PlayerBackpackSnapshots[PlayerKey] = Snapshot
    ugcprint("[UGCGameMode] Backpack saved, PlayerKey=" .. tostring(PlayerKey))
end

local function RestoreBackpackSnapshot(PlayerKey, PlayerPawn)
    local Snapshot = PlayerBackpackSnapshots[PlayerKey]
    if not Snapshot or not PlayerPawn then
        return
    end

    -- 只补回新背包中缺少的数量，防止引擎已经保留的物品被重复添加。
    for ItemID, SavedCount in pairs(Snapshot) do
        local CurrentCount = UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID) or 0
        local MissingCount = SavedCount - CurrentCount
        if MissingCount > 0 then
            UGCBackpackSystemV2.AddItemV2(PlayerPawn, ItemID, MissingCount)
        end
    end

    PlayerBackpackSnapshots[PlayerKey] = nil
    ugcprint("[UGCGameMode] Backpack restored, PlayerKey=" .. tostring(PlayerKey))
end

function UGCGameMode:ReceiveBeginPlay()
    UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnDefeat, self,
        self.OnPawnDefeat)

    if UGCGameSystem.IsServer() then
        self.PlayerKeyList = {}
        self.OriginalTeamByPlayer = {}
        self.Squads = {}
        self.MemberSquad = {}
        self.PendingInvites = {}
        self.CampByTeam = {}
        self.BackfillRequestPending = false
        self.BackfillRequestedTeamID = nil
        self.BackfillPlayerCountAtRequest = 0
        self.BackfillLoginSerial = 0
        self.BackfillLoginSerialAtRequest = 0
        self.BackfillRequestSerial = 0
        self.BackfillMatchCallbackSeen = false
        self.BackfillMatchedUID = nil
        self.BackfillRefreshScheduled = false
        UGCCampSystem.SetDefaultCampRelation(TeamConfig.CAMP_RELATION.Enemy)
        if TeamConfig.BACKFILL_ENABLED then
            local Delegate = UGCGameSystem.ApplyPlayerJoinSucceededDelegate
            if Delegate ~= nil then
                Delegate:Add(self.OnPlayerJoinSucceeded, self)
            else
                ugcprint("[Backfill] Server WARNING ApplyPlayerJoinSucceededDelegate is nil")
            end
            UGCGameSystem.OpenPlayerJoin()
            ugcprint("[Backfill] Server opened build=" .. tostring(TeamConfig.BUILD_ID))
        end
        ugcprint("[Team] Server begin build=" .. tostring(TeamConfig.BUILD_ID))
    end
end

-- ============================================================
-- 局内动态组队：所有入局玩家先拆分为独立合法 TeamID
-- ============================================================

local function IsSamePlayerKey(KeyA, KeyB)
    return KeyA ~= nil and KeyB ~= nil and tostring(KeyA) == tostring(KeyB)
end

local function ContainsPlayerKey(List, PlayerKey)
    for _, ExistingKey in ipairs(List or {}) do
        if IsSamePlayerKey(ExistingKey, PlayerKey) then
            return true
        end
    end
    return false
end

local function RemovePlayerKey(List, PlayerKey)
    for Index, ExistingKey in ipairs(List or {}) do
        if IsSamePlayerKey(ExistingKey, PlayerKey) then
            table.remove(List, Index)
            return true
        end
    end
    return false
end

function UGCGameMode:GetPlayerKey(PlayerObject)
    if PlayerObject == nil then
        return nil
    end
    if PlayerObject.PlayerKey ~= nil then
        return PlayerObject.PlayerKey
    end
    if UGCGameSystem.GetPlayerKeyByPlayerPawn ~= nil then
        return UGCGameSystem.GetPlayerKeyByPlayerPawn(PlayerObject)
    end
    return nil
end

function UGCGameMode:GetCanonicalPlayerKey(PlayerKey)
    if PlayerKey == nil then
        return nil
    end
    for _, StoredKey in ipairs(self.PlayerKeyList or {}) do
        if IsSamePlayerKey(StoredKey, PlayerKey) then
            return StoredKey
        end
    end
    return nil
end

function UGCGameMode:GetCurrentTeamID(PlayerKey)
    return tonumber(UGCTeamSystem.GetTeamIDByPlayerKey(PlayerKey)) or 0
end

function UGCGameMode:IsTeamIDAssignedToOther(TeamID, PlayerKey)
    TeamID = tonumber(TeamID) or 0
    if TeamID <= 0 then
        return true
    end
    for StoredKey, StoredTeamID in pairs(self.OriginalTeamByPlayer or {}) do
        if not IsSamePlayerKey(StoredKey, PlayerKey) and tonumber(StoredTeamID) == TeamID then
            return true
        end
    end
    return false
end

function UGCGameMode:IsTeamIDUsable(TeamID, PlayerKey, bAllowConfiguredFutureID)
    TeamID = tonumber(TeamID) or 0
    if TeamID <= 0 or TeamID > TeamConfig.MAX_MATCH_PLAYERS or
        self:IsTeamIDAssignedToOther(TeamID, PlayerKey) then
        return false
    end
    if UGCTeamSystem.IsTeamIDValid ~= nil then
        local Success, Result = pcall(UGCTeamSystem.IsTeamIDValid, TeamID)
        if Success and Result == false and not bAllowConfiguredFutureID then
            return false
        end
    end
    return true
end

function UGCGameMode:GetUnusedTeamIDCandidates(PlayerKey)
    local Candidates = {}
    for TeamID = 1, TeamConfig.MAX_MATCH_PLAYERS do
        -- IsTeamIDValid may temporarily return false for configured teams that have
        -- not been instantiated yet, especially during mobile login.
        if self:IsTeamIDUsable(TeamID, PlayerKey, true) then
            table.insert(Candidates, TeamID)
        end
    end
    return Candidates
end

function UGCGameMode:FindUnusedTeamID(PlayerKey)
    return self:GetUnusedTeamIDCandidates(PlayerKey)[1]
end

-- 局内补人使用滚动单名额，避免匹配池只有一人时无法满足批量申请。
function UGCGameMode:FindBackfillTeamID()
    for TeamID = 1, TeamConfig.MAX_MATCH_PLAYERS do
        if self:IsTeamIDUsable(TeamID, nil, true) then
            local Success, Result = pcall(function()
                return UGCTeamSystem.IsTeamIDValid(TeamID)
            end)
            ugcprint("[Backfill] Server candidate team=" .. tostring(TeamID) .. " validCall=" ..
                         tostring(Success) .. " validResult=" .. tostring(Result) .. " configuredMax=" ..
                         tostring(TeamConfig.MAX_MATCH_PLAYERS))
            return TeamID
        end
    end
    return nil
end

function UGCGameMode:ClearBackfillRequest(Reason)
    ugcprint("[Backfill] Server clear request reason=" .. tostring(Reason) .. " team=" ..
                 tostring(self.BackfillRequestedTeamID) .. " requestSerial=" ..
                 tostring(self.BackfillRequestSerial) .. " loginSerial=" .. tostring(self.BackfillLoginSerial) ..
                 " requestLoginSerial=" .. tostring(self.BackfillLoginSerialAtRequest) .. " matchedUID=" ..
                 tostring(self.BackfillMatchedUID) .. " online=" .. tostring(#self.PlayerKeyList))
    self.BackfillRequestPending = false
    self.BackfillRequestedTeamID = nil
    self.BackfillPlayerCountAtRequest = #self.PlayerKeyList
    self.BackfillLoginSerialAtRequest = self.BackfillLoginSerial
    self.BackfillMatchCallbackSeen = false
    self.BackfillMatchedUID = nil
end

function UGCGameMode:ScheduleBackfillRefresh(Reason, Delay)
    if not TeamConfig.BACKFILL_ENABLED or not UGCGameSystem.IsServer() or self.BackfillRefreshScheduled then
        return
    end
    self.BackfillRefreshScheduled = true
    local RefreshDelay = tonumber(Delay) or TeamConfig.BACKFILL_REFRESH_DELAY
    UGCTimerUtility.CreateLuaTimer(RefreshDelay, function()
        self.BackfillRefreshScheduled = false
        self:TryApplyRollingBackfill(Reason)
    end, false)
end

function UGCGameMode:TryApplyRollingBackfill(Reason)
    if not TeamConfig.BACKFILL_ENABLED or not UGCGameSystem.IsServer() then
        return false
    end
    if self.BackfillRequestPending then
        ugcprint("[Backfill] Server keep pending reason=" .. tostring(Reason) .. " team=" ..
                     tostring(self.BackfillRequestedTeamID) .. " online=" .. tostring(#self.PlayerKeyList))
        return false
    end
    if #self.PlayerKeyList >= TeamConfig.MAX_MATCH_PLAYERS then
        ugcprint("[Backfill] Server full, no request online=" .. tostring(#self.PlayerKeyList))
        return false
    end

    local TeamID = self:FindBackfillTeamID()
    if TeamID == nil then
        ugcprint("[Backfill] Server no unused TeamID online=" .. tostring(#self.PlayerKeyList))
        return false
    end

    self.BackfillRequestPending = true
    self.BackfillRequestedTeamID = TeamID
    self.BackfillPlayerCountAtRequest = #self.PlayerKeyList
    self.BackfillLoginSerialAtRequest = self.BackfillLoginSerial
    self.BackfillRequestSerial = (tonumber(self.BackfillRequestSerial) or 0) + 1
    self.BackfillMatchCallbackSeen = false
    self.BackfillMatchedUID = nil
    local RequestCount = 1
    if tonumber(TeamConfig.BACKFILL_REQUEST_COUNT) ~= 1 then
        ugcprint("[Backfill] Server WARNING request count forced to 1, configured=" ..
                     tostring(TeamConfig.BACKFILL_REQUEST_COUNT))
    end
    local Success, Result = pcall(function()
        return UGCGameSystem.ApplyPlayerJoinLimitCount({
            [TeamID] = RequestCount
        })
    end)
    local Accepted = Success and Result ~= false
    ugcprint("[Backfill] Server apply build=" .. tostring(TeamConfig.BUILD_ID) .. " reason=" .. tostring(Reason) ..
                 " team=" .. tostring(TeamID) .. " count=" .. tostring(RequestCount) .. " requestSerial=" ..
                 tostring(self.BackfillRequestSerial) .. " loginSerial=" .. tostring(self.BackfillLoginSerial) ..
                 " online=" .. tostring(#self.PlayerKeyList) .. " result=" .. tostring(Result) .. " resultType=" ..
                 type(Result) .. " accepted=" .. tostring(Accepted))

    if not Accepted then
        self:ClearBackfillRequest("apply-failed")
        self:ScheduleBackfillRefresh("retry", TeamConfig.BACKFILL_RETRY_DELAY)
        return false
    end
    return true
end

function UGCGameMode:CompleteBackfillRequestIfPlayerJoined(Reason)
    if not self.BackfillRequestPending then
        return false
    end
    local LoginSerial = tonumber(self.BackfillLoginSerial) or 0
    local RequestLoginSerial = tonumber(self.BackfillLoginSerialAtRequest) or 0
    local bLoginSeen = LoginSerial > RequestLoginSerial
    if not self.BackfillMatchCallbackSeen or not bLoginSeen then
        ugcprint("[Backfill] Server wait completion reason=" .. tostring(Reason) .. " requestSerial=" ..
                     tostring(self.BackfillRequestSerial) .. " callbackSeen=" ..
                     tostring(self.BackfillMatchCallbackSeen) .. " loginSeen=" .. tostring(bLoginSeen) ..
                     " loginSerial=" .. tostring(LoginSerial) .. " requestLoginSerial=" ..
                     tostring(RequestLoginSerial) .. " online=" .. tostring(#self.PlayerKeyList))
        return false
    end
    self:ClearBackfillRequest(Reason)
    self:ScheduleBackfillRefresh("next-slot")
    return true
end

function UGCGameMode:OnPlayerJoinSucceeded(UID, RemainingPlayerCountToJoin)
    if not UGCGameSystem.IsServer() then
        return
    end
    if not self.BackfillRequestPending then
        ugcprint("[Backfill] Server orphan matched callback uid=" .. tostring(UID) .. " remaining=" ..
                     tostring(RemainingPlayerCountToJoin) .. " requestSerial=" ..
                     tostring(self.BackfillRequestSerial) .. " online=" .. tostring(#self.PlayerKeyList))
        return
    end
    self.BackfillMatchCallbackSeen = true
    self.BackfillMatchedUID = UID
    ugcprint("[Backfill] Server matched uid=" .. tostring(UID) .. " remaining=" ..
                 tostring(RemainingPlayerCountToJoin) .. " team=" .. tostring(self.BackfillRequestedTeamID) ..
                 " requestSerial=" .. tostring(self.BackfillRequestSerial) .. " loginSerial=" ..
                 tostring(self.BackfillLoginSerial) .. " requestLoginSerial=" ..
                 tostring(self.BackfillLoginSerialAtRequest) .. " online=" .. tostring(#self.PlayerKeyList))
    self:CompleteBackfillRequestIfPlayerJoined("match-callback")
end

function UGCGameMode:ChangePlayerTeamAndVerify(PlayerKey, TeamID, Reason)
    TeamID = tonumber(TeamID) or 0
    if PlayerKey == nil or TeamID <= 0 then
        return false
    end
    local Before = self:GetCurrentTeamID(PlayerKey)
    if Before ~= TeamID then
        UGCTeamSystem.ChangePlayerTeamID(PlayerKey, TeamID)
    end
    local After = self:GetCurrentTeamID(PlayerKey)
    local bSuccess = After == TeamID
    ugcprint("[Team] Server change team reason=" .. tostring(Reason) .. " player=" .. tostring(PlayerKey) ..
                 " before=" .. tostring(Before) .. " target=" .. tostring(TeamID) .. " after=" .. tostring(After) ..
                 " success=" .. tostring(bSuccess))
    return bSuccess
end

function UGCGameMode:EnsureIndependentOriginalTeam(PlayerKey)
    local CurrentTeamID = self:GetCurrentTeamID(PlayerKey)
    -- The platform has already assigned a valid initial TeamID in most login flows.
    -- On mobile, IsTeamIDValid can temporarily return false while team state is settling;
    -- only reassign when the ID is missing or actually collides with another player.
    local bNeedsReassign = CurrentTeamID <= 0 or CurrentTeamID > TeamConfig.MAX_MATCH_PLAYERS or
                               self:IsTeamIDAssignedToOther(CurrentTeamID, PlayerKey)
    if bNeedsReassign then
        local AssignedTeamID = nil
        for _, NewTeamID in ipairs(self:GetUnusedTeamIDCandidates(PlayerKey)) do
            local ValidCall = false
            local ValidResult = nil
            if UGCTeamSystem.IsTeamIDValid ~= nil then
                ValidCall, ValidResult = pcall(UGCTeamSystem.IsTeamIDValid, NewTeamID)
            end
            ugcprint("[Team] Server independent candidate player=" .. tostring(PlayerKey) .. " current=" ..
                         tostring(CurrentTeamID) .. " target=" .. tostring(NewTeamID) .. " validCall=" ..
                         tostring(ValidCall) .. " validResult=" .. tostring(ValidResult))
            if self:ChangePlayerTeamAndVerify(PlayerKey, NewTeamID, "login-independent") then
                AssignedTeamID = NewTeamID
                break
            end
        end
        if AssignedTeamID == nil then
            ugcprint("[Team] Server ERROR no independent TeamID player=" .. tostring(PlayerKey) .. " current=" ..
                         tostring(CurrentTeamID))
            return nil
        end
        CurrentTeamID = AssignedTeamID
    end
    return CurrentTeamID
end

function UGCGameMode:EnsureCampForTeam(TeamID)
    TeamID = tonumber(TeamID)
    if TeamID == nil or TeamID <= 0 then
        return nil
    end
    if self.CampByTeam[TeamID] ~= nil then
        return self.CampByTeam[TeamID]
    end

    local CampID = UGCCampSystem.AddCamp("DynamicTeam_" .. tostring(TeamID))
    if CampID == nil or CampID < 0 then
        ugcprint("[Team] Server create camp failed team=" .. tostring(TeamID))
        return nil
    end

    for _, OtherCampID in pairs(self.CampByTeam) do
        if OtherCampID ~= CampID then
            UGCCampSystem.SetCampRelation(CampID, OtherCampID, TeamConfig.CAMP_RELATION.Enemy)
            UGCCampSystem.SetCampRelation(OtherCampID, CampID, TeamConfig.CAMP_RELATION.Enemy)
        end
    end
    self.CampByTeam[TeamID] = CampID
    local bMapped = UGCCampSystem.SetCampForTeam(TeamID, CampID)
    UGCCampSystem.SetCampRelation(CampID, CampID, TeamConfig.CAMP_RELATION.Same)
    ugcprint("[Team] Server map team=" .. tostring(TeamID) .. " camp=" .. tostring(CampID) .. " success=" ..
                 tostring(bMapped))
    return CampID
end

function UGCGameMode:GetSquadForMember(PlayerKey)
    local CanonicalKey = self:GetCanonicalPlayerKey(PlayerKey) or PlayerKey
    local TeamID = CanonicalKey and self.MemberSquad[CanonicalKey] or nil
    return TeamID and self.Squads[TeamID] or nil, TeamID, CanonicalKey
end

function UGCGameMode:GetActiveSquadCount()
    local Count = 0
    for _, Squad in pairs(self.Squads or {}) do
        if Squad ~= nil and Squad.Members ~= nil and #Squad.Members >= 2 then
            Count = Count + 1
        end
    end
    return Count
end

function UGCGameMode:ArePlayersInSameSquad(PlayerKeyA, PlayerKeyB)
    if PlayerKeyA == nil or PlayerKeyB == nil or IsSamePlayerKey(PlayerKeyA, PlayerKeyB) then
        return false
    end
    local CanonicalA = self:GetCanonicalPlayerKey(PlayerKeyA) or PlayerKeyA
    local CanonicalB = self:GetCanonicalPlayerKey(PlayerKeyB) or PlayerKeyB
    local SquadIDA = self.MemberSquad[CanonicalA]
    local SquadIDB = self.MemberSquad[CanonicalB]
    return SquadIDA ~= nil and SquadIDA == SquadIDB
end

function UGCGameMode:BuildTeamRoster()
    local Roster = {}
    for _, PlayerKey in ipairs(self.PlayerKeyList or {}) do
        local PlayerState = UGCGameSystem.GetPlayerStateByPlayerKey(PlayerKey)
        local PlayerController = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
        local PlayerPawn = PlayerController and PlayerController.Pawn or nil
        local AttackPower = PlayerPawn and tonumber(UGCAttributeSystem.GetGameAttributeValue(PlayerPawn, "AttackPower")) or 0
        local MaxHealth = PlayerPawn and tonumber(UGCPawnAttrSystem.GetHealthMax(PlayerPawn)) or 0
        if PlayerPawn == nil and PlayerState ~= nil then
            AttackPower = PlayerState.GetBaseAttack ~= nil and tonumber(PlayerState:GetBaseAttack()) or 0
            MaxHealth = PlayerState.GetBaseMaxHp ~= nil and tonumber(PlayerState:GetBaseMaxHp()) or 0
        end
        local CombatPower = math.max(0, math.floor(AttackPower + MaxHealth + 0.5))
        local Squad, SquadID = self:GetSquadForMember(PlayerKey)
        table.insert(Roster, {
            PlayerKey = PlayerKey,
            PlayerName = PlayerState and (PlayerState.PlayerName or PlayerState.RealPlayerName) or tostring(PlayerKey),
            CombatPower = CombatPower,
            TeamID = self:GetCurrentTeamID(PlayerKey),
            SquadID = SquadID or 0,
            LeaderKey = Squad and Squad.LeaderKey or 0,
            IsLeader = Squad ~= nil and IsSamePlayerKey(Squad.LeaderKey, PlayerKey),
            IsGrouped = Squad ~= nil
        })
    end
    return Roster
end

function UGCGameMode:SyncTeamUI()
    local GameState = self.GameState or UGCGameSystem.GetGameState()
    if GameState == nil then
        return
    end
    local Roster = self:BuildTeamRoster()
    ugcprint("[Team] Server sync roster count=" .. tostring(#Roster))
    if GameState.UpdateTeamRoster ~= nil then
        GameState:UpdateTeamRoster(Roster)
    end
    if GameState.UpdateNotifications ~= nil then
        GameState:UpdateNotifications(self.PendingInvites)
    end
end

function UGCGameMode:RegisterTeamPlayer(PlayerController)
    local PlayerKey = PlayerController and PlayerController.PlayerKey
    if PlayerKey == nil then
        return false
    end
    if ContainsPlayerKey(self.PlayerKeyList, PlayerKey) then
        return true
    end

    local IndependentTeamID = self:EnsureIndependentOriginalTeam(PlayerKey)
    if IndependentTeamID == nil then
        return false
    end

    self.OriginalTeamByPlayer[PlayerKey] = IndependentTeamID
    table.insert(self.PlayerKeyList, PlayerKey)
    self.BackfillLoginSerial = (tonumber(self.BackfillLoginSerial) or 0) + 1
    self:EnsureCampForTeam(IndependentTeamID)
    ugcprint("[Team] Server player login build=" .. tostring(TeamConfig.BUILD_ID) .. " key=" ..
                 tostring(PlayerKey) .. " keyType=" .. type(PlayerKey) .. " originalTeam=" ..
                 tostring(IndependentTeamID) .. " loginSerial=" .. tostring(self.BackfillLoginSerial) ..
                 " pending=" .. tostring(self.BackfillRequestPending) .. " requestSerial=" ..
                 tostring(self.BackfillRequestSerial))
    self:SyncTeamUI()
    if not self:CompleteBackfillRequestIfPlayerJoined("player-login") then
        self:ScheduleBackfillRefresh("player-login")
    end
    return true
end

function UGCGameMode:ScheduleTeamPlayerRegistration(PlayerController)
    local RetryCount = 0
    local MaxRetries = 15
    local function TryRegister()
        if self:RegisterTeamPlayer(PlayerController) then
            return
        end
        RetryCount = RetryCount + 1
        if RetryCount <= MaxRetries then
            local PlayerKey = PlayerController and PlayerController.PlayerKey
            ugcprint("[Team] Server player registration retry build=" .. tostring(TeamConfig.BUILD_ID) .. " player=" ..
                         tostring(PlayerKey) .. " attempt=" .. tostring(RetryCount) .. "/" .. tostring(MaxRetries) ..
                         " currentTeam=" .. tostring(PlayerKey and self:GetCurrentTeamID(PlayerKey) or 0))
            UGCTimerUtility.CreateLuaTimer(1, TryRegister, false)
        else
            ugcprint("[Team] Server player registration failed after retries build=" .. tostring(TeamConfig.BUILD_ID) ..
                         " player=" .. tostring(PlayerController and PlayerController.PlayerKey))
        end
    end
    UGCTimerUtility.CreateLuaTimer(0.5, TryRegister, false)
end

-- 玩家登录时: 先加载跨对局存档, 再发初始武器（Pawn可能还没好，等1秒）
-- 若 Pawn 在 1 秒后仍未就绪，则重试（最多 10 次），避免 LoadFromArchive 被整体跳过导致存档丢失
function UGCGameMode:UGC_PlayerLoginEvent(PlayerController)
    if not UGCGameSystem.IsServer() then
        return
    end
    local PC = PlayerController
    local RetryCount = 0
    local MaxRetries = 10
    local function OnLoginDeferred()
        if PC.Pawn then
            -- 1. 加载跨对局存档（注入 UID → 恢复所有注册字段）
            local PlayerState = PC.PlayerState
            if PlayerState and PlayerState.LoadFromArchive then
                local UID = UGCPawnAttrSystem.GetPlayerUID(PC.Pawn)
                PlayerState:LoadFromArchive(tonumber(UID))
                SyncPlayerExpToClient(PC)
                -- PlayerState 的复制可能晚于客户端主界面创建。存档恢复后显式同步一次
                -- 永久解锁状态，避免 Button_5 / Button_2 按默认值 0 再次显示。
                if PlayerState.GetAutoPickButtonHidden ~= nil and PlayerState:GetAutoPickButtonHidden() == true then
                    UnrealNetwork.CallUnrealRPC(PC, PC, "Client_SetAutoFeatureButtonHidden", "AutoPick")
                end
                if PlayerState.GetAutoAttackButtonHidden ~= nil and PlayerState:GetAutoAttackButtonHidden() == true then
                    UnrealNetwork.CallUnrealRPC(PC, PC, "Client_SetAutoFeatureButtonHidden", "AutoAttack")
                end
                if PlayerState.GetFeiButton0Hidden ~= nil and PlayerState:GetFeiButton0Hidden() == true then
                    UnrealNetwork.CallUnrealRPC(PC, PC, "Client_SetFeiButton0Hidden", 1)
                end
                if PlayerState.GetYXWD_InvincibleBuff ~= nil and PlayerState:GetYXWD_InvincibleBuff() == true then
                    if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
                        PlayerState:SetYXWD_InvincibleBuffActive(true)
                    else
                        PlayerState.YXWD_InvincibleBuffActive = true
                    end
                    UnrealNetwork.CallUnrealRPC(PC, PC, "Client_YXWDInvincibleBuffChanged", 1, -2)
                end
                -- 恢复上次存档的血量
                if PC.Pawn.RefreshStateMgrProperty ~= nil then
                    PC.Pawn:RefreshStateMgrProperty(false)
                end
                if PlayerState.RestoreHP then
                    PlayerState:RestoreHP(PC.Pawn)
                end
                if PC.Pawn.RefreshSoulMesh ~= nil and PlayerState.GetHunHuan ~= nil then
                    PC.Pawn:RefreshSoulMesh(PlayerState:GetHunHuan(), true)
                end
                if PC.SyncSavedTitleState ~= nil then
                    PC:SyncSavedTitleState()
                end
            end

            -- 2. 发初始武器
            for _, ItemID in ipairs(WeaponLevelConfig.GetAllBaseItemIDs()) do
                AddV2ItemIfMissing(PC.Pawn, ItemID, 1)
            end
            if PC.SyncWeaponBackpackNames ~= nil then
                PC:SyncWeaponBackpackNames()
            end
            if HTCLv2ItemID ~= nil then
                AddV2ItemIfMissing(PC.Pawn, HTCLv2ItemID, 1)
            end
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310064, 10)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310047, 1)
            -- 锻造材料
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310035, 80000)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310036, 1000)
            -- --境界升级材料先发背包
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310037, 10)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310038, 10)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310039, 10)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310040, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310041, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310042, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310043, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310044, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310045, 99)
            -- --魂环也先发
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310048, 10)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310049, 10)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310051, 10)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310053, 10)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310054, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310055, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310056, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310057, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310052, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310050, 99)

            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310008, 1000)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310007, 1)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310009, 1)
            DisuseEquippedWings(PC.Pawn)

            if PC.Pawn.RefreshWeaponAttackBonus ~= nil then
                PC.Pawn:RefreshWeaponAttackBonus(true)
                if PC.Pawn.ForceRefreshPropertySnapshot ~= nil then
                    PC.Pawn:ForceRefreshPropertySnapshot()
                end
            end

        elseif RetryCount < MaxRetries then
            -- Pawn 尚未就绪，1 秒后重试
            RetryCount = RetryCount + 1
            UGCTimerUtility.CreateLuaTimer(1, OnLoginDeferred, false)
        else
            print("[UGCGameMode] UGC_PlayerLoginEvent: Pawn not ready after " .. MaxRetries .. " retries, giving up.")
        end
    end
    UGCTimerUtility.CreateLuaTimer(1, OnLoginDeferred, false)
    self:ScheduleTeamPlayerRegistration(PC)
end

-- 此事件提供死亡前的旧 Pawn，必须在这里读取背包和血量。
function UGCGameMode:ResolveOnlinePlayerKey(PlayerKey)
    return self:GetCanonicalPlayerKey(PlayerKey)
end

function UGCGameMode:RestoreOriginalTeam(PlayerKey)
    local CanonicalKey = self:GetCanonicalPlayerKey(PlayerKey) or PlayerKey
    local OriginalTeamID = CanonicalKey and tonumber(self.OriginalTeamByPlayer[CanonicalKey]) or 0
    if OriginalTeamID <= 0 then
        ugcprint("[Team] Server restore rejected: original TeamID missing player=" .. tostring(PlayerKey))
        return false
    end
    self:EnsureCampForTeam(OriginalTeamID)
    local bRestored = self:ChangePlayerTeamAndVerify(CanonicalKey, OriginalTeamID, "restore-original")
    if bRestored then
        return true
    else
        ugcprint("[Team] Server restore original team failed key=" .. tostring(CanonicalKey))
    end
    return false
end

function UGCGameMode:CreateSquad(LeaderKey)
    LeaderKey = self:GetCanonicalPlayerKey(LeaderKey)
    if LeaderKey == nil then
        return nil
    end
    if self.MemberSquad[LeaderKey] ~= nil or self:GetActiveSquadCount() >= TeamConfig.MAX_ACTIVE_TEAMS then
        return nil
    end
    local TeamID = tonumber(self.OriginalTeamByPlayer[LeaderKey])
    if TeamID == nil or TeamID <= 0 or self.Squads[TeamID] ~= nil then
        return nil
    end
    local Squad = {TeamID = TeamID, LeaderKey = LeaderKey, Members = {LeaderKey}}
    self.Squads[TeamID] = Squad
    self.MemberSquad[LeaderKey] = TeamID
    self:EnsureCampForTeam(TeamID)
    ugcprint("[Team] Server create squad leader=" .. tostring(LeaderKey) .. " team=" .. tostring(TeamID))
    return Squad
end

function UGCGameMode:AddMemberToSquad(Squad, PlayerKey)
    PlayerKey = self:GetCanonicalPlayerKey(PlayerKey)
    if Squad == nil or PlayerKey == nil or self.MemberSquad[PlayerKey] ~= nil or
        #Squad.Members >= TeamConfig.MAX_PLAYERS_PER_TEAM then
        return false
    end
    if not self:ChangePlayerTeamAndVerify(PlayerKey, Squad.TeamID, "join-squad") then
        ugcprint("[Team] Server join team change failed key=" .. tostring(PlayerKey))
        return false
    end
    table.insert(Squad.Members, PlayerKey)
    self.MemberSquad[PlayerKey] = Squad.TeamID
    self:EnsureCampForTeam(Squad.TeamID)
    return true
end

function UGCGameMode:RemoveMemberFromSquad(Squad, PlayerKey, bRestoreTeam)
    PlayerKey = self:GetCanonicalPlayerKey(PlayerKey)
    if Squad == nil or PlayerKey == nil or IsSamePlayerKey(Squad.LeaderKey, PlayerKey) or
        self.MemberSquad[PlayerKey] ~= Squad.TeamID or not ContainsPlayerKey(Squad.Members, PlayerKey) then
        return false
    end
    if bRestoreTeam ~= false and not self:RestoreOriginalTeam(PlayerKey) then
        return false
    end
    RemovePlayerKey(Squad.Members, PlayerKey)
    self.MemberSquad[PlayerKey] = nil
    ugcprint("[Team] Server remove member player=" .. tostring(PlayerKey) .. " squad=" .. tostring(Squad.TeamID))
    return true
end

function UGCGameMode:ClearInvitesFor(PlayerKey)
    for Index = #(self.PendingInvites or {}), 1, -1 do
        local Invite = self.PendingInvites[Index]
        if IsSamePlayerKey(Invite.FromKey, PlayerKey) or IsSamePlayerKey(Invite.TargetKey, PlayerKey) then
            table.remove(self.PendingInvites, Index)
        end
    end
end

function UGCGameMode:RemoveInvite(FromKey, TargetKey)
    for Index = #(self.PendingInvites or {}), 1, -1 do
        local Invite = self.PendingInvites[Index]
        if IsSamePlayerKey(Invite.FromKey, FromKey) and IsSamePlayerKey(Invite.TargetKey, TargetKey) then
            table.remove(self.PendingInvites, Index)
            return true
        end
    end
    return false
end

function UGCGameMode:DisbandSquad(Squad, DisconnectedPlayerKey)
    if Squad == nil then
        return false
    end
    local RestoredMembers = {}
    for _, MemberKey in ipairs(Squad.Members or {}) do
        if not IsSamePlayerKey(MemberKey, DisconnectedPlayerKey) and ContainsPlayerKey(self.PlayerKeyList, MemberKey) then
            if not self:RestoreOriginalTeam(MemberKey) then
                for _, RestoredKey in ipairs(RestoredMembers) do
                    self:ChangePlayerTeamAndVerify(RestoredKey, Squad.TeamID, "disband-rollback")
                end
                ugcprint("[Team] Server disband aborted: restore failed player=" .. tostring(MemberKey))
                return false
            end
            table.insert(RestoredMembers, MemberKey)
        end
    end
    for _, MemberKey in ipairs(Squad.Members or {}) do
        self.MemberSquad[MemberKey] = nil
        self:ClearInvitesFor(MemberKey)
    end
    self.Squads[Squad.TeamID] = nil
    ugcprint("[Team] Server disband success team=" .. tostring(Squad.TeamID) .. " leader=" ..
                 tostring(Squad.LeaderKey))
    return true
end

function UGCGameMode:HandleInviteRequest(InviterObject, TargetKey)
    local InviterKey = self:GetCanonicalPlayerKey(self:GetPlayerKey(InviterObject))
    TargetKey = self:GetCanonicalPlayerKey(TargetKey)
    ugcprint("[Team] Server handle invite inviter=" .. tostring(InviterKey) .. " target=" .. tostring(TargetKey))
    if InviterKey == nil or TargetKey == nil or IsSamePlayerKey(InviterKey, TargetKey) or
        self.MemberSquad[TargetKey] ~= nil then
        ugcprint("[Team] Server invite rejected: invalid player or target already grouped")
        return false
    end

    local InviterSquad = self:GetSquadForMember(InviterKey)
    if InviterSquad ~= nil then
        if not IsSamePlayerKey(InviterSquad.LeaderKey, InviterKey) or
            #InviterSquad.Members >= TeamConfig.MAX_PLAYERS_PER_TEAM then
            return false
        end
    elseif self:GetActiveSquadCount() >= TeamConfig.MAX_ACTIVE_TEAMS then
        return false
    end

    for _, Invite in ipairs(self.PendingInvites) do
        if IsSamePlayerKey(Invite.FromKey, InviterKey) and IsSamePlayerKey(Invite.TargetKey, TargetKey) then
            return true
        end
    end
    table.insert(self.PendingInvites, {
        Type = TeamConfig.INVITE_TYPE,
        FromKey = InviterKey,
        TargetKey = TargetKey,
        TeamID = InviterSquad and InviterSquad.TeamID or self.OriginalTeamByPlayer[InviterKey]
    })
    ugcprint("[Team] Server invite from=" .. tostring(InviterKey) .. " target=" .. tostring(TargetKey))
    self:SyncTeamUI()
    return true
end

function UGCGameMode:HandleInviteResponse(ResponderObject, InviterKey, bAccept)
    local TargetKey = self:GetCanonicalPlayerKey(self:GetPlayerKey(ResponderObject))
    InviterKey = self:GetCanonicalPlayerKey(InviterKey)
    if TargetKey == nil or InviterKey == nil or not self:RemoveInvite(InviterKey, TargetKey) then
        ugcprint("[Team] Server invite response rejected responder=" .. tostring(TargetKey) .. " inviter=" ..
                     tostring(InviterKey))
        return false
    end
    if bAccept ~= true then
        self:SyncTeamUI()
        return true
    end
    if self.MemberSquad[TargetKey] ~= nil then
        self:SyncTeamUI()
        return false
    end

    local Squad = self:GetSquadForMember(InviterKey)
    if Squad ~= nil then
        if not IsSamePlayerKey(Squad.LeaderKey, InviterKey) or #Squad.Members >= TeamConfig.MAX_PLAYERS_PER_TEAM then
            self:SyncTeamUI()
            return false
        end
    else
        Squad = self:CreateSquad(InviterKey)
        if Squad == nil then
            self:SyncTeamUI()
            return false
        end
    end

    if not self:AddMemberToSquad(Squad, TargetKey) then
        if #Squad.Members == 1 then
            self.MemberSquad[Squad.LeaderKey] = nil
            self.Squads[Squad.TeamID] = nil
        end
        self:SyncTeamUI()
        return false
    end
    self:ClearInvitesFor(TargetKey)
    ugcprint("[Team] Server joined key=" .. tostring(TargetKey) .. " team=" .. tostring(Squad.TeamID))
    self:SyncTeamUI()
    return true
end

function UGCGameMode:HandleLeaveTeamRequest(PlayerObject)
    local PlayerKey = self:GetCanonicalPlayerKey(self:GetPlayerKey(PlayerObject))
    local Squad = PlayerKey and self:GetSquadForMember(PlayerKey) or nil
    if Squad == nil or IsSamePlayerKey(Squad.LeaderKey, PlayerKey) then
        ugcprint("[Team] Server leave result player=" .. tostring(PlayerKey) .. " success=false")
        return false
    end
    local bSuccess = self:RemoveMemberFromSquad(Squad, PlayerKey, true)
    if not bSuccess then
        ugcprint("[Team] Server leave result player=" .. tostring(PlayerKey) .. " success=false")
        self:SyncTeamUI()
        return false
    end
    self:ClearInvitesFor(PlayerKey)
    ugcprint("[Team] Server leave result player=" .. tostring(PlayerKey) .. " success=true")
    self:SyncTeamUI()
    return true
end

function UGCGameMode:HandleKickRequest(LeaderObject, TargetKey)
    local LeaderKey = self:GetCanonicalPlayerKey(self:GetPlayerKey(LeaderObject))
    TargetKey = self:GetCanonicalPlayerKey(TargetKey)
    local Squad = LeaderKey and self:GetSquadForMember(LeaderKey) or nil
    if Squad == nil or TargetKey == nil or not IsSamePlayerKey(Squad.LeaderKey, LeaderKey) or
        IsSamePlayerKey(LeaderKey, TargetKey) or self.MemberSquad[TargetKey] ~= Squad.TeamID then
        return false
    end
    local bSuccess = self:RemoveMemberFromSquad(Squad, TargetKey, true)
    if not bSuccess then
        ugcprint("[Team] Server kick result leader=" .. tostring(LeaderKey) .. " target=" .. tostring(TargetKey) ..
                     " success=false")
        self:SyncTeamUI()
        return false
    end
    self:ClearInvitesFor(TargetKey)
    ugcprint("[Team] Server kick result leader=" .. tostring(LeaderKey) .. " target=" .. tostring(TargetKey) ..
                 " success=true")
    self:SyncTeamUI()
    return true
end

function UGCGameMode:HandleDisbandRequest(LeaderObject)
    local LeaderKey = self:GetCanonicalPlayerKey(self:GetPlayerKey(LeaderObject))
    local Squad = LeaderKey and self:GetSquadForMember(LeaderKey) or nil
    if Squad == nil or not IsSamePlayerKey(Squad.LeaderKey, LeaderKey) then
        ugcprint("[Team] Server handle disband leader=" .. tostring(LeaderKey) .. " success=false")
        return false
    end
    local bSuccess = self:DisbandSquad(Squad)
    ugcprint("[Team] Server handle disband leader=" .. tostring(LeaderKey) .. " team=" ..
                 tostring(Squad.TeamID) .. " success=" .. tostring(bSuccess))
    self:SyncTeamUI()
    return bSuccess
end

function UGCGameMode:UGC_PlayerExitEvent(PlayerController)
    if not UGCGameSystem.IsServer() then
        return
    end
    local PlayerKey = self:GetCanonicalPlayerKey(self:GetPlayerKey(PlayerController))
    if PlayerKey == nil then
        return
    end
    local Squad = self:GetSquadForMember(PlayerKey)
    if Squad ~= nil then
        if IsSamePlayerKey(Squad.LeaderKey, PlayerKey) then
            self:DisbandSquad(Squad, PlayerKey)
        else
            self:RemoveMemberFromSquad(Squad, PlayerKey, false)
        end
    end
    self:ClearInvitesFor(PlayerKey)
    RemovePlayerKey(self.PlayerKeyList, PlayerKey)
    self.OriginalTeamByPlayer[PlayerKey] = nil
    ugcprint("[Backfill] Server player exit key=" .. tostring(PlayerKey) .. " online=" ..
                 tostring(#self.PlayerKeyList) .. " pending=" .. tostring(self.BackfillRequestPending) ..
                 " requestSerial=" .. tostring(self.BackfillRequestSerial) .. " loginSerial=" ..
                 tostring(self.BackfillLoginSerial) .. " requestLoginSerial=" ..
                 tostring(self.BackfillLoginSerialAtRequest) .. " callbackSeen=" ..
                 tostring(self.BackfillMatchCallbackSeen))
    self:SyncTeamUI()
    self:ScheduleBackfillRefresh("player-exit")
end

function UGCGameMode:UGC_PlayerKilledEvent(Killer, VictimPlayer, VictimPawn, DamageType)
    if VictimPlayer and VictimPawn then
        SaveBackpackSnapshot(VictimPlayer.PlayerKey, VictimPawn)
        DisuseEquippedWings(VictimPawn)
        -- 保存死亡前的血量到跨对局存档
        local PS = VictimPlayer.PlayerState
        if PS and PS.SaveCurrentHP then
            PS:SaveCurrentHP(VictimPawn)
        end
    end
end

-- 新 Pawn 刚生成时背包尚未完全初始化，延迟一秒再恢复。
function UGCGameMode:UGC_PlayerRespawnEvent(RespawnedController)
    local PC = RespawnedController
    local PlayerKey = PC.PlayerKey

    if PC.Is_Tower_Death_Respawn == true then
        PC.Is_Tower_Death_Respawn = nil
        PC:Server_TeleportToSpawn(201)
    end

    UGCTimerUtility.CreateLuaTimer(1, function()
        if PC and PC.Pawn then
            RestoreBackpackSnapshot(PlayerKey, PC.Pawn)
            DisuseEquippedWings(PC.Pawn)
            if PC.Pawn.RefreshStateMgrProperty ~= nil then
                PC.Pawn:RefreshStateMgrProperty(true)
            end
        end
    end, false)
end

function UGCGameMode:OnPawnDefeat(VictimPlayerKey, InstigatorPlayerKey, DamageType)
    -- 某些死亡方式不会触发 UGC_PlayerKilledEvent，尝试从 Controller 再保存一次。
    if not PlayerBackpackSnapshots[VictimPlayerKey] then
        local VictimController = UGCGameSystem.GetPlayerControllerByPlayerKey(VictimPlayerKey)
        if VictimController and VictimController.Pawn then
            SaveBackpackSnapshot(VictimPlayerKey, VictimController.Pawn)
            DisuseEquippedWings(VictimController.Pawn)
            -- 保存死亡前的血量
            local PS = VictimController.PlayerState
            if PS and PS.SaveCurrentHP then
                PS:SaveCurrentHP(VictimController.Pawn)
            end
        end
    end

    UGCPlayerPawnSystem.RespawnPlayer(VictimPlayerKey, 2, true)

    -- 防止个别情况下 UGC_PlayerRespawnEvent 未回调，重生完成后再尝试恢复一次。
    UGCTimerUtility.CreateLuaTimer(3, function()
        local RespawnedController = UGCGameSystem.GetPlayerControllerByPlayerKey(VictimPlayerKey)
        if RespawnedController and RespawnedController.Pawn then
            RestoreBackpackSnapshot(VictimPlayerKey, RespawnedController.Pawn)
            DisuseEquippedWings(RespawnedController.Pawn)
            if RespawnedController.Pawn.RefreshStateMgrProperty ~= nil then
                RespawnedController.Pawn:RefreshStateMgrProperty(true)
            end
        end
    end, false)
end
return UGCGameMode;
