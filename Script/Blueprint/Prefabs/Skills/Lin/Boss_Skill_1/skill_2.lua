---@class skill_2_C:PESkillTemplate_Base_C
--Edit Below--
local skill_2 = {}
 
function skill_2:OnEnableSkill_BP()
    skill_2.SuperClass.OnEnableSkill_BP(self)
end

function skill_2:OnDisableSkill_BP()
    skill_2.SuperClass.OnDisableSkill_BP(self)
end

function skill_2:OnActivateSkill_BP()
    skill_2.SuperClass.OnActivateSkill_BP(self)
end

function skill_2:OnDeActivateSkill_BP()
    skill_2.SuperClass.OnDeActivateSkill_BP(self)
end

function skill_2:CanActivateSkill_BP()
    return skill_2.SuperClass.CanActivateSkill_BP(self)
end

return skill_2