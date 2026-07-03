---@class cb_6_C:AActor
---@field cb_1 USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local cb_6 = {}
 
--[[
function cb_6:ReceiveBeginPlay()
    cb_6.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function cb_6:ReceiveTick(DeltaTime)
    cb_6.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function cb_6:ReceiveEndPlay()
    cb_6.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function cb_6:GetReplicatedProperties()
    return
end
--]]

--[[
function cb_6:GetAvailableServerRPCs()
    return
end
--]]

return cb_6