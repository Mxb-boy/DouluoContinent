---@class UGCPlayerPawn_C:BP_UGCPlayerPawn_C
--Edit Below--
---@class UGCPlayerPawn_C:BP_UGCPlayerPawn_C
-- Edit Below--
local UGCPlayerPawn = {}
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local RealmConfig = UGCGameSystem.UGCRequire("Script.Common.RealmConfig")
local L_Enum_Event = UGCGameSystem.UGCRequire("Script.Lin.L_Enum_Event")
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
local TalentEffectMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentEffectMgr")
local TalentUltimateMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentUltimateMgr")
local AK47Orbit = UGCGameSystem.UGCRequire("Script.utils.AK47Orbit")
local WeaponRefineConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponRefineConfig")
local PlayerLevelMgr = UGCGameSystem.UGCRequire("Script.Lin.PlayerLevelMgr")

local FLY_STATE_TAG = "PawnState.Movement.Flying"
local WEAPON_ATTACK_SOURCE_KEY = "WeaponLevel"
local WEAPON_ATTACK_CHECK_INTERVAL = 0.2
local BACKPACK_WEAPON_ATTACK_PER_ITEM = 5
local PROPERTY_WATCH_CHECK_INTERVAL = 2
local FLY_INTERRUPT_TAGS = {"PawnState.Movement.Walk", "PawnState.Movement.Run", "PawnState.Action.Jump",
                            "PawnState.Action.Crouch", "PawnState.Action.Prone", "PawnState.Action.Reload",
                            "PawnState.Action.Fire", "PawnState.Action.HoldWeapon", "PawnState.Movement.Fall"}
local FLY_DISABLE_TAGS = {"PawnState.Movement.Walk", "PawnState.Movement.Run", "PawnState.Action.Jump",
                          "PawnState.Action.Crouch", "PawnState.Action.Prone", "PawnState.Action.Reload",
                          "PawnState.Action.Fire"}
local SOUL_MESH_PATH = "Asset/Blueprint/Lin/Monster/Model/NewModel/"
local SOUL_SOCKET = "Root"
local SOUL_SCALE = Vector.New(300, 300, 300)
local SOUL_OFFSET = Vector.New(0, 0, 0)
local SOUL_ROTATION = Rotator.New(90, 0, 0)
local DEFAULT_BASE_ATTACK = 40
local WING_ATTACH_PART_TYPE = 61
local WING_ATTACH_FIX_INTERVAL = 0.25
local WING_ATTACH_FIX_ATTEMPTS = 120
local WING_CLEANUP_ATTEMPTS = 120
local bTeamPanelCreated = false
local bLobbyQuitScheduled = false

local function Round2(value)
    value = tonumber(value) or 0
    return math.floor(value * 100 + 0.5) / 100
end

local function NormalizePercent(value)
    value = tonumber(value) or 0
    if math.abs(value) > 1 then
        return value / 100
    end
    return value
end

local function IsLocalPlayerPawn(player)
    if player == nil or UGCGameSystem == nil or UGCGameSystem.GetLocalPlayerPawn == nil then
        return false
    end

    return UGCGameSystem.GetLocalPlayerPawn() == player
end

local function IsValidObject(Object)
    if Object == nil then
        return false
    end
    if UE ~= nil and UE.IsValid ~= nil then
        local Success, bValid = pcall(UE.IsValid, Object)
        return Success and bValid == true
    end
    if Object.IsValid ~= nil then
        local Success, bValid = pcall(Object.IsValid, Object)
        return Success and bValid == true
    end
    return true
end

local function IsSafeWingActorOwner(WingActor, player)
    if UGCActorComponentUtility == nil or UGCActorComponentUtility.GetOwner == nil then
        return true
    end
    local Success, Owner = pcall(UGCActorComponentUtility.GetOwner, WingActor)
    -- Owner 复制可能比 Actor 晚；空 Owner 可以继续等后续校准，但绝不修改属于其他 Pawn 的 Actor。
    return not Success or Owner == nil or Owner == player
end

local function IsWingAttachConfig(Config)
    local Success, ActorClass = pcall(function()
        return Config ~= nil and Config.ActorClass or nil
    end)
    if not Success or ActorClass == nil then
        return false
    end

    local ActorPath = tostring(ActorClass)
    -- BlueprintGeneratedClass 的 UObject 方法不一定能通过实例索引访问；使用 Lua 全局对象接口。
    if UE ~= nil and UE.GetPathName ~= nil then
        local SuccessPath, Path = pcall(UE.GetPathName, ActorClass)
        if SuccessPath and Path ~= nil then
            ActorPath = tostring(Path)
        end
    end
    -- PartType=61 可能也被其他背部装饰使用，只允许本项目 ChiBang 模型目录下的 Actor。
    return string.find(ActorPath, "/Douluo/Asset/ChiBang/Models/", 1, true) ~= nil
end

local function IsAlreadyAttachedToSocket(WingActor, ParentMesh, SocketName)
    local Success, bMatches = pcall(function()
        local Root = WingActor.RootComponent
        if Root == nil or Root.GetAttachSocketName == nil then
            return false
        end
        return Root.AttachParent == ParentMesh and tostring(Root:GetAttachSocketName()) == tostring(SocketName)
    end)
    return Success and bMatches == true
end

-- 装备存档在进场时会很早恢复。远端客户端收到 AttachActorConfigs 时，角色部位 Socket
-- 可能还没有初始化完成，导致翅膀暂时按错误挂点生成；重新穿戴正常也是这个时序差异。
-- 在短时间内用原始配置重新解析 Socket 并应用 Offset，不硬编码任何一款翅膀的变换。
local function RefreshWingActorList(player, Configs, Actors)
    if not IsValidObject(player) or not IsValidObject(player.Mesh) or Configs == nil or Actors == nil or
        UGCBlueprintFunctionLibrary == nil or UGCBlueprintFunctionLibrary.GetMeshSocketBySelector == nil or
        EAttachmentRule == nil then
        return false
    end

    local SuccessLoop, bFixedAny = pcall(function()
        local bFixed = false
        for Index, Config in pairs(Configs) do
            local SuccessConfig, AttachPos, PartType, bUsePartType, Offset = pcall(function()
                local Pos = Config ~= nil and Config.AttachPos or nil
                return Pos, Pos ~= nil and tonumber(Pos.PartType) or nil,
                    Pos ~= nil and Pos.bUsePartType or nil, Pos ~= nil and Pos.Offset or nil
            end)
            if SuccessConfig and IsWingAttachConfig(Config) and AttachPos ~= nil and
                PartType == WING_ATTACH_PART_TYPE and
                bUsePartType ~= false and Offset ~= nil then
                local SuccessActor, WingActor = pcall(function()
                    return Actors[Index]
                end)
                if SuccessActor and IsValidObject(WingActor) and WingActor.K2_AttachToComponent ~= nil and
                    WingActor.K2_SetActorRelativeTransform ~= nil and IsSafeWingActorOwner(WingActor, player) then
                    local SuccessSocket, SocketName = pcall(UGCBlueprintFunctionLibrary.GetMeshSocketBySelector,
                        AttachPos, player)
                    SocketName = SuccessSocket and SocketName or nil
                    local bSocketReady = SocketName ~= nil and tostring(SocketName) ~= "" and
                        tostring(SocketName) ~= "None"
                    if bSocketReady and player.Mesh.DoesSocketExist ~= nil then
                        local SuccessExists, bExists = pcall(player.Mesh.DoesSocketExist, player.Mesh, SocketName)
                        bSocketReady = SuccessExists and bExists == true
                    end
                    if bSocketReady then
                        local SuccessAttach, AttachResult = true, true
                        if not IsAlreadyAttachedToSocket(WingActor, player.Mesh, SocketName) then
                            SuccessAttach, AttachResult = pcall(WingActor.K2_AttachToComponent, WingActor,
                                player.Mesh, SocketName, EAttachmentRule.SnapToTarget,
                                EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget, false)
                        end
                        if SuccessAttach and AttachResult ~= false then
                            local SuccessOffset, OffsetResult = pcall(WingActor.K2_SetActorRelativeTransform,
                                WingActor, Offset, false, {}, false)
                            if SuccessOffset and OffsetResult ~= false then
                                bFixed = true
                            end
                        end
                    end
                end
            end
        end
        return bFixed
    end)
    return SuccessLoop and bFixedAny == true
end

local function RefreshWingAttachments(player)
    if not IsValidObject(player) then
        return false
    end
    -- 纯视觉校准不在专用服务器执行；监听服本机 Pawn 与普通客户端仍会执行。
    if player ~= nil and player.HasAuthority ~= nil and not IsLocalPlayerPawn(player) then
        local SuccessAuthority, bAuthority = pcall(player.HasAuthority, player)
        if SuccessAuthority and bAuthority == true then
            return false
        end
    end

    -- BP_UGCPlayerPawn 明确公开这两个字段；GetItemV2 返回的 BattleItemWrapper 不保证是装备 Handle 子类。
    return RefreshWingActorList(player, player.AttachActorConfigs, player.AttachActors)
end

