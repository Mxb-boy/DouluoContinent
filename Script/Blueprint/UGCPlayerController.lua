---@class UGCPlayerController_C:BP_UGCPlayerController_C
---@field TaskTemplateComponent TaskTemplateComponent_C
---@field GiftPackComponent GiftPackComponent_C
---@field RankingListComponent RankingListComponent_C
---@field LotteryComponent LotteryComponent_C
---@field ShopV2Component ShopV2Component_C
---@field SignInEventComponent SignInEventComponent_C
--Edit Below--
---@class UGCPlayerController_C:BP_UGCPlayerController_C
---@field TaskTemplateComponent TaskTemplateComponent_C
---@field GiftPackComponent GiftPackComponent_C
---@field RankingListComponent RankingListComponent_C
---@field LotteryComponent LotteryComponent_C
---@field ShopV2Component ShopV2Component_C
---@field SignInEventComponent SignInEventComponent_C
-- Edit Below--
local UGCPlayerController = {}
local RuntimeLog = UGCGameSystem.UGCRequire("Script.Common.RuntimeLog")
RuntimeLog.Install(UGCGameSystem.IsServer() and "SERVER" or "CLIENT")
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local RealmConfig = UGCGameSystem.UGCRequire("Script.Common.RealmConfig")
local LotteryConfig = UGCGameSystem.UGCRequire("Script.Common.LotteryConfig")
local TitleConfig = UGCGameSystem.UGCRequire("Script.Common.TitleConfig")
local Ma_NumShow = UGCGameSystem.UGCRequire("Script.Ma.Ma_NumShow")
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")
local L_Enum_Event = UGCGameSystem.UGCRequire("Script.Lin.L_Enum_Event")
local L_Enum = UGCGameSystem.UGCRequire("Script.Lin.L_Enum")
local TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
local TitleMgr = UGCGameSystem.UGCRequire("Script.Xiao.TitleMgr")
local TalentMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentMgr")
local TalentEffectMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentEffectMgr")
local PlayerLevelMgr = UGCGameSystem.UGCRequire("Script.Lin.PlayerLevelMgr")
local ShadowDisabler = UGCGameSystem.UGCRequire("Script.Common.ShadowDisabler")
local BackpackCapacityUtil = UGCGameSystem.UGCRequire("Script.Common.BackpackCapacityUtil")
local WeaponRefineConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponRefineConfig")
local DEFAULT_WQ_HIT_EFFECT_PATH = "/Game/UGC/UGCGame/Skill/Arts_Effect/CG034/Particle/P_CG034UGC_Skill_SwordFire_03.P_CG034UGC_Skill_SwordFire_03"
local TOWER_ATTENTION_SOUND_PATH = 'Asset/WwiseEvent/Attention.Attention'
local PaTa_Spawn_Point_ID = 201 -- 爬塔出生点
local PaTa_Ticket_Item_ID = 8310064 -- 爬塔传送券
local ForgeMaterialItemIDs = {
    HGRJ = 8310035,
    QNHH = 8310036,
    Protect = 8310121
}
local FORGE_FAIL_REFUND_RATE = 70
local FORGE_FAIL_REFUND_PERCENT = 0.5
local DisuseItemFunctionNames = {"DisuseItemV2", "UnUseItemV2", "CancelUseItemV2", "StopUseItemV2"}
local SoulRingItemIDs = {
    8310048, 8310049, 8310051, 8310053, 8310054, 8310055, 8310056, 8310057, 8310052, 8310050,
    8310122, 8310123, 8310124, 8310125, 8310126, 8310127, 8310128, 8310129, 8310130, 8310131
}
local SoulRingStardustRates = {}
for Index, ItemID in ipairs(SoulRingItemIDs) do
    SoulRingStardustRates[ItemID] = Index
end
local STARDUST_ITEM_ID = 8310134
local WingItemIDs = {
    [8310012] = true,
    [8310013] = true,
    [8310014] = true,
    [8310058] = true,
    [8310059] = true,
    [8310010] = true
}
local WING_EQUIPMENT_SLOT = "CB_CW"

local function GetWingItemIDFromEquipmentSlot(PlayerPawn)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil or
        UGCBackpackSystemV2.GetEquippedItemBySlotName == nil then
        return nil
    end

    local Success, EquippedItem = pcall(UGCBackpackSystemV2.GetEquippedItemBySlotName, PlayerPawn,
        WING_EQUIPMENT_SLOT)
    if not Success or EquippedItem == nil then
        return nil
    end

    local SuccessID, ItemID = pcall(function()
        if type(EquippedItem) == "number" or type(EquippedItem) == "string" then
            return tonumber(EquippedItem)
        end
        return tonumber(EquippedItem.TypeSpecificID or EquippedItem.ItemID or EquippedItem.ItemId)
    end)
    if SuccessID and WingItemIDs[ItemID] then
        return ItemID
    end
    return nil
end

local function EnsurePlayerStateArchiveUID(PlayerController)
    if PlayerController == nil or PlayerController.PlayerState == nil then
        return
    end

    local PlayerState = PlayerController.PlayerState
    if PlayerState.ArchiveUID ~= nil and tonumber(PlayerState.ArchiveUID) ~= 0 then
        return
    end

    local Pawn = PlayerController.Pawn
    if Pawn == nil and PlayerController.K2_GetPawn ~= nil then
        local Success, Result = pcall(PlayerController.K2_GetPawn, PlayerController)
        if Success then
            Pawn = Result
        end
    end

    if Pawn ~= nil and UGCPawnAttrSystem ~= nil and UGCPawnAttrSystem.GetPlayerUID ~= nil then
        PlayerState.ArchiveUID = tonumber(UGCPawnAttrSystem.GetPlayerUID(Pawn))
    end
end

function UGCPlayerController:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)
    -- Retry after engine globals are injected so the real ugcprint is captured.
    RuntimeLog.Install(UGCGameSystem.IsServer() and "SERVER" or "CLIENT")

    -- 临时修复：官方公告模块未加载时，防止引擎框架报 nil 索引警告
    if UpdateNoticeInGameUI == nil then
        UpdateNoticeInGameUI = {}
    end

    -- 注册补偿系统委托
    self:RegisterCompensationDelegates()

    -- 删去风向标
    local MainUI = UGCWidgetManagerSystem.GetMainControlUI()
    if MainUI then
        MainUI.NavigatorPanel:SetVisibility(ESlateVisibility.Collapsed)
        MainUI.Image_0:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- Create UI only on the client.
    if self:HasAuthority() then
        return
    end

    ShadowDisabler.Start(self)

    -- Fei 是独立控件，多客户端 PIE 下资源加载完成时间可能不同；提前启动独立重试，
    -- 不能因为 MainUI 已创建或某次 Fei 加载失败就永远跳过飞行按钮。
    self:RetryEnsureFeiUI(10)

    -- Prevent duplicate MainUI instances.
    if self.MainUIInstance ~= nil then
        return
    end

    local MainUIPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/Blueprint/UI/UI02.UI02_C"
    local MainUIClass = UE.LoadClass(MainUIPath)

    if MainUIClass == nil then
        ugcprint("[UGCPlayerController] MainUI class load failed: " .. MainUIPath)
        return
    end

    self.MainUIInstance = UserWidget.NewWidgetObjectBP(self, MainUIClass)
    if self.MainUIInstance == nil then
        ugcprint("[UGCPlayerController] MainUI create failed")
        return
    end

    self.MainUIInstance:AddToViewport()
    if self.MainUIInstance.RefreshYXWDBuffIcon ~= nil then
        self.MainUIInstance:RefreshYXWDBuffIcon()
    elseif self.MainUIInstance.RefreshYXWDPurchaseButton ~= nil then
        self.MainUIInstance:RefreshYXWDPurchaseButton()
    end
    if self.ClientYXWDInvincibleBuffEnabled == true and self.MainUIInstance.OnYXWDInvincibleBuffChanged ~= nil then
        self.MainUIInstance:OnYXWDInvincibleBuffChanged(1, self.ClientYXWDInvincibleBuffDurationSeconds or -2)
    end
    if self.ClientPlayerExp ~= nil and self.MainUIInstance.RefreshPlayerExpUI ~= nil then
        self.MainUIInstance:RefreshPlayerExpUI(self.ClientPlayerExp, self.ClientPlayerMaxExp)
        if self.MainUIInstance.Avarar_frame ~= nil and self.ClientPlayerLevel ~= nil then
            self.MainUIInstance.Avarar_frame:SetPlayerStateLevel(self.ClientPlayerLevel)
            self.MainUIInstance.Avarar_frame:ShowUI()
        end
    end
    ugcprint("[UGCPlayerController] MainUI created")
    self:Client_RefreshTitleBonus()

    self:EnsureFeiUI()
end

function UGCPlayerController:EnsureFeiUI()
    if self:HasAuthority() or self.FeiUIInstance ~= nil then
        return
    end

    local FeiUIPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/Blueprint/UI/Fei.Fei_C"
    local FeiUIClass = UE.LoadClass(FeiUIPath)

    if FeiUIClass == nil then
        ugcprint("[UGCPlayerController] Fei UI class load failed: " .. FeiUIPath)
        return
    end

    self.FeiUIInstance = UserWidget.NewWidgetObjectBP(self, FeiUIClass)
    if self.FeiUIInstance == nil then
        ugcprint("[UGCPlayerController] Fei UI create failed")
        return
    end

    self.FeiUIInstance:AddToViewport()
    if self.PendingFeiTowerButtonsHiddenCount ~= nil then
        self.FeiUIInstance.TowerButtonsHiddenCount = math.max(0,
            tonumber(self.PendingFeiTowerButtonsHiddenCount) or 0)
        if self.FeiUIInstance.RefreshButton0Visibility ~= nil then
            self.FeiUIInstance:RefreshButton0Visibility()
        end
    end
    ugcprint("[UGCPlayerController] Fei UI created")
end

function UGCPlayerController:RetryEnsureFeiUI(RetriesRemaining)
    if self:HasAuthority() or self.FeiUIInstance ~= nil or UGCTimerUtility == nil or
        UGCTimerUtility.CreateLuaTimer == nil then
        return
    end

    UGCTimerUtility.CreateLuaTimer(0.5, function()
        if self == nil or self.FeiUIInstance ~= nil then
            return
        end
        self:EnsureFeiUI()
        if self.FeiUIInstance == nil and (tonumber(RetriesRemaining) or 0) > 0 then
            self:RetryEnsureFeiUI(RetriesRemaining - 1)
        end
    end, false)
end

function UGCPlayerController:GetAvailableServerRPCs()
    return "Server_TeleportToSpawn", "Server_TeleportToLocation", "Server_UpdateRankingListScore",
        "Server_ClearAllRankingListData", "Client_BroadcastPlantMessage", "Client_ForgeWeaponResult",
        "Server_ForgeWeapon", "Server_AddShopItemToBackpackV2", "Server_CleanupStaleShopVirtualItem",
        "Server_EquipTitle", "Server_BeginFlyState", "Server_RequestEquippedWingState",
        "Client_SetEquippedWingItemID", "Client_RejectFlyStart",
        "Server_EndFlyState", "Server_FlyMove", "Server_StopFlyMove", "Server_UpdateWeaponAttackBonus",
        "Server_AddProbabilityBonus", "Client_ProbabilityBonusChanged", "Client_BreakRealmResult", "Server_BreakRealm",
        "Server_SetAutoPickEnabled", "Client_YXWDInvincibleBuffChanged", "Server_SetYXWDInvincibleBuffActive",
        "Client_YXWDInvincibleActiveChanged", "Server_RequestLottery", "Client_LotteryResult",
        "Server_RequestLotteryStateSync", "Client_SyncLotteryState", "Client_RefreshProperty",
        "Server_RequestSoulRingInventory", "Client_SyncSoulRingInventory",
        "Server_ConvertAllSoulRingsToStardust", "Server_ConvertSelectedSoulRingToStardust",
        "Client_SoulRingConversionResult",
        "Client_RefreshPlayerExp", "Server_SetFinalMaxHp", "Server_SetFinalAttack", "Server_RequestRefreshProperty",
        "Client_StartAutoMeleeAttack", "Server_SetAutoFeatureButtonHidden", "Client_SetAutoFeatureButtonHidden",
        "Client_SetTowerOutBoxVisible", "Client_OpenTowerTopUI", "Server_ClaimTowerTopReward",
        "Server_SetFeiButton0Hidden", "Client_SetFeiButton0Hidden", "Client_ShowMonsterDamageNumber",
        "Client_PlayWQHitEffect",
        "Client_SetFeiTowerButtonsHidden", "Client_ResetFeiTowerButtonsHidden", "Server_AddFixedBaseProperty", "Server_AddTaskProgress",
        "Server_RequestPaTaState", "Server_RequestFreePaTa", "Server_RequestTicketPaTa", "Client_SyncPaTaState",
        "Client_ShowToast", "Client_PlayerDataReset",
        "Client_PlayerDataResetStarted", "Client_PlayerDataResetFailed", "Client_GMResetLogEntry",
        "Server_RequestRuntimeLogs", "Server_RuntimeLogProbe", "Client_RuntimeLogBatch",
        "ServerRequestInvitePlayer", "ServerRespondInvite", "ServerRequestJoinTeam", "ServerRespondJoinRequest",
        "ServerRequestLeaveTeam", "ServerRequestKickPlayer", "ServerRequestDisbandTeam", "UseRedemptionCode",
        "Server_LearnTalent", "Client_TalentLearnResult",
        "Server_RequestTalentState", "Client_SyncTalentState", "Server_SetOrbitWeaponEnabled",
        "Server_SelectOrbitWeapon", "Server_SetOrbitWeaponActiveGun",
        "Server_RequestWeaponRefineState", "Server_RefineOrbitWeapon", "Client_WeaponRefineResult",
        "Server_ResolveWeaponRefine", "Client_WeaponRefineDecisionResult"
end

function UGCPlayerController:Server_SetOrbitWeaponEnabled(bEnabled)
    self.OrbitWeaponEnabled = bEnabled == true
    local Pawn = self.Pawn or (self.K2_GetPawn ~= nil and self:K2_GetPawn() or nil)
    if Pawn ~= nil and Pawn.SetOrbitWeaponEnabled ~= nil then
        Pawn:SetOrbitWeaponEnabled(self.OrbitWeaponEnabled)
    end
end

function UGCPlayerController:Server_SelectOrbitWeapon(WeaponClassPath, HitEffectPath)
    if type(WeaponClassPath) ~= "string" or WeaponClassPath == "" then
        return
    end
    local Pawn = self.Pawn or (self.K2_GetPawn ~= nil and self:K2_GetPawn() or nil)
    if Pawn ~= nil and Pawn.SetOrbitWeaponConfig ~= nil then
        if Pawn:SetOrbitWeaponConfig(WeaponClassPath, HitEffectPath) == true then
            self.OrbitWeaponClassPath = WeaponClassPath
            self.OrbitWeaponHitEffectPath = HitEffectPath
        end
    end
end

function UGCPlayerController:Server_SetOrbitWeaponActiveGun(GunIndex, DamagePercent)
    GunIndex = math.floor(tonumber(GunIndex) or 0)
    local Pawn = self.Pawn or (self.K2_GetPawn ~= nil and self:K2_GetPawn() or nil)
    if Pawn == nil or Pawn.SetOrbitWeaponActiveGun == nil then
        return
    end
    local PlayerLevel = Pawn.PlayerState ~= nil and Pawn.PlayerState.GetPlayerLevel ~= nil and
        tonumber(Pawn.PlayerState:GetPlayerLevel()) or 0
    if GunIndex >= 1 and GunIndex <= 8 and PlayerLevel >= GunIndex then
        local UnlockedCount = math.max(1, math.min(8, math.floor(PlayerLevel)))
        local SavedAttack = WeaponRefineConfig.GetCurrentStats(Pawn.PlayerState, GunIndex, UnlockedCount)
        DamagePercent = tonumber(SavedAttack) or tonumber(DamagePercent)
        DamagePercent = DamagePercent ~= nil and math.max(0.01, math.min(10000, DamagePercent)) or nil
        local SavedTier = tonumber(self.OrbitWeaponActiveGunTier) or 0
        local EffectiveTier = math.max(SavedTier, GunIndex)
        self.OrbitWeaponActiveGunTier = EffectiveTier
        self.OrbitWeaponSelectedGunIndex = GunIndex
        if DamagePercent ~= nil then
            self.OrbitWeaponDamagePercent = DamagePercent
        end
        Pawn:SetOrbitWeaponActiveGun(EffectiveTier, self.OrbitWeaponDamagePercent)
    end
end

local function GetTalentStateSnapshot(PlayerState)
    local TalentPoints = PlayerState.GetTalentPoints ~= nil and PlayerState:GetTalentPoints() or
                             math.max(0, math.floor(tonumber(PlayerState.TalentPoints) or 0))
    local LearnedTalents = PlayerState.GetLearnedTalents ~= nil and PlayerState:GetLearnedTalents() or
                               PlayerState.LearnedTalents or {}
    local EquippedUltimateID = PlayerState.GetEquippedUltimateID ~= nil and PlayerState:GetEquippedUltimateID() or
                                   math.max(0, math.floor(tonumber(PlayerState.EquippedUltimateID) or 0))
    return TalentPoints, LearnedTalents, EquippedUltimateID
end

local function ApplyTalentStateSnapshot(PlayerController, TalentPoints, LearnedTalents, EquippedUltimateID)
    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil then
        return
    end

    local LearnedCopy = {}
    if type(LearnedTalents) == "table" then
        for LearnedID, Learned in pairs(LearnedTalents) do
            if Learned == true or tonumber(Learned) == 1 then
                LearnedCopy[tostring(LearnedID)] = true
            end
        end
    end
    PlayerState.TalentPoints = math.max(0, math.floor(tonumber(TalentPoints) or 0))
    PlayerState.LearnedTalents = LearnedCopy
    PlayerState.EquippedUltimateID = math.max(0, math.floor(tonumber(EquippedUltimateID) or 0))
end

local function RefreshTalentUI(PlayerController)
    local TalentUI = PlayerController.TalentUIInstance
    if TalentUI == nil and PlayerController.MainUIInstance ~= nil then
        TalentUI = PlayerController.MainUIInstance.UI018Instance
    end
    if TalentUI ~= nil and TalentUI.RefreshTalentState ~= nil then
        TalentUI:RefreshTalentState()
    end
end

local function RequestTalentPropertyRefresh(PlayerController)
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_RequestRefreshProperty")
end

function UGCPlayerController:Server_LearnTalent(NodeID)
    local PlayerState = self.PlayerState
    if PlayerState == nil then
        return false
    end

    EnsurePlayerStateArchiveUID(self)
    if PlayerState.bArchiveLoaded ~= true then
        ugcprint("[Talent] Learn rejected: archive is not loaded")
        return false
    end

    local TalentNodeID = tonumber(NodeID)
    if TalentNodeID == nil then
        return false
    end

    local Success = TalentMgr:LearnTalent(PlayerState, TalentNodeID)
    local TalentPoints, LearnedTalents, EquippedUltimateID = GetTalentStateSnapshot(PlayerState)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_TalentLearnResult", Success, TalentNodeID, TalentPoints,
        LearnedTalents, EquippedUltimateID)
    ugcprint("[Talent] Learn node=" .. tostring(TalentNodeID) .. " success=" .. tostring(Success))
    return Success
end

function UGCPlayerController:Client_TalentLearnResult(Success, NodeID, TalentPoints, LearnedTalents,
    EquippedUltimateID)
    ApplyTalentStateSnapshot(self, TalentPoints, LearnedTalents, EquippedUltimateID)
    RefreshTalentUI(self)
    L_Com.ShowToast(Success and "天赋解锁成功" or "解锁失败，请重试")
    if Success then
        RequestTalentPropertyRefresh(self)
    end
    ugcprint("[Talent] Client result node=" .. tostring(NodeID) .. " success=" .. tostring(Success))
end

