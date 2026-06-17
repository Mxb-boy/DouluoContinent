---@class TSSJ_1_C:PESkillProjectileBase
---@field ParticleSystem UParticleSystemComponent
---@field Box UBoxComponent
--Edit Below--
local TSSJ_1 = {}
 
--[[
function TSSJ_1:ReceiveBeginPlay()
    TSSJ_1.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function TSSJ_1:ReceiveTick(DeltaTime)
    TSSJ_1.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function TSSJ_1:ReceiveEndPlay()
    TSSJ_1.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function TSSJ_1:GetReplicatedProperties()
    return
end
--]]

--[[
function TSSJ_1:GetAvailableServerRPCs()
    return
end
--]]

return TSSJ_1