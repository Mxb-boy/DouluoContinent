---@class MonsStartPoint_C:AActor
---@field DefaultSceneRoot USceneComponent
---@field Scene TEnumAsByte<Scene_Enum>
---@field BigLevel int32
---@field LittleLevel int32
---@field StartPoint int32
--Edit Below--
local MonsStartPoint = {}
 
--[[
function MonsStartPoint:ReceiveBeginPlay()
    MonsStartPoint.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function MonsStartPoint:ReceiveTick(DeltaTime)
    MonsStartPoint.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function MonsStartPoint:ReceiveEndPlay()
    MonsStartPoint.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function MonsStartPoint:GetReplicatedProperties()
    return
end
--]]

--[[
function MonsStartPoint:GetAvailableServerRPCs()
    return
end
--]]

return MonsStartPoint