function UGCPlayerController:Server_EquipTalentUltimate(NodeID)
    local PlayerState = self.PlayerState
    if PlayerState == nil then
        return false
    end

    EnsurePlayerStateArchiveUID(self)
    if PlayerState.bArchiveLoaded ~= true then
        ugcprint("[Talent] Equip ultimate rejected: archive is not loaded")
        return false
    end

    local TalentNodeID = tonumber(NodeID)
    if TalentNodeID == nil then
        return false
    end

    local Success = TalentMgr:EquipUltimate(PlayerState, TalentNodeID)
    local TalentPoints, LearnedTalents, EquippedUltimateID = GetTalentStateSnapshot(PlayerState)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_TalentUltimateEquipResult", Success, TalentNodeID,
        TalentPoints, LearnedTalents, EquippedUltimateID)
    ugcprint("[Talent] Equip ultimate node=" .. tostring(TalentNodeID) .. " success=" .. tostring(Success) ..
                 " equipped=" .. tostring(EquippedUltimateID))
    return Success
end

function UGCPlayerController:Client_TalentUltimateEquipResult(Success, NodeID, TalentPoints, LearnedTalents,
    EquippedUltimateID)
    ApplyTalentStateSnapshot(self, TalentPoints, LearnedTalents, EquippedUltimateID)
    RefreshTalentUI(self)
    ugcprint("[Talent] Client equip ultimate node=" .. tostring(NodeID) .. " success=" .. tostring(Success) ..
                 " equipped=" .. tostring(EquippedUltimateID))
end

function UGCPlayerController:Server_RequestTalentState()
    local PlayerState = self.PlayerState
    if PlayerState == nil or PlayerState.bArchiveLoaded ~= true then
        return false
    end

    if TalentMgr:GrantTestPointsIfEmpty(PlayerState) then
        ugcprint("[Talent] Granted initial test points")
    end

    local TalentPoints, LearnedTalents, EquippedUltimateID = GetTalentStateSnapshot(PlayerState)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncTalentState", TalentPoints, LearnedTalents,
        EquippedUltimateID)
    return true
end

function UGCPlayerController:Client_SyncTalentState(TalentPoints, LearnedTalents, EquippedUltimateID)
    ApplyTalentStateSnapshot(self, TalentPoints, LearnedTalents, EquippedUltimateID)
    RefreshTalentUI(self)
    RequestTalentPropertyRefresh(self)
    ugcprint("[Talent] Client state synced points=" .. tostring(TalentPoints) .. " equipped=" ..
                 tostring(EquippedUltimateID))
end

function UGCPlayerController:ServerRequestInvitePlayer(TargetKey)
    ugcprint("[Team] Server RPC invite build=" .. tostring(TeamConfig.BUILD_ID) .. " requester=" ..
                 tostring(self.PlayerKey) .. " target=" .. tostring(TargetKey))
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.HandleInviteRequest ~= nil then
        GameMode:HandleInviteRequest(self, TargetKey)
    else
        ugcprint("[Team] Server RPC invite rejected: GameMode is nil")
    end
end

function UGCPlayerController:ServerRespondInvite(InviterKey, bAccept)
    ugcprint("[Team] Server RPC invite response build=" .. tostring(TeamConfig.BUILD_ID) .. " requester=" ..
                 tostring(self.PlayerKey) .. " inviter=" .. tostring(InviterKey) .. " accept=" .. tostring(bAccept))
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.HandleInviteResponse ~= nil then
        GameMode:HandleInviteResponse(self, InviterKey, bAccept == true or tonumber(bAccept) == 1)
    else
        ugcprint("[Team] Server RPC invite response rejected: GameMode is nil")
    end
end

function UGCPlayerController:ServerRequestJoinTeam(LeaderKey)
    ugcprint("[TeamJoinRequest] Server RPC request build=" .. tostring(TeamConfig.BUILD_ID) .. " applicant=" ..
                 tostring(self.PlayerKey) .. " leader=" .. tostring(LeaderKey))
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.HandleJoinRequest ~= nil then
        GameMode:HandleJoinRequest(self, LeaderKey)
    else
        ugcprint("[TeamJoinRequest] Server RPC request rejected: GameMode is nil")
    end
end

function UGCPlayerController:ServerRespondJoinRequest(ApplicantKey, bAccept)
    ugcprint("[TeamJoinRequest] Server RPC response build=" .. tostring(TeamConfig.BUILD_ID) .. " leader=" ..
                 tostring(self.PlayerKey) .. " applicant=" .. tostring(ApplicantKey) .. " accept=" ..
                 tostring(bAccept))
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.HandleJoinRequestResponse ~= nil then
        GameMode:HandleJoinRequestResponse(self, ApplicantKey, bAccept == true or tonumber(bAccept) == 1)
    else
        ugcprint("[TeamJoinRequest] Server RPC response rejected: GameMode is nil")
    end
end

function UGCPlayerController:ServerRequestLeaveTeam()
    ugcprint("[Team] Server RPC leave build=" .. tostring(TeamConfig.BUILD_ID) .. " requester=" ..
                 tostring(self.PlayerKey))
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.HandleLeaveTeamRequest ~= nil then
        GameMode:HandleLeaveTeamRequest(self)
    else
        ugcprint("[Team] Server RPC leave rejected: GameMode is nil")
    end
end

function UGCPlayerController:ServerRequestKickPlayer(TargetKey)
    ugcprint("[Team] Server RPC kick build=" .. tostring(TeamConfig.BUILD_ID) .. " requester=" ..
                 tostring(self.PlayerKey) .. " target=" .. tostring(TargetKey))
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.HandleKickRequest ~= nil then
        GameMode:HandleKickRequest(self, TargetKey)
    else
        ugcprint("[Team] Server RPC kick rejected: GameMode is nil")
    end
end

function UGCPlayerController:ServerRequestDisbandTeam()
    ugcprint("[Team] Server RPC disband build=" .. tostring(TeamConfig.BUILD_ID) .. " requester=" ..
                 tostring(self.PlayerKey))
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.HandleDisbandRequest ~= nil then
        GameMode:HandleDisbandRequest(self)
    else
        ugcprint("[Team] Server RPC disband rejected: GameMode is nil")
    end
end

local function StopCurrentZipLine(self)
    local ZipLineChild = self.CurrentZipLineChild
    if UGCObjectUtility.IsObjectValid(ZipLineChild) then
        ZipLineChild.ActivityFakePossess:FakeUnPossessWithDettach(EUnPossessReason.Finished)
    end
    self.CurrentZipLineChild = nil
end

local function TeleportToSpawn(self, bornPointID)
    local pawn = self:K2_GetPawn()
    if not pawn then
        return false
    end

    local PlayerStartManagerComponentClass = ScriptGameplayStatics.FindClass("PlayerStartManagerComponent")
    if PlayerStartManagerComponentClass == nil or UGCGameSystem.GameMode == nil then
        return false
    end

    local PlayerStartManagerComponent = UGCGameSystem.GameMode:GetComponentByClass(PlayerStartManagerComponentClass)
    if PlayerStartManagerComponent == nil then
        return false
    end

    local PlayerStart = PlayerStartManagerComponent:FindPlayerStartByBornPointID(bornPointID, false)
    if PlayerStart == nil then
        return false
    end

    local loc = PlayerStart:K2_GetActorLocation()
    StopCurrentZipLine(self)
    UGCPlayerControllerSystem.TeleportTo(self, loc.X, loc.Y, loc.Z + 100)
    return true
end

function UGCPlayerController:Server_TeleportToSpawn(bornPointID)
    TeleportToSpawn(self, bornPointID)
end

--[[----------------------获取当天日期标记------------------------]]
local function GetPaTaToday()
    return tonumber(os.date("%Y%m%d", os.time())) or 0
end

--[[----------------------请求同步爬塔次数状态------------------------]]
function UGCPlayerController:Server_RequestPaTaState()
    local Player_State = self.PlayerState -- 玩家状态
    if Player_State == nil or Player_State.bArchiveLoaded ~= true then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncPaTaState", false, false, "玩家数据加载中，请稍后再试")
        return
    end

    local Today_Date = GetPaTaToday() -- 服务端当天日期
    local Refresh_Day = Player_State.GetPaTaRefreshDay ~= nil and Player_State:GetPaTaRefreshDay() or
                            (tonumber(Player_State.PaTaRefreshDay) or 0) -- 上次使用免费次数的日期
    UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncPaTaState", true, Refresh_Day ~= Today_Date, "")
end

--[[----------------------免费爬塔传送------------------------]]
function UGCPlayerController:Server_RequestFreePaTa()
    local Player_State = self.PlayerState -- 玩家状态
    if Player_State == nil or Player_State.bArchiveLoaded ~= true then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncPaTaState", false, false, "玩家数据加载中，请稍后再试")
        return
    end

    EnsurePlayerStateArchiveUID(self)
    local Today_Date = GetPaTaToday() -- 服务端当天日期
    local Refresh_Day = Player_State.GetPaTaRefreshDay ~= nil and Player_State:GetPaTaRefreshDay() or
                            (tonumber(Player_State.PaTaRefreshDay) or 0) -- 上次使用免费次数的日期
    if Refresh_Day == Today_Date then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncPaTaState", true, false, "今日免费次数已使用")
        return
    end

    local Save_Succeeded = false -- 免费次数保存结果
    if Player_State.SetPaTaRefreshDay ~= nil then
        Save_Succeeded = Player_State:SetPaTaRefreshDay(Today_Date) == true
    else
        Player_State.PaTaRefreshDay = Today_Date
        if Player_State.SaveToArchive ~= nil then
            Save_Succeeded = Player_State:SaveToArchive() == true
        end
    end
    if not Save_Succeeded then
        Player_State.PaTaRefreshDay = Refresh_Day
        if _G.DOREPONCE ~= nil then
            _G.DOREPONCE(Player_State, "PaTaRefreshDay")
        end
        UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncPaTaState", true, true, "爬塔次数保存失败，请重试")
        return
    end

    TeleportToSpawn(self, PaTa_Spawn_Point_ID)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncPaTaState", true, false, "")
end

--[[----------------------同步爬塔次数状态到界面------------------------]]
function UGCPlayerController:Client_SyncPaTaState(Is_Ready, Can_Use_Free, Message)
    self.Client_PaTa_State_Ready = Is_Ready == true
    self.Client_Can_Use_Free_PaTa = Can_Use_Free == true
    if self.PaTa_UI_Instance ~= nil and self.PaTa_UI_Instance.RefreshPaTaButtons ~= nil then
        self.PaTa_UI_Instance:RefreshPaTaButtons(self.Client_PaTa_State_Ready, self.Client_Can_Use_Free_PaTa)
    end
    if Message ~= nil and Message ~= "" then
        L_Com.ShowToast(Message)
    end
end

--[[----------------------用券爬塔传送------------------------]]
function UGCPlayerController:Server_RequestTicketPaTa()
    local Pawn = self.Pawn or self:K2_GetPawn()
    if Pawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetItemCountV2 == nil or
        UGCBackpackSystemV2.RemoveItemV2 == nil then
        return
    end

    local TicketCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(Pawn, PaTa_Ticket_Item_ID)) or 0
    if TicketCount <= 0 then
        return
    end

    local RemovedCount = tonumber(UGCBackpackSystemV2.RemoveItemV2(Pawn, PaTa_Ticket_Item_ID, 1)) or 0
    if RemovedCount <= 0 then
        return
    end

    TeleportToSpawn(self, PaTa_Spawn_Point_ID)
end

--- 打开通关奖励UI
function UGCPlayerController:Client_OpenTowerTopUI()
    if self.TowerTopUIInstance ~= nil then
        self.TowerTopUIInstance:AddToViewport(11000)
        return
    end

    local UIClass = UE.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/UI/TowerTopUI.TowerTopUI_C'))
    if UIClass == nil then
        ugcprint("[UGCPlayerController] TowerTopUI class load failed")
        return
    end

    self.TowerTopUIInstance = UserWidget.NewWidgetObjectBP(self, UIClass)
    if self.TowerTopUIInstance ~= nil then
        self.TowerTopUIInstance:AddToViewport(11000)
    end
end

function UGCPlayerController:Server_ClaimTowerTopReward()
    local pawn = self.Pawn or self:K2_GetPawn()
    if pawn ~= nil then
        UGCBackpackSystemV2.AddItemV2(pawn, 8310071, 1)
    end
    TeleportToSpawn(self, 1)
end

--- 传送玩家到指定坐标
---@param x number
---@param y number
---@param z number
function UGCPlayerController:Server_TeleportToLocation(x, y, z)
    StopCurrentZipLine(self)
    UGCPlayerControllerSystem.TeleportTo(self, x, y, z)
end

--[[---------------------服务端增加任务进度-------------------------]] --
function UGCPlayerController:Server_AddTaskProgress(TaskKey, AddValue)
    if self.bGMResetInProgress == true then
        return
    end
    TaskMgr:AddTaskProgressOnServer(L_Enum.AllTask[TaskKey], tonumber(AddValue) or 1, self)
end

-- WBP_RankingListBtn 更新排行榜服务端--要走官方测试按钮暂时没开
function UGCPlayerController:Server_BeginFlyState()
    local pawn = self:K2_GetPawn()
    if pawn == nil or pawn.BeginFly == nil then
        return
    end

    local EquippedWingItemID = GetWingItemIDFromEquipmentSlot(pawn) or tonumber(pawn.CurrentEquippedWingItemID)
    if not WingItemIDs[EquippedWingItemID] then
        self.bServerFlying = false
        UnrealNetwork.CallUnrealRPC(self, self, "Client_RejectFlyStart")
        return
    end

    -- 存档恢复装备时可能不会触发自定义装备回调；在首次起飞时修复服务端和拥有者客户端缓存。
    pawn.CurrentEquippedWingItemID = EquippedWingItemID
    self.EquippedWingItemID = EquippedWingItemID
    UnrealNetwork.CallUnrealRPC(self, self, "Client_SetEquippedWingItemID", EquippedWingItemID)

    self.bServerFlying = true
    self.bServerFlyMovementModeReady = false
    self.ServerFlyCachedMaxWalkSpeed = nil
    pawn:BeginFly()
end

function UGCPlayerController:Server_RequestEquippedWingState()
    local pawn = self.Pawn or (self.K2_GetPawn ~= nil and self:K2_GetPawn() or nil)
    local EquippedWingItemID = GetWingItemIDFromEquipmentSlot(pawn) or 0
    if pawn ~= nil then
        pawn.CurrentEquippedWingItemID = EquippedWingItemID > 0 and EquippedWingItemID or nil
    end
    self.EquippedWingItemID = EquippedWingItemID > 0 and EquippedWingItemID or nil
    UnrealNetwork.CallUnrealRPC(self, self, "Client_SetEquippedWingItemID", EquippedWingItemID)
end

function UGCPlayerController:Client_SetEquippedWingItemID(ItemID)
    ItemID = tonumber(ItemID) or 0
    self.EquippedWingItemID = ItemID > 0 and ItemID or nil
    local Pawn = self.Pawn or (self.K2_GetPawn ~= nil and self:K2_GetPawn() or nil)
    if Pawn ~= nil then
        Pawn.CurrentEquippedWingItemID = self.EquippedWingItemID
    end
    if ItemID <= 0 and self.FeiUIInstance ~= nil and self.FeiUIInstance.StopFly ~= nil then
        self.FeiUIInstance:StopFly()
    end
end

function UGCPlayerController:Client_RejectFlyStart()
    if self.FeiUIInstance ~= nil and self.FeiUIInstance.StopFly ~= nil then
        self.FeiUIInstance:StopFly()
    end
    self:Client_ShowToast("请装备翅膀")
end

function UGCPlayerController:Server_EndFlyState()
    local pawn = self:K2_GetPawn()
    if pawn == nil or pawn.EndFly == nil then
        return
    end

    self.bServerFlying = false
    self.bServerFlyMovementModeReady = false
    self.ServerFlyCachedMaxWalkSpeed = nil
    pawn:EndFly()
end

local FLY_SPEED = 3600

function UGCPlayerController:Server_FlyMove(DirX, DirY, DirZ, DeltaTime)
    if self.bServerFlying ~= true then
        return
    end

    local pawn = self:K2_GetPawn()
    if pawn == nil then
        return
    end
    if not WingItemIDs[tonumber(pawn.CurrentEquippedWingItemID)] then
        self:Server_StopFlyMove()
        UnrealNetwork.CallUnrealRPC(self, self, "Client_RejectFlyStart")
        return
    end

    local MovementComponent = pawn.CharacterMovement or pawn.MovementComponent
    if MovementComponent ~= nil and self.bServerFlyMovementModeReady ~= true then
        self.bServerFlyMovementModeReady = true
        if MovementComponent.SetMovementMode ~= nil then
            pcall(MovementComponent.SetMovementMode, MovementComponent, 5)
        end
        if MovementComponent.GravityScale ~= nil then
            MovementComponent.GravityScale = 0
        end
        if MovementComponent.MaxFlySpeed ~= nil then
            MovementComponent.MaxFlySpeed = FLY_SPEED
        end
        if MovementComponent.MaxWalkSpeed ~= nil then
            self.ServerFlyCachedMaxWalkSpeed = self.ServerFlyCachedMaxWalkSpeed or MovementComponent.MaxWalkSpeed
            MovementComponent.MaxWalkSpeed = FLY_SPEED
        end
        if MovementComponent.Velocity ~= nil then
            MovementComponent.Velocity = Vector.New(0, 0, 0)
        end
    end

    DirX = tonumber(DirX) or 0
    DirY = tonumber(DirY) or 0
    DirZ = tonumber(DirZ) or 0
    DeltaTime = tonumber(DeltaTime) or 0.016

    if DeltaTime <= 0 or DeltaTime > 0.2 then
        DeltaTime = 0.016
    end

    local Length = math.sqrt(DirX * DirX + DirY * DirY + DirZ * DirZ)
    if Length <= 0.01 then
        return
    end

    DirX = DirX / Length
    DirY = DirY / Length
    DirZ = DirZ / Length

    if pawn.AddMovementInput ~= nil then
        local Direction = Vector.New(DirX, DirY, DirZ)
        local Success = pcall(pawn.AddMovementInput, pawn, Direction, 1.0, true)
        if not Success then
            pcall(pawn.AddMovementInput, pawn, Direction, 1.0)
        end
    end

    if MovementComponent ~= nil and MovementComponent.Velocity ~= nil then
        MovementComponent.Velocity = Vector.New(DirX * FLY_SPEED, DirY * FLY_SPEED, DirZ * FLY_SPEED)
    end
end

function UGCPlayerController:Server_StopFlyMove()
    self.bServerFlying = false
    self.bServerFlyMovementModeReady = false

    local pawn = self:K2_GetPawn()
    if pawn == nil then
        return
    end

    if pawn.EndFly ~= nil then
        pawn:EndFly()
    end

    local MovementComponent = pawn.CharacterMovement or pawn.MovementComponent
    if MovementComponent == nil then
        return
    end

    if MovementComponent.GravityScale ~= nil then
        MovementComponent.GravityScale = 1
    end
    if self.ServerFlyCachedMaxWalkSpeed ~= nil and MovementComponent.MaxWalkSpeed ~= nil then
        MovementComponent.MaxWalkSpeed = self.ServerFlyCachedMaxWalkSpeed
    end
    self.ServerFlyCachedMaxWalkSpeed = nil
    if MovementComponent.Velocity ~= nil then
        MovementComponent.Velocity = Vector.New(0, 0, 0)
    end
    if MovementComponent.SetMovementMode ~= nil then
        pcall(MovementComponent.SetMovementMode, MovementComponent, 1)
    end
end

function UGCPlayerController:Server_UpdateWeaponAttackBonus(ItemID)
    ItemID = tonumber(ItemID)
    local pawn = self:K2_GetPawn()
    if pawn == nil or pawn.ApplyWeaponAttackBonusByItemID == nil then
        return
    end

    local playerState = self.PlayerState

    if ItemID == 0 then
        -- 存档加载前拒绝"卸下武器"（ItemID=0），防止用默认 AttackPower 覆盖服务器正确属性
        if playerState ~= nil and playerState.bArchiveLoaded ~= true then
            return
        end
        pawn.LastClientWeaponAttackItemID = nil
        pawn:ApplyWeaponAttackBonusByItemID(nil, nil, nil, nil, true)
        return
    end

    if WeaponLevelConfig.GetWeaponInfo(ItemID) == nil then
        return
    end

    if WeaponLevelConfig.GetWeaponInfo(pawn.CurrentUsedWeaponItemID) ~= nil and pawn.RefreshWeaponAttackBonus ~= nil then
        pawn:RefreshWeaponAttackBonus(true)
        return
    end

    pawn:ApplyWeaponAttackBonusByItemID(ItemID, nil, nil, nil, false)
