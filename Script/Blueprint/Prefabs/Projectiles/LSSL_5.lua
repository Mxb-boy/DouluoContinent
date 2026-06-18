---@class LSSL_5_C:PESkillProjectileBase
---@field StaticMesh1 UStaticMeshComponent
---@field StaticMesh UStaticMeshComponent
---@field Play_UGC_Skill_ChargedPunch_Throw UAkComponent
---@field ParticleSystem UParticleSystemComponent
---@field Sphere USphereComponent
--Edit Below--
local HTC_1 = {}
 
--[[
function HTC_1:ReceiveBeginPlay()
    HTC_1.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function HTC_1:ReceiveTick(DeltaTime)
    HTC_1.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function HTC_1:ReceiveEndPlay()
    HTC_1.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function HTC_1:GetReplicatedProperties()
    return
end
--]]

--[[
function HTC_1:GetAvailableServerRPCs()
    return
end
--]]

return HTC_1