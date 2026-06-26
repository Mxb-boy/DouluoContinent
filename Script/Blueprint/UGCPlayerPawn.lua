local UGCPlayerPawn = {}
local Property = UGCGameSystem.UGCRequire("Script.property.property")

local FLY_STATE_TAG = "PawnState.Movement.Flying"
local FLY_INTERRUPT_TAGS = {
    "PawnState.Movement.Walk",
    "PawnState.Movement.Run",
    "PawnState.Action.Jump",
    "PawnState.Action.Crouch",
    "PawnState.Action.Prone",
    "PawnState.Action.Reload",
    "PawnState.Action.Fire",
    "PawnState.Action.HoldWeapon",
    "PawnState.Movement.Fall",
}
local FLY_DISABLE_TAGS = {
    "PawnState.Movement.Walk",
    "PawnState.Movement.Run",
    "PawnState.Action.Jump",
    "PawnState.Action.Crouch",
    "PawnState.Action.Prone",
    "PawnState.Action.Reload",
    "PawnState.Action.Fire",
}
local SOUL_MESH_PATH = "Asset/Blueprint/Lin/Monster/Model/NewModel/"
local SOUL_SOCKET = "Root"
local SOUL_SCALE = Vector.New(300, 300, 300)
local SOUL_OFFSET = Vector.New(0, 0, 0)
local SOUL_ROTATION = Rotator.New(90, 0, 0)

local function Round2(value)
    value = tonumber(value) or 0
    return math.floor(value * 100 + 0.5) / 100
end

local function IsLocalPlayerPawn(player)
    if player == nil or UGCGameSystem == nil or UGCGameSystem.GetLocalPlayerPawn == nil then
        return false
    end

    return UGCGameSystem.GetLocalPlayerPawn() == player
end

local function BuildPropertyWatchKey(player)
    if player == nil or Property == nil or Property.GetSnapshot == nil then
        return nil
    end

    local snapshot = Property.GetSnapshot(player, player)
    return table.concat({
        tostring(Round2(snapshot.CurrentHP)),
        tostring(Round2(snapshot.MaxHP)),
        tostring(Round2(snapshot.Attack)),
        tostring(Round2(snapshot.CombatPower)),
    }, "|")
end

local function DestroySoulMesh(player)
    if player ~= nil and player.SoulMeshActor ~= nil then
        UGCActorComponentUtility.DestroyActor(player.SoulMeshActor)
        player.SoulMeshActor = nil
    end
end

local function CreateSoulMesh(player, HunHuan)
    if player == nil then
        return
    end

    DestroySoulMesh(player)

    local SoulPath = UGCMapInfoLib.GetRootLongPackagePath() .. SOUL_MESH_PATH .. "M_" .. tostring(HunHuan) .. ".M_" .. tostring(HunHuan)
    local soulMesh = UE.LoadObject(SoulPath)
    if soulMesh == nil then
        print("CreateSoulMesh load failed:", SoulPath)
        return
    end

    local staticMeshActorClass = UE.LoadClass("/Script/Engine.StaticMeshActor")
    local soulActor = UGCActorComponentUtility.SpawnActor(
        player,
        staticMeshActorClass,
        Vector.New(0, 0, 0),
        Rotator.New(0, 0, 0),
        SOUL_SCALE,
        player
    )
    if soulActor == nil then
        return
    end

    player.SoulMeshActor = soulActor

    local meshComponent = soulActor.StaticMeshComponent
    meshComponent:K2_SetMobility(EComponentMobility.Movable)
    meshComponent:SetStaticMesh(soulMesh)
    meshComponent:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    UGCActorComponentUtility.AttachToComponent(
        soulActor,
        player.Mesh,
        EAttachmentRule.SnapToTarget,
        EAttachmentRule.SnapToTarget,
        EAttachmentRule.KeepWorld,
        SOUL_SOCKET,
        false
    )
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

    local titleClass = UE.LoadClass(
        UGCMapInfoLib.GetRootLongPackagePath()
        .. "Asset/Blueprint/UI/BP_PlayerTitleActor.BP_PlayerTitleActor_C")

    if titleClass == nil then
        ugcprint("[UGCPlayerPawn] Title class load failed")
        return nil
    end

    local location = self:K2_GetActorLocation()

    self.PlayerTitleActor = UGCActorComponentUtility.SpawnActor(
        self,
        titleClass,
        location,
        {X = 0, Y = 0, Z = 0},
        {X = 1, Y = 1, Z = 1},
        self
    )

    if self.PlayerTitleActor == nil then
        ugcprint("[UGCPlayerPawn] PlayerTitleActor spawn failed")
        return nil
    end

    UGCActorComponentUtility.AttachToComponent(
        self.PlayerTitleActor,
        self.CapsuleComponent,
        EAttachmentRule.SnapToTarget,
        EAttachmentRule.SnapToTarget,
        EAttachmentRule.KeepRelative,
        "",
        false
    )

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
    UGCPawnAttrSystem.SetSpeedScale(self, 3)

    self.EquippedTitleID = self.EquippedTitleID or 0
    self.PropertyWatchElapsed = 0
    self.LastPropertyWatchKey = nil

    self:InitPlayerState()
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

    self.PropertyWatchElapsed = (self.PropertyWatchElapsed or 0) + (tonumber(DeltaTime) or 0.016)
    if self.PropertyWatchElapsed < 0.1 then
        return
    end

    self.PropertyWatchElapsed = 0
    self:NotifyPropertyChangedIfNeeded(false)
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
        Property.NotifyChanged(self)
    end
end

function UGCPlayerPawn:UGC_PlayerDeadEvent(Killer, DamageType)
    DestroySoulMesh(self)
    self:NotifyPropertyChangedIfNeeded(true)
end

function UGCPlayerPawn:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    self:NotifyPropertyChangedIfNeeded(true)
end

function UGCPlayerPawn:ReceiveEndPlay()
    -- Pawn 离场前，将当前血量写入跨对局存档（防止玩家未死亡直接退出）
    local playerState = self.PlayerState
    if playerState and playerState.SaveCurrentHP then
        playerState:SaveCurrentHP(self)
    end

    DestroySoulMesh(self)

    -- Pawn 重生或离场时，主动清理附属称号 Actor。
    if self:HasAuthority()
        and self.PlayerTitleActor
        and UE.IsValid(self.PlayerTitleActor) then
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
    self:ShowZhanLi()
    CreateSoulMesh(self, HunHuan)
end

function UGCPlayerPawn:ShowZhanLi()
    local playerState = self.PlayerState
    local HunHuan = playerState:GetHunHuan()
    --战力在这里设定,现在是魂环等级加小等级
    local dengji = HunHuan * 10 
    --[[-------------------这边是测试通知的---------------------------]]--
    -- UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(self, L_Enum_Event.Enum.ReFreshZhanLi, tostring(dengji))
end

function UGCPlayerPawn:GetReplicatedProperties()
    return {"__SubObjectRepList", "Lazy", "EquippedTitleID"}
end


return UGCPlayerPawn
