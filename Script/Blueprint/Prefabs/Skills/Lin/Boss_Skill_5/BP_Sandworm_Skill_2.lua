---@class BP_Sandworm_Skill_2_C:PESkillTemplate_Base_C
--Edit Below--
local BP_Sandworm_Skill_2 = {}
 
function BP_Sandworm_Skill_2:OnEnableSkill_BP()
    BP_Sandworm_Skill_2.SuperClass.OnEnableSkill_BP(self)
end

function BP_Sandworm_Skill_2:OnDisableSkill_BP()
    BP_Sandworm_Skill_2.SuperClass.OnDisableSkill_BP(self)
end

function BP_Sandworm_Skill_2:OnActivateSkill_BP()
    BP_Sandworm_Skill_2.SuperClass.OnActivateSkill_BP(self)
end

function BP_Sandworm_Skill_2:OnDeActivateSkill_BP()
    BP_Sandworm_Skill_2.SuperClass.OnDeActivateSkill_BP(self)
end

function BP_Sandworm_Skill_2:CanActivateSkill_BP()
    return BP_Sandworm_Skill_2.SuperClass.CanActivateSkill_BP(self)
end

return BP_Sandworm_Skill_2