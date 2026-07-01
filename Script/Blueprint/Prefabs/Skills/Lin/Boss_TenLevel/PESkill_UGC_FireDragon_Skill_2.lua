---@class PESkill_UGC_FireDragon_Skill_2_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_UGC_FireDragon_Skill_2 = {}
 
function PESkill_UGC_FireDragon_Skill_2:OnEnableSkill_BP()
    PESkill_UGC_FireDragon_Skill_2.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_UGC_FireDragon_Skill_2:OnDisableSkill_BP()
    PESkill_UGC_FireDragon_Skill_2.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_UGC_FireDragon_Skill_2:OnActivateSkill_BP()
    PESkill_UGC_FireDragon_Skill_2.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_UGC_FireDragon_Skill_2:OnDeActivateSkill_BP()
    PESkill_UGC_FireDragon_Skill_2.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_UGC_FireDragon_Skill_2:CanActivateSkill_BP()
    return PESkill_UGC_FireDragon_Skill_2.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_UGC_FireDragon_Skill_2