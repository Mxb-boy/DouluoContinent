---@class UGCGameMode_C:BP_UGCGameBase_C
-- Edit Below--
local UGCGameMode = {};
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
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
        DropCleanupSystem.StartSafetyValveTimer()
    end
end

-- ============================================================
-- 自动补位玩家修复：将非大厅组队的自动补位玩家踢到独立队伍
-- ============================================================

local function GetUnusedTeamID()
    local AllTeamIDs = UGCTeamSystem.GetTeamIDs() or {}
    local UsedIDs = {}
    for _, tid in ipairs(AllTeamIDs) do
        UsedIDs[tostring(tid)] = true
    end
    for id = 100, 999 do
        if not UsedIDs[tostring(id)] then
            return id
        end
    end
    return nil
end

local function FixAutoMatchedPlayer(PlayerController)
    if PlayerController == nil then
        return
    end
    local PlayerKey = PlayerController.PlayerKey
    if PlayerKey == nil then
        return
    end

    local TeamID = UGCTeamSystem.GetTeamIDByPlayerKey(PlayerKey)
    if TeamID == nil then
        return
    end

    local TeamPlayerKeys = UGCTeamSystem.GetPlayerKeysByTeamID(TeamID)
    if TeamPlayerKeys == nil or #TeamPlayerKeys <= 1 then
        return
    end

    local LobbyMates = UGCTeamSystem.GetLobbyTeammatePlayerKeysByPlayerKey(PlayerKey)
    local bHasLobbyMateOnTeam = false
    if LobbyMates ~= nil then
        for _, MatePK in ipairs(LobbyMates) do
            for _, TeamPK in ipairs(TeamPlayerKeys) do
                if tostring(MatePK) == tostring(TeamPK) then
                    bHasLobbyMateOnTeam = true
                    break
                end
            end
            if bHasLobbyMateOnTeam then
                break
            end
        end
    end

    if not bHasLobbyMateOnTeam then
        local NewTeamID = GetUnusedTeamID()
        if NewTeamID ~= nil then
            UGCTeamSystem.ChangePlayerTeamID(PlayerKey, NewTeamID)
            ugcprint("[UGCGameMode] Auto-matched player " .. tostring(PlayerKey) ..
                         " reassigned from team " .. tostring(TeamID) .. " to team " .. tostring(NewTeamID))
        end
    end
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

    -- 5秒后修复自动补位玩家（确保PlayerKey已初始化，队伍分配已完成）
    UGCTimerUtility.CreateLuaTimer(5, function()
        FixAutoMatchedPlayer(PC)
    end, false)
end

-- 此事件提供死亡前的旧 Pawn，必须在这里读取背包和血量。
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