end

local function GetVirtualItemManager()
    if UGCGamePartSystem ~= nil and UGCGamePartSystem.IsGamePartLoaded ~= nil and
        UGCGamePartSystem.IsGamePartLoaded("VirtualItemManager") then
        return UGCGamePartSystem.GetGamePartGlobalActor("VirtualItemManager")
    end

    if UGCBlueprintFunctionLibrary ~= nil and UGCGameSystem.GameState ~= nil then
        return UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager")
    end

    return nil
end

local function GetPlayerPawn(PlayerController)
    if PlayerController.Pawn ~= nil then
        return PlayerController.Pawn
    end
    if PlayerController.K2_GetPawn ~= nil then
        return PlayerController:K2_GetPawn()
    end
    return nil
end

local function TryCall(Object, FunctionName, ...)
    if Object == nil then
        return nil
    end

    local Func = Object[FunctionName]
    if Func == nil then
        return nil
    end

    local Success, Result = pcall(Func, Object, ...)
    if Success then
        return Result
    end

    Success, Result = pcall(Func, ...)
    if Success then
        return Result
    end

    return nil
end

local function GetItemIDFromObject(Object)
    if Object == nil then
        return nil
    end

    local DirectItemID = tonumber(Object)
    if DirectItemID ~= nil then
        return DirectItemID
    end
    local ObjectType = type(Object)
    if ObjectType ~= "table" and ObjectType ~= "userdata" then
        return nil
    end

    local FieldNames = {"ItemID", "ItemId", "itemID", "ItemDefineID", "DefineID", "DefineId", "ID", "WPID"}
    for _, FieldName in ipairs(FieldNames) do
        local Success, FieldValue = pcall(function()
            return Object[FieldName]
        end)
        if Success then
            local ItemID = tonumber(FieldValue)
            if ItemID ~= nil then
                return ItemID
            end
        end
    end

    local FunctionNames = {"GetItemID", "GetItemId", "GetItemDefineID", "GetDefineID", "GetDefineId"}
    for _, FunctionName in ipairs(FunctionNames) do
        local ItemID = tonumber(TryCall(Object, FunctionName))
        if ItemID ~= nil then
            return ItemID
        end
    end

    return nil
end

local function GetCurrentHeldWeapon(PlayerController)
    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn == nil or UGCWeaponManagerSystem == nil or UGCWeaponManagerSystem.GetCurrentWeapon == nil then
        return nil
    end

    return UGCWeaponManagerSystem.GetCurrentWeapon(Pawn)
end

local function IsSameWeaponType(Weapon, WeaponInfo)
    if Weapon == nil or WeaponInfo == nil then
        return false
    end

    local HeldWeaponID = tonumber(Weapon.WeaponConfigID or Weapon.WuQiID or Weapon.WeaponTypeID)
    if HeldWeaponID == WeaponInfo.ID then
        return true
    end

    local HeldItemID = nil
    local ItemFieldNames = {"ItemID", "ItemId", "itemID", "ItemDefineID", "DefineID", "DefineId", "WPID"}
    for _, FieldName in ipairs(ItemFieldNames) do
        local Success, FieldValue = pcall(function()
            return Weapon[FieldName]
        end)
        if Success and tonumber(FieldValue) ~= nil then
            HeldItemID = tonumber(FieldValue)
            break
        end
    end
    if HeldItemID == nil then
        local FunctionNames = {"GetItemID", "GetItemId", "GetItemDefineID", "GetDefineID", "GetDefineId"}
        for _, FunctionName in ipairs(FunctionNames) do
            HeldItemID = tonumber(TryCall(Weapon, FunctionName))
            if HeldItemID ~= nil then
                break
            end
        end
    end
    local HeldInfo = WeaponLevelConfig.GetWeaponInfo(HeldItemID)
    if HeldInfo ~= nil and HeldInfo.ID == WeaponInfo.ID then
        return true
    end

    return HeldItemID == nil or tonumber(HeldItemID) == tonumber(WeaponInfo.WPID)
end

local TrySetDisplayNameOnObject

local function GetStoredWeaponLevel(PlayerController, WeaponInfo)
    if WeaponInfo == nil then
        return 1
    end

    PlayerController.WeaponLevelByID = PlayerController.WeaponLevelByID or {}
    local CachedLevel = tonumber(PlayerController.WeaponLevelByID[WeaponInfo.ID])
    if CachedLevel ~= nil then
        return math.max(1, math.min(WeaponInfo.MaxLevel, CachedLevel))
    end

    local PlayerState = PlayerController.PlayerState
    if PlayerState ~= nil and PlayerState.GetWeaponLevel ~= nil and
        (PlayerState.HasWeaponLevel == nil or PlayerState:HasWeaponLevel(WeaponInfo.ID)) then
        return math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(PlayerState:GetWeaponLevel(WeaponInfo.ID)) or 1))
    end

    local Weapon = GetCurrentHeldWeapon(PlayerController)
    if Weapon ~= nil then
        if IsSameWeaponType(Weapon, WeaponInfo) then
            local ActorLevel = tonumber(Weapon.WeaponLevel)
            if ActorLevel ~= nil then
                local Level = math.max(1, math.min(WeaponInfo.MaxLevel, ActorLevel))
                PlayerController.WeaponLevelByID = PlayerController.WeaponLevelByID or {}
                PlayerController.WeaponLevelByID[WeaponInfo.ID] = Level
                return Level
            end
        end
    end

    return math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(PlayerController.WeaponLevelByID[WeaponInfo.ID]) or 1))
end

local function SetStoredWeaponLevel(PlayerController, WeaponInfo, Level)
    if WeaponInfo == nil then
        return
    end

    Level = math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(Level) or 1))
    local PlayerState = PlayerController.PlayerState
    if PlayerState ~= nil and PlayerState.SetWeaponLevel ~= nil then
        PlayerState:SetWeaponLevel(WeaponInfo.ID, Level)
    end
    PlayerController.WeaponLevelByID = PlayerController.WeaponLevelByID or {}
    PlayerController.WeaponLevelByID[WeaponInfo.ID] = Level

    local AttackPercent = WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponInfo.ID, Level)
    local DisplayName = WeaponLevelConfig.BuildDisplayName(WeaponInfo.WPID, Level)
    local Weapon = GetCurrentHeldWeapon(PlayerController)
    if Weapon ~= nil then
        if IsSameWeaponType(Weapon, WeaponInfo) then
            Weapon.WeaponLevel = Level
            Weapon.WeaponConfigID = WeaponInfo.ID
            Weapon.WeaponLevel_0 = tonumber(AttackPercent) or 0
            TrySetDisplayNameOnObject(Weapon, DisplayName)
        end
    end

end

local function GetWeaponLevelFromItemDefineID(ItemDefineID, WeaponInfo, StackIndex)
    if ItemDefineID == nil or WeaponInfo == nil then
        return nil
    end
    if UGCItemSystemV2 == nil or UGCItemSystemV2.LoadItemCustomData == nil then
        return nil
    end

    StackIndex = math.max(1, tonumber(StackIndex) or 1)
    local Success, CustomData = pcall(UGCItemSystemV2.LoadItemCustomData, ItemDefineID)
    if Success and type(CustomData) == "table" then
        local Level = nil
        if type(CustomData.WeaponLevelsByStackIndex) == "table" then
            Level = tonumber(CustomData.WeaponLevelsByStackIndex[tostring(StackIndex)] or
                                 CustomData.WeaponLevelsByStackIndex[StackIndex])
        end
        Level = Level or tonumber(CustomData.WeaponLevel or CustomData.StrengthenLv)
        if Level ~= nil then
            return math.max(1, math.min(WeaponInfo.MaxLevel, Level))
        end
    end

    return nil
end

local function SetWeaponLevelToItemDefineID(ItemDefineID, WeaponInfo, Level, StackIndex)
    if ItemDefineID == nil or WeaponInfo == nil then
        return false
    end
    if UGCItemSystemV2 == nil or UGCItemSystemV2.LoadItemCustomData == nil or UGCItemSystemV2.SaveItemCustomData == nil then
        return false
    end

    Level = math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(Level) or 1))
    StackIndex = math.max(1, tonumber(StackIndex) or 1)
    local Success, CustomData = pcall(UGCItemSystemV2.LoadItemCustomData, ItemDefineID)
    if not Success or type(CustomData) ~= "table" then
        CustomData = {}
    end
    CustomData.WeaponLevelsByStackIndex = CustomData.WeaponLevelsByStackIndex or {}
    CustomData.WeaponLevelsByStackIndex[tostring(StackIndex)] = Level
    CustomData.WeaponLevel = Level
    CustomData.StrengthenLv = Level
    CustomData.TemplateID = WeaponInfo.WPID
    return pcall(UGCItemSystemV2.SaveItemCustomData, ItemDefineID, CustomData)
end

local function IsItemDefineIDInBackpack(PlayerController, ItemDefineID)
    if ItemDefineID == nil then
        return false
    end
    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn == nil or UGCBackpackSystemV2 == nil then
        return false
    end

    if UGCBackpackSystemV2.VerifyItemDefineIDInBackpack ~= nil then
        local Success, Result = pcall(UGCBackpackSystemV2.VerifyItemDefineIDInBackpack, Pawn, ItemDefineID)
        if Success then
            return Result == true or (tonumber(Result) or 0) ~= 0
        end
    end

    if UGCBackpackSystemV2.GetItemCountByDefineIDV2 ~= nil then
        local Success, Count, Count2 = pcall(UGCBackpackSystemV2.GetItemCountByDefineIDV2, Pawn, ItemDefineID)
        if Success then
            return (tonumber(Count2) or tonumber(Count) or 0) > 0
        end
    end

    return false
end

local function GetItemIDFromDefineID(ItemDefineID)
    if ItemDefineID == nil then
        return nil
    end
    local DefineIDType = type(ItemDefineID)
    if DefineIDType == "number" or DefineIDType == "string" then
        return tonumber(ItemDefineID)
    elseif DefineIDType ~= "table" and DefineIDType ~= "userdata" then
        return nil
    end

    local FieldNames = {"TypeSpecificID", "ItemID", "ItemId", "itemID", "ID", "WPID"}
    for _, FieldName in ipairs(FieldNames) do
        local Success, FieldValue = pcall(function()
            return ItemDefineID[FieldName]
        end)
        if Success then
            local ItemID = tonumber(FieldValue)
            if ItemID ~= nil then
                return ItemID
            end
        end
    end

    return GetItemIDFromObject(ItemDefineID)
end

TrySetDisplayNameOnObject = function(Object, DisplayName)
    if Object == nil or DisplayName == nil then
        return false
    end
    if type(Object) ~= "table" then
        return false
    end

    local bChanged = false
    local SetterNames = {"SetItemName", "SetName", "SetDisplayName", "SetItemDisplayName", "SetCustomName",
                         "SetItemNameText"}
    for _, FunctionName in ipairs(SetterNames) do
        local Func = Object[FunctionName]
        if Func ~= nil then
            local Success, Result = pcall(Func, Object, DisplayName)
            if not Success then
                Success, Result = pcall(Func, DisplayName)
            end
            bChanged = bChanged or (Success and Result ~= false)
        end
    end

    local FieldNames = {"ItemName", "Name", "DisplayName", "ItemDisplayName", "ItemNameText", "CustomName",
                        "DisplayNameText"}
    for _, FieldName in ipairs(FieldNames) do
        local Success = pcall(function()
            Object[FieldName] = DisplayName
        end)
        bChanged = bChanged or Success
    end

    local NestedNames = {"ItemData", "ItemConfig", "Config", "ItemDefine", "ItemTableData"}
    for _, NestedName in ipairs(NestedNames) do
        local NestedObject = Object[NestedName]
        if NestedObject ~= nil then
            bChanged = TrySetDisplayNameOnObject(NestedObject, DisplayName) or bChanged
        end
    end

    return bChanged
end

local function GetBackpackComponent(Pawn, PlayerController)
    if Pawn ~= nil then
        return Pawn.BackpackComponent or Pawn.BackpackComponentV2 or Pawn.BP_BackpackComponentV2
    end
    if PlayerController ~= nil then
        return PlayerController.BackpackComponent or PlayerController.BackpackComponentV2 or
                   PlayerController.BP_BackpackComponentV2
    end
    return nil
end

local function TrySetDisplayNameByBackpackComponent(BackpackComponent, ItemDefineID, DisplayName)
    if BackpackComponent == nil or ItemDefineID == nil or DisplayName == nil then
        return false
    end

    local SetterNames = {"SetItemNameV2", "SetItemDisplayNameV2", "SetDisplayNameV2", "SetCustomNameV2",
                         "UpdateItemNameV2", "UpdateItemDisplayNameV2"}
    for _, FunctionName in ipairs(SetterNames) do
        local Func = BackpackComponent[FunctionName]
        if Func ~= nil then
            local Success, Result = pcall(Func, BackpackComponent, ItemDefineID, DisplayName)
            if Success and Result ~= false then
                return true
            end
        end
    end

    return false
end

function UGCPlayerController:SyncWeaponBackpackNames()
    local Pawn = GetPlayerPawn(self)
    if Pawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetAllItemDefineIDsV2 == nil then
        return
    end
    local AllItemData = UGCBackpackSystemV2.GetAllItemDefineIDsV2(Pawn)
    if AllItemData == nil then
        return
    end

    local BackpackComponent = GetBackpackComponent(Pawn, self)
    for _, ItemDefineID in pairs(AllItemData) do
        local ItemID = GetItemIDFromDefineID(ItemDefineID)
        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
        if WeaponInfo ~= nil then
            local Level = tonumber(WeaponInfo.Level) or GetWeaponLevelFromItemDefineID(ItemDefineID, WeaponInfo, 1) or 1
            Level = tonumber(Level) or 1
            Level = math.max(1, math.min(WeaponInfo.MaxLevel, Level))
            local DisplayName = WeaponLevelConfig.BuildDisplayName(WeaponInfo.WPID, Level)
            TrySetDisplayNameOnObject(ItemDefineID, DisplayName)
            TrySetDisplayNameByBackpackComponent(BackpackComponent, ItemDefineID, DisplayName)
        end
    end
end

local function GetItemCount(PlayerController, ItemID)
    local BackpackCount = 0
    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        BackpackCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(Pawn, ItemID)) or 0
    end

    local VirtualCount = 0
    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil and VirtualItemManager.GetItemNum ~= nil then
        local Success, Result = pcall(VirtualItemManager.GetItemNum, VirtualItemManager, ItemID, PlayerController)
        if Success and Result ~= nil then
            VirtualCount = tonumber(Result) or 0
        end
    end

    if BackpackCount > VirtualCount then
        return BackpackCount
    end

    return VirtualCount
end

function UGCPlayerController:Server_RequestSoulRingInventory()
    local Entries = {}
    for _, ItemID in ipairs(SoulRingItemIDs) do
        local Success, Count = pcall(GetItemCount, self, ItemID)
        Count = Success and (tonumber(Count) or 0) or 0
        if Count > 0 then
            table.insert(Entries, tostring(ItemID) .. ":" .. tostring(math.floor(Count)))
        end
    end
    local Snapshot = table.concat(Entries, ",")
    ugcprint("[SoulRingInventory:SERVER] snapshot=" .. Snapshot)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncSoulRingInventory", Snapshot)
end

function UGCPlayerController:Client_SyncSoulRingInventory(Snapshot)
    ugcprint("[SoulRingInventory:CLIENT] snapshot=" .. tostring(Snapshot))
    local MainUI = self.MainUIInstance
    local SoulRingUI = MainUI and (MainUI.UI017Instance or MainUI.UI15Instance)
        or self.UI017Instance or self.UI15Instance
    if SoulRingUI ~= nil and SoulRingUI.ApplySoulRingInventorySnapshot ~= nil then
        SoulRingUI:ApplySoulRingInventorySnapshot(Snapshot)
    end
end

local function BuildBackpackSoulRingSnapshot(PlayerController)
    local Pawn = GetPlayerPawn(PlayerController)
    local Entries = {}
    if Pawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetItemCountV2 == nil then
        return ""
    end

    for _, ItemID in ipairs(SoulRingItemIDs) do
        local Success, Count = pcall(UGCBackpackSystemV2.GetItemCountV2, Pawn, ItemID)
        Count = Success and math.max(0, math.floor(tonumber(Count) or 0)) or 0
        if Count > 0 then
            table.insert(Entries, tostring(ItemID) .. ":" .. tostring(Count))
        end
    end
    return table.concat(Entries, ",")
end

function UGCPlayerController:Server_ConvertAllSoulRingsToStardust()
    if self.bSoulRingConversionInProgress == true then
        return
    end
    self.bSoulRingConversionInProgress = true

    local Pawn = GetPlayerPawn(self)
    local RemovedItems = {}
    local StardustReward = 0
    local bBackpackAvailable = Pawn ~= nil and UGCBackpackSystemV2 ~= nil and
        UGCBackpackSystemV2.GetItemCountV2 ~= nil and
        UGCBackpackSystemV2.RemoveItemV2 ~= nil and
        UGCBackpackSystemV2.AddItemV2 ~= nil
    if bBackpackAvailable then
        for Index, ItemID in ipairs(SoulRingItemIDs) do
            local CountOK, Count = pcall(UGCBackpackSystemV2.GetItemCountV2, Pawn, ItemID)
            Count = CountOK and math.max(0, math.floor(tonumber(Count) or 0)) or 0
            if Count > 0 then
                local RemoveOK, RemovedCount = pcall(
                    UGCBackpackSystemV2.RemoveItemV2, Pawn, ItemID, Count)
                RemovedCount = RemoveOK and math.max(0, math.floor(tonumber(RemovedCount) or 0)) or 0
                if RemovedCount > 0 then
                    table.insert(RemovedItems, {ItemID = ItemID, Count = RemovedCount})
                    StardustReward = StardustReward + RemovedCount * Index
                end
            end
        end
    end

    local bSuccess = StardustReward > 0
    local Message = "没有可转换的魂环"
    if bSuccess then
        local AddOK, AddedCount = pcall(
            UGCBackpackSystemV2.AddItemV2, Pawn, STARDUST_ITEM_ID, StardustReward)
        AddedCount = AddOK and math.max(0, math.floor(tonumber(AddedCount) or 0)) or 0
        bSuccess = AddedCount == StardustReward
        if bSuccess then
            Message = "成功转换为" .. tostring(StardustReward) .. "个星尘"
        else
            if AddedCount > 0 then
                pcall(UGCBackpackSystemV2.RemoveItemV2, Pawn, STARDUST_ITEM_ID, AddedCount)
            end
            for _, RemovedItem in ipairs(RemovedItems) do
                pcall(UGCBackpackSystemV2.AddItemV2, Pawn, RemovedItem.ItemID, RemovedItem.Count)
            end
            StardustReward = 0
            Message = "转换失败，魂环已返还"
        end
    elseif not bBackpackAvailable then
        Message = "背包暂不可用，请稍后重试"
    end

    local StardustCount = 0
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        local CountOK, Count = pcall(UGCBackpackSystemV2.GetItemCountV2, Pawn, STARDUST_ITEM_ID)
        StardustCount = CountOK and math.max(0, math.floor(tonumber(Count) or 0)) or 0
    end
    local Snapshot = BuildBackpackSoulRingSnapshot(self)
    self.bSoulRingConversionInProgress = false
    UnrealNetwork.CallUnrealRPC(
        self, self, "Client_SoulRingConversionResult",
        bSuccess, StardustReward, StardustCount, Snapshot, Message)
end