-- AttachActorConfigs/AttachActors 的复制并非原子操作。卸下翅膀后，远端仍可能在随后几帧
-- 根据旧配置生成 Actor，因此不能只清一次缓存；只清理由本项目翅膀配置生成且属于当前 Pawn 的 Actor。
local function CleanupWingActors(player)
    if not IsValidObject(player) or player.AttachActorConfigs == nil or player.AttachActors == nil then
        return 0
    end

    local SuccessLoop, RemovedCount = pcall(function()
        local Count = 0
        local Candidates = {}
        for Index, Config in pairs(player.AttachActorConfigs) do
            if IsWingAttachConfig(Config) then
                local SuccessActor, WingActor = pcall(function()
                    return player.AttachActors[Index]
                end)
                if SuccessActor and IsValidObject(WingActor) then
                    Candidates[WingActor] = true
                end
            end
        end
        -- 配置数组可能已经先清空，但 Actor 数组里仍留着旧对象。翅膀 Actor 的 Lua
        -- 模块提供统一标记，保证这种“有 Actor、无 Config”的残影也能被识别。
        for _, WingActor in pairs(player.AttachActors) do
            if IsValidObject(WingActor) then
                local SuccessMarker, Marker = pcall(function()
                    return WingActor.IsDouluoWingActor
                end)
                if SuccessMarker and type(Marker) == "function" then
                    local SuccessCall, bIsWing = pcall(Marker, WingActor)
                    if SuccessCall and bIsWing == true then
                        Candidates[WingActor] = true
                    end
                end
            end
        end
        for WingActor in pairs(Candidates) do
            if IsValidObject(WingActor) and IsSafeWingActorOwner(WingActor, player) then
                    local SuccessDestroy = false
                    if WingActor.K2_DestroyActor ~= nil then
                        SuccessDestroy = pcall(WingActor.K2_DestroyActor, WingActor)
                    elseif UGCActorComponentUtility ~= nil and UGCActorComponentUtility.DestroyActor ~= nil then
                        SuccessDestroy = pcall(UGCActorComponentUtility.DestroyActor, WingActor)
                    end
                    if SuccessDestroy then
                        Count = Count + 1
                    end
            end
        end
        return Count
    end)
    return SuccessLoop and (tonumber(RemovedCount) or 0) or 0
end

local function StartWingAttachmentFix(player)
    if not IsValidObject(player) then
        return
    end
    player.WingAttachFixElapsed = 0
    player.WingAttachFixAttemptsLeft = WING_ATTACH_FIX_ATTEMPTS
    player.WingAttachFixSuccesses = 0
end

local function StartWingCleanup(player)
    if not IsValidObject(player) then
        return
    end
    player.WingAttachFixAttemptsLeft = 0
    player.WingCleanupElapsed = 0
    player.WingCleanupAttemptsLeft = WING_CLEANUP_ATTEMPTS
    CleanupWingActors(player)
end

local function ApplyWingVisualState(player)
    local ItemID = tonumber(player ~= nil and player.EquippedWingVisualItemID) or -1
    if ItemID > 0 then
        player.WingCleanupAttemptsLeft = 0
        StartWingAttachmentFix(player)
    elseif ItemID == 0 then
        StartWingCleanup(player)
    end
end

local function GetOrbitWeaponController(Pawn)
    if Pawn == nil then
        return nil
    end
    if Pawn.Controller ~= nil then
        return Pawn.Controller
    end
    if UGCGameSystem.GetPlayerControllerByPlayerPawn ~= nil then
        local Success, Controller = pcall(UGCGameSystem.GetPlayerControllerByPlayerPawn, Pawn)
        if Success then
            return Controller
        end
    end
    return nil
end

-- PlayerState 中保存的等级可能晚于经验值刷新，因此武器解锁统一取可确认的最高等级。
local function GetEffectiveOrbitPlayerLevel(Pawn)
    if Pawn == nil then
        return 1
    end
    local PlayerState = Pawn.PlayerState
    local PlayerLevel = PlayerState ~= nil and PlayerState.GetPlayerLevel ~= nil and
        tonumber(PlayerState:GetPlayerLevel()) or 1
    if PlayerLevelMgr ~= nil and PlayerState ~= nil and PlayerState.GetPlayerExp ~= nil then
        local ExpLevel = PlayerLevelMgr:GetLevelByExp(PlayerState:GetPlayerExp())
        PlayerLevel = math.max(PlayerLevel, tonumber(ExpLevel) or 1)
    end
    local OrbitController = GetOrbitWeaponController(Pawn)
    PlayerLevel = math.max(PlayerLevel,
        OrbitController ~= nil and tonumber(OrbitController.ClientPlayerLevel) or 1)
    return PlayerLevel
end

local function BuildOrbitWeaponCode(Tier)
    Tier = math.max(0, math.min(8, math.floor(tonumber(Tier) or 0)))
    local CodeText = ""
    for Index = 1, Tier do
        CodeText = CodeText .. tostring(Index)
    end
    return tonumber(CodeText) or 0
end

local function SyncTeamCombatPower()
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.SyncTeamUI ~= nil then
        GameMode:SyncTeamUI()
    end
end

local function GetWeaponBaseAttack(player)
    if player == nil then
        return DEFAULT_BASE_ATTACK
    end

    if player.PlayerState ~= nil and player.PlayerState.GetBaseAttack ~= nil then
        local StateBaseAttack = TalentEffectMgr:GetEffectiveBaseAttack(player.PlayerState)
        if StateBaseAttack ~= nil and StateBaseAttack > 0 then
            player.WeaponBaseAttackPower = StateBaseAttack
            return StateBaseAttack
        end
    end

    local CurrentAttack = DEFAULT_BASE_ATTACK
    if player ~= nil and UGCAttributeSystem ~= nil and UGCAttributeSystem.GetGameAttributeValue ~= nil then
        CurrentAttack = tonumber(UGCAttributeSystem.GetGameAttributeValue(player, "AttackPower")) or DEFAULT_BASE_ATTACK
    end

    if player.WeaponBaseAttackPower == nil then
        player.WeaponBaseAttackPower = CurrentAttack
        return CurrentAttack
    end

    if player.LastAppliedWeaponAttackPower == nil then
        return player.WeaponBaseAttackPower
    end

    if math.abs((tonumber(CurrentAttack) or 0) - (tonumber(player.LastAppliedWeaponAttackPower) or 0)) > 0.01 then
        player.WeaponBaseAttackPower = CurrentAttack
    end

    return player.WeaponBaseAttackPower
end

local function BuildPropertyWatchKey(player)
    if player == nil then
        return nil
    end

    local hp = UGCPawnAttrSystem.GetHealth(player) or 0
    local maxHp = UGCPawnAttrSystem.GetHealthMax(player) or 0
    local attack = DEFAULT_BASE_ATTACK
    if UGCAttributeSystem ~= nil and UGCAttributeSystem.GetGameAttributeValue ~= nil then
        attack = tonumber(UGCAttributeSystem.GetGameAttributeValue(player, "AttackPower")) or DEFAULT_BASE_ATTACK
    end
    return table.concat({tostring(Round2(hp)), tostring(Round2(maxHp)), tostring(Round2(attack))}, "|")
end

local function CountBackpackWeaponAttackBonus(player)
    if player == nil or UGCBackPackSystem == nil or UGCBackPackSystem.GetAllItemData == nil then
        return 0, 0
    end

    local AllItemData = UGCBackPackSystem.GetAllItemData(player)
    if AllItemData == nil then
        return 0, 0
    end

    local WeaponCount = 0
    local AttackPercentBySeries = {}
    for _, ItemData in pairs(AllItemData) do
        local ItemID = tonumber(ItemData.ItemID or ItemData.ItemId or ItemData.itemID or ItemData.TypeSpecificID)
        local Count = tonumber(ItemData.Count or ItemData.ItemCount or ItemData.ItemNum or ItemData.Num) or 1
        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
        local SeriesKey = WeaponInfo ~= nil and (WeaponInfo.SeriesKey or WeaponInfo.ID) or nil
        if Count > 0 and SeriesKey ~= nil then
            local Level = WeaponInfo ~= nil and WeaponInfo.Level or 1
            local AttackPercent = WeaponInfo ~= nil and WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponInfo.ID, Level) or
                                      BACKPACK_WEAPON_ATTACK_PER_ITEM
            local OldAttackPercent = AttackPercentBySeries[SeriesKey]
            if OldAttackPercent == nil then
                WeaponCount = WeaponCount + 1
                AttackPercentBySeries[SeriesKey] = AttackPercent
            elseif AttackPercent > OldAttackPercent then
                AttackPercentBySeries[SeriesKey] = AttackPercent
            end
        end
    end

    local TotalAttackPercent = 0
    for _, AttackPercent in pairs(AttackPercentBySeries) do
        TotalAttackPercent = TotalAttackPercent + (tonumber(AttackPercent) or 0)
    end

    return TotalAttackPercent, WeaponCount
end

local function GetRankAttackBonus(player)
    if player == nil or player.PlayerState == nil then
        return 0
    end
    if player.PlayerState.GetRankAttackBonus ~= nil then
        return math.max(0, tonumber(player.PlayerState:GetRankAttackBonus()) or 0)
    end
    return math.max(0, tonumber(player.PlayerState.RankAttackBonus) or 0)
end

