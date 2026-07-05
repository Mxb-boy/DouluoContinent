---@class cb_1_C:AActor
---@field cb_1 USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local cb_1 = {}
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

local function DestroyIfOwnerInvalid(actor)
    actor.OwnerPawn = actor.OwnerPawn or UGCActorComponentUtility.GetOwner(actor)
    local ownerPawn = actor.OwnerPawn
    if ownerPawn == nil or (UE ~= nil and UE.IsValid ~= nil and not UE.IsValid(ownerPawn)) then
        actor:K2_DestroyActor()
    end
end

function cb_1:ReceiveBeginPlay()
    cb_1.SuperClass.ReceiveBeginPlay(self)
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(2)
    end
end

function cb_1:ReceiveTick(DeltaTime)
    cb_1.SuperClass.ReceiveTick(self, DeltaTime)
    DestroyIfOwnerInvalid(self)
end

function cb_1:ReceiveEndPlay()
    cb_1.SuperClass.ReceiveEndPlay(self) 
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(0)
    end
end

--[[
function cb_1:GetReplicatedProperties()
    return
end
--]]

--[[
function cb_1:GetAvailableServerRPCs()
    return
end
--]]

return cb_1
