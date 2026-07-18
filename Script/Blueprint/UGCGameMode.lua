---@class UGCGameMode_C:BP_UGCGameBase_C
-- Edit Below--
local UGCGameMode = {};
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")
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

    if self:HasAuthority() then
        self.PlayerKeyList = {}
        self.OriginalTeamByPlayer = {}
        self.Squads = {}
        self.MemberSquad = {}
        self.PendingInvites = {}
        self.CampByTeam = {}
        self.PendingIndependentTeamByPlayer = {}
        DropCleanupSystem.StartSafetyValveTimer()
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

local function IsTeamIDValid(TeamID)
    TeamID = tonumber(TeamID)
    if TeamID == nil or TeamID <= 0 or UGCTeamSystem.IsTeamIDValid == nil then
        return false
    end
    local Success, Result = pcall(UGCTeamSystem.IsTeamIDValid, TeamID)
    return Success and Result == true
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

function UGCGameMode:GetCurrentTeamID(PlayerKey)
    return tonumber(UGCTeamSystem.GetTeamIDByPlayerKey(PlayerKey)) or 0
end

function UGCGameMode:GetCandidateTeamIDs()
    local Candidates = {}
    local Added = {}
    local function TryAdd(TeamID)
        TeamID = tonumber(TeamID)
        if TeamID ~= nil and not Added[TeamID] and IsTeamIDValid(TeamID) then
            Added[TeamID] = true
            table.insert(Candidates, TeamID)
        end
    end

    for _, TeamID in ipairs(UGCTeamSystem.GetTeamIDs() or {}) do
        TryAdd(TeamID)
    end
    for TeamID = 1, TeamConfig.MAX_SERVER_PLAYERS do
        TryAdd(TeamID)
    end
    table.sort(Candidates)
    return Candidates
end

function UGCGameMode:GetUnusedTeamID(PlayerKey)
    local Used = {}
    for ExistingKey, TeamID in pairs(self.OriginalTeamByPlayer or {}) do
        if not IsSamePlayerKey(ExistingKey, PlayerKey) then
            Used[tonumber(TeamID)] = true
        end
    end
    for ExistingKey, TeamID in pairs(self.PendingIndependentTeamByPlayer or {}) do
        if not IsSamePlayerKey(ExistingKey, PlayerKey) then
            Used[tonumber(TeamID)] = true
        end
    end
    for _, TeamID in ipairs(self:GetCandidateTeamIDs()) do
        if not Used[TeamID] then
            return TeamID
        end
    end
    return nil
end

function UGCGameMode:EnsureIndependentTeam(PlayerKey)
    local CurrentTeamID = self:GetCurrentTeamID(PlayerKey)
    local bConflict = false
    for ExistingKey, TeamID in pairs(self.OriginalTeamByPlayer or {}) do
        if not IsSamePlayerKey(ExistingKey, PlayerKey) and tonumber(TeamID) == CurrentTeamID then
            bConflict = true
            break
        end
    end
    if IsTeamIDValid(CurrentTeamID) and not bConflict then
        self.PendingIndependentTeamByPlayer[PlayerKey] = nil
        return CurrentTeamID
    end

    local NewTeamID = self.PendingIndependentTeamByPlayer[PlayerKey]
    if not IsTeamIDValid(NewTeamID) then
        NewTeamID = self:GetUnusedTeamID(PlayerKey)
        self.PendingIndependentTeamByPlayer[PlayerKey] = NewTeamID
    end
    if NewTeamID == nil then
        return nil
    end

    UGCTeamSystem.ChangePlayerTeamID(PlayerKey, NewTeamID)
    local AppliedTeamID = self:GetCurrentTeamID(PlayerKey)
    if AppliedTeamID ~= NewTeamID then
        return nil
    end
    self.PendingIndependentTeamByPlayer[PlayerKey] = nil
    return AppliedTeamID
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

    self.CampByTeam[TeamID] = CampID
    UGCCampSystem.SetCampForTeam(TeamID, CampID)
    UGCCampSystem.SetCampRelation(CampID, CampID, TeamConfig.CAMP_RELATION.Same)
    for _, OtherCampID in pairs(self.CampByTeam) do
        if OtherCampID ~= CampID then
            UGCCampSystem.SetCampRelation(CampID, OtherCampID, TeamConfig.CAMP_RELATION.Enemy)
            UGCCampSystem.SetCampRelation(OtherCampID, CampID, TeamConfig.CAMP_RELATION.Enemy)
        end
    end
    ugcprint("[Team] Server map team=" .. tostring(TeamID) .. " camp=" .. tostring(CampID))
    return CampID
