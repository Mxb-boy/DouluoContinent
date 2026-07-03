---@class CB_2_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_2 = {}

local function DestroyIfOwnerInvalid(actor)
    actor.OwnerPawn = actor.OwnerPawn or UGCActorComponentUtility.GetOwner(actor)
    local ownerPawn = actor.OwnerPawn
    if ownerPawn == nil or (UE ~= nil and UE.IsValid ~= nil and not UE.IsValid(ownerPawn)) then
        actor:K2_DestroyActor()
    end
end

--[[
function CB_2:ReceiveBeginPlay()
    CB_2.SuperClass.ReceiveBeginPlay(self)
end
--]]

function CB_2:ReceiveTick(DeltaTime)
    CB_2.SuperClass.ReceiveTick(self, DeltaTime)
    DestroyIfOwnerInvalid(self)
end

--[[
function CB_2:ReceiveEndPlay()
    CB_2.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function CB_2:GetReplicatedProperties()
    return
end
--]]

--[[
function CB_2:GetAvailableServerRPCs()
    return
end
--]]

return CB_2