local function SetWeaponBonusPercent(player, AttackPercent, bForce)
    AttackPercent = tonumber(AttackPercent) or 0
    local BackpackWeaponAttackPercent, BackpackWeaponCount = CountBackpackWeaponAttackBonus(player)
    local bNeedShowStateMgr = IsLocalPlayerPawn(player) and StateMgr ~= nil and StateMgr.UI ~= nil and
                                  (bForce or player.LastStateMgrWeaponAttackPercent ~= AttackPercent or
                                      player.LastStateMgrBackpackWeaponAttackPercent ~= BackpackWeaponAttackPercent)
    if not bForce and player.LastWeaponAttackPercent == AttackPercent and player.LastBackpackWeaponAttackPercent ==
        BackpackWeaponAttackPercent and not bNeedShowStateMgr then
        return
    end

    player.LastWeaponAttackPercent = AttackPercent
    player.LastBackpackWeaponAttackPercent = BackpackWeaponAttackPercent
    if bNeedShowStateMgr then
        player.LastStateMgrWeaponAttackPercent = AttackPercent
        player.LastStateMgrBackpackWeaponAttackPercent = BackpackWeaponAttackPercent
        StateMgr:WuQiTextShow(AttackPercent, false, BackpackWeaponAttackPercent, BackpackWeaponCount)
    end
end
-- 境界加成结果生成并推送给管理器
local function UpdateRealmBonusResult(player, HunHuan)
    if player == nil or RealmConfig == nil or RealmConfig.GetAttrBonuses == nil then
        return
    end

    local Bonuses = RealmConfig.GetAttrBonuses(HunHuan)
    player.RealmBonusResult = {
        Level = math.max(1, math.min(RealmConfig.MaxLevel, tonumber(HunHuan) or 1)),
        HPPercent = tonumber(Bonuses.HPPercent) or 0,
        AttackPercent = tonumber(Bonuses.AttackPercent) or 0
    }

    if player.RealmBonusManager ~= nil and player.RealmBonusManager.SetRealmBonus ~= nil then
        player.RealmBonusManager:SetRealmBonus(player, player.RealmBonusResult)
    end
end

local WeaponNameToSeries = {
    HWSCJ = "HWSCJ",
    TSSJ = "TSSJ",
    HTC = "HTC",
    LCSL = "LCSL",
    LSSL = "LCSL",
    XJWQ = "XJWQ",
    XSWQ = "XJWQ"
}

local function Utf8Name(...)
    return string.char(...)
end

local WeaponDisplayNameToSeries = {
    [Utf8Name(230, 181, 183, 231, 142, 139, 228, 184, 137, 229, 143, 137, 230, 136, 159)] = "HWSCJ",
    [Utf8Name(229, 164, 169, 228, 189, 191, 229, 156, 163, 229, 137, 145)] = "TSSJ",
    [Utf8Name(230, 152, 138, 229, 164, 169, 233, 148, 164)] = "HTC",
    [Utf8Name(231, 189, 151, 229, 136, 185, 231, 165, 158, 233, 149, 176)] = "LCSL",
    [Utf8Name(229, 185, 189, 229, 133, 137, 231, 159, 173, 229, 136, 128)] = "XJWQ",
    [Utf8Name(229, 185, 189, 229, 133, 137, 231, 159, 173, 229, 136, 131)] = "XJWQ"
}

local WeaponLevelNameToLevel = {
    [Utf8Name(230, 153, 174, 233, 128, 154)] = 1,
    [Utf8Name(228, 188, 152, 231, 167, 128)] = 2,
    [Utf8Name(231, 178, 190, 232, 137, 175)] = 3,
    [Utf8Name(229, 143, 178, 232, 175, 151)] = 4,
    [Utf8Name(228, 188, 160, 232, 175, 180)] = 5
}

local function TryCall(Object, FunctionName, ...)
    if Object == nil then
        return nil
    end

    local Success, Function = pcall(function()
        return Object[FunctionName]
    end)
    if not Success or Function == nil then
        return nil
    end

    local Result = nil
    Success, Result = pcall(Function, Object, ...)
    if Success then
        return Result
    end

    Success, Result = pcall(Function, ...)
    if Success then
        return Result
    end

    return nil
end

local function GetObjectName(Object)
    if Object == nil then
        return nil
    end

    local Name = TryCall(Object, "GetName")
    if Name ~= nil then
        return tostring(Name)
    end

    Name = TryCall(Object, "GetPathName")
    if Name ~= nil then
        return tostring(Name)
    end

    if Object.GetClass ~= nil then
        local Class = TryCall(Object, "GetClass")
        Name = GetObjectName(Class)
        if Name ~= nil then
            return Name
        end
    end

    return tostring(Object)
end

local function GetNameFromItemData(ItemData)
    if ItemData == nil then
        return nil
    end

    local Name = ItemData.ItemName or ItemData.Name or ItemData.DisplayName or ItemData.ItemDisplayName or
                     ItemData.ItemNameText

    if Name ~= nil then
        return tostring(Name)
    end

    local NestedData = ItemData.ItemData or ItemData.ItemConfig or ItemData.Config or ItemData.ItemDefine or
                           ItemData.ItemTableData

    if NestedData == nil then
        return nil
    end

    Name = NestedData.ItemName or NestedData.Name or NestedData.DisplayName or NestedData.ItemDisplayName or
               NestedData.ItemNameText

    if Name ~= nil then
        return tostring(Name)
    end

    return nil
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

local function GetItemConfigName(ItemID)
    ItemID = tonumber(ItemID)
    if ItemID == nil then
        return nil
    end

    if UGCBackPackSystem ~= nil then
        local FunctionNames = {"GetItemData", "GetItemConfigData", "GetItemDataByItemID", "GetItemDefine"}
        for _, FunctionName in ipairs(FunctionNames) do
            local ConfigData = TryCall(UGCBackPackSystem, FunctionName, ItemID)
            local Name = GetNameFromItemData(ConfigData)
            if Name ~= nil and Name ~= "" then
                return Name
            end
        end
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil then
        local ConfigData = TryCall(VirtualItemManager, "GetItemData", ItemID)
        local Name = GetNameFromItemData(ConfigData)
        if Name ~= nil and Name ~= "" then
            return Name
        end
    end

    return nil
end

local function GetWeaponObjectItemName(Weapon)
    local Name = GetNameFromItemData(Weapon)
    if Name ~= nil and Name ~= "" then
        return Name
    end

    local FunctionNames = {"GetItemName", "GetName", "GetDisplayName", "GetItemDisplayName"}
    for _, FunctionName in ipairs(FunctionNames) do
        Name = TryCall(Weapon, FunctionName)
        if Name ~= nil and tostring(Name) ~= "" then
            return tostring(Name)
        end
    end

    return nil
end

local function GetSeriesKeyFromName(Name)
    if Name == nil then
        return nil
    end

    Name = tostring(Name)
    for Pattern, SeriesKey in pairs(WeaponDisplayNameToSeries) do
        if string.find(Name, Pattern, 1, true) ~= nil then
            return SeriesKey
        end
    end

    Name = string.upper(Name)
    for Pattern, SeriesKey in pairs(WeaponNameToSeries) do
        if string.find(Name, Pattern, 1, true) ~= nil then
            return SeriesKey
        end
    end

    return nil
end

--[[
local function GetLevelFromName(Name)
    if Name == nil then
        return nil
    end

    Name = tostring(Name)
    local BracketValue = string.match(Name, "%(([^()]*)%)") or string.match(Name, "（([^（）]*)）")
    if BracketValue ~= nil then
        local Level = tonumber(string.match(BracketValue, "[Ll][Vv]%s*(%d+)") or string.match(BracketValue, "(%d+)"))
        if Level ~= nil then
            return Level
        end
    end

    for Pattern, Level in pairs(WeaponLevelNameToLevel) do
        if string.find(Name, Pattern, 1, true) ~= nil then
            return Level
        end
    end

    return nil
end
]]

local function GetLevelFromName(Name)
    if Name == nil then
        return nil
    end

    Name = tostring(Name)
    local FullWidthLeft = string.char(239, 188, 136)
    local FullWidthRight = string.char(239, 188, 137)
    local BracketValue = string.match(Name, "%(([^()]*)%)") or
                             string.match(Name, FullWidthLeft .. "([^" .. FullWidthLeft .. FullWidthRight .. "]*)" ..
            FullWidthRight)
    if BracketValue ~= nil then
        local Level = tonumber(string.match(BracketValue, "[Ll][Vv]%s*(%d+)") or string.match(BracketValue, "(%d+)"))
        if Level ~= nil then
            return Level
        end
    end

    for Pattern, Level in pairs(WeaponLevelNameToLevel) do
        if string.find(Name, Pattern, 1, true) ~= nil then
            return Level
        end
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

    local FieldNames = {"ItemID", "ItemId", "itemID", "ItemDefineID", "DefineID", "DefineId", "ID"}
    for _, FieldName in ipairs(FieldNames) do
        local ItemID = tonumber(Object[FieldName])
        if ItemID ~= nil then
            return ItemID
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

