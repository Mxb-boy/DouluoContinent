---@class LSSL_2_C:PESkillProjectileBase
---@field StaticMesh1 UStaticMeshComponent
---@field StaticMesh UStaticMeshComponent
---@field Play_UGC_Skill_ChargedPunch_Throw UAkComponent
---@field ParticleSystem UParticleSystemComponent
---@field Sphere USphereComponent
--Edit Below--
local LSSL_2 = {}
 
--[[
function LSSL_2:ReceiveBeginPlay()
    LSSL_2.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function LSSL_2:ReceiveTick(DeltaTime)
    LSSL_2.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function LSSL_2:ReceiveEndPlay()
    LSSL_2.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function LSSL_2:GetReplicatedProperties()
    return
end
--]]

--[[
function LSSL_2:GetAvailableServerRPCs()
    return
end
--]]

return LSSL_2