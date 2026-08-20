---@class CB_T5_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_T5 = {}
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

local function DestroyIfOwnerInvalid(actor)
    actor.OwnerPawn = actor.OwnerPawn or UGCActorComponentUtility.GetOwner(actor)
    local ownerPawn = actor.OwnerPawn
    if ownerPawn == nil or (UE ~= nil and UE.IsValid ~= nil and not UE.IsValid(ownerPawn)) then
        actor:K2_DestroyActor()
    end
end

function CB_T5:IsDouluoWingActor()
    return true
end

function CB_T5:ReceiveBeginPlay()
    CB_T5.SuperClass.ReceiveBeginPlay(self)
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(5)
    end
end

function CB_T5:ReceiveTick(DeltaTime)
    CB_T5.SuperClass.ReceiveTick(self, DeltaTime)
    DestroyIfOwnerInvalid(self)
end

function CB_T5:ReceiveEndPlay()
    CB_T5.SuperClass.ReceiveEndPlay(self) 
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(0)
    end
end

--[[
function CB_T5:GetReplicatedProperties()
    return
end
--]]

--[[
function CB_T5:GetAvailableServerRPCs()
    return
end
--]]

return CB_T5