end

function UGCGameMode:GetSquadForMember(PlayerKey)
    local TeamID = self.MemberSquad[PlayerKey]
    return TeamID and self.Squads[TeamID] or nil, TeamID
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
    local SquadIDA = self.MemberSquad[PlayerKeyA]
    local SquadIDB = self.MemberSquad[PlayerKeyB]
    return SquadIDA ~= nil and SquadIDA == SquadIDB
end

function UGCGameMode:BuildTeamRoster()
    local Roster = {}
    for _, PlayerKey in ipairs(self.PlayerKeyList or {}) do
        local PlayerState = UGCGameSystem.GetPlayerStateByPlayerKey(PlayerKey)
        local Squad, SquadID = self:GetSquadForMember(PlayerKey)
        table.insert(Roster, {
            PlayerKey = PlayerKey,
            PlayerName = PlayerState and (PlayerState.PlayerName or PlayerState.RealPlayerName) or tostring(PlayerKey),
            TeamID = self:GetCurrentTeamID(PlayerKey),
            SquadID = SquadID or 0,
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

    local IndependentTeamID = self:EnsureIndependentTeam(PlayerKey)
    if IndependentTeamID == nil then
        return false
    end

    self.OriginalTeamByPlayer[PlayerKey] = IndependentTeamID
    table.insert(self.PlayerKeyList, PlayerKey)
    self:EnsureCampForTeam(IndependentTeamID)
    ugcprint("[Team] Server player login key=" .. tostring(PlayerKey) .. " originalTeam=" ..
                 tostring(IndependentTeamID))
    self:SyncTeamUI()
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
            UGCTimerUtility.CreateLuaTimer(1, TryRegister, false)
        else
            ugcprint("[Team] Server player registration failed after retries")
        end
    end
    UGCTimerUtility.CreateLuaTimer(0.5, TryRegister, false)
end

-- 玩家登录时: 先加载跨对局存档, 再发初始武器（Pawn可能还没好，等1秒）
-- 若 Pawn 在 1 秒后仍未就绪，则重试（最多 10 次），避免 LoadFromArchive 被整体跳过导致存档丢失
function UGCGameMode:UGC_PlayerLoginEvent(PlayerController)
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
    for _, ExistingKey in ipairs(self.PlayerKeyList or {}) do
        if IsSamePlayerKey(ExistingKey, PlayerKey) then
            return ExistingKey
        end
    end
    return nil
end

function UGCGameMode:RestoreOriginalTeam(PlayerKey)
    local OriginalTeamID = self.OriginalTeamByPlayer[PlayerKey]
    if not IsTeamIDValid(OriginalTeamID) then
        return false
    end
    UGCTeamSystem.ChangePlayerTeamID(PlayerKey, OriginalTeamID)
    local bRestored = self:GetCurrentTeamID(PlayerKey) == tonumber(OriginalTeamID)
    if bRestored then
        self:EnsureCampForTeam(OriginalTeamID)
    else
        ugcprint("[Team] Server restore original team failed key=" .. tostring(PlayerKey))
    end
    return bRestored
end

function UGCGameMode:CreateSquad(LeaderKey)
    if self.MemberSquad[LeaderKey] ~= nil or self:GetActiveSquadCount() >= TeamConfig.MAX_ACTIVE_TEAMS then
        return nil
    end
    local TeamID = tonumber(self.OriginalTeamByPlayer[LeaderKey])
    if not IsTeamIDValid(TeamID) or self.Squads[TeamID] ~= nil then
        return nil
    end
    local Squad = {TeamID = TeamID, LeaderKey = LeaderKey, Members = {LeaderKey}}
    self.Squads[TeamID] = Squad
    self.MemberSquad[LeaderKey] = TeamID
    self:EnsureCampForTeam(TeamID)
    return Squad
end

function UGCGameMode:AddMemberToSquad(Squad, PlayerKey)
    if Squad == nil or self.MemberSquad[PlayerKey] ~= nil or #Squad.Members >= TeamConfig.MAX_PLAYERS_PER_TEAM then
        return false
    end
    UGCTeamSystem.ChangePlayerTeamID(PlayerKey, Squad.TeamID)
    if self:GetCurrentTeamID(PlayerKey) ~= tonumber(Squad.TeamID) then
        ugcprint("[Team] Server join team change failed key=" .. tostring(PlayerKey))
        return false
    end
    table.insert(Squad.Members, PlayerKey)
    self.MemberSquad[PlayerKey] = Squad.TeamID
    self:EnsureCampForTeam(Squad.TeamID)
    return true
end

function UGCGameMode:RemoveMemberFromSquad(Squad, PlayerKey, bRestoreTeam)
    if Squad == nil or not RemovePlayerKey(Squad.Members, PlayerKey) then
        return false
    end
    self.MemberSquad[PlayerKey] = nil
    if bRestoreTeam ~= false then
        self:RestoreOriginalTeam(PlayerKey)
    end
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
    self.Squads[Squad.TeamID] = nil
    for _, MemberKey in ipairs(Squad.Members or {}) do
        self.MemberSquad[MemberKey] = nil
        self:ClearInvitesFor(MemberKey)
        if not IsSamePlayerKey(MemberKey, DisconnectedPlayerKey) and ContainsPlayerKey(self.PlayerKeyList, MemberKey) then
            self:RestoreOriginalTeam(MemberKey)
        end
    end
    ugcprint("[Team] Server disband team=" .. tostring(Squad.TeamID))
    return true
end

function UGCGameMode:HandleInviteRequest(InviterKey, TargetKey)
    InviterKey = self:ResolveOnlinePlayerKey(InviterKey)
    TargetKey = self:ResolveOnlinePlayerKey(TargetKey)
    if InviterKey == nil or TargetKey == nil or IsSamePlayerKey(InviterKey, TargetKey) or
        self.MemberSquad[TargetKey] ~= nil then
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
    table.insert(self.PendingInvites, {Type = TeamConfig.INVITE_TYPE, FromKey = InviterKey, TargetKey = TargetKey})
    ugcprint("[Team] Server invite from=" .. tostring(InviterKey) .. " target=" .. tostring(TargetKey))
    self:SyncTeamUI()
    return true
end

function UGCGameMode:HandleInviteResponse(TargetKey, InviterKey, bAccept)
    TargetKey = self:ResolveOnlinePlayerKey(TargetKey)
    InviterKey = self:ResolveOnlinePlayerKey(InviterKey)
    if TargetKey == nil or InviterKey == nil or not self:RemoveInvite(InviterKey, TargetKey) then
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

function UGCGameMode:HandleLeaveTeamRequest(PlayerKey)
    PlayerKey = self:ResolveOnlinePlayerKey(PlayerKey)
    local Squad = PlayerKey and self:GetSquadForMember(PlayerKey) or nil
    if Squad == nil or IsSamePlayerKey(Squad.LeaderKey, PlayerKey) then
        return false
    end
    self:RemoveMemberFromSquad(Squad, PlayerKey, true)
    self:ClearInvitesFor(PlayerKey)
    self:SyncTeamUI()
    return true
end

function UGCGameMode:HandleKickRequest(LeaderKey, TargetKey)
    LeaderKey = self:ResolveOnlinePlayerKey(LeaderKey)
    TargetKey = self:ResolveOnlinePlayerKey(TargetKey)
    local Squad = LeaderKey and self:GetSquadForMember(LeaderKey) or nil
    if Squad == nil or TargetKey == nil or not IsSamePlayerKey(Squad.LeaderKey, LeaderKey) or
        IsSamePlayerKey(LeaderKey, TargetKey) or self.MemberSquad[TargetKey] ~= Squad.TeamID then
        return false
    end
    self:RemoveMemberFromSquad(Squad, TargetKey, true)
    self:ClearInvitesFor(TargetKey)
    self:SyncTeamUI()
    return true
end

function UGCGameMode:HandleDisbandRequest(LeaderKey)
    LeaderKey = self:ResolveOnlinePlayerKey(LeaderKey)
    local Squad = LeaderKey and self:GetSquadForMember(LeaderKey) or nil
    if Squad == nil or not IsSamePlayerKey(Squad.LeaderKey, LeaderKey) then
        return false
    end
    self:DisbandSquad(Squad)
    self:SyncTeamUI()
    return true
end

function UGCGameMode:UGC_PlayerExitEvent(PlayerController)
    local PlayerKey = self:ResolveOnlinePlayerKey(self:GetPlayerKey(PlayerController))
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
    self.PendingIndependentTeamByPlayer[PlayerKey] = nil
    self:SyncTeamUI()
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
