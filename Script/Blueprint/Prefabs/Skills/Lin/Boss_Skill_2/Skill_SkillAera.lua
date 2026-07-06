---@class Skill_SkillAera_C:PESkillTemplate_Base_C
--Edit Below--
local Skill_SkillAera = {}
 
function Skill_SkillAera:OnEnableSkill_BP()
    Skill_SkillAera.SuperClass.OnEnableSkill_BP(self)
end

function Skill_SkillAera:OnDisableSkill_BP()
    Skill_SkillAera.SuperClass.OnDisableSkill_BP(self)
end

function Skill_SkillAera:OnActivateSkill_BP()
    Skill_SkillAera.SuperClass.OnActivateSkill_BP(self)
end

function Skill_SkillAera:OnDeActivateSkill_BP()
    Skill_SkillAera.SuperClass.OnDeActivateSkill_BP(self)
end

function Skill_SkillAera:CanActivateSkill_BP()
    return Skill_SkillAera.SuperClass.CanActivateSkill_BP(self)
end

return Skill_SkillAera