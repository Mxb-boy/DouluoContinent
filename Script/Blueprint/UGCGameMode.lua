---@class UGCGameMode_C:BP_UGCGameBase_C
--Edit Below--
local UGCGameMode = {};
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")

-- 保存玩家死亡前的背包快照，键为 PlayerKey。
local PlayerBackpackSnapshots = {};

local WingActorClassPaths = {
    "Asset/ChiBang/Models/Model1/cb_1.cb_1_C",
    "Asset/ChiBang/Models/Model10/CB_2.CB_2_C",
    "Asset/ChiBang/Models/Model11/CB_3.CB_3_C",
    "Asset/ChiBang/Models/Model12/CB_4.CB_4_C",
    "Asset/ChiBang/Models/Model8/CB_T5.CB_T5_C",
    "Asset/ChiBang/Models/Model9/cb_6.cb_6_C",
}
local WingDestroyDistanceSq = 200 * 200

local function IsActorNearPawn(Actor, PlayerPawn)
    if Actor == nil or PlayerPawn == nil or Actor.K2_GetActorLocation == nil or PlayerPawn.K2_GetActorLocation == nil then
        return false
    end

    local ActorOk, ActorLocation = pcall(Actor.K2_GetActorLocation, Actor)
    local PawnOk, PawnLocation = pcall(PlayerPawn.K2_GetActorLocation, PlayerPawn)
    if not ActorOk or not PawnOk or ActorLocation == nil or PawnLocation == nil then
        return false
    end

    local DX = (ActorLocation.X or 0) - (PawnLocation.X or 0)
    local DY = (ActorLocation.Y or 0) - (PawnLocation.Y or 0)
    local DZ = (ActorLocation.Z or 0) - (PawnLocation.Z or 0)
    return DX * DX + DY * DY + DZ * DZ <= WingDestroyDistanceSq
end

local function IsActorOwnedByPawn(Actor, PlayerPawn)
    if Actor == nil or PlayerPawn == nil then
        return false
    end

    if Actor.OwnerPawn == PlayerPawn then
        return true
    end

    if UGCActorComponentUtility ~= nil and UGCActorComponentUtility.GetOwner ~= nil then
        local Success, Owner = pcall(UGCActorComponentUtility.GetOwner, Actor)
        if Success and Owner == PlayerPawn then
            return true
        end
    end

    return IsActorNearPawn(Actor, PlayerPawn)
end

local function DestroyPlayerWingActors(PlayerPawn)
    if PlayerPawn == nil or UGCActorComponentUtility == nil or UGCActorComponentUtility.GetAllActorsOfClass == nil then
        return
    end

    local RootPath = UGCMapInfoLib.GetRootLongPackagePath()
    for _, ClassPath in ipairs(WingActorClassPaths) do
        local WingClass = UE.LoadClass(RootPath .. ClassPath)
        if WingClass ~= nil then
            local WingActors = UGCActorComponentUtility.GetAllActorsOfClass(PlayerPawn, WingClass)
            for _, WingActor in ipairs(WingActors or {}) do
                if IsActorOwnedByPawn(WingActor, PlayerPawn) then
                    WingActor:K2_DestroyActor()
                end
            end
        end
    end
end

local function SaveBackpackSnapshot(PlayerKey, PlayerPawn)
    if not PlayerKey or not PlayerPawn then
        return
    end

    local AllItemData = UGCBackPackSystem.GetAllItemData(PlayerPawn)
    local Snapshot = {}

    if AllItemData then
        for _, ItemData in pairs(AllItemData) do
            local ItemID = tonumber(ItemData.ItemID)
            local Count = tonumber(ItemData.Count) or 0
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
        local CurrentCount = UGCBackPackSystem.GetItemCount(PlayerPawn, ItemID) or 0
        local MissingCount = SavedCount - CurrentCount
        if MissingCount > 0 then
            UGCBackPackSystem.AddItem(PlayerPawn, ItemID, MissingCount)
        end
    end

    PlayerBackpackSnapshots[PlayerKey] = nil
    ugcprint("[UGCGameMode] Backpack restored, PlayerKey=" .. tostring(PlayerKey))
end

