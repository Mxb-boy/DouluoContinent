---@class SkillAera_Firepillar_C:BP_MagicFieldActorBase_C
---@field P_CG035_Sandworm_Skill02_02 UParticleSystemComponent
---@field Capsule UCapsuleComponent
--Edit Below--
local SkillAera_Firepillar = {}
 
--[[
function SkillAera_Firepillar:ReceiveBeginPlay()
    SkillAera_Firepillar.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function SkillAera_Firepillar:ReceiveTick(DeltaTime)
    SkillAera_Firepillar.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function SkillAera_Firepillar:ReceiveEndPlay()
    SkillAera_Firepillar.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function SkillAera_Firepillar:GetReplicatedProperties()
    return
end
--]]

--[[
function SkillAera_Firepillar:GetAvailableServerRPCs()
    return
end
--]]

return SkillAera_Firepillar