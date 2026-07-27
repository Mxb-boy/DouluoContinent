---@class Skill_2_C:PESkillTemplate_Base_C
--Edit Below--
local Skill_2 = {}
 
function Skill_2:OnEnableSkill_BP()
    Skill_2.SuperClass.OnEnableSkill_BP(self)
end

function Skill_2:OnDisableSkill_BP()
    Skill_2.SuperClass.OnDisableSkill_BP(self)
end

function Skill_2:OnActivateSkill_BP()
    Skill_2.SuperClass.OnActivateSkill_BP(self)
end

function Skill_2:OnDeActivateSkill_BP()
    Skill_2.SuperClass.OnDeActivateSkill_BP(self)
end

function Skill_2:CanActivateSkill_BP()
    return Skill_2.SuperClass.CanActivateSkill_BP(self)
end

return Skill_2