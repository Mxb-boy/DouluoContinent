---@class UGCPlayerPawn_C:BP_UGCPlayerPawn_C
-- Edit Below--
local UGCPlayerPawn = {}
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local RealmConfig = UGCGameSystem.UGCRequire("Script.Common.RealmConfig")
local L_Enum_Event = UGCGameSystem.UGCRequire("Script.Lin.L_Enum_Event")
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

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

local function GetWeaponBaseAttack(player)
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
    for _, ItemData in pairs(AllItemData) do
        local ItemID = tonumber(ItemData.ItemID or ItemData.ItemId or ItemData.itemID or ItemData.TypeSpecificID)
        local Count = tonumber(ItemData.Count or ItemData.ItemCount or ItemData.ItemNum or ItemData.Num) or 1
        if Count > 0 and WeaponLevelConfig.GetWeaponInfo(ItemID) ~= nil then
            WeaponCount = WeaponCount + Count
        end
    end

    return WeaponCount * BACKPACK_WEAPON_ATTACK_PER_ITEM, WeaponCount
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
        return DirectItemID, WeaponLevelConfig.GetWeaponInfo(DirectItemID)
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
                return ItemID, WeaponInfo
            end
        end
    end

    local FunctionNames = {"GetItemID", "GetItemId", "GetItemDefineID", "GetDefineID", "GetDefineId"}
    for _, FunctionName in ipairs(FunctionNames) do
        local ItemID = tonumber(TryCall(Object, FunctionName))
        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
        if WeaponInfo ~= nil then
            return ItemID, WeaponInfo
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
                return Weapon.WPID, WeaponLevelConfig.GetWeaponInfo(Weapon.WPID)
            end
        end
    end

    local FallbackItemID = GetItemIDFromObject(Object)
    return FallbackItemID, WeaponLevelConfig.GetWeaponInfo(FallbackItemID)
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

local function GetBestBackpackWeaponItemID(player, SeriesKey)
    if player == nil or SeriesKey == nil or UGCBackPackSystem == nil or UGCBackPackSystem.GetAllItemData == nil then
        return nil
    end

    local AllItemData = UGCBackPackSystem.GetAllItemData(player)
    if AllItemData == nil then
        return nil
    end

    local BestItemID = nil
    local BestLevel = 0
    for _, ItemData in pairs(AllItemData) do
        local ItemID = tonumber(ItemData.ItemID)
        local Count = tonumber(ItemData.Count or ItemData.ItemCount or ItemData.ItemNum or ItemData.Num) or 0
        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
        if Count > 0 and WeaponInfo ~= nil and WeaponInfo.SeriesKey == SeriesKey and WeaponInfo.Level > BestLevel then
            BestItemID = ItemID
            BestLevel = WeaponInfo.Level
        end
    end

    return BestItemID
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

    local ItemID, WeaponInfo = GetWeaponInfoFromObject(Weapon)
    local ActorLevel = tonumber(Weapon.WeaponLevel)
    if WeaponInfo ~= nil then
        local HeldWeaponName = GetWeaponObjectItemName(Weapon)
        local NameLevel = GetLevelFromName(HeldWeaponName)
        -- Backpack replacement can leave the equipped actor on its old item ID briefly.
        -- The controller cache is updated by the forge result before this refresh runs.
        local CachedLevel = player.WeaponLevelByID ~= nil and tonumber(player.WeaponLevelByID[WeaponInfo.ID]) or nil
        local Controller = player.Controller
        if CachedLevel == nil and Controller ~= nil and Controller.WeaponLevelByID ~= nil then
            CachedLevel = tonumber(Controller.WeaponLevelByID[WeaponInfo.ID])
        end
        local SavedLevel = nil
        if CachedLevel == nil and player.PlayerState ~= nil and player.PlayerState.GetWeaponLevel ~= nil and
            (player.PlayerState.HasWeaponLevel == nil or player.PlayerState:HasWeaponLevel(WeaponInfo.ID)) then
            SavedLevel = tonumber(player.PlayerState:GetWeaponLevel(WeaponInfo.ID))
        end

        local Level = math.max(1, math.min(WeaponInfo.MaxLevel, CachedLevel or SavedLevel or NameLevel or ActorLevel or
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
                         tostring(NameLevel) .. ", cachedLevel=" .. tostring(CachedLevel) .. ", savedLevel=" ..
                         tostring(SavedLevel) .. ", actorLevel=" .. tostring(ActorLevel))
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

        return GetBestBackpackWeaponItemID(player, SeriesKey) or WeaponLevelConfig.GetItemID(SeriesKey, 1), SeriesKey,
            ItemName, 1
    end

    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if WeaponInfo ~= nil then
        return ItemID, WeaponInfo.SeriesKey, GetItemConfigName(ItemID), WeaponInfo.Level
    end

    SeriesKey = GetSeriesKeyFromName(GetObjectName(Weapon))
    if SeriesKey == nil then
        return nil, nil
    end

    return GetBestBackpackWeaponItemID(player, SeriesKey) or WeaponLevelConfig.GetItemID(SeriesKey, 1), SeriesKey, nil,
        nil
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

function UGCPlayerPawn:ReceiveBeginPlay()
    UGCPlayerPawn.SuperClass.ReceiveBeginPlay(self)
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

    if not self:HasAuthority() then
        return
    end

    self:EnsurePlayerTitleActor()
end

function UGCPlayerPawn:ReceiveTick(DeltaTime)
    if UGCPlayerPawn.SuperClass ~= nil and UGCPlayerPawn.SuperClass.ReceiveTick ~= nil then
        UGCPlayerPawn.SuperClass.ReceiveTick(self, DeltaTime)
    end

    local SafeDeltaTime = tonumber(DeltaTime) or 0.016

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
    local NormalizedAttackPercent = NormalizePercent(AttackPercent)
    local FinalAttack = BaseAttack * (1 + NormalizedAttackPercent)
    SetWeaponBonusPercent(self, AttackPercent, bForce)
    local bSetBaseAttackSuccess = false

    local WeaponAttackKey = tostring(ItemID or "none") .. "|" .. tostring(SeriesKey or "none") .. "|" ..
                                tostring(ItemName or "none") .. "|" .. tostring(Level or "none") .. "|" ..
                                tostring(AttackPercent) .. "|" .. tostring(Round2(BaseAttack))
    if not bForce and self.LastWeaponAttackKey == WeaponAttackKey then
        return
    end

    self.LastWeaponAttackKey = WeaponAttackKey

    -- 服务端直接写入 AttackPower，不依赖客户端 RPC（避免 bArchiveLoaded 拦截导致武器伤害失效）
    if self:HasAuthority() then
        UGCAttributeSystem.SetGameAttributeValue(self, "AttackPower", FinalAttack)
    end

    ugcprint(
        "[UGCPlayerPawn:RefreshWeaponAttackBonus] item=" .. tostring(ItemID) .. ", series=" .. tostring(SeriesKey) ..
            ", name=" .. tostring(ItemName) .. ", level=" .. tostring(Level) .. ", attackPercent=" ..
            tostring(AttackPercent) .. ", baseAttack=" .. tostring(BaseAttack) .. ", finalAttack=" ..
            tostring(FinalAttack) .. ", setBaseAttackSuccess=" .. tostring(bSetBaseAttackSuccess))

    -- self:ForceRefreshPropertySnapshot()
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

function UGCPlayerPawn:GetReplicatedProperties()
    return {"__SubObjectRepList", "Lazy", "EquippedTitleID"}
end

return UGCPlayerPawn
