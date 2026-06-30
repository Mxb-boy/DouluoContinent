---@class skill_3_C:PESkillTemplate_Base_C
--Edit Below--
local skill_3 = {}
 
function skill_3:OnEnableSkill_BP()
    skill_3.SuperClass.OnEnableSkill_BP(self)
end

function skill_3:OnDisableSkill_BP()
    skill_3.SuperClass.OnDisableSkill_BP(self)
end

function skill_3:OnActivateSkill_BP()
    skill_3.SuperClass.OnActivateSkill_BP(self)
end

function skill_3:OnDeActivateSkill_BP()
    skill_3.SuperClass.OnDeActivateSkill_BP(self)
end

function skill_3:CanActivateSkill_BP()
    return skill_3.SuperClass.CanActivateSkill_BP(self)
end

return skill_3