function UGCPlayerController:Server_ConvertSelectedSoulRingToStardust(ItemID)
    if self.bSoulRingConversionInProgress == true then
        return
    end
    self.bSoulRingConversionInProgress = true

    ItemID = tonumber(ItemID)
    local StardustRate = SoulRingStardustRates[ItemID]
    local Pawn = GetPlayerPawn(self)
    local bBackpackAvailable = Pawn ~= nil and UGCBackpackSystemV2 ~= nil and
        UGCBackpackSystemV2.GetItemCountV2 ~= nil and
        UGCBackpackSystemV2.RemoveItemV2 ~= nil and
        UGCBackpackSystemV2.AddItemV2 ~= nil
    local bSuccess = false
    local StardustReward = 0
    local Message = "请选择要转换的魂环"

    if StardustRate ~= nil and bBackpackAvailable then
        local CountOK, Count = pcall(UGCBackpackSystemV2.GetItemCountV2, Pawn, ItemID)
        Count = CountOK and math.max(0, math.floor(tonumber(Count) or 0)) or 0
        if Count > 0 then
            local RemoveOK, RemovedCount = pcall(
                UGCBackpackSystemV2.RemoveItemV2, Pawn, ItemID, Count)
            RemovedCount = RemoveOK and math.max(0, math.floor(tonumber(RemovedCount) or 0)) or 0
            if RemovedCount > 0 then
                StardustReward = RemovedCount * StardustRate
                local AddOK, AddedCount = pcall(
                    UGCBackpackSystemV2.AddItemV2, Pawn, STARDUST_ITEM_ID, StardustReward)
                AddedCount = AddOK and math.max(0, math.floor(tonumber(AddedCount) or 0)) or 0
                bSuccess = AddedCount == StardustReward
                if bSuccess then
                    Message = "成功转换为" .. tostring(StardustReward) .. "个星尘"
                else
                    if AddedCount > 0 then
                        pcall(UGCBackpackSystemV2.RemoveItemV2, Pawn, STARDUST_ITEM_ID, AddedCount)
                    end
                    pcall(UGCBackpackSystemV2.AddItemV2, Pawn, ItemID, RemovedCount)
                    StardustReward = 0
                    Message = "转换失败，魂环已返还"
                end
            else
                Message = "魂环扣除失败，请稍后重试"
            end
        else
            Message = "选中的魂环已不在背包中"
        end
    elseif StardustRate ~= nil and not bBackpackAvailable then
        Message = "背包暂不可用，请稍后重试"
    end

    local StardustCount = 0
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        local CountOK, Count = pcall(UGCBackpackSystemV2.GetItemCountV2, Pawn, STARDUST_ITEM_ID)
        StardustCount = CountOK and math.max(0, math.floor(tonumber(Count) or 0)) or 0
    end
    local Snapshot = BuildBackpackSoulRingSnapshot(self)
    self.bSoulRingConversionInProgress = false
    UnrealNetwork.CallUnrealRPC(
        self, self, "Client_SoulRingConversionResult",
        bSuccess, StardustReward, StardustCount, Snapshot, Message)
end

function UGCPlayerController:Client_SoulRingConversionResult(
    bSuccess, StardustReward, StardustCount, Snapshot, Message)
    local MainUI = self.MainUIInstance
    local SoulRingUI = MainUI and (MainUI.UI017Instance or MainUI.UI15Instance)
        or self.UI017Instance or self.UI15Instance
    if SoulRingUI ~= nil and SoulRingUI.ApplySoulRingConversionResult ~= nil then
        SoulRingUI:ApplySoulRingConversionResult(
            bSuccess, StardustReward, StardustCount, Snapshot)
    end
    if Message ~= nil and tostring(Message) ~= "" then
        L_Com.ShowToast(tostring(Message))
    end
end

local function BuildWeaponRefineSnapshot(PlayerState)
    local Entries = {}
    local StatsByGun = PlayerState ~= nil and PlayerState.GetWeaponRefineStats ~= nil and
        PlayerState:GetWeaponRefineStats() or {}
    for GunIndex = 1, WeaponRefineConfig.MAX_GUN_COUNT do
        local Stats = StatsByGun[GunIndex] or StatsByGun[tostring(GunIndex)]
        local Attack = type(Stats) == "table" and tonumber(Stats.Attack) or nil
        local AttackSpeed = type(Stats) == "table" and tonumber(Stats.AttackSpeed) or nil
        if Attack ~= nil and AttackSpeed ~= nil then
            table.insert(Entries, tostring(GunIndex) .. ":" ..
                WeaponRefineConfig.FormatNumber(Attack) .. ":" ..
                WeaponRefineConfig.FormatNumber(AttackSpeed))
        end
    end
    return table.concat(Entries, ",")
end

local function GetBackpackItemCount(Pawn, ItemID)
    if Pawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetItemCountV2 == nil then
        return 0
    end
    local Success, Count = pcall(UGCBackpackSystemV2.GetItemCountV2, Pawn, ItemID)
    return Success and math.max(0, math.floor(tonumber(Count) or 0)) or 0
end

function UGCPlayerController:Server_RequestWeaponRefineState()
    local PlayerState = self.PlayerState
    if PlayerState == nil or PlayerState.bArchiveLoaded ~= true then
        return false
    end
    local Pawn = GetPlayerPawn(self)
    local Pending = self.PendingWeaponRefine
    local GunIndex = Pending ~= nil and Pending.GunIndex or 0
    local Attack = Pending ~= nil and Pending.Attack or 0
    local AttackSpeed = Pending ~= nil and Pending.AttackSpeed or 0
    UnrealNetwork.CallUnrealRPC(self, self, "Client_WeaponRefineResult", true,
        GunIndex, Attack, AttackSpeed,
        GetBackpackItemCount(Pawn, WeaponRefineConfig.STARDUST_ITEM_ID),
        BuildWeaponRefineSnapshot(PlayerState), "")
    return true
end

function UGCPlayerController:Server_RefineOrbitWeapon(GunIndex, bLockAttack, bLockAttackSpeed)
    if self.bWeaponRefineInProgress == true then
        return false
    end
    self.bWeaponRefineInProgress = true

    GunIndex = math.floor(tonumber(GunIndex) or 0)
    bLockAttack = bLockAttack == true
    bLockAttackSpeed = bLockAttackSpeed == true
    local PlayerState = self.PlayerState
    local Pawn = GetPlayerPawn(self)
    local PlayerLevel = PlayerState ~= nil and PlayerState.GetPlayerLevel ~= nil and
        math.floor(tonumber(PlayerState:GetPlayerLevel()) or 0) or 0
    local UnlockedCount = math.max(1, math.min(WeaponRefineConfig.MAX_GUN_COUNT, PlayerLevel))
    local Row = WeaponRefineConfig.GetRow(GunIndex, UnlockedCount)
    local bSuccess = false
    local Attack, AttackSpeed = 0, 0
    local Message = "洗练失败，请稍后重试"

    EnsurePlayerStateArchiveUID(self)
    if PlayerState == nil or PlayerState.bArchiveLoaded ~= true then
        Message = "存档尚未加载，请稍后重试"
    elseif GunIndex < 1 or GunIndex > WeaponRefineConfig.MAX_GUN_COUNT or GunIndex > PlayerLevel then
        Message = "该武器尚未解锁"
    elseif bLockAttack and bLockAttackSpeed then
        Message = "攻击和攻速不能同时锁定"
    elseif self.PendingWeaponRefine ~= nil then
        Message = "请先确认或放弃上一次洗练属性"
    elseif Row == nil then
        Message = "洗练配置读取失败"
    elseif Pawn == nil or UGCBackpackSystemV2 == nil or
        UGCBackpackSystemV2.GetItemCountV2 == nil or UGCBackpackSystemV2.RemoveItemV2 == nil then
        Message = "背包暂不可用，请稍后重试"
    else
        local Cost = math.max(1, math.floor(tonumber(Row.Cost) or 1))
        local StardustCount = GetBackpackItemCount(Pawn, WeaponRefineConfig.STARDUST_ITEM_ID)
        if StardustCount < Cost then
            Message = "星尘不足，需要" .. tostring(Cost) .. "个"
        else
            local RemoveOK, RemovedCount = pcall(UGCBackpackSystemV2.RemoveItemV2, Pawn,
                WeaponRefineConfig.STARDUST_ITEM_ID, Cost)
            RemovedCount = RemoveOK and math.max(0, math.floor(tonumber(RemovedCount) or 0)) or 0
            if RemovedCount ~= Cost then
                if RemovedCount > 0 and UGCBackpackSystemV2.AddItemV2 ~= nil then
                    pcall(UGCBackpackSystemV2.AddItemV2, Pawn,
                        WeaponRefineConfig.STARDUST_ITEM_ID, RemovedCount)
                end
                Message = "星尘扣除失败，请稍后重试"
            else
                Attack, AttackSpeed = WeaponRefineConfig.Roll(Row)
                local CurrentAttack, CurrentAttackSpeed =
                    WeaponRefineConfig.GetCurrentStats(PlayerState, GunIndex, UnlockedCount)
                if bLockAttack then
                    Attack = CurrentAttack
                end
                if bLockAttackSpeed then
                    AttackSpeed = CurrentAttackSpeed
                end
                self.PendingWeaponRefine = {
                    GunIndex = GunIndex,
                    Attack = Attack,
                    AttackSpeed = AttackSpeed,
                    UnlockedCount = UnlockedCount
                }
                bSuccess = true
                Message = "洗练完成，请确认是否更换属性"
            end
        end
    end

    local Snapshot = BuildWeaponRefineSnapshot(PlayerState)
    local StardustCount = GetBackpackItemCount(Pawn, WeaponRefineConfig.STARDUST_ITEM_ID)
    self.bWeaponRefineInProgress = false
    UnrealNetwork.CallUnrealRPC(self, self, "Client_WeaponRefineResult", bSuccess, GunIndex,
        Attack, AttackSpeed, StardustCount, Snapshot, Message)
    return bSuccess
end

function UGCPlayerController:Server_ResolveWeaponRefine(bAccept)
    local Pending = self.PendingWeaponRefine
    local PlayerState = self.PlayerState
    local Pawn = GetPlayerPawn(self)
    local bSuccess = false
    local bAccepted = bAccept == true
    local Message = "没有待处理的洗练属性"

    if Pending ~= nil then
        if not bAccepted then
            self.PendingWeaponRefine = nil
            bSuccess = true
            Message = "已放弃新洗练属性"
        elseif PlayerState == nil or PlayerState.bArchiveLoaded ~= true or
            PlayerState.SetWeaponRefineStat == nil then
            Message = "存档尚未加载，请稍后重试"
        else
            bSuccess = PlayerState:SetWeaponRefineStat(Pending.GunIndex,
                Pending.Attack, Pending.AttackSpeed) == true
            if bSuccess then
                self.PendingWeaponRefine = nil
                Message = "新洗练属性已更换"
                if self.OrbitWeaponSelectedGunIndex == Pending.GunIndex and
                    Pawn ~= nil and Pawn.SetOrbitWeaponActiveGun ~= nil then
                    self.OrbitWeaponDamagePercent = Pending.Attack
                    Pawn:SetOrbitWeaponActiveGun(Pending.UnlockedCount, Pending.Attack)
                end
            else
                Message = "属性保存失败，请重试"
            end
        end
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_WeaponRefineDecisionResult",
        bSuccess, bAccepted,
        GetBackpackItemCount(Pawn, WeaponRefineConfig.STARDUST_ITEM_ID),
        BuildWeaponRefineSnapshot(PlayerState), Message)
    return bSuccess
end

function UGCPlayerController:Client_WeaponRefineResult(bSuccess, GunIndex, Attack, AttackSpeed,
    StardustCount, Snapshot, Message)
    local MainUI = self.MainUIInstance
    local WeaponUI = MainUI and MainUI.UI017Instance or self.UI017Instance
    if WeaponUI ~= nil and WeaponUI.ApplyWeaponRefineResult ~= nil then
        WeaponUI:ApplyWeaponRefineResult(bSuccess, GunIndex, Attack, AttackSpeed,
            StardustCount, Snapshot)
    end
    if Message ~= nil and tostring(Message) ~= "" then
        L_Com.ShowToast(tostring(Message))
    end
end

function UGCPlayerController:Client_WeaponRefineDecisionResult(bSuccess, bAccepted,
    StardustCount, Snapshot, Message)
    local MainUI = self.MainUIInstance
    local WeaponUI = MainUI and MainUI.UI017Instance or self.UI017Instance
    if WeaponUI ~= nil and WeaponUI.ApplyWeaponRefineDecisionResult ~= nil then
        WeaponUI:ApplyWeaponRefineDecisionResult(bSuccess, bAccepted, StardustCount, Snapshot)
    end
    if Message ~= nil and tostring(Message) ~= "" then
        L_Com.ShowToast(tostring(Message))
    end
end

local function AddItem(PlayerController, ItemID, Count)
    Count = tonumber(Count) or 0
    if Count <= 0 then
        return true
    end

    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.AddItemV2 ~= nil then
        local Success, Result = pcall(UGCBackpackSystemV2.AddItemV2, Pawn, ItemID, Count)
        print("[ShopV2:SERVER] BackpackV2 path: OK=" .. tostring(Success) .. " Result=" .. tostring(Result))
        if Success and Result ~= false and Result ~= 0 then
            if WeaponLevelConfig.GetWeaponInfo(ItemID) ~= nil and Pawn.RefreshWeaponAttackBonus ~= nil then
                Pawn:RefreshWeaponAttackBonus(true)
                if Pawn.ForceRefreshPropertySnapshot ~= nil then
                    Pawn:ForceRefreshPropertySnapshot()
                end
            end
            return true
        end
    else
        print("[ShopV2:SERVER] BackpackV2 path: UNAVAILABLE (Pawn=" .. tostring(Pawn) .. " BPS=" ..
                  tostring(UGCBackpackSystemV2) .. ")")
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil and VirtualItemManager.AddVirtualItem ~= nil then
        local Success, Result = pcall(VirtualItemManager.AddVirtualItem, VirtualItemManager, PlayerController, ItemID,
            Count)
        print("[ShopV2:SERVER] Virtual path: OK=" .. tostring(Success) .. " Result=" .. tostring(Result))
        if Success and Result ~= false then
            if Pawn ~= nil and WeaponLevelConfig.GetWeaponInfo(ItemID) ~= nil and Pawn.RefreshWeaponAttackBonus ~= nil then
                Pawn:RefreshWeaponAttackBonus(true)
                if Pawn.ForceRefreshPropertySnapshot ~= nil then
                    Pawn:ForceRefreshPropertySnapshot()
                end
            end
            return true
        end
    end

    print("[ShopV2:SERVER] All paths FAILED")
    return false
end

local function TryRefundForgeFailMaterials(PlayerController, Cost)
    if Cost == nil then
        return false
    end

    if math.random(1, 100) > FORGE_FAIL_REFUND_RATE then
        return false
    end

    local HGRJRefund = math.floor((tonumber(Cost.HGRJ) or 0) * FORGE_FAIL_REFUND_PERCENT)
    local QNHHRefund = math.floor((tonumber(Cost.QNHH) or 0) * FORGE_FAIL_REFUND_PERCENT)

    if HGRJRefund > 0 then
        AddItem(PlayerController, ForgeMaterialItemIDs.HGRJ, HGRJRefund)
    end
    if QNHHRefund > 0 then
        AddItem(PlayerController, ForgeMaterialItemIDs.QNHH, QNHHRefund)
    end

    ugcprint("[UGCPlayerController:TryRefundForgeFailMaterials] HGRJ=" .. tostring(HGRJRefund) .. ", QNHH=" ..
                 tostring(QNHHRefund))
    return HGRJRefund > 0 or QNHHRefund > 0
end

local function RemoveItem(PlayerController, ItemID, Count)
    Count = tonumber(Count) or 0
    if Count <= 0 then
        return true
    end

    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.RemoveItemV2 ~= nil then
        local Success, Result = pcall(UGCBackpackSystemV2.RemoveItemV2, Pawn, ItemID, Count)
        if Success and Result ~= false and Result ~= 0 then
            return true
        end
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil then
        local VirtualCount = 0
        if VirtualItemManager.GetItemNum ~= nil then
            local CountSuccess, CountResult = pcall(VirtualItemManager.GetItemNum, VirtualItemManager, ItemID,
                PlayerController)
            if CountSuccess then
                VirtualCount = tonumber(CountResult) or 0
            end
        end

        local Func = VirtualItemManager.RemoveVirtualItem or VirtualItemManager.RemoveItem
        if Func ~= nil and VirtualCount >= Count then
            local Success, Result = pcall(Func, VirtualItemManager, PlayerController, ItemID, Count)
            if Success and Result ~= false and Result ~= 0 then
                return true
            end
        end
    end

    return false
end

local function FindBackpackItemDefineID(PlayerController, ItemID)
    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetAllItemDefineIDsV2 == nil then
        return nil
    end

    local AllItemDefineIDs = UGCBackpackSystemV2.GetAllItemDefineIDsV2(Pawn)
    if AllItemDefineIDs == nil then
        return nil
    end
    for _, ItemDefineID in pairs(AllItemDefineIDs) do
        if tonumber(GetItemIDFromDefineID(ItemDefineID)) == tonumber(ItemID) then
            return ItemDefineID
        end
    end
    return nil
end

local function FindHeldWeaponItemIDBySeries(PlayerController, SeriesKey)
    if SeriesKey == nil then
        return nil
    end

    local BestItemID = nil
    local BestLevel = -1
    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetAllItemDefineIDsV2 ~= nil then
        local AllItemDefineIDs = UGCBackpackSystemV2.GetAllItemDefineIDsV2(Pawn)
        if AllItemDefineIDs ~= nil then
            for _, ItemDefineID in pairs(AllItemDefineIDs) do
                local ItemID = tonumber(GetItemIDFromDefineID(ItemDefineID))
                local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
                if WeaponInfo ~= nil and WeaponInfo.SeriesKey == SeriesKey and GetItemCount(PlayerController, ItemID) >
                    0 then
                    local Level = tonumber(WeaponInfo.Level) or 1
                    if Level > BestLevel then
                        BestItemID = ItemID
                        BestLevel = Level
                    end
                end
            end
        end
    end

    if BestItemID ~= nil then
        return BestItemID
    end

    for _, Weapon in ipairs(WeaponLevelConfig.GetAllWeapons()) do
        if Weapon.SeriesKey == SeriesKey then
            local LevelItemIDs = Weapon.LevelItemIDs or {}
            for Level, ItemID in pairs(LevelItemIDs) do
                ItemID = tonumber(ItemID)
                Level = tonumber(Level) or 1
                if ItemID ~= nil and Level > BestLevel and GetItemCount(PlayerController, ItemID) > 0 then
                    BestItemID = ItemID
                    BestLevel = Level
                end
            end
            local BaseItemID = tonumber(Weapon.WPID)
            if BaseItemID ~= nil and 1 > BestLevel and GetItemCount(PlayerController, BaseItemID) > 0 then
                BestItemID = BaseItemID
                BestLevel = 1
            end
        end
    end

    return BestItemID
end

local function GetResultItemIDByLevel(WeaponInfo, ResultLevel, FallbackItemID)
    if WeaponInfo == nil then
        return FallbackItemID
    end

    local Weapon = WeaponLevelConfig.GetWeaponByID(WeaponInfo.ID)
    local LevelItemIDs = Weapon ~= nil and Weapon.LevelItemIDs or nil
    ResultLevel = tonumber(ResultLevel) or tonumber(WeaponInfo.Level) or 1
    if LevelItemIDs ~= nil and LevelItemIDs[ResultLevel] ~= nil then
        return LevelItemIDs[ResultLevel]
    end

    return FallbackItemID
end

local function TryDisuseBackpackItem(PlayerController, ItemDefineID)
    if ItemDefineID == nil then
        return false
    end

    local Pawn = GetPlayerPawn(PlayerController)
    for _, FunctionName in ipairs(DisuseItemFunctionNames) do
        local Func = UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2[FunctionName] or nil
        if Func ~= nil then
            local Success, Result = pcall(Func, Pawn, ItemDefineID)
            if Success and Result ~= false and Result ~= 0 then
                return true
            end
        end
    end

    local BackpackComponent = GetBackpackComponent(Pawn, PlayerController)
    for _, FunctionName in ipairs(DisuseItemFunctionNames) do
        local Func = BackpackComponent ~= nil and BackpackComponent[FunctionName] or nil
        if Func ~= nil then
            local Success, Result = pcall(Func, BackpackComponent, ItemDefineID)
            if Success and Result ~= false and Result ~= 0 then
                return true
            end
        end
    end
    return false
end

