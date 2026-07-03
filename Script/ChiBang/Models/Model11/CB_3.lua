---@class CB_3_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_3 = {}

local function DestroyIfOwnerInvalid(actor)
    actor.OwnerPawn = actor.OwnerPawn or UGCActorComponentUtility.GetOwner(actor)
    local ownerPawn = actor.OwnerPawn
    if ownerPawn == nil or (UE ~= nil and UE.IsValid ~= nil and not UE.IsValid(ownerPawn)) then
        actor:K2_DestroyActor()
    end
end

--[[
function CB_3:ReceiveBeginPlay()
    CB_3.SuperClass.ReceiveBeginPlay(self)
end
--]]

function CB_3:ReceiveTick(DeltaTime)
    CB_3.SuperClass.ReceiveTick(self, DeltaTime)
    DestroyIfOwnerInvalid(self)
end

--[[
function CB_3:ReceiveEndPlay()
    CB_3.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function CB_3:GetReplicatedProperties()
    return
end
--]]

--[[
function CB_3:GetAvailableServerRPCs()
    return
end
--]]

return CB_3
