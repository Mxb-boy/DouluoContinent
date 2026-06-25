local UGCPlayerPawn = {}

local SOUL_MESH_PATH = "Asset/Blueprint/Lin/Monster/Model/NewModel/"
local SOUL_SOCKET = "Root"
local SOUL_SCALE = Vector.New(300, 300, 300)
local SOUL_OFFSET = Vector.New(0, 0, 0)
local SOUL_ROTATION = Rotator.New(90, 0, 0)

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

function UGCPlayerPawn:ReceiveBeginPlay()
    UGCPlayerPawn.SuperClass.ReceiveBeginPlay(self)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.Test_01)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshZhanLi)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshZhanLi_01)
    UGCGenericMessageSystem.ListenObjectMessage(self, L_Enum_Event.Enum.ReFreshZhanLi_01, self, self.InitPlayerState)
    UGCPawnAttrSystem.SetSpeedScale(self, 3)

    self.EquippedTitleID = self.EquippedTitleID or 0

    self:InitPlayerState()

    if not self:HasAuthority() then
        return
    end

    self:EnsurePlayerTitleActor()
end

function UGCPlayerPawn:UGC_PlayerDeadEvent(Killer, DamageType)
    DestroySoulMesh(self)
end

function UGCPlayerPawn:ReceiveEndPlay()
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
    local HunHuan = playerState:GetHunHuan()
    self:ShowZhanLi()
    CreateSoulMesh(self, HunHuan)
end

function UGCPlayerPawn:ShowZhanLi()
    local playerState = self.PlayerState
    local HunHuan = playerState:GetHunHuan()
    local HunHuan_Little = playerState:GetHunHuan_Little()
    --战力在这里设定,现在是魂环等级加小等级
    local dengji = HunHuan * 10 + HunHuan_Little
    UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(self, L_Enum_Event.Enum.ReFreshZhanLi, tostring(dengji))
end

function UGCPlayerPawn:GetReplicatedProperties()
    return {"__SubObjectRepList", "Lazy", "EquippedTitleID"}
end


return UGCPlayerPawn
