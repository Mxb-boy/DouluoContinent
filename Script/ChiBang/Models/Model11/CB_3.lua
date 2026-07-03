---@class CB_3_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_3 = {}
 
--[[
function CB_3:ReceiveBeginPlay()
    CB_3.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function CB_3:ReceiveTick(DeltaTime)
    CB_3.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

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