--- 一键吃掉背包里的魂环
function UGCPlayerController:Server_EatAllSoulRings()
    local Pawn = GetPlayerPawn(self)
    if Pawn == nil then
        return
    end

    local LastBaseAttack = nil
    local LastBaseMaxHp = nil

    for _, ItemID in ipairs(SoulRingItemIDs) do
        local Count = GetItemCount(self, ItemID)
        if Count > 0 and RemoveItem(self, ItemID, Count) then
            local Success, _, NewBaseAttack, NewBaseMaxHp = pcall(L_Com.UseHunHuan, Pawn, ItemID, Count)
            if Success then
                LastBaseAttack = NewBaseAttack
                LastBaseMaxHp = NewBaseMaxHp
                TaskMgr:AddTaskProgressOnServer(L_Enum.AllTask.UseHunHuan, Count, self)
            else
                AddItem(self, ItemID, Count)
                ugcprint("[UGCPlayerController:Server_EatAllSoulRings] UseHunHuan failed: " .. tostring(ItemID))
            end
        end
    end

    if LastBaseAttack ~= nil and LastBaseMaxHp ~= nil then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_RefreshProperty", LastBaseAttack, LastBaseMaxHp)
    end
end

--- 商城购买后通过 V2 API 把物品加到背包，并清理虚拟物品（必须在服务端执行）
---@param BackpackItemID number 背包物品ID
---@param Num number 数量
---@param VirtualItemID number 源虚拟物品ID（用于清理）
function UGCPlayerController:Server_AddShopItemToBackpackV2(BackpackItemID, Num, VirtualItemID)
    BackpackItemID = tonumber(BackpackItemID)
    Num = tonumber(Num) or 1
    VirtualItemID = tonumber(VirtualItemID)
    if BackpackItemID == nil or Num <= 0 then
        print("[ShopV2:SERVER] Invalid params: " .. tostring(BackpackItemID) .. " x " .. tostring(Num))
        return
    end
    local PlayerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self)
    if PlayerPawn == nil then
        print("[ShopV2:SERVER] PlayerPawn nil")
        return
    end
    if BackpackCapacityUtil ~= nil and BackpackCapacityUtil.IsFullIncludingEquipped ~= nil and
        BackpackCapacityUtil.IsFullIncludingEquipped(PlayerPawn) == true then
        print("[ShopV2:SERVER] Backpack full including equipped items, keeping virtual item as fallback")
        UnrealNetwork.CallUnrealRPC(self, self, "Client_ShowToast", "背包已满")
        return
    end
    local before = UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, BackpackItemID)
    print("[ShopV2:SERVER] BEFORE AddItemV2: ItemID=" .. tostring(BackpackItemID) .. " count=" .. tostring(before))
    local AddSucceeded, ret = pcall(UGCBackpackSystemV2.AddItemV2, PlayerPawn, BackpackItemID, Num)
    local AddedCount = AddSucceeded and (tonumber(ret) or 0) or 0
    local after = UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, BackpackItemID)
    print("[ShopV2:SERVER] AFTER AddItemV2: callOK=" .. tostring(AddSucceeded) ..
              " added=" .. tostring(AddedCount) .. " count=" .. tostring(after))

    -- AddItemV2 返回成功添加的数量。返回 0 可能是物品配置、重复限制等原因，
    -- 不能一律提示背包已满；只有容量复查确实已满时才弹容量提示。
    if AddedCount <= 0 then
        print("[ShopV2:SERVER] AddItemV2 FAILED, keeping virtual item as fallback")
        if BackpackCapacityUtil ~= nil and BackpackCapacityUtil.IsFullIncludingEquipped ~= nil and
            BackpackCapacityUtil.IsFullIncludingEquipped(PlayerPawn) == true then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_ShowToast", "背包已满")
        end
        return
    end

    if VirtualItemID ~= nil then
        local VirtualItemManager = UGCGamePartSystem.GetGamePartGlobalActor("VirtualItemManager")
        if VirtualItemManager then
            local rmOK, rmErr =
                pcall(VirtualItemManager.RemoveVirtualItem, VirtualItemManager, self, VirtualItemID, AddedCount)
            print("[ShopV2:SERVER] RemoveVirtualItem(VItemID=" .. tostring(VirtualItemID) .. " x " .. tostring(AddedCount) ..
                      ") ok=" .. tostring(rmOK) .. " err=" .. tostring(rmErr))
        end
    end

    if AddedCount < Num and BackpackCapacityUtil ~= nil and
        BackpackCapacityUtil.IsFullIncludingEquipped ~= nil and
        BackpackCapacityUtil.IsFullIncludingEquipped(PlayerPawn) == true then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_ShowToast", "背包已满")
    end
end

--- 商城打开时清理历史遗留的虚拟物品（必须在服务端执行）
---@param VirtualItemID number 虚拟物品ID
function UGCPlayerController:Server_CleanupStaleShopVirtualItem(VirtualItemID)
    if not UGCGameSystem.IsServer() then
        return
    end

    VirtualItemID = tonumber(VirtualItemID)
    if VirtualItemID == nil or VirtualItemID <= 0 then
        return
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager == nil or VirtualItemManager.GetItemNum == nil or
        VirtualItemManager.RemoveVirtualItem == nil then
        print("[ShopV2:SERVER] stale virtual item cleanup unavailable")
        return
    end

    local CountSucceeded, CountResult = pcall(VirtualItemManager.GetItemNum, VirtualItemManager,
        VirtualItemID, self)
    local Count = CountSucceeded and math.max(0, tonumber(CountResult) or 0) or 0
    print("[ShopV2:SERVER] stale virtual item count itemID=" .. tostring(VirtualItemID) ..
              " count=" .. tostring(Count) .. " querySucceeded=" .. tostring(CountSucceeded))
    if Count <= 0 then
        return
    end

    local RemoveSucceeded, RemoveResult = pcall(VirtualItemManager.RemoveVirtualItem,
        VirtualItemManager, self, VirtualItemID, Count)
    print("[ShopV2:SERVER] stale virtual item removed itemID=" .. tostring(VirtualItemID) ..
              " count=" .. tostring(Count) .. " callSucceeded=" .. tostring(RemoveSucceeded) ..
              " result=" .. tostring(RemoveResult))
end

function UGCPlayerController:Server_ForgeWeapon(ItemID, UseProtect)
    ItemID = tonumber(ItemID)
    local bRequestProtect = UseProtect == true or tonumber(UseProtect) == 1
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if ItemID == nil or WeaponInfo == nil then
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Invalid item: " .. tostring(ItemID))
        return
    end

    if GetItemCount(self, ItemID) <= 0 then
        local CurrentItemID = FindHeldWeaponItemIDBySeries(self, WeaponInfo.SeriesKey)
        if CurrentItemID == nil then
            ugcprint("[UGCPlayerController:Server_ForgeWeapon] Weapon not found: " .. tostring(ItemID))
            return
        end
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] selected item missing, use current series item: " ..
                     tostring(ItemID) .. "->" .. tostring(CurrentItemID))
        ItemID = CurrentItemID
        WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    end

    local CurrentItemDefineID = FindBackpackItemDefineID(self, ItemID)
    local CurrentLevel = GetWeaponLevelFromItemDefineID(CurrentItemDefineID, WeaponInfo, 1) or
                             tonumber(WeaponInfo.Level) or 1
    local Cost = WeaponLevelConfig.GetForgeCost(ItemID, CurrentLevel)
    if Cost == nil then
        ugcprint(
            "[UGCPlayerController:Server_ForgeWeapon] Max level or missing level config: item=" .. tostring(ItemID) ..
                ", level=" .. tostring(CurrentLevel))
        return
    end

    if GetItemCount(self, ForgeMaterialItemIDs.HGRJ) < (Cost.HGRJ or 0) or GetItemCount(self, ForgeMaterialItemIDs.QNHH) <
        (Cost.QNHH or 0) then
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Material not enough")
        return
    end

    if self.bForgeWeaponBusy then
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] busy, ignore repeated request")
        return
    end
    self.bForgeWeaponBusy = true
    local function ClearForgeWeaponBusy()
        if self ~= nil then
            self.bForgeWeaponBusy = false
        end
    end

    local RollResultType = WeaponLevelConfig.RollForgeResult(ItemID, CurrentLevel)
    local ResultType = RollResultType
    local bUseProtectThisForge = RollResultType == "Destroy" and bRequestProtect == true and CurrentLevel >= 10 and
                                     CurrentLevel <= 14 and GetItemCount(self, ForgeMaterialItemIDs.Protect) > 0
    local ResultLevel = nil
    if bUseProtectThisForge then
        ResultType = "Protect"
        ResultLevel = math.random(6, 10)
    else
        ResultLevel = WeaponLevelConfig.GetResultLevel(ItemID, CurrentLevel, RollResultType)
    end
    local ResultItemID = nil
    if RollResultType ~= "Destroy" or bUseProtectThisForge then
        ResultItemID = GetResultItemIDByLevel(WeaponInfo, ResultLevel, ItemID) or ItemID
    end
    local ShouldRemoveWeapon = RollResultType == "Destroy" or ResultItemID ~= ItemID
    if ShouldRemoveWeapon then
        local ItemDefineID = FindBackpackItemDefineID(self, ItemID)
        if ItemDefineID ~= nil then
            TryDisuseBackpackItem(self, ItemDefineID)
        end
    end

    if not RemoveItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0) then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_ForgeWeaponResult", "Error", ItemID, ItemID, CurrentLevel)
        ClearForgeWeaponBusy()
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove HGRJ failed")
        return
    end
    if not RemoveItem(self, ForgeMaterialItemIDs.QNHH, Cost.QNHH or 0) then
        AddItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0)
        UnrealNetwork.CallUnrealRPC(self, self, "Client_ForgeWeaponResult", "Error", ItemID, ItemID, CurrentLevel)
        ClearForgeWeaponBusy()
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove QNHH failed")
        return
    end
    if bUseProtectThisForge and not RemoveItem(self, ForgeMaterialItemIDs.Protect, 1) then
        AddItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0)
        AddItem(self, ForgeMaterialItemIDs.QNHH, Cost.QNHH or 0)
        UnrealNetwork.CallUnrealRPC(self, self, "Client_ForgeWeaponResult", "Error", ItemID, ItemID, CurrentLevel)
        ClearForgeWeaponBusy()
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove protect item failed")
        return
    end

    UGCTimerUtility.CreateLuaTimer(0.2, function()
        if self == nil then
            return
        end

        local bKeptOriginalWeapon = false
        if ShouldRemoveWeapon then
            if not RemoveItem(self, ItemID, 1) then
                local ItemDefineID = FindBackpackItemDefineID(self, ItemID)
                local bSavedLevel = RollResultType ~= "Destroy" or bUseProtectThisForge
                bSavedLevel = bSavedLevel and ItemDefineID ~= nil and
                                  SetWeaponLevelToItemDefineID(ItemDefineID, WeaponInfo, ResultLevel, 1) == true
                if not bSavedLevel then
                    AddItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0)
                    AddItem(self, ForgeMaterialItemIDs.QNHH, Cost.QNHH or 0)
                    if bUseProtectThisForge then
                        AddItem(self, ForgeMaterialItemIDs.Protect, 1)
                    end
                    UnrealNetwork.CallUnrealRPC(self, self, "Client_ForgeWeaponResult", "Error", ItemID, ItemID,
                        CurrentLevel)
                    ClearForgeWeaponBusy()
                    ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove old weapon failed")
                    return
                end
                ResultItemID = ItemID
                bKeptOriginalWeapon = true
                ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove old weapon failed, saved level on item: " ..
                             tostring(ItemID) .. ", level=" .. tostring(ResultLevel))
            end
            if RollResultType ~= "Destroy" or bUseProtectThisForge then
                if not bKeptOriginalWeapon and not AddItem(self, ResultItemID, 1) then
                    AddItem(self, ItemID, 1)
                    AddItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0)
                    AddItem(self, ForgeMaterialItemIDs.QNHH, Cost.QNHH or 0)
                    if bUseProtectThisForge then
                        AddItem(self, ForgeMaterialItemIDs.Protect, 1)
                    end
                    UnrealNetwork.CallUnrealRPC(self, self, "Client_ForgeWeaponResult", "Error", ItemID, ItemID,
                        CurrentLevel)
                    ClearForgeWeaponBusy()
                    ugcprint("[UGCPlayerController:Server_ForgeWeapon] Add result weapon failed: " ..
                                 tostring(ResultItemID))
                    return
                end
            end
        end

        self.WeaponLevelByID = self.WeaponLevelByID or {}
        self.WeaponLevelByID[WeaponInfo.ID] = ResultLevel
        local Pawn = GetPlayerPawn(self)
        if Pawn ~= nil then
            Pawn.WeaponLevelByID = Pawn.WeaponLevelByID or {}
            Pawn.WeaponLevelByID[WeaponInfo.ID] = ResultLevel
        end
        local PlayerState = self.PlayerState
        if PlayerState ~= nil and PlayerState.SetWeaponLevel ~= nil then
            PlayerState:SetWeaponLevel(WeaponInfo.ID, ResultLevel)
        end
        if self.SyncWeaponBackpackNames ~= nil then
            self:SyncWeaponBackpackNames()
        end

        if RollResultType ~= "Success" then
            TryRefundForgeFailMaterials(self, Cost)
        end

        UnrealNetwork.CallUnrealRPC(self, self, "Client_ForgeWeaponResult", ResultType, ItemID, ResultItemID or 0,
            ResultLevel)
        ClearForgeWeaponBusy()
    end, false)

    ugcprint(
        "[UGCPlayerController:Server_ForgeWeapon] result=" .. tostring(ResultType) .. ", item=" .. tostring(ItemID) ..
            "->" .. tostring(ResultItemID) .. ", level=" .. tostring(CurrentLevel) .. "->" .. tostring(ResultLevel) ..
            ", protect=" .. tostring(bUseProtectThisForge))
end

function UGCPlayerController:Client_ForgeWeaponResult(ResultType, OldItemID, ResultItemID, ResultLevel, ItemDefineID,
    StackIndex)
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ResultItemID)
    if WeaponInfo ~= nil then
        self.WeaponLevelByID = self.WeaponLevelByID or {}
        self.WeaponLevelByID[WeaponInfo.ID] = math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(ResultLevel) or 1))
    end

    local Pawn = GetPlayerPawn(self)
    if Pawn ~= nil and WeaponInfo ~= nil then
        local Level = math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(ResultLevel) or WeaponInfo.Level or 1))
        Pawn.WeaponLevelByID = Pawn.WeaponLevelByID or {}
        Pawn.WeaponLevelByID[WeaponInfo.ID] = Level
    end
    if Pawn ~= nil and Pawn.RefreshWeaponAttackBonus ~= nil then
        Pawn:RefreshWeaponAttackBonus(true)
        if Pawn.ForceRefreshPropertySnapshot ~= nil then
            Pawn:ForceRefreshPropertySnapshot()
        end
    end

    if self.MainUIInstance == nil or self.MainUIInstance.UI10Instance == nil then
        ugcprint("[UGCPlayerController:Client_ForgeWeaponResult] UI10 instance is nil")
        return
    end

    local UI10Instance = self.MainUIInstance.UI10Instance
    if UI10Instance.OnForgeWeaponResult ~= nil then
        UI10Instance:OnForgeWeaponResult(ResultType, OldItemID, ResultItemID, ResultLevel, ItemDefineID, StackIndex)
    end
end
-- 突破
local function GetRealmLevel(PlayerController)
    if PlayerController.RealmLevel ~= nil then
        return tonumber(PlayerController.RealmLevel) or 1
    end

    if PlayerController.PlayerState ~= nil and PlayerController.PlayerState.GetHunHuan ~= nil then
        return tonumber(PlayerController.PlayerState:GetHunHuan()) or 1
    end

    return 1
end

local function SetRealmLevel(PlayerController, Level)
    PlayerController.RealmLevel = math.max(1, math.min(RealmConfig.MaxLevel, tonumber(Level) or 1))
end

local function GetRealmFailCount(PlayerController, Level)
    PlayerController.RealmFailCounts = PlayerController.RealmFailCounts or {}
    return tonumber(PlayerController.RealmFailCounts[Level]) or 0
end

local function SetRealmFailCount(PlayerController, Level, Count)
    PlayerController.RealmFailCounts = PlayerController.RealmFailCounts or {}
    PlayerController.RealmFailCounts[Level] = math.max(0, tonumber(Count) or 0)
end

local function GetRealmCombatPower(PlayerController)
    local PlayerPawn = PlayerController:K2_GetPawn()
    if PlayerPawn == nil then
        return 0
    end

    local AttackPower = tonumber(UGCAttributeSystem.GetGameAttributeValue(PlayerPawn, "AttackPower")) or 0
    local MaxHP = tonumber(UGCPawnAttrSystem.GetHealthMax(PlayerPawn)) or 0
    return AttackPower + MaxHP
end

local function BuildRealmConsumeItems(Config, UseLuckyCard)
    local Items = {}
    for _, Item in ipairs(Config.NeedItems or {}) do
        table.insert(Items, Item)
    end
    if UseLuckyCard then
        table.insert(Items, {
            ItemID = RealmConfig.LuckyItemID,
            Count = 1,
            Name = "突破幸运符"
        })
    end
    return Items
end

local function HasRealmNeedItems(PlayerController, Config, UseLuckyCard)
    for _, Item in ipairs(BuildRealmConsumeItems(Config, UseLuckyCard)) do
        local ItemID = tonumber(Item.ItemID)
        local NeedCount = tonumber(Item.Count) or 0
        if ItemID ~= nil and GetItemCount(PlayerController, ItemID) < NeedCount then
            return false, Item
        end
    end

    return true, nil
end

local function RemoveRealmNeedItems(PlayerController, Config, UseLuckyCard)
    local RemovedItems = {}
    for _, Item in ipairs(BuildRealmConsumeItems(Config, UseLuckyCard)) do
        local ItemID = tonumber(Item.ItemID)
        local NeedCount = tonumber(Item.Count) or 0
        if ItemID ~= nil and NeedCount > 0 then
            if not RemoveItem(PlayerController, ItemID, NeedCount) then
                for _, RemovedItem in ipairs(RemovedItems) do
                    AddItem(PlayerController, RemovedItem.ItemID, RemovedItem.Count)
                end
                return false, Item
            end

            table.insert(RemovedItems, {
                ItemID = ItemID,
                Count = NeedCount
            })
        end
    end

    return true, nil
end

function UGCPlayerController:Server_BreakRealm(TargetLevel, UseLuckyCard)
    TargetLevel = tonumber(TargetLevel)
    UseLuckyCard = UseLuckyCard == true or tonumber(UseLuckyCard) == 1
    local CurrentLevel = GetRealmLevel(self)
    local ExpectedLevel = CurrentLevel + 1

    if TargetLevel ~= ExpectedLevel or TargetLevel == nil or TargetLevel > RealmConfig.MaxLevel then
        ugcprint("[UGCPlayerController:Server_BreakRealm] invalid target=" .. tostring(TargetLevel) .. ", current=" ..
                     tostring(CurrentLevel))
        return
    end

    local Config = RealmConfig.Get(TargetLevel)
    if Config == nil then
        return
    end

    local CurrentPower = GetRealmCombatPower(self)
    local NeedPower = tonumber(Config.NeedPower)
    if NeedPower == nil then
        ugcprint("[UGCPlayerController:Server_BreakRealm] NeedPower is nil, target=" .. tostring(TargetLevel))
        return
    end
    if CurrentPower < NeedPower then
        ugcprint("[UGCPlayerController:Server_BreakRealm] power not enough: current=" .. tostring(CurrentPower) ..
                     ", need=" .. tostring(NeedPower) .. ", target=" .. tostring(TargetLevel))
        return
    end

    local FailCount = GetRealmFailCount(self, TargetLevel)
    local HasItems, MissingItem = HasRealmNeedItems(self, Config, UseLuckyCard)
    if not HasItems then
        ugcprint("[UGCPlayerController:Server_BreakRealm] item not enough: " ..
                     tostring(MissingItem and MissingItem.Name or "nil") .. ", target=" .. tostring(TargetLevel))
        UnrealNetwork.CallUnrealRPC(self, self, "Client_BreakRealmResult", false, CurrentLevel, TargetLevel, FailCount,
            0, false)
        return
    end

    local RemoveSuccess, RemoveFailedItem = RemoveRealmNeedItems(self, Config, UseLuckyCard)
    if not RemoveSuccess then
        ugcprint("[UGCPlayerController:Server_BreakRealm] remove item failed: " ..
                     tostring(RemoveFailedItem and RemoveFailedItem.Name or "nil") .. ", target=" ..
                     tostring(TargetLevel))
        UnrealNetwork.CallUnrealRPC(self, self, "Client_BreakRealmResult", false, CurrentLevel, TargetLevel, FailCount,
            0, false)
        return
    end

    local ExtraRate = UseLuckyCard and RealmConfig.LuckyExtraRate or 0
    local Success, IsGuaranteed, UsedRate = RealmConfig.RollBreakResult(TargetLevel, FailCount, ExtraRate)
    local NewLevel = CurrentLevel

    if Success then
        NewLevel = TargetLevel
        SetRealmLevel(self, NewLevel)
        SetRealmFailCount(self, TargetLevel, 0)

        local PlayerPawn = self:K2_GetPawn()
        local PlayerState = PlayerPawn and PlayerPawn.PlayerState
        if PlayerState ~= nil and PlayerState.SetHunHuan ~= nil then
            PlayerState:SetHunHuan(NewLevel)
        end
        if PlayerPawn ~= nil and PlayerPawn.RefreshSoulMesh ~= nil then
            PlayerPawn:RefreshSoulMesh(NewLevel, true)
        end
    else
        FailCount = FailCount + 1
        SetRealmFailCount(self, TargetLevel, FailCount)
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_BreakRealmResult", Success, NewLevel, TargetLevel, FailCount,
        UsedRate, IsGuaranteed)

    ugcprint("[UGCPlayerController:Server_BreakRealm] target=" .. tostring(TargetLevel) .. ", success=" ..
                 tostring(Success) .. ", rate=" .. tostring(UsedRate) .. ", guaranteed=" .. tostring(IsGuaranteed) ..
                 ", failCount=" .. tostring(FailCount) .. ", extraRate=" .. tostring(ExtraRate))
