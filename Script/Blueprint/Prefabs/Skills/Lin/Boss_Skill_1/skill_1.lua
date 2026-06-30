---@class skill_1_C:PESkillTemplate_Base_C
--Edit Below--
local skill_1 = {}
 
function skill_1:OnEnableSkill_BP()
    skill_1.SuperClass.OnEnableSkill_BP(self)
end

function skill_1:OnDisableSkill_BP()
    skill_1.SuperClass.OnDisableSkill_BP(self)
end

function skill_1:OnActivateSkill_BP()
    skill_1.SuperClass.OnActivateSkill_BP(self)
end

function skill_1:OnDeActivateSkill_BP()
    skill_1.SuperClass.OnDeActivateSkill_BP(self)
end

function skill_1:CanActivateSkill_BP()
    return skill_1.SuperClass.CanActivateSkill_BP(self)
end

return skill_1