---@class CB_5_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_5 = {}

local function DestroyIfOwnerInvalid(actor)
    actor.OwnerPawn = actor.OwnerPawn or UGCActorComponentUtility.GetOwner(actor)
    local ownerPawn = actor.OwnerPawn
    if ownerPawn == nil or (UE ~= nil and UE.IsValid ~= nil and not UE.IsValid(ownerPawn)) then
        actor:K2_DestroyActor()
    end
end

--[[
function CB_5:ReceiveBeginPlay()
    CB_5.SuperClass.ReceiveBeginPlay(self)
end
--]]

function CB_5:ReceiveTick(DeltaTime)
    CB_5.SuperClass.ReceiveTick(self, DeltaTime)
    DestroyIfOwnerInvalid(self)
end

--[[
function CB_5:ReceiveEndPlay()
    CB_5.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function CB_5:GetReplicatedProperties()
    return
end
--]]

--[[
function CB_5:GetAvailableServerRPCs()
    return
end
--]]

return CB_5
