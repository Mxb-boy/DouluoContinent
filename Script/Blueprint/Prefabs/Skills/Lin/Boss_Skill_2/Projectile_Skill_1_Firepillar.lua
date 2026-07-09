---@class Projectile_Skill_1_Firepillar_C:PESkillProjectileBase
---@field ParticleSystem UParticleSystemComponent
---@field Capsule1 UCapsuleComponent
--Edit Below--
local Projectile_Skill_1_Firepillar = {}
 
--[[
function Projectile_Skill_1_Firepillar:ReceiveBeginPlay()
    Projectile_Skill_1_Firepillar.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function Projectile_Skill_1_Firepillar:ReceiveTick(DeltaTime)
    Projectile_Skill_1_Firepillar.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function Projectile_Skill_1_Firepillar:ReceiveEndPlay()
    Projectile_Skill_1_Firepillar.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function Projectile_Skill_1_Firepillar:GetReplicatedProperties()
    return
end
--]]

--[[
function Projectile_Skill_1_Firepillar:GetAvailableServerRPCs()
    return
end
--]]

return Projectile_Skill_1_Firepillar