-- 成功方法名缓存（weak-keyed 表，避免阻止 GC）
-- key: player, value: 上次拿到武器的时间戳
local function GetWeaponInfoFromObject(Object)
    if Object == nil then
        return nil, nil
    end

    local DirectItemID = tonumber(Object)
    if DirectItemID ~= nil then
        return DirectItemID, WeaponLevelConfig.GetWeaponInfo(DirectItemID), true
    end

    local ItemFieldNames = {"ItemID", "ItemId", "itemID", "ItemDefineID", "DefineID", "DefineId", "WPID"}
    for _, FieldName in ipairs(ItemFieldNames) do
        local Success, FieldValue = pcall(function()
            return Object[FieldName]
        end)
        if Success then
            local ItemID = tonumber(FieldValue)
            local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
            if WeaponInfo ~= nil then
                return ItemID, WeaponInfo, true
            end
        end
    end

    local FunctionNames = {"GetItemID", "GetItemId", "GetItemDefineID", "GetDefineID", "GetDefineId"}
    for _, FunctionName in ipairs(FunctionNames) do
        local ItemID = tonumber(TryCall(Object, FunctionName))
        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
        if WeaponInfo ~= nil then
            return ItemID, WeaponInfo, true
        end
    end

    local ObjectName = GetWeaponObjectItemName(Object) or GetObjectName(Object)
    local SeriesKey = GetSeriesKeyFromName(ObjectName)
    if SeriesKey ~= nil then
        local SeriesItemID = WeaponLevelConfig.GetItemID(SeriesKey, 1)
        local SeriesInfo = WeaponLevelConfig.GetWeaponInfo(SeriesItemID)
        if SeriesInfo ~= nil then
            return SeriesItemID, SeriesInfo, false
        end
    end

    local WeaponIDFieldNames = {"WeaponConfigID", "WuQiID", "WeaponID", "WeaponTypeID"}
    for _, FieldName in ipairs(WeaponIDFieldNames) do
        local Success, FieldValue = pcall(function()
            return Object[FieldName]
        end)
        if Success then
            local WeaponID = tonumber(FieldValue)
            local Weapon = WeaponLevelConfig.GetWeaponByID(WeaponID)
            if Weapon ~= nil then
                return Weapon.WPID, WeaponLevelConfig.GetWeaponInfo(Weapon.WPID), false
            end
        end
    end

    local FallbackItemID = GetItemIDFromObject(Object)
    return FallbackItemID, WeaponLevelConfig.GetWeaponInfo(FallbackItemID), FallbackItemID ~= nil
end

local PlayerNoWeaponCache = setmetatable({}, {
    __mode = "k"
})
-- 无武器缓存过期间隔（秒），期间直接返回 nil
local NO_WEAPON_CACHE_TTL = 1.0

local function GetCurrentHeldWeapon(player)
    if player == nil then
        return nil
    end

    -- 主路径：使用官方 UGC API（UGCPlayerController:TryAutoMeleeAttack 也在用）
    if UGCWeaponManagerSystem ~= nil and UGCWeaponManagerSystem.GetCurrentWeapon ~= nil then
        local Weapon = UGCWeaponManagerSystem.GetCurrentWeapon(player)
        if Weapon ~= nil then
            PlayerNoWeaponCache[player] = nil
            return Weapon
        end

        -- 无武器：用 TTL 缓存避免每 tick 高频重试
        local LastNilTime = PlayerNoWeaponCache[player]
        if LastNilTime ~= nil and (os.clock() - LastNilTime) < NO_WEAPON_CACHE_TTL then
            return nil
        end
        PlayerNoWeaponCache[player] = os.clock()
    end

    return nil
end

local function SetWeaponRuntimeDisplayName(Weapon, DisplayName)
    if Weapon == nil or DisplayName == nil then
        return
    end

    local SetterNames = {"SetItemName", "SetName", "SetDisplayName", "SetItemDisplayName", "SetCustomName"}
    for _, FunctionName in ipairs(SetterNames) do
        local Func = Weapon[FunctionName]
        if Func ~= nil then
            local Success = pcall(Func, Weapon, DisplayName)
            if not Success then
                pcall(Func, DisplayName)
            end
        end
    end

    local FieldNames = {"ItemName", "Name", "DisplayName", "ItemDisplayName", "ItemNameText", "CustomName"}
    for _, FieldName in ipairs(FieldNames) do
        pcall(function()
            Weapon[FieldName] = DisplayName
        end)
    end
end

local function GetHeldWeaponAttributeItemID(player)
    local Weapon = GetCurrentHeldWeapon(player)
    if Weapon == nil then
        return nil, nil
    end

    local UsedItemID = tonumber(player.CurrentUsedWeaponItemID)
    local UsedWeaponInfo = WeaponLevelConfig.GetWeaponInfo(UsedItemID)
    if UsedWeaponInfo ~= nil then
        local UsedLevel = math.max(1, math.min(UsedWeaponInfo.MaxLevel,
            tonumber(player.CurrentUsedWeaponLevel) or tonumber(UsedWeaponInfo.Level) or 1))
        local AttributeItemID = WeaponLevelConfig.GetItemID(UsedWeaponInfo.SeriesKey, UsedLevel) or UsedItemID
        Weapon.WeaponLevel = UsedLevel
        Weapon.WeaponConfigID = UsedWeaponInfo.ID
        Weapon.WeaponLevel_0 = WeaponLevelConfig.GetAttackPercentByWeaponID(UsedWeaponInfo.ID, UsedLevel)
        SetWeaponRuntimeDisplayName(Weapon, WeaponLevelConfig.BuildDisplayName(UsedWeaponInfo.WPID, UsedLevel))
        local DebugKey = "used|" .. tostring(UsedWeaponInfo.ID) .. "|" .. tostring(UsedLevel) .. "|" ..
                             tostring(Weapon.WeaponLevel_0)
        if player.LastHeldWeaponAttackDebugKey ~= DebugKey then
            player.LastHeldWeaponAttackDebugKey = DebugKey
            ugcprint("[UGCPlayerPawn:GetHeldWeaponAttribute] usedItem=" .. tostring(UsedItemID) .. ", weaponID=" ..
                         tostring(UsedWeaponInfo.ID) .. ", level=" .. tostring(UsedLevel) .. ", attack=" ..
                         tostring(Weapon.WeaponLevel_0))
        end
        return AttributeItemID, UsedWeaponInfo.SeriesKey, UsedWeaponInfo.Name, UsedLevel
    end

    local ItemID, WeaponInfo, bTrustItemLevel = GetWeaponInfoFromObject(Weapon)
    local ActorLevel = tonumber(Weapon.WeaponLevel)
    if WeaponInfo ~= nil then
        local HeldWeaponName = GetWeaponObjectItemName(Weapon)
        local NameLevel = GetLevelFromName(HeldWeaponName)
        local ItemLevel = bTrustItemLevel == true and tonumber(WeaponInfo.Level) or nil
        local Level = math.max(1, math.min(WeaponInfo.MaxLevel, ItemLevel or NameLevel or ActorLevel or
            tonumber(WeaponInfo.Level) or 1))
        local AttributeItemID = WeaponLevelConfig.GetItemID(WeaponInfo.SeriesKey, Level) or ItemID
        Weapon.WeaponLevel = Level
        Weapon.WeaponConfigID = WeaponInfo.ID
        Weapon.WeaponLevel_0 = WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponInfo.ID, Level)
        SetWeaponRuntimeDisplayName(Weapon, WeaponLevelConfig.BuildDisplayName(WeaponInfo.WPID, Level))
        local DebugKey = tostring(WeaponInfo.ID) .. "|" .. tostring(Level) .. "|" .. tostring(Weapon.WeaponLevel_0)
        if player.LastHeldWeaponAttackDebugKey ~= DebugKey then
            player.LastHeldWeaponAttackDebugKey = DebugKey
            ugcprint("[UGCPlayerPawn:GetHeldWeaponAttribute] weaponID=" .. tostring(WeaponInfo.ID) .. ", level=" ..
                         tostring(Level) .. ", attack=" .. tostring(Weapon.WeaponLevel_0) .. ", nameLevel=" ..
                         tostring(NameLevel) .. ", actorLevel=" .. tostring(ActorLevel))
        end
        return AttributeItemID, WeaponInfo.SeriesKey, HeldWeaponName or WeaponInfo.Name, Level
    end

    local ItemName = GetItemConfigName(ItemID) or GetWeaponObjectItemName(Weapon)
    local SeriesKey = GetSeriesKeyFromName(ItemName)
    local Level = GetLevelFromName(ItemName)
    if SeriesKey ~= nil then
        if Level ~= nil then
            return WeaponLevelConfig.GetItemID(SeriesKey, Level), SeriesKey, ItemName, Level
        end

        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
        if WeaponInfo ~= nil and WeaponInfo.SeriesKey == SeriesKey then
            return ItemID, SeriesKey, ItemName, WeaponInfo.Level
        end

        return WeaponLevelConfig.GetItemID(SeriesKey, 1), SeriesKey, ItemName, 1
    end

    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if WeaponInfo ~= nil then
        return ItemID, WeaponInfo.SeriesKey, GetItemConfigName(ItemID), WeaponInfo.Level
    end

    SeriesKey = GetSeriesKeyFromName(GetObjectName(Weapon))
    if SeriesKey == nil then
        return nil, nil
    end

    return WeaponLevelConfig.GetItemID(SeriesKey, 1), SeriesKey, nil, 1
end

local function DestroySoulMesh(player)
    if player ~= nil and player.SoulMeshActor ~= nil then
        UGCActorComponentUtility.DestroyActor(player.SoulMeshActor)
        player.SoulMeshActor = nil
    end
end

