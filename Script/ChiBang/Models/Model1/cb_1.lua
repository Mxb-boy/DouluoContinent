---@class cb_1_C:AActor
---@field cb_1 USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local cb_1 = {}

--[[
function cb_1:ReceiveBeginPlay()
    cb_1.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function cb_1:ReceiveTick(DeltaTime)
    cb_1.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function cb_1:ReceiveEndPlay()
    cb_1.SuperClass.ReceiveEndPlay(self) 
end
--]]

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
