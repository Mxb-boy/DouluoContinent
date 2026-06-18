---@class LSSL_1_C:PESkillProjectileBase
---@field ParticleSystem UParticleSystemComponent
---@field Box UBoxComponent
--Edit Below--
local LSSL_1 = {}
 
--[[
function LSSL_1:ReceiveBeginPlay()
    LSSL_1.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function LSSL_1:ReceiveTick(DeltaTime)
    LSSL_1.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function LSSL_1:ReceiveEndPlay()
    LSSL_1.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function LSSL_1:GetReplicatedProperties()
    return
end
--]]

--[[
function LSSL_1:GetAvailableServerRPCs()
    return
end
--]]

return LSSL_1