end

function UGCPlayerController:Client_BreakRealmResult(Success, NewLevel, TargetLevel, FailCount, UsedRate, IsGuaranteed)
    self.RealmLevel = tonumber(NewLevel) or self.RealmLevel

    if Success then
        local PlayerPawn = self:K2_GetPawn()
        if PlayerPawn ~= nil and PlayerPawn.RefreshSoulMesh ~= nil then
            PlayerPawn:RefreshSoulMesh(NewLevel)
        end
    end

    if self.MainUIInstance ~= nil and self.MainUIInstance.RefreshRealmNameText ~= nil then
        self.MainUIInstance:RefreshRealmNameText()
    end

    if self.MainUIInstance == nil or self.MainUIInstance.UI08Instance == nil then
        ugcprint("[UGCPlayerController:Client_BreakRealmResult] UI08 instance is nil")
        return
    end

    local UI08Instance = self.MainUIInstance.UI08Instance
    if UI08Instance.OnRealmBreakResult ~= nil then
        UI08Instance:OnRealmBreakResult(Success, NewLevel, TargetLevel, FailCount, UsedRate, IsGuaranteed)
    elseif UI08Instance.OnRealmLevelChanged ~= nil then
        UI08Instance:OnRealmLevelChanged(NewLevel)
    end
end

-- 装备相关
-- Lottery
local function GetLotteryState(PlayerController, LotteryType)
    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil then
        return nil
    end

    local State = PlayerState.GetLotteryState and PlayerState:GetLotteryState() or PlayerState.LotteryState
    if State == nil then
        State = {}
        PlayerState.LotteryState = State
    end

    local Key = tostring(LotteryType)
    if State[Key] == nil then
        State[Key] = {
            Round = 0,
            Completed = false,
            OwnedAwards = {},
            GrandPrize = false
        }
    end

    State[Key].OwnedAwards = State[Key].OwnedAwards or {}
    return State[Key], State
end

local function SaveLotteryState(PlayerController, State)
    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil then
        return
    end

    if PlayerState.SetLotteryState ~= nil then
        PlayerState:SetLotteryState(State)
    else
        PlayerState.LotteryState = State
        if PlayerState.SaveToArchive ~= nil then
            PlayerState:SaveToArchive()
        end
    end
end

local function GetRemainingAwards(Pool, LotteryState)
    local Awards = {}
    for Index, Award in ipairs(Pool.Awards or {}) do
        if LotteryState.OwnedAwards[tostring(Index)] ~= true then
            table.insert(Awards, {
                Index = Index,
                Award = Award,
                IsGrandPrize = false
            })
        end
    end

    if LotteryState.GrandPrize ~= true then
        table.insert(Awards, {
            Index = 0,
            Award = Pool.GrandPrize,
            IsGrandPrize = true
        })
    end

    return Awards
end

local function RollAward(Candidates)
    local TotalWeight = 0
    for _, Candidate in ipairs(Candidates) do
        TotalWeight = TotalWeight + (tonumber(Candidate.Award.Weight) or 0)
    end

    if TotalWeight <= 0 then
        return Candidates[1]
    end

    local Roll = math.random(1, TotalWeight)
    local Acc = 0
    for _, Candidate in ipairs(Candidates) do
        Acc = Acc + (tonumber(Candidate.Award.Weight) or 0)
        if Roll <= Acc then
            return Candidate
        end
    end

    return Candidates[#Candidates]
end

local function GrantLotteryAward(PlayerController, Award)
    if Award == nil then
        return true
    end

    local ItemID = tonumber(Award.ItemID) or 0
    local Count = tonumber(Award.Count) or 1
    if ItemID <= 0 then
        return true
    end

    return AddItem(PlayerController, ItemID, Count)
end

local function AddLotteryAwardToList(ItemList, Award)
    local ItemID = tonumber(Award and Award.ItemID) or 0
    if ItemID > 0 then
        table.insert(ItemList, {
            ItemID = ItemID,
            ItemNum = tonumber(Award.Count) or 1
        })
    end
end

function UGCPlayerController:Server_RequestLottery(LotteryType, SlotIndex)
    LotteryType = tonumber(LotteryType) or 0
    local Pool = LotteryConfig.GetPool(LotteryType)
    if Pool == nil then
        ugcprint("[UGCPlayerController:Server_RequestLottery] invalid type=" .. tostring(LotteryType))
        UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -1, 0, 0, 0, {})
        return
    end

    local LotteryState, AllLotteryState = GetLotteryState(self, LotteryType)
    if LotteryState == nil then
        return
    end

    if LotteryState.Completed == true and not LotteryConfig.CanDrawCompletedPool() then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -2, 0, 0, 1, {})
        return
    end

    local NextRound = (tonumber(LotteryState.Round) or 0) + 1
    local Cost = LotteryConfig.GetRoundCost(NextRound)
    if (tonumber(LotteryConfig.CostItemID) or 0) > 0 then
        if GetItemCount(self, LotteryConfig.CostItemID) < Cost then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -3, 0, 0, 0, {})
            return
        end
        if not RemoveItem(self, LotteryConfig.CostItemID, Cost) then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -4, 0, 0, 0, {})
            return
        end
    end

    local Candidate = nil
    if LotteryConfig.IsGrandPrizeRound(LotteryType, NextRound) and LotteryState.GrandPrize ~= true then
        Candidate = {
            Index = 0,
            Award = Pool.GrandPrize,
            IsGrandPrize = true
        }
    else
        local Candidates = GetRemainingAwards(Pool, LotteryState)
        if #Candidates <= 0 then
            LotteryState.Completed = true
            SaveLotteryState(self, AllLotteryState)
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -2, 0, 0, 1, {})
            return
        end
        Candidate = RollAward(Candidates)
    end

    local Award = Candidate.Award
    local ItemList = {}
    if Candidate.IsGrandPrize then
        if not GrantLotteryAward(self, Award) then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -5, 0, 0, 0, {})
            return
        end
        AddLotteryAwardToList(ItemList, Award)

        LotteryState.GrandPrize = true
        local AllMissingAwardsGranted = true
        if LotteryConfig.GrantMissingAwardsOnGrandPrize then
            for Index, MissingAward in ipairs(Pool.Awards or {}) do
                if LotteryState.OwnedAwards[tostring(Index)] ~= true then
                    if GrantLotteryAward(self, MissingAward) then
                        LotteryState.OwnedAwards[tostring(Index)] = true
                        AddLotteryAwardToList(ItemList, MissingAward)
                    else
                        AllMissingAwardsGranted = false
                    end
                end
            end
        end
        if LotteryConfig.CompleteOnGrandPrize and AllMissingAwardsGranted then
            LotteryState.Completed = true
        end
    else
        if not GrantLotteryAward(self, Award) then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -5, 0, 0, 0, {})
            return
        end
        AddLotteryAwardToList(ItemList, Award)
        LotteryState.OwnedAwards[tostring(Candidate.Index)] = true
    end

    LotteryState.Round = NextRound
    SaveLotteryState(self, AllLotteryState)

    UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, Candidate.Index,
        tonumber(Award.ItemID) or 0, tonumber(Award.Count) or 1, LotteryState.Completed and 1 or 0, ItemList)

    -- 只有服务端完成扣券、发奖并保存抽奖状态后，才算一次有效抽奖。
    TaskMgr:AddTaskProgressOnServer(L_Enum.AllTask.LotterySummon, 1, self)
    TitleMgr:CheckAndUnlock(5, self)
    TitleMgr:CheckAndUnlock(6, self)
end

function UGCPlayerController:Client_LotteryResult(LotteryType, SlotIndex, AwardItemID, AwardCount, bCompleted, ItemList)
    if self.UI14Instance ~= nil and self.UI14Instance.OnLotteryResult ~= nil then
        self.UI14Instance:OnLotteryResult(LotteryType, SlotIndex, AwardItemID, AwardCount, bCompleted, ItemList)
        return
    end

    if self.MainUIInstance ~= nil and self.MainUIInstance.UI14Instance ~= nil and
        self.MainUIInstance.UI14Instance.OnLotteryResult ~= nil then
        self.MainUIInstance.UI14Instance:OnLotteryResult(LotteryType, SlotIndex, AwardItemID, AwardCount, bCompleted,
            ItemList)
    end
end

function UGCPlayerController:Server_RequestLotteryStateSync()
    local PlayerState = self.PlayerState
    local LotteryState = PlayerState and PlayerState.GetLotteryState and PlayerState:GetLotteryState() or
                             (PlayerState and PlayerState.LotteryState) or {}
    UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncLotteryState", LotteryState)
end

function UGCPlayerController:Client_SyncLotteryState(LotteryState)
    local PlayerState = self.PlayerState
    if PlayerState ~= nil then
        PlayerState.LotteryState = LotteryState or {}
    end

    local UI14Instance = self.MainUIInstance and self.MainUIInstance.UI14Instance or self.UI14Instance
    if UI14Instance ~= nil and UI14Instance.Refresh ~= nil then
        UI14Instance:Refresh()
    end
end

function UGCPlayerController:Client_UnlockTitle(titleID)
    titleID = tonumber(titleID) or 0
    if titleID < 1 or titleID > TitleConfig.MaxTitleID then
        return
    end

    self.UnlockedTitles = self.UnlockedTitles or {}
    self.UnlockedTitles[titleID] = true

    local titleUI = self.MainUIInstance and self.MainUIInstance.TitleUIInstance or nil
    if titleUI ~= nil and titleUI.UnlockTitle ~= nil then
        titleUI:UnlockTitle(titleID)
    end

    local titleConfig = TitleConfig.GetTitle(titleID)
    local titleName = titleConfig and titleConfig.Name or ("称号" .. titleID)
    L_Com.ShowToast("恭喜解锁“" .. titleName .. "”！")
    self:Client_RefreshTitleBonus()
end

function UGCPlayerController:Client_RefreshTitleBonus()
    local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
    if StateMgr == nil or StateMgr.ChengHaoTextShow == nil then
        return
    end
    if StateMgr.UI == nil or StateMgr.UI.TextBlock_114 == nil then
        return
    end

    local bonus = TitleConfig.GetUnlockedTitleBonus(self.UnlockedTitles)
    StateMgr:ChengHaoTextShow(bonus.AttackPercent)
end

function UGCPlayerController:Client_SyncKillMonsterCount(killMonsterCount)
    killMonsterCount = math.max(0, tonumber(killMonsterCount) or 0)
    self.KillMonsterCount = killMonsterCount

    local playerState = self.PlayerState
    if playerState ~= nil then
        playerState.KillMonsterCount = killMonsterCount
    end

    local titleUI = self.MainUIInstance and self.MainUIInstance.TitleUIInstance or nil
    if titleUI ~= nil and titleUI.SelectedTitleID == 15 and titleUI.SelectTitle ~= nil then
        titleUI:SelectTitle(15)
    end
end

function UGCPlayerController:Client_SyncTitleState(unlockedTitles, equippedTitleID, killMonsterCount)
    self.UnlockedTitles = unlockedTitles or {}
    self.EquippedTitleID = tonumber(equippedTitleID) or 0
    self:Client_SyncKillMonsterCount(killMonsterCount)

    local titleUI = self.MainUIInstance and self.MainUIInstance.TitleUIInstance or nil
    if titleUI ~= nil then
        titleUI.EquippedTitleID = self.EquippedTitleID
        titleUI.UnlockedTitles = {}
        for titleID = 1, TitleConfig.MaxTitleID do
            titleUI.UnlockedTitles[titleID] = self.UnlockedTitles[titleID] == true or
                                                   self.UnlockedTitles[tostring(titleID)] == true
            if titleUI.RefreshTitleLockState ~= nil then
                titleUI:RefreshTitleLockState(titleID)
            end
        end
        for id, unlocked in pairs(self.UnlockedTitles) do
            if unlocked and titleUI.UnlockTitle ~= nil then
                titleUI:UnlockTitle(id)
            end
        end
        if titleUI.SelectedTitleID ~= nil and titleUI.SelectTitle ~= nil then
            titleUI:SelectTitle(titleUI.SelectedTitleID)
        end
    end

    self:Client_RefreshTitleBonus()
end

function UGCPlayerController:UnlockTitle(titleID)
    if self.bGMResetInProgress == true then
        return
    end
    titleID = tonumber(titleID) or 0
    if titleID < 1 or titleID > TitleConfig.MaxTitleID then
        return
    end

    local playerState = self.PlayerState
    if playerState ~= nil and playerState.IsTitleUnlocked ~= nil and playerState:IsTitleUnlocked(titleID) then
        return
    end

    if playerState ~= nil and playerState.SetTitleUnlocked ~= nil then
        playerState:SetTitleUnlocked(titleID)
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_UnlockTitle", titleID)
end

function UGCPlayerController:SyncSavedTitleState()
    local playerState = self.PlayerState
    if playerState == nil then
        return
    end

    local unlockedTitles = playerState.GetUnlockedTitles and playerState:GetUnlockedTitles() or
                               playerState.UnlockedTitles
    local equippedTitleID = playerState.GetEquippedTitleID and playerState:GetEquippedTitleID() or
                                playerState.EquippedTitleID
    equippedTitleID = tonumber(equippedTitleID) or 0
    local killMonsterCount = playerState.GetKillMonsterCount and playerState:GetKillMonsterCount() or
                                 playerState.KillMonsterCount

    local pawn = self:K2_GetPawn()
    if pawn ~= nil and equippedTitleID > 0 then
        pawn.EquippedTitleID = equippedTitleID
        local titleActor = pawn.PlayerTitleActor
        if (titleActor == nil or not UE.IsValid(titleActor)) and pawn.EnsurePlayerTitleActor ~= nil then
            titleActor = pawn:EnsurePlayerTitleActor()
        end
        if titleActor and UE.IsValid(titleActor) and titleActor.SetTitle then
            titleActor:SetTitle(equippedTitleID)
        end
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_SyncTitleState", unlockedTitles or {}, equippedTitleID,
        tonumber(killMonsterCount) or 0)
end

-- Title equip
function UGCPlayerController:Server_EquipTitle(titleID)
    if self.bGMResetInProgress == true then
        return
    end
    titleID = tonumber(titleID) or 0

    if titleID < 1 or titleID > TitleConfig.MaxTitleID then
        return
    end

    local pawn = self:K2_GetPawn()
    if pawn == nil then
        return
    end

    if self.PlayerState ~= nil and self.PlayerState.IsTitleUnlocked ~= nil and
        not self.PlayerState:IsTitleUnlocked(titleID) then
        return
    end

    if (pawn.EquippedTitleID or 0) == titleID then
        return
    end

    pawn.EquippedTitleID = titleID
    self.EquippedTitleID = titleID
    if self.PlayerState ~= nil and self.PlayerState.SetEquippedTitleID ~= nil then
        self.PlayerState:SetEquippedTitleID(titleID)
    end

    -- 刷新头顶称号
    local titleActor = pawn.PlayerTitleActor
    if (titleActor == nil or not UE.IsValid(titleActor)) and pawn.EnsurePlayerTitleActor ~= nil then
        titleActor = pawn:EnsurePlayerTitleActor()
    end

    if titleActor and UE.IsValid(titleActor) and titleActor.SetTitle then
        titleActor:SetTitle(titleID)
    end

    -- 预留属性
end

-- WBP_RankingListBtn 更新排行榜服务端--要走官方测试按钮暂时没开
function UGCPlayerController:Server_UpdateRankingListScore(UID, RankID, Score, IsIncremental)
    if self.bGMResetInProgress == true then
        ugcprint("[GMReset] ranking update blocked during reset player=" .. tostring(self.PlayerKey))
        return
    end
    local RankingListGlobalActor = UGCGamePartSystem.GetGamePartGlobalActor("RankingListManager")
    if RankingListGlobalActor == nil then
        ugcprint("[UGCPlayerController:Server_UpdateRankingListScore] RankingListManager global actor is nil")
        return
    end

    local bIncremental = tonumber(IsIncremental) == 1
    RankingListGlobalActor:UpdateScore(self, tonumber(UID), tonumber(RankID), tonumber(Score), bIncremental)
end

-- 排行榜清除数据请求服务端--要走官方测试按钮暂时没开
function UGCPlayerController:Server_ClearAllRankingListData()
    local RankingListGlobalActor = UGCGamePartSystem.GetGamePartGlobalActor("RankingListManager")
    if RankingListGlobalActor == nil then
        ugcprint("[UGCPlayerController:Server_ClearAllRankingListData] RankingListManager global actor is nil")
        return
    end

    RankingListGlobalActor:PIEClearAllRankListData()
end

function UGCPlayerController:Client_BroadcastPlantMessage(UID, level)
    --[[------------------客户端收到全服通知----------------------------]] --
    -- UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.Test_01,UID,level)
end

--[[---------------------增加概率-------------------------]] --
function UGCPlayerController:Server_AddProbabilityBonus(value)
    value = tonumber(value) or 100
    if self.PlayerState == nil or self.PlayerState.SetProbability_Bonus == nil then
        return
    end
    self.PlayerState:SetProbability_Bonus(value)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_ProbabilityBonusChanged", self.PlayerState.Probability_Bonus)
end

function UGCPlayerController:Server_AddProbabilityBonusDuration(value, durationSeconds)
    local Duration = tonumber(durationSeconds) or 0
    if Duration <= 0 then
        return
    end

    if self.ProbabilityBonusPermanent == true then
        local PermanentValue = tonumber(self.ProbabilityBonusPermanentValue) or 100
        if (tonumber(value) or 100) > PermanentValue then
            self.ProbabilityBonusPermanentValue = tonumber(value) or 100
        end
        self:Server_AddProbabilityBonus(self.ProbabilityBonusPermanentValue)
        return
    end

    local CurrentValue = 100
    if self.PlayerState ~= nil then
        if self.PlayerState.GetProbability_Bonus ~= nil then
            CurrentValue = tonumber(self.PlayerState:GetProbability_Bonus()) or 100
        else
            CurrentValue = tonumber(self.PlayerState.Probability_Bonus) or 100
        end
    end

    if (tonumber(self.ProbabilityBonusRemainingSeconds) or 0) <= 0 and CurrentValue > 100 and CurrentValue >=
        (tonumber(value) or 100) then
        self.ProbabilityBonusPermanent = true
        self.ProbabilityBonusPermanentValue = CurrentValue
        self:Server_AddProbabilityBonus(CurrentValue)
        return
    end

    self.ProbabilityBonusRemainingSeconds = (tonumber(self.ProbabilityBonusRemainingSeconds) or 0) + Duration
    self.ProbabilityBonusTimedValue = math.max(tonumber(self.ProbabilityBonusTimedValue) or 100, tonumber(value) or 100)
    self:Server_AddProbabilityBonus(self.ProbabilityBonusTimedValue)

    local PlayerKey = self.PlayerKey or tostring(self)
    local TimerName = "ProbabilityBonus_" .. tostring(PlayerKey)

    UGCTimerUtility.RemoveLuaTimerByName(TimerName)
    UGCTimerUtility.CreateLuaTimer(1, function()
        if self.ProbabilityBonusPermanent == true then
            self.ProbabilityBonusRemainingSeconds = 0
            UGCTimerUtility.RemoveLuaTimerByName(TimerName)
            return
        end

        self.ProbabilityBonusRemainingSeconds = (tonumber(self.ProbabilityBonusRemainingSeconds) or 0) - 1
        if self.ProbabilityBonusRemainingSeconds <= 0 then
            self.ProbabilityBonusRemainingSeconds = 0
            self.ProbabilityBonusTimedValue = nil
            UGCTimerUtility.RemoveLuaTimerByName(TimerName)
            self:Server_AddProbabilityBonus(100)
        end
    end, true, TimerName)
