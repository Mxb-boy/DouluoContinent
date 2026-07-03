---@class CB_5_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_5 = {}
 
--[[
function CB_5:ReceiveBeginPlay()
    CB_5.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function CB_5:ReceiveTick(DeltaTime)
    CB_5.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

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