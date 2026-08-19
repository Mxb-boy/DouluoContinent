---@class WQ_C:AActor
---@field ParticleSystem UParticleSystemComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local WQ = {}
 
--[[
function WQ:ReceiveBeginPlay()
    WQ.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function WQ:ReceiveTick(DeltaTime)
    WQ.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function WQ:ReceiveEndPlay()
    WQ.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function WQ:GetReplicatedProperties()
    return
end
--]]

--[[
function WQ:GetAvailableServerRPCs()
    return
end
--]]

return WQ