end

function UGCPlayerController:Server_SetProbabilityBonusPermanent(value)
    value = tonumber(value) or 100
    if self.PlayerState ~= nil then
        if self.PlayerState.GetProbability_Bonus ~= nil then
            value = math.max(value, tonumber(self.PlayerState:GetProbability_Bonus()) or 100)
        else
            value = math.max(value, tonumber(self.PlayerState.Probability_Bonus) or 100)
        end
    end

    local PermanentValue = tonumber(self.ProbabilityBonusPermanentValue) or 100
    if value < PermanentValue then
        value = PermanentValue
    end

    self.ProbabilityBonusPermanent = true
    self.ProbabilityBonusPermanentValue = value
    self.ProbabilityBonusRemainingSeconds = 0
    self.ProbabilityBonusTimedValue = nil

    local PlayerKey = self.PlayerKey or tostring(self)
    UGCTimerUtility.RemoveLuaTimerByName("ProbabilityBonus_" .. tostring(PlayerKey))

    self:Server_AddProbabilityBonus(value)
end

function UGCPlayerController:Client_ProbabilityBonusChanged(value)
    local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
    if StateMgr ~= nil and StateMgr.BeiLvTextShow ~= nil and StateMgr.UI ~= nil then
        StateMgr:BeiLvTextShow(value)
    end
end

--[[----------------------客户端请求同步存档属性------------------------]]
function UGCPlayerController:Server_RequestRefreshProperty()
    local pawn = self.Pawn or self:K2_GetPawn()
    local playerState = self.PlayerState
    if pawn == nil or playerState == nil or playerState.bArchiveLoaded ~= true then
        return
    end

    if pawn.RefreshStateMgrProperty ~= nil then
        pawn:RefreshStateMgrProperty(false)
    end

    -- 存档加载完成后主动同步真实倍率，避免客户端仍显示默认的100%
    UnrealNetwork.CallUnrealRPC(self, self, "Client_ProbabilityBonusChanged", playerState:GetProbability_Bonus())

    if PlayerLevelMgr ~= nil and playerState.GetPlayerExp ~= nil and playerState.GetPlayerLevel ~= nil then
        local playerExp = playerState:GetPlayerExp()
        local playerLevel = PlayerLevelMgr:GetLevelByExp(playerExp)
        local currentExp = PlayerLevelMgr:GetCurrentLevelExp(playerExp, playerLevel)
        local currentMaxExp = PlayerLevelMgr:GetCurrentLevelMaxExp(playerLevel, playerState:GetPlayerMaxExp())
        UnrealNetwork.CallUnrealRPC(self, self, "Client_RefreshPlayerExp", currentExp, currentMaxExp, playerLevel)
    end
end

function UGCPlayerController:Client_RefreshProperty(baseAttack, baseMaxHp, hp, maxHp, bFillHealth)
    if self.MainUIInstance ~= nil and self.MainUIInstance.OnRefreshProperty ~= nil then
        self.MainUIInstance:OnRefreshProperty(baseAttack, baseMaxHp, hp, maxHp, bFillHealth)
        return
    end

    UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.ReFreshProperty, baseAttack, baseMaxHp,
        hp, maxHp, bFillHealth)
end

--[[----------------------刷新玩家经验显示和等级显示------------------------]]
function UGCPlayerController:Client_RefreshPlayerExp(playerExp, playerMaxExp, playerLevel)
    self.ClientPlayerExp = playerExp
    self.ClientPlayerMaxExp = playerMaxExp
    self.ClientPlayerLevel = playerLevel
    local Pawn = self.Pawn or (self.K2_GetPawn ~= nil and self:K2_GetPawn() or nil)
    if Pawn ~= nil and Pawn.SetOrbitWeaponActiveGun ~= nil then
        Pawn:SetOrbitWeaponActiveGun(math.max(1, math.min(8, math.floor(tonumber(playerLevel) or 1))),
            Pawn.OrbitWeaponDamagePercent)
    end
    if self.MainUIInstance ~= nil and self.MainUIInstance.RefreshPlayerExpUI ~= nil then
        self.MainUIInstance:RefreshPlayerExpUI(playerExp, playerMaxExp)
        --[[-----------------------刷新等级显示-----------------------]] --
        if self.MainUIInstance.Avarar_frame ~= nil then
            self.MainUIInstance.Avarar_frame:SetPlayerStateLevel(playerLevel)
            self.MainUIInstance.Avarar_frame:ShowUI()
        end
    end

    local MainUI = self.MainUIInstance
    local SoulRingUI = MainUI and (MainUI.UI017Instance or MainUI.UI15Instance)
        or self.UI017Instance or self.UI15Instance
    if SoulRingUI ~= nil and SoulRingUI.SetCurrentPlayerLevel ~= nil then
        SoulRingUI:SetCurrentPlayerLevel(playerLevel)
    end
end

function UGCPlayerController:Client_ShowToast(text)
    L_Com.ShowToast(tostring(text or ""))
end

function UGCPlayerController:Client_GMResetLogEntry(Level, Stage, Message, TimeText, Sequence)
    local Text = "[TagLog] [GMReset] [GM_RESET][CLIENT_FORWARD][" .. tostring(Stage or "unknown") .. "] seq=" ..
                     tostring(Sequence or 0) .. " " .. tostring(Message or "")
    -- Keep a distinct source so this dedicated RPC does not advance the generic
    -- server-log sequence cursor with a client-local sequence number.
    RuntimeLog.AppendForwarded("SERVER_GM", TimeText, Level, Text)
    if self.RuntimeLogUIInstance ~= nil and
        (UE.IsValid == nil or UE.IsValid(self.RuntimeLogUIInstance)) and
        self.RuntimeLogUIInstance.RefreshRuntimeLogs ~= nil then
        self.RuntimeLogUIInstance.PageIndex = 1
        self.RuntimeLogUIInstance:RefreshRuntimeLogs()
    end
end

function UGCPlayerController:Server_RequestRuntimeLogs(AfterSequence)
    if not UGCGameSystem.IsServer() then
        return
    end
    local Batch, LastSequence, HasMore = RuntimeLog.GetServerBatch(AfterSequence, RuntimeLog.BATCH_SIZE)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_RuntimeLogBatch", Batch, LastSequence, HasMore)
end

function UGCPlayerController:Server_RuntimeLogProbe()
    if not UGCGameSystem.IsServer() then
        return
    end
    RuntimeLog.Info("[LOG_PROBE][SERVER][INFO] server capture path active")
    RuntimeLog.Warn("[LOG_PROBE][SERVER][WARN] sample warning for search validation")
end

function UGCPlayerController:Client_RuntimeLogBatch(BatchText, LastSequence, HasMore)
    self.RuntimeLogSyncPending = false
    for Line in string.gmatch(tostring(BatchText or ""), "[^\n]+") do
        local Sequence, TimeText, Level, Message = string.match(Line, "^(.-)\t(.-)\t(.-)\t(.*)$")
        if Sequence ~= nil then
            RuntimeLog.AppendRemote(tonumber(Sequence), TimeText, Level, Message)
        end
    end
    RuntimeLog.SetServerCursor(tonumber(LastSequence) or 0)
    if tonumber(HasMore) ~= 1 and self.RuntimeLogUIInstance ~= nil and
        (UE.IsValid == nil or UE.IsValid(self.RuntimeLogUIInstance)) and
        self.RuntimeLogUIInstance.RefreshRuntimeLogs ~= nil then
        self.RuntimeLogUIInstance:RefreshRuntimeLogs()
    end
    if tonumber(HasMore) == 1 then
        local ContinueSync = function()
            self:RequestRuntimeLogSync()
        end
        if UGCTimerUtility ~= nil and UGCTimerUtility.CreateLuaTimer ~= nil then
            UGCTimerUtility.CreateLuaTimer(0.05, ContinueSync, false)
        else
            ContinueSync()
        end
    end
end

function UGCPlayerController:RequestRuntimeLogSync()
    if self:HasAuthority() then
        return
    end
    if self.RuntimeLogSyncPending == true then
        return
    end
    self.RuntimeLogSyncPending = true
    local Success = pcall(UnrealNetwork.CallUnrealRPC, self, self, "Server_RequestRuntimeLogs",
        RuntimeLog.GetLatestServerSequence())
    if not Success then
        self.RuntimeLogSyncPending = false
    end
end

function UGCPlayerController:ClearRuntimeLogs()
    RuntimeLog.Clear()
    if self.RuntimeLogUIInstance ~= nil and
        (UE.IsValid == nil or UE.IsValid(self.RuntimeLogUIInstance)) and
        self.RuntimeLogUIInstance.RefreshRuntimeLogs ~= nil then
        self.RuntimeLogUIInstance:RefreshRuntimeLogs()
    end
    self:Client_ShowToast("日志已清空")
end

function UGCPlayerController:OpenRuntimeLogConsole(SearchText)
    RuntimeLog.Info("[LOG_PROBE][CLIENT][INFO] client capture path active")
    RuntimeLog.Warn("[LOG_PROBE][CLIENT][WARN] sample warning for search validation")
    pcall(UnrealNetwork.CallUnrealRPC, self, self, "Server_RuntimeLogProbe")
    local Existing = self.RuntimeLogUIInstance
    if Existing ~= nil and (UE.IsValid == nil or UE.IsValid(Existing)) then
        Existing:SetVisibility(ESlateVisibility.Visible)
        if Existing.OpenRuntimeLogs ~= nil then
            Existing:OpenRuntimeLogs(tostring(SearchText or ""))
        end
        self:RequestRuntimeLogSync()
        return
    end

    local UIClass = UE.LoadClass(UGCGameSystem.GetUGCResourcesFullPath(
        "Asset/Blueprint/UI/GMLogConsole.GMLogConsole_C"))
    if UIClass == nil then
        self:Client_ShowToast("日志界面加载失败")
        ugcprint("[RuntimeLogUI] GMLogConsole class load failed")
        return
    end
    local Widget = UserWidget.NewWidgetObjectBP(self, UIClass)
    if Widget == nil then
        self:Client_ShowToast("日志界面创建失败")
        ugcprint("[RuntimeLogUI] GMLogConsole widget create failed")
        return
    end
    self.RuntimeLogUIInstance = Widget
    Widget:AddToViewport(12000)
    if Widget.OpenRuntimeLogs ~= nil then
        Widget:OpenRuntimeLogs(tostring(SearchText or ""))
    end
    self:RequestRuntimeLogSync()
end

-- Compatibility aliases keep existing GM scripts working while using the new console.
function UGCPlayerController:OpenGMResetLogUI(SearchText)
    self:OpenRuntimeLogConsole(SearchText)
end

function UGCPlayerController:ClearGMResetLogs()
    self:ClearRuntimeLogs()
end

--- GM 重置完成后的客户端收口刷新，不触发“突破成功/失败”等业务提示。
function UGCPlayerController:Client_PlayerDataResetStarted()
    RuntimeLog.Info("[TagLog] [GMReset] [CLIENT][started] player=" .. tostring(self.PlayerKey) ..
        " resetInProgress=true serverSync=false")
    local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
    if StateMgr ~= nil then
        StateMgr.bPlayerDataResetInProgress = true
        StateMgr.bServerSynced = false
    end
end

function UGCPlayerController:Client_PlayerDataResetFailed()
    RuntimeLog.Error("[TagLog] [GMReset] [CLIENT][failed] player=" .. tostring(self.PlayerKey) ..
        " resetInProgress=false refreshRequested=true")
    local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
    if StateMgr ~= nil then
        StateMgr.bPlayerDataResetInProgress = false
        StateMgr.bServerSynced = false
    end
    UnrealNetwork.CallUnrealRPC(self, self, "Server_RequestRefreshProperty")
end

function UGCPlayerController:Client_PlayerDataReset()
    RuntimeLog.Info("[TagLog] [GMReset] [CLIENT][completed_received] player=" .. tostring(self.PlayerKey) ..
        " applyingLocalDefaults=true")
    self.RealmLevel = 1
    self.UnlockedTitles = {}
    self.EquippedTitleID = 0
    local PlayerState = self.PlayerState
    if PlayerState ~= nil then
        PlayerState.HunHuan = 1
        PlayerState.Probability_Bonus = 100
        PlayerState.BaseAttack = 40
        PlayerState.BaseMaxHp = 100
        PlayerState.PlayerLevel = 1
        PlayerState.PlayerExp = 0
        PlayerState.PlayerMaxExp = 60
        PlayerState.LotteryState = {}
        PlayerState.WeaponLevels = {}
        PlayerState.UnlockedTitles = {}
        PlayerState.KillMonsterCount = 0
        PlayerState.EquippedTitleID = 0
    end

    local PlayerPawn = self:K2_GetPawn()
    if PlayerPawn ~= nil and PlayerPawn.RefreshSoulMesh ~= nil then
        PlayerPawn:RefreshSoulMesh(1)
    end
    if self.MainUIInstance ~= nil and self.MainUIInstance.RefreshRealmNameText ~= nil then
        self.MainUIInstance:RefreshRealmNameText()
    end

    local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
    if StateMgr ~= nil then
        StateMgr.bPlayerDataResetInProgress = false
        StateMgr.bServerSynced = false
        StateMgr.BaseAttack = 40
        StateMgr.BaseMaxHp = 100
    end
    local TitleUI = self.MainUIInstance and self.MainUIInstance.TitleUIInstance or nil
    if TitleUI ~= nil then
        TitleUI.SelectedTitleID = nil
    end
    self:Client_SyncTitleState({}, 0, 0)
    if StateMgr ~= nil and StateMgr.UI ~= nil and StateMgr.JingJieTextShow ~= nil then
        StateMgr:ChiBangTextShow(0, true)
        StateMgr:WuQiTextShow(0, true, 0, 0)
        StateMgr:ChengHaoTextShow(0, true)
        StateMgr:JingJieTextShow(1, true)
        StateMgr:CountAll(nil, 100, 100, true)
    end
    RuntimeLog.Info("[TagLog] [GMReset] [CLIENT][refresh_complete] player=" .. tostring(self.PlayerKey) ..
        " level=1 exp=0 realm=1 attack=40 maxHp=100 titles=0 returnToLobby=false")

    -- 重置完成后停留在当前对局，避免自动 ReturnToLobby 触发官方大厅 UI 初始化问题。
    -- 玩家可使用大厅/退出入口手动返回大厅。
end

--[[-------------------------固定添加属性---------------------]] --
local function FormatAFKRewardValue(value)
    local text = string.format("%.2f", tonumber(value) or 0)
    text = string.gsub(text, "0+$", "")
    text = string.gsub(text, "%.$", "")
    return text
end

function UGCPlayerController:Server_AddFixedBaseProperty()
    if self.bGMResetInProgress == true then
        ugcprint("[GMReset] fixed property reward blocked during reset player=" .. tostring(self.PlayerKey))
        return
    end
    local playerState = self.PlayerState
    if playerState == nil then
        return
    end

    local baseAttack = playerState:GetBaseAttack()
    local baseMaxHp = playerState:GetBaseMaxHp()
    local addAttack = 1
    local addMaxHp = 5

    if baseMaxHp >= 10000 then
        addAttack = baseAttack * 0.0001
        addMaxHp = baseMaxHp * 0.0005
    end

    local newBaseAttack = baseAttack + addAttack
    local newBaseMaxHp = baseMaxHp + addMaxHp

    playerState:SetBaseAttack(newBaseAttack)
    playerState:SetBaseMaxHp(newBaseMaxHp)

    UnrealNetwork.CallUnrealRPC(self, self, "Client_RefreshProperty", newBaseAttack, newBaseMaxHp)
    local rewardText = "挂机修炼收益：最大生命 +" .. FormatAFKRewardValue(addMaxHp) ..
                           "，攻击 +" .. FormatAFKRewardValue(addAttack)
    UnrealNetwork.CallUnrealRPC(self, self, "Client_ShowToast", rewardText)
    ugcprint("[AFKZone] reward player=" .. tostring(self.PlayerKey) ..
                 " addMaxHp=" .. tostring(addMaxHp) .. " addAttack=" .. tostring(addAttack))
end

function UGCPlayerController:Client_SetTowerOutBoxVisible(bVisible)
    local bShow = bVisible == true or bVisible == 1
    if self.MainUIInstance ~= nil and self.MainUIInstance.SetTowerOutBoxImageVisible ~= nil then
        self.MainUIInstance:SetTowerOutBoxImageVisible(bShow)
    end

    if bShow then
        self:PlayTowerAttentionSound()
    else
        self:StopTowerAttentionSound()
    end
end

function UGCPlayerController:PlayTowerAttentionSound()
    self.TowerAttentionSoundCount = (self.TowerAttentionSoundCount or 0) + 1
    if self.TowerAttentionSoundID ~= nil then
        return
    end

    local FullPath = UGCGameSystem.GetUGCResourcesFullPath(TOWER_ATTENTION_SOUND_PATH)
    local SoundAsset = UE.LoadObject(FullPath)
    if SoundAsset == nil then
        self.TowerAttentionSoundCount = nil
        return
    end

    local Pawn = GetPlayerPawn(self)
    if Pawn == nil then
        self.TowerAttentionSoundCount = nil
        return
    end

    self.TowerAttentionSoundID = UGCSoundManagerSystem.PlaySoundAttachActor(SoundAsset, Pawn, true)
end

function UGCPlayerController:StopTowerAttentionSound()
    local SoundCount = (self.TowerAttentionSoundCount or 1) - 1
    if SoundCount > 0 then
        self.TowerAttentionSoundCount = SoundCount
        return
    end

    self.TowerAttentionSoundCount = nil
    if self.TowerAttentionSoundID == nil then
        return
    end

    UGCSoundManagerSystem.StopSoundByID(self.TowerAttentionSoundID)
    self.TowerAttentionSoundID = nil
end

function UGCPlayerController:StopTowerAttentionSoundImmediately()
    self.TowerAttentionSoundCount = nil
    if self.TowerAttentionSoundID ~= nil then
        UGCSoundManagerSystem.StopSoundByID(self.TowerAttentionSoundID)
        self.TowerAttentionSoundID = nil
    end
end

function UGCPlayerController:Client_YXWDInvincibleBuffChanged(bEnabled, DurationSeconds)
    self.ClientYXWDInvincibleBuffEnabled = bEnabled == true or tonumber(bEnabled) == 1
    self.ClientYXWDInvincibleBuffDurationSeconds = tonumber(DurationSeconds) or -2

    if self.PlayerState ~= nil and self.ClientYXWDInvincibleBuffEnabled == true then
        self.PlayerState.YXWD_InvincibleBuff = 1
    end

    if self.MainUIInstance ~= nil and self.MainUIInstance.OnYXWDInvincibleBuffChanged ~= nil then
        self.MainUIInstance:OnYXWDInvincibleBuffChanged(bEnabled, DurationSeconds)
    end
end

--[[------------------------自动拾取----------------------]] --
function UGCPlayerController:Server_SetYXWDInvincibleBuffActive(bEnabled)
    local PlayerState = self.PlayerState
    if PlayerState == nil then
        return
    end

    local bHasBuff = false
    if PlayerState.GetYXWD_InvincibleBuff ~= nil then
        bHasBuff = PlayerState:GetYXWD_InvincibleBuff() == true
    else
        bHasBuff = tonumber(PlayerState.YXWD_InvincibleBuff) == 1
    end

    if not bHasBuff then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_YXWDInvincibleActiveChanged", 0)
        return
    end

    local bActive = bEnabled == true or tonumber(bEnabled) == 1
    if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
        PlayerState:SetYXWD_InvincibleBuffActive(bActive)
    else
        PlayerState.YXWD_InvincibleBuffActive = bActive
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_YXWDInvincibleActiveChanged", bActive and 1 or 0)
end

