---@class CreateMonsWall_C:AActor
---@field Box UBoxComponent
---@field StaticMesh UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CreateMonsWall = {}
 
--[[
function CreateMonsWall:ReceiveBeginPlay()
    CreateMonsWall.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function CreateMonsWall:ReceiveTick(DeltaTime)
    CreateMonsWall.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function CreateMonsWall:ReceiveEndPlay()
    CreateMonsWall.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function CreateMonsWall:GetReplicatedProperties()
    return
end
--]]

--[[
function CreateMonsWall:GetAvailableServerRPCs()
    return
end
--]]

return CreateMonsWall