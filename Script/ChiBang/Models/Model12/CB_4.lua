---@class CB_4_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_4 = {}
 
--[[
function CB_4:ReceiveBeginPlay()
    CB_4.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function CB_4:ReceiveTick(DeltaTime)
    CB_4.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function CB_4:ReceiveEndPlay()
    CB_4.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function CB_4:GetReplicatedProperties()
    return
end
--]]

--[[
function CB_4:GetAvailableServerRPCs()
    return
end
--]]

return CB_4