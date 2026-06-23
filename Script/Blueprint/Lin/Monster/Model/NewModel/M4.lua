---@class M4_C:AActor
---@field StaticMesh UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local M4 = {}
 
--[[
function M4:ReceiveBeginPlay()
    M4.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function M4:ReceiveTick(DeltaTime)
    M4.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function M4:ReceiveEndPlay()
    M4.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function M4:GetReplicatedProperties()
    return
end
--]]

--[[
function M4:GetAvailableServerRPCs()
    return
end
--]]

return M4