local function DestroyAttachedActors(player)
    if player == nil or player.K2_GetAttachedActors == nil then
        return
    end

    local Success, AttachedActors = pcall(player.K2_GetAttachedActors, player)
    if not Success or AttachedActors == nil then
        return
    end

    for _, Actor in pairs(AttachedActors) do
        if Actor ~= nil and Actor ~= player then
            UGCActorComponentUtility.DestroyActor(Actor)
        end
    end

    player.SoulMeshActor = nil
    player.PlayerTitleActor = nil
    player.__SubObjectRepList = nil
end

local function CreateSoulMesh(player, HunHuan)
    if player == nil then
        return
    end

    DestroySoulMesh(player)

    local SoulLevel = (tonumber(HunHuan) or 1) - 1
    if SoulLevel <= 0 then
        return
    end

    local SoulPath = UGCMapInfoLib.GetRootLongPackagePath() .. SOUL_MESH_PATH .. "M_" .. tostring(SoulLevel) .. ".M_" ..
                         tostring(SoulLevel)
    local soulMesh = UE.LoadObject(SoulPath)
    if soulMesh == nil then
        print("CreateSoulMesh load failed:", SoulPath)
        return
    end

    local staticMeshActorClass = UE.LoadClass("/Script/Engine.StaticMeshActor")
    local soulActor = UGCActorComponentUtility.SpawnActor(player, staticMeshActorClass, Vector.New(0, 0, 0),
        Rotator.New(0, 0, 0), SOUL_SCALE, player)
    if soulActor == nil then
        return
    end

    player.SoulMeshActor = soulActor

    local meshComponent = soulActor.StaticMeshComponent
    meshComponent:K2_SetMobility(EComponentMobility.Movable)
    meshComponent:SetStaticMesh(soulMesh)
    meshComponent:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    UGCActorComponentUtility.AttachToComponent(soulActor, player.Mesh, EAttachmentRule.SnapToTarget,
        EAttachmentRule.SnapToTarget, EAttachmentRule.KeepWorld, SOUL_SOCKET, false)
    meshComponent:K2_SetRelativeLocation(SOUL_OFFSET, false, {}, false)
    meshComponent:K2_SetRelativeRotation(SOUL_ROTATION, false, {}, false)
end

local function AddReplicatedSubObject(player, actor)
    if player == nil or actor == nil then
        return
    end

    player.__SubObjectRepList = player.__SubObjectRepList or {}
    for _, subObject in ipairs(player.__SubObjectRepList) do
        if subObject == actor then
            return
        end
    end

    table.insert(player.__SubObjectRepList, actor)
end

local function RemoveReplicatedSubObject(player, actor)
    if player == nil or player.__SubObjectRepList == nil or actor == nil then
        return
    end

    for index = #player.__SubObjectRepList, 1, -1 do
        if player.__SubObjectRepList[index] == actor then
            table.remove(player.__SubObjectRepList, index)
        end
    end
end

function UGCPlayerPawn:EnsurePlayerTitleActor()
    if not self:HasAuthority() then
        return self.PlayerTitleActor
    end

    if self.PlayerTitleActor and UE.IsValid(self.PlayerTitleActor) then
        AddReplicatedSubObject(self, self.PlayerTitleActor)
        return self.PlayerTitleActor
    end

    local titleClass = UE.LoadClass(UGCMapInfoLib.GetRootLongPackagePath() ..
                                        "Asset/Blueprint/UI/BP_PlayerTitleActor.BP_PlayerTitleActor_C")

    if titleClass == nil then
        ugcprint("[UGCPlayerPawn] Title class load failed")
        return nil
    end

    local location = self:K2_GetActorLocation()

    self.PlayerTitleActor = UGCActorComponentUtility.SpawnActor(self, titleClass, location, {
        X = 0,
        Y = 0,
        Z = 0
    }, {
        X = 1,
        Y = 1,
        Z = 1
    }, self)

    if self.PlayerTitleActor == nil then
        ugcprint("[UGCPlayerPawn] PlayerTitleActor spawn failed")
        return nil
    end

    UGCActorComponentUtility.AttachToComponent(self.PlayerTitleActor, self.CapsuleComponent,
        EAttachmentRule.SnapToTarget, EAttachmentRule.SnapToTarget, EAttachmentRule.KeepRelative, "", false)

    AddReplicatedSubObject(self, self.PlayerTitleActor)

    return self.PlayerTitleActor
end

local function InterruptStateSafe(player, tag)
    if UGCPersistEffectSystem == nil or UGCPersistEffectSystem.InterruptDynamicState == nil then
        return
    end

    pcall(UGCPersistEffectSystem.InterruptDynamicState, player, tag)
end

local function SetStateDisabledSafe(player, tag, bDisabled)
    if UGCPersistEffectSystem == nil or UGCPersistEffectSystem.SetDynamicStateDisabled == nil then
        return
    end

    local Success = pcall(UGCPersistEffectSystem.SetDynamicStateDisabled, player, tag, bDisabled)
    if not Success and bDisabled then
        pcall(UGCPersistEffectSystem.SetDynamicStateDisabled, player, tag)
    end
end

function UGCPlayerPawn:BeginFly()
    if UGCPersistEffectSystem == nil then
        return
    end

    if not UGCPersistEffectSystem.HasDynamicState(self, FLY_STATE_TAG) then
        UGCPersistEffectSystem.EnterDynamicState(self, FLY_STATE_TAG)
        ugcprint("[UGCPlayerPawn] Enter fly state")

        for _, Tag in ipairs(FLY_INTERRUPT_TAGS) do
            InterruptStateSafe(self, Tag)
        end
        for _, Tag in ipairs(FLY_DISABLE_TAGS) do
            SetStateDisabledSafe(self, Tag, true)
        end
    end
end

function UGCPlayerPawn:EndFly()
    if UGCPersistEffectSystem == nil then
        return
    end

    if UGCPersistEffectSystem.HasDynamicState(self, FLY_STATE_TAG) then
        UGCPersistEffectSystem.LeaveDynamicState(self, FLY_STATE_TAG)
        ugcprint("[UGCPlayerPawn] Leave fly state")
    end

    for _, Tag in ipairs(FLY_DISABLE_TAGS) do
        SetStateDisabledSafe(self, Tag, false)
    end
end

local function ScheduleQuitLobbyTeam()
    if bLobbyQuitScheduled then
        return
    end
    bLobbyQuitScheduled = true
    local Attempt = 0
    local MaxAttempts = math.max(1, tonumber(TeamConfig.LOBBY_QUIT_RETRY_COUNT) or 1)
    local function TryQuitLobbyTeam()
        Attempt = Attempt + 1
        local PlayerController = UGCGameSystem.GetLocalPlayerController()
        local LocalKey = UGCGameSystem.GetLocalPlayerKey()
        if LocalKey == nil and PlayerController ~= nil then
            LocalKey = PlayerController.PlayerKey
        end

        local bReady = PlayerController ~= nil and LocalKey ~= nil
        ugcprint("[Team] Client quit lobby team attempt build=" .. tostring(TeamConfig.BUILD_ID) .. " attempt=" ..
                     tostring(Attempt) .. "/" .. tostring(MaxAttempts) .. " ready=" .. tostring(bReady) ..
                     " localKey=" .. tostring(LocalKey) .. " keyType=" .. type(LocalKey))
        if bReady then
            local Success, Result = pcall(UGCTeamSystem.QuitLobbyTeam)
            ugcprint("[Team] Client quit lobby team requested build=" .. tostring(TeamConfig.BUILD_ID) ..
                         " attempt=" .. tostring(Attempt) .. " callSuccess=" .. tostring(Success) .. " result=" ..
                         tostring(Result) .. " localKey=" .. tostring(LocalKey))
        end

        if Attempt < MaxAttempts then
            UGCTimerUtility.CreateLuaTimer(TeamConfig.LOBBY_QUIT_RETRY_INTERVAL, TryQuitLobbyTeam, false)
        elseif not bReady then
            ugcprint("[Team] Client quit lobby team stopped: local player not ready build=" ..
                         tostring(TeamConfig.BUILD_ID))
        end
    end
    UGCTimerUtility.CreateLuaTimer(TeamConfig.LOBBY_QUIT_DELAY, TryQuitLobbyTeam, false)
end

local function CreateTeamPanelForLocalPlayer()
    if bTeamPanelCreated then
        return
    end
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    if PlayerController == nil or PlayerController.TeamPanelInstance ~= nil then
        return
    end
    local Path = UGCGameSystem.GetUGCResourcesFullPath("Asset/UI015.UI015_C")
    local WidgetClass = UE.LoadClass(Path)
    if WidgetClass == nil then
        ugcprint("[Team] Client TeamPanel class load failed: " .. tostring(Path))
        return
    end
    local Widget = UGCWidgetManagerSystem.CreateWidget(WidgetClass)
    if Widget == nil then
        ugcprint("[Team] Client TeamPanel create failed")
        return
    end
    PlayerController.TeamPanelInstance = Widget
    bTeamPanelCreated = true
    Widget:AddToViewport(TeamConfig.UI_Z_ORDER)
    ugcprint("[Team] Client UI015 team panel created from local Pawn build=" .. tostring(TeamConfig.BUILD_ID) ..
                 " zOrder=" .. tostring(TeamConfig.UI_Z_ORDER))
end

function UGCPlayerPawn:OnRep_AttachActorConfigs()
    if UGCPlayerPawn.SuperClass ~= nil and UGCPlayerPawn.SuperClass.OnRep_AttachActorConfigs ~= nil then
        UGCPlayerPawn.SuperClass.OnRep_AttachActorConfigs(self)
    end
    if tonumber(self.EquippedWingVisualItemID) == 0 then
        StartWingCleanup(self)
    else
        StartWingAttachmentFix(self)
    end