function UGCPlayerController:Client_YXWDInvincibleActiveChanged(bActive)
    if self.MainUIInstance ~= nil and self.MainUIInstance.OnYXWDInvincibleActiveChanged ~= nil then
        self.MainUIInstance:OnYXWDInvincibleActiveChanged(bActive)
    end
end

function UGCPlayerController:Server_SetFinalMaxHp(finalMaxHp, bFillHealth)
    if self.bGMResetInProgress == true then
        return
    end
    local pawn = self.Pawn
    if pawn == nil then
        return
    end
    -- 存档加载前拒绝客户端 RPC，防止默认值覆盖服务器正确属性
    local playerState = self.PlayerState
    if playerState ~= nil and playerState.bArchiveLoaded ~= true then
        return
    end
    finalMaxHp = tonumber(finalMaxHp) or 100
    local oldMaxHp = UGCPawnAttrSystem.GetHealthMax(pawn) or finalMaxHp
    local oldHp = UGCPawnAttrSystem.GetHealth(pawn) or oldMaxHp
    UGCPawnAttrSystem.SetHealthMax(pawn, finalMaxHp)

    if bFillHealth then
        oldHp = finalMaxHp
    else
        local addHp = finalMaxHp - oldMaxHp
        if addHp > 0 then
            oldHp = oldHp + addHp
        end
    end
    UGCPawnAttrSystem.SetHealth(pawn, math.min(oldHp, finalMaxHp))
    TitleMgr:CheckCombatPowerTitles(self)
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.SyncTeamUI ~= nil then
        GameMode:SyncTeamUI()
    end
end

function UGCPlayerController:Server_SetFinalAttack(finalAttack)
    if self.bGMResetInProgress == true then
        return
    end
    local pawn = self.Pawn
    if pawn == nil then
        return
    end
    -- 客户端参数不包含排行加成；排行百分比只从服务端 PlayerState 读取并补入。
    finalAttack = tonumber(finalAttack) or 40
    -- 存档加载前仅拒绝默认值（40），防止用默认 AttackPower 覆盖服务器正确属性；
    -- 但如果客户端已计算出武器/境界加成后的非默认值，则允许通过。
    local playerState = self.PlayerState
    if playerState ~= nil and playerState.bArchiveLoaded ~= true and finalAttack <= 40 then
        return
    end
    if playerState ~= nil then
        local baseAttack = TalentEffectMgr:GetEffectiveBaseAttack(playerState)
        local rankBonus = playerState.GetRankAttackBonus ~= nil and tonumber(playerState:GetRankAttackBonus()) or
                              (tonumber(playerState.RankAttackBonus) or 0)
        finalAttack = finalAttack + (baseAttack or 40) * math.max(0, rankBonus or 0) / 100
    end
    UGCAttributeSystem.SetGameAttributeValue(pawn, "AttackPower", finalAttack)
    TitleMgr:CheckCombatPowerTitles(self)
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.SyncTeamUI ~= nil then
        GameMode:SyncTeamUI()
    end
end

local AUTO_PICK_RANGE = 600
local AUTO_PICK_INTERVAL = 0.5
function UGCPlayerController:Server_SetAutoPickEnabled(bEnabled)
    self.bAutoPickEnabled = bEnabled
    local TimerName = "AutoPick_" .. tostring(self.PlayerKey)
    UGCTimerUtility.RemoveLuaTimerByName(TimerName)
    if not bEnabled then
        return
    end

    UGCTimerUtility.CreateLuaTimer(AUTO_PICK_INTERVAL, function()
        local Location = self.Pawn:K2_GetActorLocation()
        local Wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(Location, AUTO_PICK_RANGE)

        for _, Wrappers in pairs(Wrappers) do
            UGCItemSystemV2.TryPickupWrapperItem(self.Pawn, Wrappers, nil, Wrappers:GetItemCount(), true)
        end
    end, true, TimerName)

    --[[--------------------这边测试加战力--------------------------]] --
    -- local pawn = self.Pawn or self:K2_GetPawn()
    -- L_Com.UseHunHuan(pawn, 8310055, 100)
end

--[[----------------------自动攻击------------------------]] --
function UGCPlayerController:StopAutoMeleeAttack()
    UGCTimerUtility.RemoveLuaTimerByName("AutoMeleeAttack")
end

local Auto_Melee_Attack = 0.45
local function TriggerMeleeWeaponAttack(Weapon)
    local PressEvent = EWeaponTriggerEvent.EWeaponTriggerEvent_PressFuncBtn
    local ReleaseEvent = EWeaponTriggerEvent.EWeaponTriggerEvent_ReleaseFuncBtn
    Weapon:TriggerWeaponEvent(PressEvent, "")
    Weapon:TriggerWeaponEvent(ReleaseEvent, "")
end

function UGCPlayerController:StartAutoMeleeAttack()
    UGCTimerUtility.RemoveLuaTimerByName("AutoMeleeAttack")
    UGCTimerUtility.CreateLuaTimer(Auto_Melee_Attack, function()
        self:TryAutoMeleeAttack()
    end, true, "AutoMeleeAttack")
end

function UGCPlayerController:Client_StartAutoMeleeAttack()
    self:StartAutoMeleeAttack()
    if self.MainUIInstance ~= nil then
        self.MainUIInstance.bAutoMeleeAttackEnabled = true
    end
end

function UGCPlayerController:Server_SetAutoFeatureButtonHidden(FeatureName)
    if self.PlayerState == nil then
        return
    end

    EnsurePlayerStateArchiveUID(self)

    if FeatureName == "AutoPick" then
        if self.PlayerState.SetAutoPickButtonHidden ~= nil then
            self.PlayerState:SetAutoPickButtonHidden(true)
        else
            self.PlayerState.AutoPickButtonHidden = 1
            if self.PlayerState.SaveToArchive ~= nil then
                self.PlayerState:SaveToArchive()
            end
        end
    elseif FeatureName == "AutoAttack" then
        if self.PlayerState.SetAutoAttackButtonHidden ~= nil then
            self.PlayerState:SetAutoAttackButtonHidden(true)
        else
            self.PlayerState.AutoAttackButtonHidden = 1
            if self.PlayerState.SaveToArchive ~= nil then
                self.PlayerState:SaveToArchive()
            end
        end
    else
        return
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_SetAutoFeatureButtonHidden", FeatureName)
end

function UGCPlayerController:Client_SetAutoFeatureButtonHidden(FeatureName)
    if self.PlayerState ~= nil then
        if FeatureName == "AutoPick" then
            self.PlayerState.AutoPickButtonHidden = 1
            self.ClientAutoPickButtonHidden = true
        elseif FeatureName == "AutoAttack" then
            self.PlayerState.AutoAttackButtonHidden = 1
            self.ClientAutoAttackButtonHidden = true
        end
    elseif FeatureName == "AutoPick" then
        self.ClientAutoPickButtonHidden = true
    elseif FeatureName == "AutoAttack" then
        self.ClientAutoAttackButtonHidden = true
    end

    if self.MainUIInstance ~= nil and self.MainUIInstance.RefreshYXWDPurchaseButton ~= nil then
        self.MainUIInstance:RefreshYXWDPurchaseButton()
    end

    if FeatureName == "AutoAttack" and self.MainUIInstance ~= nil and
        self.MainUIInstance.EnableDefaultAutoAttackIfUnlocked ~= nil then
        self.MainUIInstance:EnableDefaultAutoAttackIfUnlocked()
    end
end

function UGCPlayerController:Server_SetFeiButton0Hidden(value)
    if self.PlayerState == nil then
        return
    end

    if (self.PlayerState.ArchiveUID == nil or self.PlayerState.ArchiveUID == 0) and self.Pawn ~= nil and
        UGCPawnAttrSystem ~= nil and UGCPawnAttrSystem.GetPlayerUID ~= nil then
        self.PlayerState.ArchiveUID = tonumber(UGCPawnAttrSystem.GetPlayerUID(self.Pawn))
    end

    if self.PlayerState.SetFeiButton0Hidden ~= nil then
        self.PlayerState:SetFeiButton0Hidden(value)
    else
        self.PlayerState.FeiButton0Hidden = (value == true or tonumber(value) == 1) and 1 or 0
        if self.PlayerState.SaveToArchive ~= nil then
            self.PlayerState:SaveToArchive()
        end
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_SetFeiButton0Hidden", value)
end

function UGCPlayerController:Client_SetFeiButton0Hidden(value)
    if self.PlayerState ~= nil then
        self.PlayerState.FeiButton0Hidden = (value == true or tonumber(value) == 1) and 1 or 0
    end

    if self.FeiUIInstance ~= nil and self.FeiUIInstance.RefreshButton0Visibility ~= nil then
        self.FeiUIInstance:RefreshButton0Visibility()
    end
end

function UGCPlayerController:Client_SetFeiTowerButtonsHidden(value)
    if value == true or tonumber(value) == 1 then
        self.PendingFeiTowerButtonsHiddenCount = (self.PendingFeiTowerButtonsHiddenCount or 0) + 1
    else
        self.PendingFeiTowerButtonsHiddenCount = math.max(0,
            (self.PendingFeiTowerButtonsHiddenCount or 0) - 1)
    end
    if self.FeiUIInstance ~= nil and self.FeiUIInstance.SetTowerButtonsHidden ~= nil then
        self.FeiUIInstance:SetTowerButtonsHidden(value)
    end
end

function UGCPlayerController:Client_ResetFeiTowerButtonsHidden()
    self.PendingFeiTowerButtonsHiddenCount = 0
    if self.FeiUIInstance ~= nil and self.FeiUIInstance.ResetTowerButtonsHidden ~= nil then
        self.FeiUIInstance:ResetTowerButtonsHidden()
    end
end

local function SetDamageNumberItemText(Item, Text)
    Item.Text = Text
end

local function SetDamageNumberItemImage(Item, ImagePath)
    Item.Text = ""
    Item.ImagePath = ImagePath
    Item.ImageScaleX = 3
    Item.ImageScaleY = 4
end

function UGCPlayerController:Client_ShowMonsterDamageNumber(TargetActor, Damage)
    if TargetActor == nil then
        return
    end

    local Params = UGCGameSystem.MakeCustomDamageNumberParams()
    local TextItem = {}
    local NumberText, _, UnitImagePath = Ma_NumShow.GetNumShowData(Damage)
    SetDamageNumberItemText(TextItem, NumberText)

    if UnitImagePath ~= nil then
        local UnitItem = {}
        SetDamageNumberItemImage(UnitItem, UnitImagePath)
        Params.Items = {TextItem, UnitItem}
    else
        Params.Items = {TextItem}
    end

    UGCGameSystem.AddUGCCustomDamageNumber(self, TargetActor, Params)
end

local function ResolveWQHitEffectPath(EffectPath)
    if type(EffectPath) ~= "string" or EffectPath == "" then
        return DEFAULT_WQ_HIT_EFFECT_PATH
    end

    if string.sub(EffectPath, 1, 1) == "/" then
        return EffectPath
    end

    if UGCGameSystem ~= nil and UGCGameSystem.GetUGCResourcesFullPath ~= nil then
        local Success, FullPath = pcall(UGCGameSystem.GetUGCResourcesFullPath, EffectPath)
        if Success and type(FullPath) == "string" and FullPath ~= "" then
            return FullPath
        end
    end

    return EffectPath
end

function UGCPlayerController:Client_PlayWQHitEffect(TargetActor, EffectPath)
    if TargetActor == nil or TargetActor.K2_GetActorLocation == nil then
        return
    end

    local success, location = pcall(TargetActor.K2_GetActorLocation, TargetActor)
    if success and location ~= nil then
        L_Com.PlayParticleAtLocation(self, ResolveWQHitEffectPath(EffectPath), location, nil, {X = 2, Y = 2, Z = 2})
    end
end

function UGCPlayerController:TryAutoMeleeAttack()
    local Pawn = self.Pawn
    local MeleeSlot = ESurviveWeaponPropSlot.SWPS_MeleeWeapon
    if tonumber(UGCWeaponManagerSystem.GetCurrentWeaponSlot(Pawn)) == tonumber(MeleeSlot) then
        TriggerMeleeWeaponAttack(UGCWeaponManagerSystem.GetCurrentWeapon(Pawn))
    end
end

--[[----------------------补偿系统----------------------]] --
-- 注册补偿系统委托
-- 服务器注册全部3个委托，客户端只注册单笔补偿委托
function UGCPlayerController:RegisterCompensationDelegates()
    if UGCCommoditySystem == nil then
        return
    end

    -- 单笔补偿（服务器&客户端都会收到）
    if UGCCommoditySystem.CompensateUGCCommodityDelegate ~= nil then
        UGCCommoditySystem.CompensateUGCCommodityDelegate:Add(self.OnCompensateUGCCommodity, self)
    end

    -- 以下两个委托仅服务器
    if self:HasAuthority() then
        if UGCCommoditySystem.CompensateUGCCommodityBatchDelegate ~= nil then
            UGCCommoditySystem.CompensateUGCCommodityBatchDelegate:Add(self.OnCompensateUGCCommodityBatch, self)
        end
        if UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate ~= nil then
            UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate:Add(self.OnBuyUGCCommodityResultBetweenGames,
                self)
        end
    end

    print("[Compensation] RegisterCompensationDelegates: isServer=" .. tostring(self:HasAuthority()))
end

-- 注销补偿系统委托
function UGCPlayerController:UnregisterCompensationDelegates()
    if UGCCommoditySystem == nil then
        return
    end

    if UGCCommoditySystem.CompensateUGCCommodityDelegate ~= nil then
        UGCCommoditySystem.CompensateUGCCommodityDelegate:Remove(self.OnCompensateUGCCommodity, self)
    end

    if self:HasAuthority() then
        if UGCCommoditySystem.CompensateUGCCommodityBatchDelegate ~= nil then
            UGCCommoditySystem.CompensateUGCCommodityBatchDelegate:Remove(self.OnCompensateUGCCommodityBatch, self)
        end
        if UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate ~= nil then
            UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate:Remove(
                self.OnBuyUGCCommodityResultBetweenGames, self)
        end
    end
end

function UGCPlayerController:ReceiveEndPlay()
    self:StopTowerAttentionSoundImmediately()
    self:UnregisterCompensationDelegates()
end

--- 单笔补偿回调（服务器&客户端都会收到）
---@param PlayerKey number
---@param UID number
---@param CommodityID number 物品ID（对应UGCObject表）
---@param Count number 补偿数量
---@param ProductID number 商品ID（对应UGCShop表）
function UGCPlayerController:OnCompensateUGCCommodity(PlayerKey, UID, CommodityID, Count, ProductID)
    print(string.format(
        "[Compensation] OnCompensateUGCCommodity: PlayerKey=%s UID=%s CommodityID=%s Count=%s ProductID=%s",
        tostring(PlayerKey), tostring(UID), tostring(CommodityID), tostring(Count), tostring(ProductID)))

    -- 服务器收到后转发给对应客户端
    if self:HasAuthority() then
        local TargetPC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
        if TargetPC ~= nil then
            UnrealNetwork.CallUnrealRPC(self, TargetPC, "Client_CompensationReceived", CommodityID, Count, ProductID)
        end
    end
end

--- 批量补偿回调（仅服务器）
---@param PlayerKey number
---@param UID number
---@param CommodityList table 补偿商品列表
function UGCPlayerController:OnCompensateUGCCommodityBatch(PlayerKey, UID, CommodityList)
    print(string.format("[Compensation] OnCompensateUGCCommodityBatch: PlayerKey=%s UID=%s count=%d",
        tostring(PlayerKey), tostring(UID), #CommodityList))

    local TargetPC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
    if TargetPC == nil then
        return
    end

    -- 逐个转发给客户端
    for _, item in ipairs(CommodityList) do
        UnrealNetwork.CallUnrealRPC(self, TargetPC, "Client_CompensationReceived", item.CommodityID, item.Count,
            item.ProductID or 0)
    end
end

--- 跨局商品变化回调（仅服务器）
---@param PlayerKey number
---@param UID number
---@param CommodityID number 物品ID
---@param Count number 新增的差异数量
function UGCPlayerController:OnBuyUGCCommodityResultBetweenGames(PlayerKey, UID, CommodityID, Count)
    print(string.format(
        "[Compensation] OnBuyUGCCommodityResultBetweenGames: PlayerKey=%s UID=%s CommodityID=%s Count=%s",
        tostring(PlayerKey), tostring(UID), tostring(CommodityID), tostring(Count)))

    local TargetPC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
    if TargetPC == nil then
        return
    end

    -- 转发给客户端弹窗（ProductID传0表示跨局变化，非补偿购买）
    UnrealNetwork.CallUnrealRPC(self, TargetPC, "Client_CompensationReceived", CommodityID, Count, 0)
end

--- 客户端收到补偿通知后弹窗
---@param CommodityID number 物品ID
---@param Count number 数量
---@param ProductID number 商品ID（0表示跨局变化）
function UGCPlayerController:Client_CompensationReceived(CommodityID, Count, ProductID)
    print(string.format("[Compensation] Client_CompensationReceived: CommodityID=%s Count=%s ProductID=%s",
        tostring(CommodityID), tostring(Count), tostring(ProductID)))

    -- 复用 ShopV2Manager 的弹窗
    if ShopV2Manager ~= nil and ShopV2Manager.ShowItemGetPopup ~= nil then
        ShopV2Manager:ShowItemGetPopup(CommodityID, Count)
    else
        print("[Compensation] ShopV2Manager not available, popup skipped")
    end
end

--- GM测试补偿系统（客户端调用，服务器执行模拟补偿）
---@param TestType number 1=单笔 2=批量 3=跨局
---@param CommodityID number 物品ID（默认1001）
---@param Count number 数量（默认5）
function UGCPlayerController:Server_TestCompensation(TestType, CommodityID, Count)
    if not self:HasAuthority() then
        return
    end
    TestType = tonumber(TestType) or 1
    CommodityID = tonumber(CommodityID) or 1001
    Count = tonumber(Count) or 5

    print(string.format("[Compensation][GM] Server_TestCompensation: type=%d item=%d count=%d", TestType, CommodityID,
        Count))

    if TestType == 1 then
        -- 模拟单笔补偿
        self:OnCompensateUGCCommodity(self.PlayerKey, 0, CommodityID, Count, 9000001)
    elseif TestType == 2 then
        -- 模拟批量补偿
        local list = {{
            CommodityID = CommodityID,
            Count = Count,
            ProductID = 9000001
        }, {
            CommodityID = CommodityID + 1,
            Count = Count + 2,
            ProductID = 9000002
        }}
        self:OnCompensateUGCCommodityBatch(self.PlayerKey, 0, list)
    elseif TestType == 3 then
        -- 模拟跨局商品变化
        self:OnBuyUGCCommodityResultBetweenGames(self.PlayerKey, 0, CommodityID, Count)
    end
end

--[[----------------------测试兑换码------------------------]]
function UGCPlayerController:UseRedemptionCode(RedemptionCode)
    if not self.bUseRedemptionCodeResultDelegateInit then
        self.bUseRedemptionCodeResultDelegateInit = true
        UGCCommoditySystem.UseRedemptionCodeResultDelegate:Add(self.OnUseRedemptionCodeResult, self)
    end

    local PlayerPawn = self:GetPlayerCharacterSafety()
    local UID = UGCPawnAttrSystem.GetPlayerUID(PlayerPawn)
    print(string.format("[UseRedemptionCode] UID=%s Code=%s", tostring(UID), tostring(RedemptionCode)))
    UGCCommoditySystem.UseRedemptionCode(tonumber(UID), RedemptionCode)
end

--[[----------------------打印兑换码结果------------------------]]
function UGCPlayerController:OnUseRedemptionCodeResult(Result, PlayerKey, UID, CommodityID, Count, ProductID)
    if Result == EUseRedemptionCodeResult.Success then
        print(string.format("[UseRedemptionCode] Success UID=%s CommodityID=%s Count=%s ProductID=%s", tostring(UID),
            tostring(CommodityID), tostring(Count), tostring(ProductID)))
    else
        print(string.format("[UseRedemptionCode] Failed Result=%s UID=%s PlayerKey=%s", tostring(Result), tostring(UID),
            tostring(PlayerKey)))
    end
end

return UGCPlayerController
