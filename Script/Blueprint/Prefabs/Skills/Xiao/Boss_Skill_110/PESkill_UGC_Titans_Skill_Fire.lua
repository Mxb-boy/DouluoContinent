---@class PESkill_UGC_Titans_Skill_Fire_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_UGC_Titans_Skill_Fire = {}
 
function PESkill_UGC_Titans_Skill_Fire:OnEnableSkill_BP()
    PESkill_UGC_Titans_Skill_Fire.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_UGC_Titans_Skill_Fire:OnDisableSkill_BP()
    PESkill_UGC_Titans_Skill_Fire.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_UGC_Titans_Skill_Fire:OnActivateSkill_BP()
    PESkill_UGC_Titans_Skill_Fire.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_UGC_Titans_Skill_Fire:OnDeActivateSkill_BP()
    PESkill_UGC_Titans_Skill_Fire.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_UGC_Titans_Skill_Fire:CanActivateSkill_BP()
    return PESkill_UGC_Titans_Skill_Fire.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_UGC_Titans_Skill_Fire