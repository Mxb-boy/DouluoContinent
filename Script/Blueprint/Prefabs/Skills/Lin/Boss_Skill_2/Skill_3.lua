---@class Skill_3_C:PESkillTemplate_Base_C
--Edit Below--
local Skill_3 = {}
 
function Skill_3:OnEnableSkill_BP()
    Skill_3.SuperClass.OnEnableSkill_BP(self)
end

function Skill_3:OnDisableSkill_BP()
    Skill_3.SuperClass.OnDisableSkill_BP(self)
end

function Skill_3:OnActivateSkill_BP()
    Skill_3.SuperClass.OnActivateSkill_BP(self)
end

function Skill_3:OnDeActivateSkill_BP()
    Skill_3.SuperClass.OnDeActivateSkill_BP(self)
end

function Skill_3:CanActivateSkill_BP()
    return Skill_3.SuperClass.CanActivateSkill_BP(self)
end

return Skill_3