end

function UGCPlayerPawn:RequestWingAttachmentFix()
    StartWingAttachmentFix(self)
end

function UGCPlayerPawn:SetEquippedWingVisualItemID(ItemID)
    ItemID = math.max(0, tonumber(ItemID) or 0)
    self.EquippedWingVisualItemID = ItemID
    ApplyWingVisualState(self)
end

function UGCPlayerPawn:OnRep_EquippedWingVisualItemID()
    ApplyWingVisualState(self)
end

function UGCPlayerPawn:ReceiveBeginPlay()
    UGCPlayerPawn.SuperClass.ReceiveBeginPlay(self)
    -- 兼容 AttachActorConfigs 在 Lua BeginPlay 之前已经完成首次复制的情况。
    if tonumber(self.EquippedWingVisualItemID) == 0 then
        StartWingCleanup(self)
    else
        StartWingAttachmentFix(self)
    end
    -- 默认开启身上旋转武器；Button_81 可在运行时切换开关。
    local OrbitController = GetOrbitWeaponController(self)
    self.bOrbitWeaponEnabled = OrbitController == nil or OrbitController.OrbitWeaponEnabled ~= false
    if OrbitController ~= nil then
        OrbitController.OrbitWeaponEnabled = self.bOrbitWeaponEnabled
        self.OrbitWeaponClassPath = OrbitController.OrbitWeaponClassPath
        self.OrbitWeaponHitEffectPath = OrbitController.OrbitWeaponHitEffectPath
        self.OrbitWeaponDamagePercent = OrbitController.OrbitWeaponDamagePercent
        self.OrbitWeaponSkinIndex = OrbitController.OrbitWeaponSkinIndex
        self.OrbitWeaponDamagePercents = OrbitController.OrbitWeaponDamagePercents
        self.OrbitWeaponRotationSpeed = OrbitController.OrbitWeaponRotationSpeed
    end
    local CurrentLevel = GetEffectiveOrbitPlayerLevel(self)
    local ActiveTier = WeaponRefineConfig.GetUnlockedWeaponCount(CurrentLevel)
    self:SetOrbitWeaponActiveGun(ActiveTier, self.OrbitWeaponDamagePercent)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.Test_01)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshZhanLi)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshZhanLi_01)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshProperty)
    UGCGenericMessageSystem.ListenObjectMessage(self, L_Enum_Event.Enum.ReFreshZhanLi_01, self, self.InitPlayerState)

    self.EquippedTitleID = self.EquippedTitleID or 0
    self.PropertyWatchElapsed = 0
    self.WeaponAttackElapsed = 0
    self.LastPropertyWatchKey = nil
    self.LastWeaponAttackKey = nil

    self:InitPlayerState()
    self:RefreshWeaponAttackBonus(true)
    self:NotifyPropertyChangedIfNeeded(true)

    -- Standalone/listen-server Pawn has Authority; a client-owned Pawn is local.
    -- Cover both cases before the early return below.
    if self:IsOrbitWeaponEnabled() and (self:HasAuthority() or IsLocalPlayerPawn(self)) then
        AK47Orbit.Start(self)
    end

    if not self:HasAuthority() then
        ScheduleQuitLobbyTeam()
        CreateTeamPanelForLocalPlayer()
        return
    end
    self:OnPawnInit()
    self:EnsurePlayerTitleActor()
end

local PLAYER_SKILL_1_REQUIRED_LEVEL = 50 -- 第一个技能解锁需要的等级
local PLAYER_SKILL_1_PATH = 'Asset/Blueprint/Prefabs/Skills/Lin/PlayerSkill/PlayerSkill_1.PlayerSkill_1_C'

function UGCPlayerPawn:OnPawnInit()
    local playerState = self.PlayerState
    if playerState ~= nil and playerState.bArchiveLoaded == true then
        TalentUltimateMgr:ScheduleLoginRestore(self, playerState)
    end

    if playerState ~= nil and playerState:GetPlayerLevel() >= PLAYER_SKILL_1_REQUIRED_LEVEL then
        UGCPersistEffectSystem.AddSkillByClass(self, UGCGameSystem.GetUGCResourcesFullPath(PLAYER_SKILL_1_PATH))
    end
end

-- 身上旋转武器开关：false 立即销毁，true 立即生成并恢复旋转。
function UGCPlayerPawn:SetOrbitWeaponEnabled(bEnabled)
    self.bOrbitWeaponEnabled = bEnabled == true
    local OrbitController = GetOrbitWeaponController(self)
    if OrbitController ~= nil then
        OrbitController.OrbitWeaponEnabled = self.bOrbitWeaponEnabled
    end
    if not self.bOrbitWeaponEnabled then
        AK47Orbit.Stop(self)
    elseif self:HasAuthority() or IsLocalPlayerPawn(self) then
        AK47Orbit.Start(self)
    end
    return self.bOrbitWeaponEnabled
end

function UGCPlayerPawn:IsOrbitWeaponEnabled()
    return self.bOrbitWeaponEnabled ~= false
end

function UGCPlayerPawn:SetOrbitWeaponConfig(WeaponClassPath, HitEffectPath)
    local bSuccess = AK47Orbit.SetWeapon(self, WeaponClassPath, HitEffectPath)
    if bSuccess ~= true then
        return false
    end
    local OrbitController = GetOrbitWeaponController(self)
    if OrbitController ~= nil then
        OrbitController.OrbitWeaponClassPath = WeaponClassPath
        OrbitController.OrbitWeaponHitEffectPath = HitEffectPath
        OrbitController.OrbitWeaponEnabled = self.bOrbitWeaponEnabled ~= false
    end
    return true
end

function UGCPlayerPawn:SetOrbitWeaponActiveGun(GunIndex, DamagePercent)
    local RequestedTier = math.max(0, math.min(8, math.floor(tonumber(GunIndex) or 0)))
    local OrbitController = GetOrbitWeaponController(self)
    local EffectiveTier = RequestedTier
    self.OrbitWeaponActiveGunTier = EffectiveTier
    local EffectiveDamagePercent = DamagePercent
    if OrbitController ~= nil then
        OrbitController.OrbitWeaponActiveGunTier = EffectiveTier
        if tonumber(DamagePercent) ~= nil and tonumber(DamagePercent) > 0 then
            OrbitController.OrbitWeaponDamagePercent = tonumber(DamagePercent)
        end
    end
    return AK47Orbit.SetActiveGun(self, EffectiveTier, EffectiveDamagePercent)
end

function UGCPlayerPawn:SetOrbitWeaponDamagePercents(DamagePercents)
    local OrbitController = GetOrbitWeaponController(self)
    if OrbitController ~= nil then
        OrbitController.OrbitWeaponDamagePercents = DamagePercents
    end
    return AK47Orbit.SetDamagePercents(self, DamagePercents)
end

function UGCPlayerPawn:SetOrbitWeaponRotationSpeed(RotationSpeed)
    RotationSpeed = math.max(0, tonumber(RotationSpeed) or 0)
    self.OrbitWeaponRotationSpeed = RotationSpeed
    local OrbitController = GetOrbitWeaponController(self)
    if OrbitController ~= nil then
        OrbitController.OrbitWeaponRotationSpeed = RotationSpeed
    end
    return AK47Orbit.SetRotationSpeed(self, RotationSpeed)
end