function UGCGameMode:ReceiveBeginPlay()
    UGCGenericMessageSystem.ListenGlobalMessage(
        self,
        UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnDefeat,
        self,
        self.OnPawnDefeat
    )
end

-- 玩家登录时: 先加载跨对局存档, 再发初始武器（Pawn可能还没好，等1秒）
function UGCGameMode:UGC_PlayerLoginEvent(PlayerController)
    local PC = PlayerController
    UGCTimerUtility.CreateLuaTimer(1, function()
        if PC.Pawn then
            -- 1. 加载跨对局存档（注入 UID → 恢复所有注册字段）
            local PlayerState = PC.PlayerState
            if PlayerState and PlayerState.LoadFromArchive then
                local UID = UGCPawnAttrSystem.GetPlayerUID(PC.Pawn)
                PlayerState:LoadFromArchive(tonumber(UID))
                if PlayerState.GetYXWD_InvincibleBuff ~= nil and PlayerState:GetYXWD_InvincibleBuff() == true then
                    if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
                        PlayerState:SetYXWD_InvincibleBuffActive(true)
                    else
                        PlayerState.YXWD_InvincibleBuffActive = true
                    end
                    UnrealNetwork.CallUnrealRPC(PC, PC, "Client_YXWDInvincibleBuffChanged", 1, -2)
                end
                -- 恢复上次存档的血量
                if PlayerState.RestoreHP then
                    PlayerState:RestoreHP(PC.Pawn)
                end
                if PC.Pawn.RefreshSoulMesh ~= nil and PlayerState.GetHunHuan ~= nil then
                    PC.Pawn:RefreshSoulMesh(PlayerState:GetHunHuan(), true)
                end
            end

            -- 2. 发初始武器
            for _, ItemID in ipairs(WeaponLevelConfig.GetAllBaseItemIDs()) do
                UGCBackpackSystemV2.AddItemV2(PC.Pawn, ItemID, 1)
            end
            if HTCLv2ItemID ~= nil then
                UGCBackpackSystemV2.AddItemV2(PC.Pawn, HTCLv2ItemID, 1)
            end
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310046, 1)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310047, 1)
            --锻造材料
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310035, 1000)
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
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310048, 10)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310049, 10)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310051, 10)
            UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310053, 10)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310054, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310055, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310056, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310057, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310052, 99)
            -- UGCBackpackSystemV2.AddItemV2(PC.Pawn, 8310050, 99)

            if PC.Pawn.RefreshWeaponAttackBonus ~= nil then
                PC.Pawn:RefreshWeaponAttackBonus(true)
                if PC.Pawn.ForceRefreshPropertySnapshot ~= nil then
                    PC.Pawn:ForceRefreshPropertySnapshot()
                end
            end

        end
    end, false)
end

-- 此事件提供死亡前的旧 Pawn，必须在这里读取背包和血量。
function UGCGameMode:UGC_PlayerKilledEvent(Killer, VictimPlayer, VictimPawn, DamageType)
    if VictimPlayer and VictimPawn then
        DestroyPlayerWingActors(VictimPawn)
        SaveBackpackSnapshot(VictimPlayer.PlayerKey, VictimPawn)
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
        end
    end, false)
end


function UGCGameMode:OnPawnDefeat(VictimPlayerKey, InstigatorPlayerKey, DamageType)
    -- 某些死亡方式不会触发 UGC_PlayerKilledEvent，尝试从 Controller 再保存一次。
    if not PlayerBackpackSnapshots[VictimPlayerKey] then
        local VictimController = UGCGameSystem.GetPlayerControllerByPlayerKey(VictimPlayerKey)
        if VictimController and VictimController.Pawn then
            DestroyPlayerWingActors(VictimController.Pawn)
            SaveBackpackSnapshot(VictimPlayerKey, VictimController.Pawn)
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
        local RespawnedController =
            UGCGameSystem.GetPlayerControllerByPlayerKey(VictimPlayerKey)
        if RespawnedController and RespawnedController.Pawn then
            RestoreBackpackSnapshot(VictimPlayerKey, RespawnedController.Pawn)
        end
    end, false)
end
return UGCGameMode; 
