local UGCPlayerPawn = {}

local SOUL_MESH_PATH = "Asset/Blueprint/Lin/Monster/Model/NewModel/"
local SOUL_SOCKET = "Root"
local SOUL_SCALE = Vector.New(50, 50, 50)
local SOUL_OFFSET = Vector.New(0, 0, 0)
local SOUL_ROTATION = Rotator.New(90, 0, 0)

function UGCPlayerPawn:ReceiveBeginPlay()
    UGCPlayerPawn.SuperClass.ReceiveBeginPlay(self)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.Test_01)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshZhanLi)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshZhanLi_01)
    UGCGenericMessageSystem.ListenObjectMessage(self, L_Enum_Event.Enum.ReFreshZhanLi_01, self, self.InitPlayerState)
    UGCPawnAttrSystem.SetSpeedScale(self, 3)
    self:InitPlayerState()
end

local function CreateSoulMesh(player, HunHuan)

   if player == nil then
        return
    end

    if player.SoulMeshActor ~= nil then
        UGCActorComponentUtility.DestroyActor(player.SoulMeshActor)
        player.SoulMeshActor = nil
    end

    local SoulPath=SOUL_MESH_PATH.."M_"..tostring(HunHuan)..".M_"..tostring(HunHuan)
    local meshPath = UGCGameSystem.GetUGCResourcesFullPath(SoulPath)
    local soulMesh = UE.LoadObject(meshPath)
    if soulMesh == nil then
        print("CreateSoulMesh load failed:", meshPath)
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
    local dengji = HunHuan*10 + HunHuan_Little
    UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(self, L_Enum_Event.Enum.ReFreshZhanLi, tostring(dengji))
end

function UGCPlayerPawn:GetReplicatedProperties()
    return {"__SubObjectRepList", "Lazy"}
end

return UGCPlayerPawn