function UGCPlayerPawn:ReceiveTick(DeltaTime)
    if UGCPlayerPawn.SuperClass ~= nil and UGCPlayerPawn.SuperClass.ReceiveTick ~= nil then
        UGCPlayerPawn.SuperClass.ReceiveTick(self, DeltaTime)
    end

    local SafeDeltaTime = tonumber(DeltaTime) or 0.016

    if (tonumber(self.WingAttachFixAttemptsLeft) or 0) > 0 then
        self.WingAttachFixElapsed = (tonumber(self.WingAttachFixElapsed) or 0) + SafeDeltaTime
        if self.WingAttachFixElapsed >= WING_ATTACH_FIX_INTERVAL then
            self.WingAttachFixElapsed = 0
            self.WingAttachFixAttemptsLeft = self.WingAttachFixAttemptsLeft - 1
            if RefreshWingAttachments(self) then
                self.WingAttachFixSuccesses = (tonumber(self.WingAttachFixSuccesses) or 0) + 1
                if self.WingAttachFixSuccesses >= 4 then
                    self.WingAttachFixAttemptsLeft = 0
                end
            else
                self.WingAttachFixSuccesses = 0
            end
        end
    end

    if (tonumber(self.WingCleanupAttemptsLeft) or 0) > 0 and
        tonumber(self.EquippedWingVisualItemID) == 0 then
        self.WingCleanupElapsed = (tonumber(self.WingCleanupElapsed) or 0) + SafeDeltaTime
        if self.WingCleanupElapsed >= WING_ATTACH_FIX_INTERVAL then
            self.WingCleanupElapsed = 0
            self.WingCleanupAttemptsLeft = self.WingCleanupAttemptsLeft - 1
            CleanupWingActors(self)
        end
    end

    -- 死亡时清理 WQ；复活后血量恢复时自动重新生成。
    local CurrentHealth = tonumber(UGCPawnAttrSystem.GetHealth(self)) or 0
    if CurrentHealth <= 0 then
        if self.AK47OrbitState ~= nil then
            AK47Orbit.Stop(self)
        end
    elseif self:IsOrbitWeaponEnabled() and (self:HasAuthority() or IsLocalPlayerPawn(self)) then
        -- 重生时Controller/PlayerState可能晚于Pawn就绪；存活期间主动校准，避免一直停留在默认1把。
        local OrbitController = GetOrbitWeaponController(self)
        local DesiredWeaponClassPath = OrbitController ~= nil and
            OrbitController.OrbitWeaponClassPath or self.OrbitWeaponClassPath
        local DesiredHitEffectPath = OrbitController ~= nil and
            OrbitController.OrbitWeaponHitEffectPath or self.OrbitWeaponHitEffectPath
        local CurrentActorClassPath = self.AK47OrbitState ~= nil and
            self.AK47OrbitState.WeaponClassPath or nil
        if type(DesiredWeaponClassPath) == "string" and DesiredWeaponClassPath ~= "" and
            (self.OrbitWeaponClassPath ~= DesiredWeaponClassPath or
                (CurrentActorClassPath ~= nil and CurrentActorClassPath ~= DesiredWeaponClassPath)) then
            self:SetOrbitWeaponConfig(DesiredWeaponClassPath, DesiredHitEffectPath)
        end
        local EffectiveLevel = GetEffectiveOrbitPlayerLevel(self)
        local DesiredTier = WeaponRefineConfig.GetUnlockedWeaponCount(EffectiveLevel)
        local OrbitActor = self.AK47OrbitState ~= nil and self.AK47OrbitState.Actor or nil
        local ActualGunCode = OrbitActor ~= nil and tonumber(OrbitActor.ActiveGunCode) or nil
        local ExpectedGunCode = BuildOrbitWeaponCode(DesiredTier)
        if DesiredTier ~= (tonumber(self.OrbitWeaponActiveGunTier) or 0) or
            (ActualGunCode ~= nil and ActualGunCode ~= ExpectedGunCode) then
            self:SetOrbitWeaponActiveGun(DesiredTier,
                OrbitController ~= nil and OrbitController.OrbitWeaponDamagePercent or
                    self.OrbitWeaponDamagePercent)
        end
        AK47Orbit.Start(self)
        AK47Orbit.Update(self, SafeDeltaTime)
    elseif self.AK47OrbitState ~= nil then
        AK47Orbit.Stop(self)
    end

    self.WeaponAttackElapsed = (self.WeaponAttackElapsed or 0) + SafeDeltaTime
    if self.WeaponAttackElapsed >= WEAPON_ATTACK_CHECK_INTERVAL then
        self.WeaponAttackElapsed = 0
        self:RefreshWeaponAttackBonus(false)
    end

    self.PropertyWatchElapsed = (self.PropertyWatchElapsed or 0) + SafeDeltaTime
    if self.PropertyWatchElapsed >= PROPERTY_WATCH_CHECK_INTERVAL then
        self.PropertyWatchElapsed = 0
        self:NotifyPropertyChangedIfNeeded(false)
    end
end

function UGCPlayerPawn:RefreshWeaponAttackBonus(bForce)
    local ItemID, SeriesKey, ItemName, Level = GetHeldWeaponAttributeItemID(self)
    if not self:HasAuthority() then
        if WeaponLevelConfig.GetWeaponInfo(ItemID) == nil then
            SetWeaponBonusPercent(self, 0, bForce)
            if self.LastWeaponAttackKey ~= "none" then
                self.LastWeaponAttackKey = "none"
                local PlayerController = GameplayStatics.GetPlayerController(self, 0)
                if PlayerController ~= nil then
                    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_UpdateWeaponAttackBonus", 0)
                end
            end
            return
        end

        local ClientWeaponAttackKey = tostring(ItemID or "none") .. "|" .. tostring(SeriesKey or "none") .. "|" ..
                                          tostring(ItemName or "none") .. "|" .. tostring(Level or "none")
        self:ApplyWeaponAttackBonusLocalDisplay(ItemID, SeriesKey, ItemName, Level, bForce)

        if not bForce and self.LastWeaponAttackKey == ClientWeaponAttackKey then
            return
        end
        self.LastWeaponAttackKey = ClientWeaponAttackKey

        local PlayerController = GameplayStatics.GetPlayerController(self, 0)
        if PlayerController ~= nil then
            UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_UpdateWeaponAttackBonus",
                tonumber(ItemID) or 0)
        end
        return
    end

    if WeaponLevelConfig.GetWeaponInfo(ItemID) == nil and self.LastClientWeaponAttackItemID ~= nil then
        ItemID = self.LastClientWeaponAttackItemID
        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
        if WeaponInfo ~= nil then
            SeriesKey = WeaponInfo.SeriesKey
            Level = WeaponInfo.Level
        end
    end

    self:ApplyWeaponAttackBonusByItemID(ItemID, SeriesKey, ItemName, Level, bForce)
end

function UGCPlayerPawn:GetCurrentWeaponBonusPercent()
    local ItemID, _, _, Level = GetHeldWeaponAttributeItemID(self)
    local Weapon = GetCurrentHeldWeapon(self)
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    local AttackPercent = WeaponInfo ~= nil and WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponInfo.ID, Level) or 0
    if Weapon ~= nil then
        if WeaponInfo ~= nil then
            Weapon.WeaponConfigID = WeaponInfo.ID
        end
        Weapon.WeaponLevel_0 = AttackPercent
    end

    return AttackPercent
end

function UGCPlayerPawn:ApplyWeaponAttackBonusLocalDisplay(ItemID, SeriesKey, ItemName, Level, bForce)
    local Weapon = GetCurrentHeldWeapon(self)
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    local AttackPercent = WeaponInfo ~= nil and WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponInfo.ID, Level) or 0
    if Weapon ~= nil then
        Weapon.WeaponLevel = math.max(1, tonumber(Level) or 1)
        if WeaponInfo ~= nil then
            Weapon.WeaponConfigID = WeaponInfo.ID
        end
        Weapon.WeaponLevel_0 = AttackPercent
    end
    SetWeaponBonusPercent(self, AttackPercent, bForce)

    local BaseAttack = GetWeaponBaseAttack(self)
    local CurrentBaseAttack = BaseAttack
    local NormalizedAttackPercent = NormalizePercent(AttackPercent)
    local FinalAttack = BaseAttack * (1 + NormalizedAttackPercent)
    local LocalAttackPercent = 0

    local LocalWeaponAttackKey = tostring(ItemID or "none") .. "|" .. tostring(SeriesKey or "none") .. "|" ..
                                     tostring(ItemName or "none") .. "|" .. tostring(Level or "none") .. "|" ..
                                     tostring(AttackPercent) .. "|" .. tostring(Round2(BaseAttack)) .. "|" ..
                                     tostring(Round2(CurrentBaseAttack))
    if not bForce and self.LastLocalWeaponAttackDisplayKey == LocalWeaponAttackKey then
        return
    end

    self.LastLocalWeaponAttackDisplayKey = LocalWeaponAttackKey
    -- self:ForceRefreshPropertySnapshot()
end

function UGCPlayerPawn:ApplyWeaponAttackBonusByItemID(ItemID, SeriesKey, ItemName, Level, bForce)
    if self:HasAuthority() and self.PlayerState ~= nil and self.PlayerState.GetHunHuan ~= nil then
        UpdateRealmBonusResult(self, self.PlayerState:GetHunHuan())
    end

    ItemID = tonumber(ItemID)
    if ItemID == 0 then
        ItemID = nil
    end

    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if self:HasAuthority() and WeaponInfo ~= nil then
        self.LastClientWeaponAttackItemID = ItemID
    end
    if WeaponInfo ~= nil then
        SeriesKey = SeriesKey or WeaponInfo.SeriesKey
        if Level == nil then
            Level = WeaponInfo.Level
        end
        Level = math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(Level) or 1))
    end

    local Weapon = GetCurrentHeldWeapon(self)
    local AttackPercent = WeaponInfo ~= nil and WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponInfo.ID, Level) or 0
    if Weapon ~= nil and WeaponInfo ~= nil then
        Weapon.WeaponLevel = Level
        Weapon.WeaponConfigID = WeaponInfo.ID
        Weapon.WeaponLevel_0 = AttackPercent
        SetWeaponRuntimeDisplayName(Weapon, WeaponLevelConfig.BuildDisplayName(WeaponInfo.WPID, Level))
    end
    local BaseAttack = GetWeaponBaseAttack(self)
    local BackpackWeaponAttackPercent = CountBackpackWeaponAttackBonus(self)
    local RankAttackPercent = GetRankAttackBonus(self)
    local TotalAttackPercent = AttackPercent + BackpackWeaponAttackPercent + RankAttackPercent
    local NormalizedAttackPercent = NormalizePercent(TotalAttackPercent)
    local FinalAttack = BaseAttack * (1 + NormalizedAttackPercent)
    SetWeaponBonusPercent(self, AttackPercent, bForce)
    local bSetBaseAttackSuccess = false

    local WeaponAttackKey = tostring(ItemID or "none") .. "|" .. tostring(SeriesKey or "none") .. "|" ..
                                tostring(ItemName or "none") .. "|" .. tostring(Level or "none") .. "|" ..
                                tostring(AttackPercent) .. "|" .. tostring(BackpackWeaponAttackPercent) .. "|" ..
                                tostring(Round2(BaseAttack))
    if not bForce and self.LastWeaponAttackKey == WeaponAttackKey then
        return
    end

    self.LastWeaponAttackKey = WeaponAttackKey

    -- 服务端直接写入 AttackPower，不依赖客户端 RPC（避免 bArchiveLoaded 拦截导致武器伤害失效）
    if self:HasAuthority() then
        UGCAttributeSystem.SetGameAttributeValue(self, "AttackPower", FinalAttack)
        SyncTeamCombatPower()
    end

    ugcprint(
        "[UGCPlayerPawn:RefreshWeaponAttackBonus] item=" .. tostring(ItemID) .. ", series=" .. tostring(SeriesKey) ..
            ", name=" .. tostring(ItemName) .. ", level=" .. tostring(Level) .. ", attackPercent=" ..
            tostring(AttackPercent) .. ", backpackAttackPercent=" .. tostring(BackpackWeaponAttackPercent) ..
            ", rankAttackPercent=" .. tostring(RankAttackPercent) ..
            ", totalAttackPercent=" .. tostring(TotalAttackPercent) .. ", baseAttack=" .. tostring(BaseAttack) .. ", finalAttack=" ..
            tostring(FinalAttack) .. ", setBaseAttackSuccess=" .. tostring(bSetBaseAttackSuccess))

    -- self:ForceRefreshPropertySnapshot()
