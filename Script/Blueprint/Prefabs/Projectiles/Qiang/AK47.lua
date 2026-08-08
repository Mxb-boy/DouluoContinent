---@class AK47_C:PESkillProjectileBase
---@field StaticMesh UStaticMeshComponent
---@field ParticleSystem UParticleSystemComponent
---@field Box UBoxComponent
--Edit Below--
local AK47 = {}
 
--[[
function AK47:ReceiveBeginPlay()
    AK47.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function AK47:ReceiveTick(DeltaTime)
    AK47.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function AK47:ReceiveEndPlay()
    AK47.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function AK47:GetReplicatedProperties()
    return
end
--]]

--[[
function AK47:GetAvailableServerRPCs()
    return
end
--]]

return AK47