---@class BP_UGC_Rope_C:AActor
---@field EndMesh UStaticMeshComponent
---@field Cable UCableComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local BP_UGC_Rope = {}
 
function BP_UGC_Rope:PrintVector(Vector)
end
function BP_UGC_Rope:ReceiveBeginPlay()
    BP_UGC_Rope.SuperClass.ReceiveBeginPlay(self)
    self:PrintVector(self:K2_GetActorLocation())
end
--]]

--[[
function BP_UGC_Rope:ReceiveTick(DeltaTime)
    BP_UGC_Rope.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_UGC_Rope:ReceiveEndPlay()
    BP_UGC_Rope.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_UGC_Rope:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_UGC_Rope:GetAvailableServerRPCs()
    return
end
--]]

return BP_UGC_Rope