end

-- 服务端按基础攻击应用排行百分比差值；覆盖新旧值，不对当前攻击力重复乘算。
function UGCPlayerPawn:ApplyRankAttackBonusDelta(OldBonus, NewBonus)
    if self.HasAuthority == nil or self:HasAuthority() == false then
        return false
    end

    local BaseAttack = GetWeaponBaseAttack(self)
    local CurrentAttack = tonumber(UGCAttributeSystem.GetGameAttributeValue(self, "AttackPower")) or BaseAttack
    OldBonus = math.max(0, tonumber(OldBonus) or 0)
    NewBonus = math.max(0, tonumber(NewBonus) or 0)
    local FinalAttack = math.max(0, CurrentAttack + BaseAttack * (NewBonus - OldBonus) / 100)

    UGCAttributeSystem.SetGameAttributeValue(self, "AttackPower", FinalAttack)
    SyncTeamCombatPower()
    self:ForceRefreshPropertySnapshot()
    ugcprint(string.format("[UGCPlayerPawn] Rank attack applied: Old=%s New=%s Base=%s Final=%s",
        tostring(OldBonus), tostring(NewBonus), tostring(BaseAttack), tostring(FinalAttack)))
    return true
end

function UGCPlayerPawn:ForceRefreshPropertySnapshot()
    self.LastPropertyWatchKey = nil
    self:NotifyPropertyChangedIfNeeded(true)
end
-- 境界主动读取入口
function UGCPlayerPawn:RefreshStateMgrProperty(bFillHealth)
    local playerState = self.PlayerState
    if playerState == nil then
        return
    end

    if playerState.GetHunHuan ~= nil then
        self:RefreshSoulMesh(playerState:GetHunHuan())
    end

    self.LastWeaponAttackKey = nil
    self.LastLocalWeaponAttackDisplayKey = nil
    self.WeaponBaseAttackPower = nil
    self:RefreshWeaponAttackBonus(true)

    local baseAttack = playerState.GetBaseAttack ~= nil and playerState:GetBaseAttack() or DEFAULT_BASE_ATTACK
    local baseMaxHp = playerState.GetBaseMaxHp ~= nil and playerState:GetBaseMaxHp() or 100

    if self:HasAuthority() then
        UGCPawnAttrSystem.SetHealthMax(self, baseMaxHp)
        if bFillHealth then
            UGCPawnAttrSystem.SetHealth(self, baseMaxHp)
        end

        local playerController = self.Controller
        if playerController ~= nil then
            UnrealNetwork.CallUnrealRPC(playerController, playerController, "Client_RefreshProperty", baseAttack,
                baseMaxHp, nil, nil, bFillHealth == true)
        end
    else
        UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.ReFreshProperty, baseAttack,
            baseMaxHp, nil, nil, bFillHealth == true)
    end

    self:ForceRefreshPropertySnapshot()
end

function UGCPlayerPawn:GetRealmBonusResult()
    if self.RealmBonusResult == nil and self.PlayerState ~= nil and self.PlayerState.GetHunHuan ~= nil then
        UpdateRealmBonusResult(self, self.PlayerState:GetHunHuan())
    end
    return self.RealmBonusResult
end

function UGCPlayerPawn:NotifyPropertyChangedIfNeeded(bForce)
    if not IsLocalPlayerPawn(self) then
        return
    end

    local propertyWatchKey = BuildPropertyWatchKey(self)
    if propertyWatchKey == nil then
        return
    end

    if bForce or self.LastPropertyWatchKey ~= propertyWatchKey then
        self.LastPropertyWatchKey = propertyWatchKey
        local hp = UGCPawnAttrSystem.GetHealth(self)
        local maxHp = UGCPawnAttrSystem.GetHealthMax(self)
        UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.ReFreshProperty, nil, nil, hp, maxHp)
    end
end

function UGCPlayerPawn:UGC_PlayerDeadEvent(Killer, DamageType)
    -- Pawn 死亡时通常不会立刻触发 EndPlay，因此在死亡回调中主动销毁 WQ。
    AK47Orbit.Stop(self)
    DestroySoulMesh(self)
    DestroyAttachedActors(self)
    self:NotifyPropertyChangedIfNeeded(true)
end

function UGCPlayerPawn:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    self:NotifyPropertyChangedIfNeeded(true)

    local hp = UGCPawnAttrSystem.GetHealth(self)
    local maxHp = UGCPawnAttrSystem.GetHealthMax(self)

    if self:HasAuthority() then
        local playerController = self.Controller
        if playerController ~= nil then
            UnrealNetwork.CallUnrealRPC(playerController, playerController, "Client_RefreshProperty", nil, nil, hp,
                maxHp)
        end
    else
        UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.ReFreshProperty, nil, nil, hp, maxHp)
    end
end

function UGCPlayerPawn:ReceiveEndPlay()
    UGCGenericMessageSystem.UnListenMessage(self, L_Enum_Event.Enum.ReFreshZhanLi_01)

    AK47Orbit.Stop(self)

    -- Pawn 离场前，将当前血量写入跨对局存档（防止玩家未死亡直接退出）
    local playerState = self.PlayerState
    if playerState and playerState.SaveCurrentHP then
        playerState:SaveCurrentHP(self)
    end

    DestroySoulMesh(self)
    DestroyAttachedActors(self)

    -- Pawn 重生或离场时，主动清理附属称号 Actor。
    if self:HasAuthority() and self.PlayerTitleActor and UE.IsValid(self.PlayerTitleActor) then
        RemoveReplicatedSubObject(self, self.PlayerTitleActor)
        self.PlayerTitleActor:K2_DestroyActor()
        self.PlayerTitleActor = nil
    end

    UGCPlayerPawn.SuperClass.ReceiveEndPlay(self)
end

function UGCPlayerPawn:InitPlayerState()
    local playerState = self.PlayerState
    if playerState == nil then
        return
    end
    local HunHuan = playerState:GetHunHuan()
    UpdateRealmBonusResult(self, HunHuan)
    self:ShowZhanLi()
    CreateSoulMesh(self, HunHuan)
end

function UGCPlayerPawn:RefreshSoulMesh(HunHuan, bFillHealth)
    HunHuan = math.max(1, math.min(RealmConfig.MaxLevel, tonumber(HunHuan) or 1))
    UpdateRealmBonusResult(self, HunHuan)
    CreateSoulMesh(self, HunHuan)
end

function UGCPlayerPawn:ShowZhanLi()
    local playerState = self.PlayerState
    if playerState == nil then
        return
    end
    local HunHuan = playerState:GetHunHuan()
    -- 战力在这里设定,现在是魂环等级加小等级
    local dengji = HunHuan * 10
    --[[-------------------这边是测试通知的---------------------------]] --
    -- UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(self, L_Enum_Event.Enum.ReFreshZhanLi, tostring(dengji))
end

function UGCPlayerPawn:UGC_TakeDamageOverrideEvent(Damage, DamageType, EventInstigator, DamageCauser, Hit)
    if not self:HasAuthority() then
        return Damage
    end
    local VictimKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(self)
    local AttackerKey = EventInstigator and EventInstigator.PlayerKey or nil
    if AttackerKey == nil and EventInstigator ~= nil and EventInstigator.Pawn ~= nil then
        AttackerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(EventInstigator.Pawn)
    end
    local GameMode = UGCGameSystem.GetGameMode()
    if GameMode ~= nil and GameMode.ArePlayersInSameSquad ~= nil and
        GameMode:ArePlayersInSameSquad(VictimKey, AttackerKey) then
        ugcprint("[Team] Server blocked friendly damage attacker=" .. tostring(AttackerKey) .. " victim=" ..
                     tostring(VictimKey) .. " damage=" .. tostring(Damage))
        return 0
    end
    return Damage
end

function UGCPlayerPawn:GetReplicatedProperties()
    return {"__SubObjectRepList", "Lazy"}, {"EquippedTitleID", "EquippedWingVisualItemID"}
end

return UGCPlayerPawn
